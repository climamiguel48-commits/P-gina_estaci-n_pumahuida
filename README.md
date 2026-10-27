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
