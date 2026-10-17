### Este script utiliza la API de BANXICO para descargar los datos nacionales
### de remesas. Los consolida en una sola tabla y luego compara los totales
### con los totales de las remesas por entidad federativa, para los
### mismos periodos y fechas disponibles.
###
### Produce un archivo CSV con los totales nacionales de remesas, por año y trimestre

library(httr2)
library(jsonlite)
library(tidyr)
library(dplyr)
## 0. Carpeta
dir.create("data/raw/remesas_nacional/", recursive = TRUE, showWarnings = FALSE)

## 1. Cargar el token
## Está guardado en el .Renviron del proyecto, que no se sube a GitHub
## Se puede solicitar un token en la página de BANXICO
token <- Sys.getenv("BANXICO_TOKEN")

## 2. Series para descargar
## Ingresadas manualmente
serie_id <- "SE27803"

## 3. Descargar los datos
## Crear la solicitud
req <- request("https://www.banxico.org.mx/SieAPIRest/service/v1") |>
    req_url_path_append("series", serie_id, "datos") |>
    req_headers(`Bmx-Token` = token, Accept = "application/json")
resp <- req_perform(req)
raw_txt <- resp_body_string(resp)
writeLines(raw_txt, paste0("data/raw/remesas_nacional/",
                             serie_id, ".json"))

## 4. Extraer datos de los archivos descargados y consolidar
archivo <- paste0("data/raw/remesas_nacional/", serie_id, ".json")
parsed <- fromJSON(archivo)
## Crear tabla con datos por entidad
remesas_total_nacional <- unnest(parsed$bmx$series, cols = datos)


## 5. Revisar los datos y definir las columnas
## Transformar columna de remesas a valores numéricos
remesas_total_nacional$valor <- as.numeric(gsub(",", "", remesas_total_nacional$dato))
## Eliminar columnas no necesarias
remesas_total_nacional <- remesas_total_nacional[, c("fecha", "valor")]
## Cambiar a fecha
remesas_total_nacional$fecha <- as.Date(remesas_total_nacional$fecha, format = "%d/%m/%Y")
## Lubridate
remesas_total_nacional$quarterlabel <- paste0(lubridate::year(remesas_total_nacional$fecha), "-T",
                                   lubridate::quarter(remesas_total_nacional$fecha))
remesas_total_nacional$year <- as.integer(lubridate::year(remesas_total_nacional$fecha))
remesas_total_nacional$quarter <- lubridate::quarter(remesas_total_nacional$fecha)

## 6. Crear la tabla de comparación
## Total nacional de remesas por año y trimestre
## Agrupar por año y trimestre, sumar y mantener solamente los trimestres completos
nacional <- remesas_total_nacional |>
  group_by(year, quarter) |>
  summarise(total_nacional = sum(valor), n_meses = n(), .groups = "drop") |>
  filter(n_meses == 3)
## Total de remesas para cada entidad por año y trimestre
## Agrupar por año y trimestre, y sumar
remesas_ent <- read.csv("data/processed/remesas_entidades.csv")
entidades <- remesas_ent |>
  group_by(year, quarter) |>
  summarise(suma_estados = sum(valor), n_estados = n(), .groups = "drop")
## Unir ambas tablas, conservando solamente los trimestres que existen en
## ambas. Calcular la diferencia entre los totales de remesas, en cifras
## absolutas y en porcentaje
comparacion <- entidades |>
  inner_join(nacional, by = c("year", "quarter")) |>
  mutate(diferencia = total_nacional - suma_estados,
         diferencia_pct = 100 * diferencia / total_nacional)

## Mirar el panorama general de la diferencia porcentual.
## Sin notación científica y redondeado a 4 decimales
summary(round(comparacion$diferencia_pct, 4))

## Las diferencias son 0, por lo que son minúsculas y se verifica
## que no faltan estados ni hay series equivocadas, y que la suma estatal
## reproduce el total nacional.

## 7. Guardar el archivo de los totales nacionales
write.csv(remesas_total_nacional, "data/processed/remesas_nacionales.csv", row.names = FALSE)
