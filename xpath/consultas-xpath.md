# Consultas XPath sobre el catálogo

Las 10 consultas se ejecutan con `java herramientas/Procesar.java` (paso 3) y los resultados de abajo son los que imprime el programa con el `datos/catalogo.xml` actual. Todas son XPath 1.0, que es lo que trae Java de serie.

## 1. Número de juegos del catálogo

```xpath
count(/catalogo/juego)
```

Devuelve un número: **16**.

## 2. Títulos con PEGI 18

```xpath
/catalogo/juego[@pegi = 18]/titulo
```

Filtra por un atributo. Devuelve 3 nodos: The Witcher 3: Wild Hunt, God of War y Red Dead Redemption 2.

## 3. Juegos de Switch por menos de 20 euros

```xpath
/catalogo/juego[plataformas/plataforma = 'Switch' and precio < 20]/titulo
```

`plataformas/plataforma = 'Switch'` es cierto si **alguna** de las plataformas del juego es Switch (comparación de un conjunto de nodos con una cadena). Devuelve 5 nodos: Hollow Knight, Stardew Valley, Celeste, Fortnite y Gris.

## 4. Juegos que solo salieron en una plataforma

```xpath
/catalogo/juego[count(plataformas/plataforma) = 1]/titulo
```

Devuelve 4 nodos: The Legend of Zelda: Breath of the Wild, Mario Kart 8 Deluxe, Animal Crossing: New Horizons y Portal 2.

## 5. Estudios españoles

```xpath
/catalogo/juego/estudio[@pais = 'ES']
```

Aquí el resultado son los propios elementos `estudio`, no los títulos. Devuelve 2 nodos: Nomada Studio y The Game Kitchen.

## 6. Juego con la nota más alta

```xpath
/catalogo/juego[not(nota < ../juego/nota)]/titulo
```

XPath 1.0 no tiene `max()`. El truco es quedarse con el juego cuya nota **no** es menor que ninguna otra. Devuelve 1 nodo: The Legend of Zelda: Breath of the Wild (9.7). Si hubiera empate saldrían todos los empatados.

## 7. Precio medio del catálogo

```xpath
sum(/catalogo/juego/precio) div count(/catalogo/juego)
```

Tampoco hay `avg()`, así que se divide la suma entre el total. Devuelve un número: **30,32** (485,12 / 16). En XPath la división es `div` porque `/` ya se usa para las rutas.

## 8. Géneros del juego más reciente

```xpath
(/catalogo/juego[not(anio < ../juego/anio)])[1]/generos/genero
```

Mismo truco que en la 6, pero con el año, y luego se baja hasta los géneros. Con `(...)[1]` me quedo con el primero si hay empate; sin los paréntesis se mezclarían los géneros de todos los juegos de ese año. Devuelve 3 nodos (de Elden Ring, 2022): Rol, Acción y Mundo abierto.

## 9. Título del juego con id J07

```xpath
string(/catalogo/juego[@id = 'J07']/titulo)
```

Con `string()` el resultado ya no es un nodo sino una cadena: **Elden Ring**.

## 10. ¿Hay algún juego PEGI 3 en Xbox Series?

```xpath
boolean(/catalogo/juego[@pegi = 3 and plataformas/plataforma = 'Xbox Series'])
```

`boolean()` de un conjunto de nodos es cierto si no está vacío. Devuelve **false**: los tres juegos PEGI 3 (Mario Kart 8 Deluxe, Animal Crossing y Gris) no están en Xbox Series.

## Tipos de resultado

| Tipo | Consultas |
| --- | --- |
| Conjunto de nodos | 2, 3, 4, 5, 6, 8 |
| Número | 1, 7 |
| Cadena | 9 |
| Booleano | 10 |
