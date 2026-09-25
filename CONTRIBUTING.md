# Contribuir

Las mejoras son bienvenidas, especialmente nuevas reglas de premio,
visualizaciones o comprobaciónes estadísticas.

1. Crea una rama a partir de `main`.
2. Mantén el motor de `R/` libre de dependencias externas.
3. Añade o actualiza pruebas en `tests/testthat/`.
4. Ejecuta `make test` antes de abrir un pull request.
5. Si cambia el modelo, regenera `analysis/report.md` con `make report`.

No mezcles en una misma regla resultados que puedan solaparse. Toda tabla de
premios nueva debe incluir su RTP teórico y una comprobación de que la suma de
probabilidades es uno.
