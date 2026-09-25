# Retrospectiva de la práctica original

## Contexto

La primera versión fue una práctica de Probabilidad y Estadistica realizada en
RStudio. Simulaba una máquina de cuatro rodillos con cinco figuras: gamba,
escorpión, cerdo, ratón y panda. El panda tenia una probabilidad menor y actuaba
como símbolo especial.

La entrega recibio una calificación de 4,75. El fichero fuente se perdio, pero
el informe permitio reconstruir el planteamiento, el código principal y los
cálculos empleados.

## Que funcionaba

- Uso de `sample()` con probabilidades no uniformes.
- Incorporacion de una cuarta ventana respecto al ejercicio base.
- Representacion mediante emoji.
- Primer intento de relaciónar probabilidades y premios con el retorno.
- Ejecuciones de ejemplo documentadas en el informe.

## Problemas detectados

### Probabilidad de cuatro símbolos comunes

La expresión original era equivalente a:

```r
3 * dbinom(4, 4, 0.04)
```

Usaba la probabilidad del panda para los símbolos comunes y multiplicaba por
tres, aunque existen cuatro símbolos comunes. La expresión correcta es:

```r
4 * 0.24^4
```

### Probabilidad de tres símbolos comunes

El mismo error se propagaba al caso de tres coincidencias. Hay que elegir la
posición distinta, considerar cualquiera de los cuatro símbolos comunes y
permitir que el cuarto símbolo sea cualquier otro:

```r
4 * choose(4, 3) * 0.24^3 * 0.76
```

### Resultados sin premio

La versión original no calculaba el complemento de todas las categorías
premiadas. La probabilidad correcta de no obtener premio es 0,8183808.

### Tabla de premios incoherente

Se definia el vector `c(75, 25, 6, 2, 0)`, pero el premio de 6 EUR nunca se
utilizaba. Tres pandas recibian el mismo premio que cuatro símbolos comunes. La
relación entre los importes finales y el retorno objetivo tampoco se verificaba.

### Estructura del programa

Cada rodillo y cada condicion estaban escritos manualmente. No habia funciones,
pruebas, una semilla reproducible en el código final ni una simulación masiva
que contrastase la teoria.

## Decisiones de la reimplementación

- Mantener los cinco símbolos y sus probabilidades originales.
- Convertir las reglas en categorías exclusivas y con nombre.
- Enumerar todo el espacio muestral para obtener probabilidades exactas.
- Separar configuración, tirada, teoria, optimización y simulación.
- Ajustar una tabla de premios entera a un RTP objetivo del 70 %.
- Añadir pruebas unitarias para que los errores anteriores no reaparezcan.
- Presentar el modelo mediante una aplicación Shiny y un informe reproducible.

El cambio principal no es visual: la nueva versión puede justificar cada numero
que muestra y reproducir cada resultado publicado.
