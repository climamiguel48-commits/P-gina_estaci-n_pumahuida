# Preparación de datos para la página de la estación Pumahuida -----------------

paquetes <- c("readxl", "dplyr", "tidyr", "lubridate", "purrr", "tibble")

faltantes <- paquetes[!vapply(paquetes, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
if (length(faltantes) > 0) {
  stop(
    "Faltan paquetes de R: ", paste(faltantes, collapse = ", "),
    ". Ejecuta instalar_paquetes.R una vez."
  )
}

library(readxl)
library(dplyr)
library(tidyr)
library(lubridate)
library(purrr)
library(tibble)

archivo_datos <- file.path("datos", "Datos_Parcela_CAE2.xlsx")

if (!file.exists(archivo_datos)) {
  stop("No se encontró: ", archivo_datos)
}

datos <- read_excel(archivo_datos, sheet = 1)

if (!"fecha_hora" %in% names(datos)) {
  stop("El archivo debe contener la columna 'fecha_hora'.")
}

# Los registros del datalogger se tratan como hora local del sitio.
datos <- datos %>%
  mutate(
    fecha_hora = ymd_hms(as.character(fecha_hora), quiet = TRUE)
  )

if ("fecha_hora_inicio" %in% names(datos)) {
  datos <- datos %>%
    mutate(
      fecha_hora_inicio = ymd_hms(as.character(fecha_hora_inicio), quiet = TRUE)
    )
}

datos <- datos %>%
  filter(!is.na(fecha_hora)) %>%
  arrange(fecha_hora) %>%
  distinct(fecha_hora, .keep_all = TRUE)

# Catálogo de variables que se mostrarán en la página.
# agregacion define el resumen semanal/mensual:
# - sum: variables acumulativas
# - mean: variables continuas
# - max: máximo del período
# - circular: media circular para dirección del viento
catalogo <- tribble(
  ~variable,         ~nombre,                              ~unidad,       ~agregacion, ~columna_tabla,
  "AirT_C_Avg",     "Temperatura del aire",              "°C",         "mean",      "T aire (°C)",
  "RH",             "Humedad relativa",                  "%",          "mean",      "HR (%)",
  "BP_mbar_Avg",    "Presión barométrica",               "mbar",       "mean",      "P barom. (mbar)",
  "VP_mbar_Avg",    "Presión de vapor",                  "mbar",       "mean",      "P vapor (mbar)",
  "WS_ms_Avg",      "Velocidad del viento",              "m/s",        "mean",      "Viento (m/s)",
  "MaxWS_ms_Avg",   "Velocidad máxima del viento",       "m/s",        "max",       "Viento máx. (m/s)",
  "WindDir",        "Dirección del viento",              "°",          "circular",  "Dir. viento (°)",
  "Rain_mm_Tot",    "Precipitación",                      "mm",         "sum",       "Precip. total (mm)",
  "ETos",           "Evapotranspiración de referencia",  "mm",         "sum",       "ETo total (mm)",
  "SlrFD_W_Avg",    "Radiación solar incidente",         "W/m²",       "mean",      "Rad. solar (W/m²)",
  "SlrTF_MJ_Tot",   "Radiación solar acumulada",         "MJ/m²",      "sum",       "Rad. acum. (MJ/m²)",
  "NR_Wm2_Avg",     "Radiación neta",                    "W/m²",       "mean",      "Rad. neta (W/m²)",
  "SHF_Avg",        "Flujo de calor del suelo",          "W/m²",       "mean",      "Flujo suelo (W/m²)",
  "TT_C_Avg",       "Temperatura objetivo IR",           "°C",         "mean",      "T objetivo IR (°C)",
  "SBT_C_Avg",      "Temperatura del cuerpo del sensor", "°C",         "mean",      "T sensor IR (°C)",
  "Temp_TC1_C_Avg", "Temperatura de suelo TC1",          "°C",         "mean",      "T suelo TC1 (°C)",
  "Temp_TC2_C_Avg", "Temperatura de suelo TC2",          "°C",         "mean",      "T suelo TC2 (°C)",
  "SWC_5CM_Avg",    "Contenido de agua del suelo 5 cm",  "m³/m³",      "mean",      "SWC 5 cm (m³/m³)",
  "SWC_40CM_Avg",   "Contenido de agua del suelo 40 cm", "m³/m³",      "mean",      "SWC 40 cm (m³/m³)"
)

# Mantener solo variables presentes en el archivo y convertirlas a numérico.
catalogo <- catalogo %>% filter(variable %in% names(datos))

datos <- datos %>%
  mutate(
    across(
      all_of(catalogo$variable),
      ~ suppressWarnings(as.numeric(.x))
    )
  )

# Precipitación diaria para la serie temporal.
# Rain_mm_Tot es el total registrado en cada intervalo horario, por lo que
# para visualizar lluvia de forma clara se suma por día. Los resúmenes
# semanal y mensual siguen sumando los intervalos originales.
if ("Rain_mm_Tot" %in% names(datos)) {
  precipitacion_diaria <- datos %>%
    transmute(
      fecha = as.Date(fecha_hora),
      lluvia_mm = suppressWarnings(as.numeric(Rain_mm_Tot))
    ) %>%
    group_by(fecha) %>%
    summarise(
      valor = sum(lluvia_mm, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(fecha)
} else {
  precipitacion_diaria <- tibble(
    fecha = as.Date(character()),
    valor = numeric()
  )
}

media_circular_grados <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0) return(NA_real_)
  rad <- x * pi / 180
  ang <- atan2(mean(sin(rad)), mean(cos(rad))) * 180 / pi
  (ang + 360) %% 360
}

agregar_vector <- function(x, metodo) {
  x <- suppressWarnings(as.numeric(x))
  if (!any(is.finite(x))) return(NA_real_)

  switch(
    metodo,
    sum      = sum(x, na.rm = TRUE),
    mean     = mean(x, na.rm = TRUE),
    max      = max(x, na.rm = TRUE),
    circular = media_circular_grados(x),
    mean(x, na.rm = TRUE)
  )
}

resumir_periodo <- function(datos, unidad_periodo = c("week", "month")) {
  unidad_periodo <- match.arg(unidad_periodo)

  datos_periodo <- datos %>%
    mutate(
      periodo = if (unidad_periodo == "week") {
        as.Date(floor_date(fecha_hora, unit = "week", week_start = 1))
      } else {
        as.Date(floor_date(fecha_hora, unit = "month"))
      }
    )

  datos_periodo %>%
    group_split(periodo) %>%
    map_dfr(function(g) {
      periodo_actual <- first(g$periodo)

      catalogo %>%
        transmute(
          periodo = periodo_actual,
          variable,
          nombre,
          unidad,
          agregacion,
          columna_tabla,
          valor = map2_dbl(
            variable,
            agregacion,
            ~ agregar_vector(g[[.x]], .y)
          )
        )
    }) %>%
    arrange(periodo, variable)
}

resumen_semanal <- resumir_periodo(datos, "week")
resumen_mensual <- resumir_periodo(datos, "month")

crear_tabla_resumen <- function(resumen) {
  resumen %>%
    select(periodo, columna_tabla, valor) %>%
    pivot_wider(names_from = columna_tabla, values_from = valor) %>%
    arrange(desc(periodo))
}

tabla_semanal <- crear_tabla_resumen(resumen_semanal)
tabla_mensual <- crear_tabla_resumen(resumen_mensual)

fecha_min <- min(datos$fecha_hora, na.rm = TRUE)
fecha_max <- max(datos$fecha_hora, na.rm = TRUE)
n_registros <- nrow(datos)
