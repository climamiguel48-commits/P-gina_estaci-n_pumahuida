# Estación meteorológica Pumahuida — CAE-2

Página simple para visualizar la estación meteorológica de la parcela CAE-2.

## La página incluye

- series temporales interactivas de las variables;
- resumen semanal;
- resumen mensual.

La precipitación se representa mediante barras. Las variables acumulativas se suman por período; las variables continuas se promedian, la velocidad máxima usa el máximo y la dirección del viento usa media circular.

## Primera ejecución

En RStudio:

```r
source("instalar_paquetes.R")
```

Luego renderiza:

```bash
quarto render
```

La página se genera en `docs/`.

## Actualizar los datos

Reemplaza:

`datos/Datos_Parcela_CAE2.xlsx`

por la nueva versión del archivo manteniendo el mismo nombre y vuelve a ejecutar `quarto render`.


## Cambios v4

- Se restauraron y separaron visualmente los controles 7 d, 30 d, 6 m y Todo.
- La precipitación de la serie temporal se muestra como total diario en barras.
- Los totales semanal y mensual se calculan sumando Rain_mm_Tot.
- El eje Y se reajusta automáticamente al cambiar de variable para evitar barras recortadas.
- La precipitación mensual muestra el total sobre cada barra.


## Cambios v5

- El selector de variables ya no usa el menú interno de Plotly: ahora es un selector HTML ancho y táctil.
- Los accesos 7 d, 30 d, 6 m y Todo son botones externos siempre visibles sobre la serie temporal.
- En smartphone los cuatro botones ocupan una fila completa y el selector ocupa el 100 % del ancho.
- Se eliminó el range slider de Plotly para ganar espacio en pantallas pequeñas.
- Los gráficos mantienen fechas dd-mm-aaaa y el detalle exacto en el hover.
