# Política de privacidad de Mountain Solar

Última actualización: 6 de octubre de 2026. [English](PRIVACY.md).

Mountain Solar es una esfera para Garmin Connect IQ mantenida por el propietario
de [este repositorio](https://github.com/davidRetana/mountain-solar-watchface).
Esta política describe el comportamiento actual de la aplicación. Garmin y
OpenStreetMap Foundation operan sus servicios con sus propias políticas.

## Datos utilizados en el reloj

La esfera lee la hora, fecha e idioma del reloj, pasos y objetivo de pasos,
nivel de batería y estimación de días restantes, historial reciente de
pulsaciones y altitud, y observaciones de Garmin Weather. Estas observaciones
pueden incluir temperatura, fecha de observación y coordenadas de la estación
meteorológica, que pueden diferir de la ubicación real de quien lleva el reloj.

La esfera no inicia GPS ni medición óptica de pulsaciones. Usa información
disponible mediante las API de Garmin. Pulsaciones, altitud, pasos, batería e
idioma del reloj no se envían al servicio de ciudades. La aplicación no
incluye publicidad, analítica, registro de cuentas ni seguimiento mediante
identificadores del dispositivo; tampoco envía datos a un servidor del
desarrollador.

## Consulta de ciudades y comunicación a terceros

Cuando la ubicación meteorológica actual no tiene una ciudad guardada, la
esfera consulta automáticamente el servicio público Nominatim de
OpenStreetMap Foundation mediante la conectividad de Garmin Connect.

La petición HTTPS incluye coordenadas meteorológicas redondeadas a dos
decimales, preferencia de idioma español, opciones de geocodificación inversa
y un identificador con nombre/versión del proyecto y URL del repositorio.
Redondear reduce la precisión, pero no anonimiza la ubicación. Nominatim puede
procesar o registrar las peticiones conforme a la
[política de privacidad de OpenStreetMap Foundation](https://osmfoundation.org/wiki/Privacy_Policy).
También se aplica su [política de uso](https://operations.osmfoundation.org/policies/nominatim/).
Los datos de ciudades son © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright),
bajo la licencia Open Database License (ODbL).

Actualmente no existe un interruptor ni una confirmación adicional dentro de
la aplicación para esta consulta. Si no quieres enviar las coordenadas
meteorológicas a Nominatim, no uses esta versión de la esfera. Cambiar el
idioma de la interfaz del reloj no modifica la preferencia de español que ya
utiliza la petición de ciudad.

## Almacenamiento y conservación

Las lecturas mostradas se conservan en la memoria de trabajo. La aplicación
guarda de forma persistente en el reloj hasta ocho pares de coordenadas
redondeadas con sus nombres de ciudad. Una entrada nueva sustituye la menos
reciente cuando la caché está llena. También guarda el estado de reintentos
para evitar peticiones repetidas después de fallos de conexión. Las ciudades
pueden permanecer hasta ser sustituidas o eliminar el almacenamiento de la
aplicación; esta versión no tiene caducidad por tiempo ni un control separado
para vaciar la caché.

Desinstala la esfera mediante el procedimiento de Garmin para eliminar su
almacenamiento. Esto no elimina datos de salud o actividad del reloj, Garmin
Connect u otras aplicaciones, ni registros de peticiones del proveedor
externo. El desarrollador no tiene acceso remoto a la caché de ciudades del
reloj.

## Permisos y opciones

Se declaran `SensorHistory`, `Positioning`, `Communications` y `Background`.
Permiten leer historial existente, obtener coordenadas meteorológicas,
consultar ciudades por Internet y ejecutar esa consulta en segundo plano.
No hacen que esta esfera inicie GPS o medición óptica de pulsaciones. Garmin
controla la disponibilidad de permisos; los datos ausentes o caducados se
muestran como `--`.

## Contacto y cambios

Para consultas sobre la aplicación o esta política, contacta con el
desarrollador mediante las
[incidencias del proyecto](https://github.com/davidRetana/mountain-solar-watchface/issues).
Al publicar el repositorio, las incidencias también son públicas: no incluyas
coordenadas, datos de salud, credenciales ni otra información privada. Para
datos conservados por Garmin u OpenStreetMap Foundation, utiliza el contacto
de privacidad de la organización correspondiente.

Esta política se actualizará cuando cambien el uso de datos, los proveedores
o la conservación.
