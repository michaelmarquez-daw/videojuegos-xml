'use strict';

const RUTA_CATALOGO = '../datos/catalogo.json';

const formulario = document.getElementById('filtros');
const estado = document.getElementById('estado');
const lista = document.getElementById('lista');
const plantilla = document.getElementById('plantilla-ficha');

const formatoPrecio = new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'EUR' });
const formatoNota = new Intl.NumberFormat('es-ES', { minimumFractionDigits: 1, maximumFractionDigits: 1 });

let juegos = [];

async function cargarCatalogo() {
  try {
    const respuesta = await fetch(RUTA_CATALOGO);
    if (!respuesta.ok) {
      throw new Error(`HTTP ${respuesta.status}`);
    }
    const datos = await respuesta.json();
    juegos = datos.juegos;

    rellenarSelect('plataforma', valoresDistintos(juego => juego.plataformas));
    rellenarSelect('genero', valoresDistintos(juego => juego.generos));
    mostrar();
  } catch (error) {
    // Lo más habitual es abrir el HTML con doble clic: fetch no funciona con file://
    estado.textContent = 'No se ha podido cargar el catálogo. Abre la página desde un servidor local (Live Server o php -S).';
    console.error(error);
  }
}

function valoresDistintos(obtenerLista) {
  const valores = new Set(juegos.flatMap(obtenerLista));
  return [...valores].sort((a, b) => a.localeCompare(b, 'es'));
}

function rellenarSelect(id, valores) {
  const select = document.getElementById(id);
  for (const valor of valores) {
    select.add(new Option(valor, valor));
  }
}

function filtrar() {
  const texto = formulario.busqueda.value.trim().toLowerCase();
  const plataforma = formulario.plataforma.value;
  const genero = formulario.genero.value;
  const edad = Number(formulario.edad.value);

  return juegos.filter(juego => {
    const coincideTexto = texto === ''
      || juego.titulo.toLowerCase().includes(texto)
      || juego.estudio.nombre.toLowerCase().includes(texto);
    const coincidePlataforma = plataforma === '' || juego.plataformas.includes(plataforma);
    const coincideGenero = genero === '' || juego.generos.includes(genero);
    const aptoPorEdad = edad === 0 || juego.pegi <= edad;
    return coincideTexto && coincidePlataforma && coincideGenero && aptoPorEdad;
  });
}

function ordenar(lista, criterio) {
  const copia = [...lista];
  switch (criterio) {
    case 'precio':
      return copia.sort((a, b) => a.precio - b.precio);
    case 'anio':
      return copia.sort((a, b) => b.anio - a.anio);
    case 'titulo':
      return copia.sort((a, b) => a.titulo.localeCompare(b.titulo, 'es'));
    default:
      return copia.sort((a, b) => b.nota - a.nota || a.titulo.localeCompare(b.titulo, 'es'));
  }
}

function colorPegi(pegi) {
  if (pegi <= 7) return 'pegi--verde';
  if (pegi <= 16) return 'pegi--naranja';
  return 'pegi--rojo';
}

// Se usa textContent y no innerHTML para no interpretar HTML que venga en los datos
function crearFicha(juego) {
  const ficha = plantilla.content.firstElementChild.cloneNode(true);

  const nota = ficha.querySelector('.nota');
  nota.querySelector('.nota__valor').textContent = formatoNota.format(juego.nota);
  if (juego.nota >= 9.5) {
    nota.classList.add('nota--alta');
  }

  ficha.querySelector('h2').textContent = juego.titulo;
  ficha.querySelector('.ficha__datos').textContent =
    `${juego.estudio.nombre} (${juego.estudio.pais}), ${juego.anio}. ${juego.generos.join(', ')}`;
  ficha.querySelector('.ficha__plataformas').textContent = `Plataformas: ${juego.plataformas.join(', ')}`;
  ficha.querySelector('.ficha__descripcion').textContent = juego.descripcion ?? '';

  const pegi = ficha.querySelector('.pegi');
  pegi.textContent = `PEGI ${juego.pegi}`;
  pegi.classList.add(colorPegi(juego.pegi));

  ficha.querySelector('.ficha__precio').textContent =
    juego.precio === 0 ? 'Gratis' : formatoPrecio.format(juego.precio);

  return ficha;
}

function mostrar() {
  const resultado = ordenar(filtrar(), formulario.orden.value);

  lista.replaceChildren(...resultado.map(crearFicha));

  if (resultado.length === 0) {
    estado.textContent = 'Ningún juego cumple esos filtros.';
  } else {
    estado.textContent = `Mostrando ${resultado.length} de ${juegos.length} juegos.`;
  }
}

formulario.addEventListener('input', mostrar);
formulario.addEventListener('submit', evento => evento.preventDefault());

cargarCatalogo();
