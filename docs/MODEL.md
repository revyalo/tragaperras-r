# Modelo probabilístico

## Espacio muestral

Cada tirada contiene cuatro rodillos independientes. En cada rodillo puede
aparecer uno de cinco símbolos:

```text
P(gamba) = P(escorpión) = P(cerdo) = P(ratón) = 0,24
P(panda) = 0,04
```

Existen `5^4 = 625` resultados ordenados. La probabilidad de un resultado es el
producto de las probabilidades de sus cuatro símbolos.

## Categorías premiadas

Las reglas se evaluan en orden y son mutuamente excluyentes:

1. Cuatro pandas.
2. Cuatro símbolos comunes iguales.
3. Exactamente tres pandas.
4. Exactamente tres símbolos comunes iguales.
5. Cualquier otro resultado.

Las probabilidades se pueden obtener analíticamente:

```text
P(4 pandas)  = 0,04^4                              = 0,00000256
P(4 comunes) = 4 * 0,24^4                          = 0,01327104
P(3 pandas)  = C(4,3) * 0,04^3 * 0,96              = 0,00024576
P(3 comunes) = 4 * C(4,3) * 0,24^3 * (1 - 0,24)   = 0,16809984
P(sin premio) = 1 - suma(categorías premiadas)      = 0,81838080
```

El paquete verifica estas expresiónes enumerando de manera independiente las
625 combinaciones.

## Retorno al jugador

Para una apuesta de 1 EUR y premios de 126, 26, 75 y 2 EUR:

```text
E[premio] =
  0,00000256 * 126 +
  0,01327104 * 26 +
  0,00024576 * 75 +
  0,16809984 * 2
  = 0,70000128 EUR
```

Por tanto:

```text
RTP              = 70,000128 %
ventaja de banca = 29,999872 %
tasa de premio   = 18,161920 %
```

## Optimización de la tabla

`find_integer_paytable()` busca premios enteros próximos a un RTP solicitado.
Para reducir el espacio de busqueda, recorre los premios de tres pandas,
cuatro comunes y tres comunes, y despeja algebraicamente el jackpot requerido.
Despues conserva las alternativas que cumplen:

```text
premio(4 pandas) > premio(3 pandas) >
premio(4 comunes) > premio(3 comunes) > 0
```

Las candidatas se ordenan por su distancia absoluta al retorno objetivo.

## Teoría y simulación

La enumeracion exacta responde a cuanto deberia devolver la máquina a largo
plazo. La simulación Monte Carlo responde a cuanto puede observarse en una
muestra finita. Una desviación temporal respecto al 70 % no invalida el modelo:
la dispersión de los premios y los resultados raros producen variabilidad.

La aplicación presenta ambos valores y un intervalo de confianza aproximado del
95 % para evitar confundir una ejecución concreta con la esperanza teórica.
