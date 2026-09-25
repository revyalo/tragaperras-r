# Tragaperras estadística en R

[![R](https://img.shields.io/badge/R-%3E%3D%204.1-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)
[![Tests](https://github.com/revyalo/tragaperras-r/actions/workflows/r-tests.yml/badge.svg)](https://github.com/revyalo/tragaperras-r/actions/workflows/r-tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)

Reimplementación completa de una práctica universitaria de probabilidad. El
proyecto transforma una tirada aislada en un modelo reproducible: enumera las
625 combinaciones posibles, calcula el retorno exacto, busca tablas de premios
enteras y contrasta la teoria mediante simulaciones Monte Carlo.

> **Resultado principal:** la tabla incluida devuelve un RTP teórico del
> **70,000128 %** para una apuesta de 1 EUR.

## Que aporta la versión 2

- Motor de juego dividido en funciones reutilizables.
- Cinco símbolos, cuatro rodillos y reglas de premio mutuamente excluyentes.
- Cálculo exacto independiente de la simulación.
- Busqueda automatica de tablas de premios para un RTP objetivo.
- Simulación vectorizada y reproducible de hasta millones de tiradas.
- Intervalo de confianza del RTP observado y evolucion del saldo.
- Aplicación Shiny para jugar, simular y explorar el modelo.
- Informe R Markdown con código, tablas y gráficas regenerables.
- Pruebas unitarias y ejecución automatica en GitHub Actions.

## Modelo

| Símbolo | Probabilidad por rodillo |
|---|---:|
| Gamba, escorpión, cerdo o ratón | 24 % cada uno |
| Panda | 4 % |

La tabla de premios por defecto se obtuvo buscando importes enteros con la
jerarquia `4 pandas > 3 pandas > 4 comunes > 3 comunes`:

| Resultado | Probabilidad exacta | Premio |
|---|---:|---:|
| Cuatro pandas | 0,000256 % | 126 EUR |
| Cuatro símbolos comunes iguales | 1,327104 % | 26 EUR |
| Exactamente tres pandas | 0,024576 % | 75 EUR |
| Exactamente tres comunes iguales | 16,809984 % | 2 EUR |
| Sin premio | 81,838080 % | 0 EUR |

El retorno se calcula como:

```text
RTP = sum(probabilidad(resultado) * premio(resultado)) / coste_tirada
    = 0,70000128
```

La derivación completa esta en [docs/MODEL.md](docs/MODEL.md) y el análisis
reproducible en [analysis/report.Rmd](analysis/report.Rmd).

## Uso rápido

Clona el repositorio e instala las dependencias opcionales:

```r
install.packages(c("shiny", "ggplot2", "testthat", "knitr", "rmarkdown"))
```

Para abrir la aplicación:

```r
shiny::runApp()
```

Para utilizar solamente el motor no hacen falta paquetes externos:

```r
invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))

machine <- create_machine()
spin_machine(machine, seed = 42)

theory <- theoretical_summary(machine)
theory$rtp
#> 0.7000013

simulation <- simulate_spins(machine, n = 100000, seed = 2026)
simulation_summary(simulation)$observed_rtp
```

Tambien se pueden buscar otras tablas de premios:

```r
find_integer_paytable(machine, target_rtp = 0.70, max_results = 5)
```

## Reproducir el análisis y las pruebas

Desde RStudio se puede abrir `tragaperras.Rproj`. En terminal:

```bash
make test
make report
make run
```

La simulación no se utiliza para demostrar el RTP: el valor teórico procede de
enumerar las 625 combinaciones. Monte Carlo funciona como validación
independiente y permite observar la variabilidad a corto plazo.

## De práctica suspendida a proyecto reproducible

La versión universitaria original obtuvo un 4,75. La retrospectiva en
[docs/RETROSPECTIVE.md](docs/RETROSPECTIVE.md) conserva el planteamiento y
documenta los errores corregidos, entre ellos probabilidades incorrectas,
premios sin utilizar y la ausencia de validación experimental.

Este repositorio representa una reimplementación posterior. El objetivo no es
ocultar los fallos originales, sino mostrar el proceso completo de detectarlos,
medirlos y corregirlos.

## Aviso

Proyecto exclusivamente educativo. El RTP es un promedio teórico a largo plazo
y no garantiza el resultado de una sesion concreta.

## Licencia

[MIT](LICENSE.md) - David Arevalo Rey, 2026.
