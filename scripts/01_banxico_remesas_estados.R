### Este script utiliza la API de BANXICO para descargar los datos de remesas
### por entidad federativa. Los descarga de manera individual y luego los
### consolida en una sola tabla, también formateando las columnas.
###
### Produce un archivo csv con 6 columnas: cve_ent, fecha, valor, quarterlabel,
### year y quarter.

library(httr2)
library(jsonlite)
library(tidyr)

## 0. Carpetas
dir.create("data/raw/remesas_por_estado/", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed/", recursive = TRUE, showWarnings = FALSE)

## 1. Cargar el token
## Está guardado en el .Renviron del proyecto, que no se sube a GitHub
## Se puede solicitar un token en la página de BANXICO
token <- Sys.getenv("BANXICO_TOKEN")

## 2. Series para descargar
## Remesas por entidad federativa
## Ingresadas manualmente en el archivo de lookup
series_ids <- read.csv("data/lookup/entidades.csv", colClasses = c("character",
                                                                   "character",
                                                                   "character"))

## 3. Descargar los datos en un ciclo, porque BANXICO API tiene límites
for (i in seq_len(nrow(series_ids))) {
  ## Cargar id, 32 estados
  id <- series_ids$series_id[i]
  print(id)
  ## Crear la solicitud
  req <- request("https://www.banxico.org.mx/SieAPIRest/service/v1") |>
    req_url_path_append("series", id, "datos") |>
    req_headers(`Bmx-Token` = token, Accept = "application/json")
  resp <- req_perform(req)
  raw_txt <- resp_body_string(resp)
  writeLines(raw_txt, paste0("data/raw/remesas_por_estado/",
                             series_ids$cve_ent[i], ".json"))
  Sys.sleep(0.5)
}

## 4. Extraer datos de los archivos descargados y consolidar
remesas_ent <- data.frame()
for (i in seq_len(nrow(series_ids))) {
  archivo <- paste0("data/raw/remesas_por_estado/",
                    series_ids$cve_ent[i], ".json")
  parsed <- fromJSON(archivo)
  ## Crear tabla con datos por entidad
  tabla <- unnest(parsed$bmx$series, cols = datos)
  ## Añadir clave de entidad INEGI
  tabla$cve_ent <- series_ids$cve_ent[i]
  ## Añadir la tabla del estado a la general
  remesas_ent <- rbind(remesas_ent, tabla)
}


## 5. Revisar los datos y definir las columnas
## Transformar columna de remesas a valores numéricos
remesas_ent$valor <- as.numeric(gsub(",", "", remesas_ent$dato))
## Revisar que no haya valores nulos
stopifnot(sum(is.na(remesas_ent$valor)) == 0)
## El valor de nulos debe ser 0
## Eliminar columnas no necesarias
remesas_ent <- remesas_ent[, c("cve_ent", "fecha", "valor")]
## Cambiar a fecha
remesas_ent$fecha <- as.Date(remesas_ent$fecha, format = "%d/%m/%Y")
## Lubridate
remesas_ent$quarterlabel <- paste0(lubridate::year(remesas_ent$fecha), "-T",
                              lubridate::quarter(remesas_ent$fecha))
remesas_ent$year <- as.integer(lubridate::year(remesas_ent$fecha))
remesas_ent$quarter <- lubridate::quarter(remesas_ent$fecha)

## 6. Guardar los datos
write.csv(remesas_ent, "data/processed/remesas_entidades.csv", row.names = FALSE)



