# Data sources

## Banco de México (BANXICO): Remesas por entidad federativa - (CA79)
- Access: SIE API
- Series IDs: SE29670" "SE29671" "SE28672" "SE29673" "SE29674"
"SE29675" "SE29676" "SE29677" "SE29678" "SE29679"
"SE29681" "SE29682" "SE29683" "SE29684" "SE28680"
"SE29685" "SE29686" "SE29687" "SE29688" "SE29689"
"SE29690" "SE29691" "SE29692" "SE29693" "SE29694"
"SE29695" "SE29696" "SE29697" "SE29698" "SE29699"
"SE29670" "SE29671"
- Units / frequency: Millones de dólares / trimestral
- First available period: Primer trimestre 2003
- Notes:

## Banco de México (BANXICO): Ingresos por Remesas - (CE81)
- Access: SIE API
- Series IDs: "SE27803"
- Units / frequency: Millones de dólares / mensual
- First available period: Enero 1995
- Notes:


## BANXICO: Ingresos por remesas, distribución por municipio - (CE166)
- Access: manual download from SIE
- URL: https://www.banxico.org.mx/SieInternet/consultarDirectorioInternetAction.do?sector=1&accion=consultarCuadro&idCuadro=CE166&locale=es
- File name in data/raw: remesas_muni.csv
- Accessed: 17 October 2026
- Notes: Ene-Mar 2013 - Abr-Jun 2026.

## Decisions and oddities:
- Manual download of CE166 because, although they are series, the API has call
limits.
- Checked that the remittance totals of each state match the national total for
the corresponding quarter. The differences aresmaller than 0 percentage-wise.
