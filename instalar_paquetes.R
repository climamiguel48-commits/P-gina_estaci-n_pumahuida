paquetes <- c(
  "readxl",
  "dplyr",
  "tidyr",
  "lubridate",
  "purrr",
  "tibble",
  "plotly"
)

faltantes <- paquetes[!vapply(paquetes, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]

if (length(faltantes) > 0) {
  install.packages(faltantes)
} else {
  message("Todos los paquetes necesarios ya están instalados.")
}
