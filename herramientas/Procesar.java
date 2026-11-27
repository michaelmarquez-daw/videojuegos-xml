import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import javax.xml.XMLConstants;
import javax.xml.namespace.QName;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

/**
 * Valida el catálogo con la DTD y el XSD, ejecuta las consultas XPath
 * y genera salida/catalogo.html y datos/catalogo.json con XSLT.
 *
 * Uso, desde la carpeta del proyecto:
 *   java herramientas/Procesar.java                    (usa datos/catalogo.xml)
 *   java herramientas/Procesar.java otro-catalogo.xml  (solo valida y consulta, no genera nada)
 */
public class Procesar {

    private static final Path XML_POR_DEFECTO = Path.of("datos", "catalogo.xml");
    private static final Path XSD = Path.of("datos", "catalogo.xsd");
    private static final Path XSL_HTML = Path.of("xslt", "catalogo-a-html.xsl");
    private static final Path XSL_JSON = Path.of("xslt", "catalogo-a-json.xsl");
    private static final Path SALIDA_HTML = Path.of("salida", "catalogo.html");
    private static final Path SALIDA_JSON = Path.of("datos", "catalogo.json");

    private static final Locale ESPANOL = Locale.of("es", "ES");

    record Consulta(String descripcion, String expresion, QName tipo) {}

    // Las mismas consultas que están explicadas en xpath/consultas-xpath.md
    private static final List<Consulta> CONSULTAS = List.of(
        new Consulta("Número de juegos del catálogo",
            "count(/catalogo/juego)", XPathConstants.NUMBER),
        new Consulta("Títulos con PEGI 18",
            "/catalogo/juego[@pegi = 18]/titulo", XPathConstants.NODESET),
        new Consulta("Juegos de Switch por menos de 20 euros",
            "/catalogo/juego[plataformas/plataforma = 'Switch' and precio < 20]/titulo", XPathConstants.NODESET),
        new Consulta("Juegos que solo salieron en una plataforma",
            "/catalogo/juego[count(plataformas/plataforma) = 1]/titulo", XPathConstants.NODESET),
        new Consulta("Estudios españoles",
            "/catalogo/juego/estudio[@pais = 'ES']", XPathConstants.NODESET),
        new Consulta("Juego con la nota más alta",
            "/catalogo/juego[not(nota < ../juego/nota)]/titulo", XPathConstants.NODESET),
        new Consulta("Precio medio del catálogo",
            "sum(/catalogo/juego/precio) div count(/catalogo/juego)", XPathConstants.NUMBER),
        new Consulta("Géneros del juego más reciente",
            "(/catalogo/juego[not(anio < ../juego/anio)])[1]/generos/genero", XPathConstants.NODESET),
        new Consulta("Título del juego con id J07",
            "string(/catalogo/juego[@id = 'J07']/titulo)", XPathConstants.STRING),
        new Consulta("¿Hay algún juego PEGI 3 en Xbox Series?",
            "boolean(/catalogo/juego[@pegi = 3 and plataformas/plataforma = 'Xbox Series'])", XPathConstants.BOOLEAN)
    );

    public static void main(String[] args) throws Exception {
        Path xml = args.length > 0 ? Path.of(args[0]).normalize() : XML_POR_DEFECTO;
        if (!Files.exists(xml) || !Files.exists(XSD)) {
            System.err.println("No encuentro " + xml + " o " + XSD
                + ". Ejecuta el programa desde la carpeta del proyecto.");
            System.exit(1);
        }

        System.out.println("Procesando " + xml);

        System.out.println("\n1. Validación con la DTD");
        Document documento = cargarValidandoConDtd(xml);

        System.out.println("\n2. Validación con el XSD");
        validarConXsd(xml);

        System.out.println("\n3. Consultas XPath");
        ejecutarConsultas(documento);

        // Con un fichero de prueba no se sobrescriben el HTML ni el JSON del catálogo real
        if (!xml.equals(XML_POR_DEFECTO)) {
            System.out.println("\nEs un fichero de prueba: no se genera HTML ni JSON.");
            return;
        }

        System.out.println("\n4. Transformaciones XSLT");
        transformar(xml, XSL_HTML, SALIDA_HTML);
        transformar(xml, XSL_JSON, SALIDA_JSON);

        System.out.println("\nTerminado.");
    }

    private static Document cargarValidandoConDtd(Path xml) throws Exception {
        DocumentBuilderFactory fabrica = DocumentBuilderFactory.newInstance();
        fabrica.setValidating(true);
        fabrica.setNamespaceAware(true);
        // Solo funciona si hay DTD: quita los saltos de línea y sangrías entre elementos
        fabrica.setIgnoringElementContentWhitespace(true);

        DocumentBuilder constructor = fabrica.newDocumentBuilder();
        ListaErrores errores = new ListaErrores();
        constructor.setErrorHandler(errores);

        Document documento = null;
        try {
            documento = constructor.parse(xml.toFile());
        } catch (SAXParseException e) {
            // ya se ha guardado en errores
        } catch (IOException e) {
            // Por ejemplo, un DOCTYPE que apunta a una DTD que no existe
            System.out.println("   No se puede leer: " + e.getMessage());
            System.exit(1);
        }
        comprobar(errores);
        return documento;
    }

    private static void validarConXsd(Path xml) throws Exception {
        SchemaFactory fabrica = SchemaFactory.newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
        Schema esquema = fabrica.newSchema(XSD.toFile());
        Validator validador = esquema.newValidator();
        ListaErrores errores = new ListaErrores();
        validador.setErrorHandler(errores);
        try {
            validador.validate(new StreamSource(xml.toFile()));
        } catch (SAXParseException e) {
            // ya se ha guardado en errores
        } catch (IOException e) {
            System.out.println("   No se puede leer: " + e.getMessage());
            System.exit(1);
        }
        comprobar(errores);
    }

    private static void comprobar(ListaErrores errores) {
        if (errores.estaVacia()) {
            System.out.println("   Correcto: el documento es válido.");
            return;
        }
        System.out.println("   El documento NO es válido:");
        errores.todos().forEach(error -> System.out.println("   - " + error));
        System.exit(1);
    }

    private static void ejecutarConsultas(Document documento) throws Exception {
        XPath xpath = XPathFactory.newInstance().newXPath();
        int numero = 1;
        for (Consulta consulta : CONSULTAS) {
            Object resultado = xpath.evaluate(consulta.expresion(), documento, consulta.tipo());
            System.out.printf("%n  %2d. %s%n", numero++, consulta.descripcion());
            System.out.println("      " + consulta.expresion());
            for (String linea : comoTexto(resultado)) {
                System.out.println("      -> " + linea);
            }
        }
    }

    private static List<String> comoTexto(Object resultado) {
        List<String> lineas = new ArrayList<>();
        if (resultado instanceof NodeList nodos) {
            for (int i = 0; i < nodos.getLength(); i++) {
                lineas.add(nodos.item(i).getTextContent().trim());
            }
            if (lineas.isEmpty()) {
                lineas.add("(ningún nodo)");
            }
        } else if (resultado instanceof Double numero) {
            // Los enteros sin decimales y el resto con dos decimales y coma
            if (numero == Math.floor(numero)) {
                lineas.add(String.valueOf(numero.longValue()));
            } else {
                lineas.add(String.format(ESPANOL, "%.2f", numero));
            }
        } else {
            lineas.add(String.valueOf(resultado));
        }
        return lineas;
    }

    private static void transformar(Path xml, Path xsl, Path salida) throws Exception {
        Files.createDirectories(salida.getParent());
        Transformer transformador = TransformerFactory.newInstance()
            .newTransformer(new StreamSource(xsl.toFile()));
        transformador.transform(new StreamSource(xml.toFile()), new StreamResult(salida.toFile()));
        System.out.printf("   %s + %s -> %s (%d bytes)%n",
            xml.getFileName(), xsl.getFileName(), salida, Files.size(salida));
    }

    // Junta todos los errores para enseñarlos de una vez
    static class ListaErrores implements ErrorHandler {

        private final List<String> errores = new ArrayList<>();

        @Override
        public void warning(SAXParseException e) {
            System.out.println("   Aviso: " + e.getMessage());
        }

        @Override
        public void error(SAXParseException e) {
            anotar(e);
        }

        @Override
        public void fatalError(SAXParseException e) throws SAXException {
            anotar(e);
            throw e;
        }

        private void anotar(SAXParseException e) {
            errores.add("línea " + e.getLineNumber() + ", columna " + e.getColumnNumber()
                + ": " + e.getMessage());
        }

        boolean estaVacia() {
            return errores.isEmpty();
        }

        List<String> todos() {
            return errores;
        }
    }
}
