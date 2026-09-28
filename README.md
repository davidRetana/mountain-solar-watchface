# Mountain Solar Watchface

Esfera dinámica para Garmin fēnix 7 Solar de 47 mm (`fenix7`, MIP 260 × 260). Diseño basado en [watchface3.jpg](watchface3.jpg).

## Ramas

- `main`: commit inicial vacío.
- `feature/static-version`: diseño estático aprobado, guardado en `c7980f8`.
- `feature/dynamic-data`: integración progresiva de datos reales.

## Datos conectados

Hora local en formato de 24 horas y fecha en español, pasos y objetivo de ActivityMonitor, y batería de System.getSystemStats(). Se muestran días completos de batería cuando están disponibles (`<1 d` para menos de un día), con porcentaje como alternativa. Color verde desde el 30 %, ámbar desde el 10 % y rojo por debajo. El relleno del icono refleja el porcentaje.

La hora se amplía proporcionalmente hasta un ancho máximo de 232 píxeles, sin estirar los números. Las huellas se dibujan sobre píxeles enteros a la izquierda de una barra de pasos de 156 × 7 píxeles. La barra de pasos se limita al 100 %. Un objetivo ausente o cero deja la barra vacía. El texto utiliza separadores de miles y reduce su tamaño si la fila resulta demasiado larga.

`DataProvider` consulta los datos una vez por minuto cuando Garmin solicita actualizar la esfera, y al recibir el resultado del servicio de ciudad. `WatchData` conserva la instantánea y `Formatters` prepara textos y progreso. No hay actualizaciones parciales de segundos. El servicio de fondo solo se programa cuando falta el nombre de la ubicación actual; no hay un evento periódico de ciudad. Se declaran `SensorHistory`, `Positioning`, `Communications` y `Background`. `Positioning` permite leer las coordenadas de la estación meteorológica; no se solicita ninguna adquisición GPS. Las lecturas ausentes se muestran con `--`.

## Meteorología y barra solar

Garmin Weather proporciona temperatura en °C y coordenadas de la observación, que pueden diferir de la ubicación exacta del usuario. Se leen sus datos locales cada minuto, sin forzar una descarga. Observaciones sin fecha, futuras o de más de dos horas se presentan como datos ausentes. Garmin exige el permiso `Positioning` para proporcionar `observationLocationPosition`, aunque se lea desde Weather. Ya no se utiliza el campo obsoleto `observationLocationName`.

Si falta el nombre de una ubicación, se obtiene mediante geocodificación inversa de Nominatim/OpenStreetMap a través de Garmin Connect. Las coordenadas enviadas se redondean a dos decimales; no se activa GPS. Se guardan hasta ocho ubicaciones, conservando las visitadas más recientemente. Volver a una ubicación guardada muestra su nombre sin Internet y cancela cualquier consulta pendiente. Mientras no haya un nombre para las coordenadas actuales, se muestra `--`; nunca se reutiliza el nombre de otra ubicación. El formato anterior de una sola ciudad sigue siendo legible.

`CityScheduler` programa un único evento para una ciudad pendiente, tan pronto como permita Garmin: al menos cinco minutos después del último evento temporal. Si no hay coordenadas válidas o la ciudad ya está guardada, elimina el evento. `CityService` vuelve a comprobar Weather y la caché antes de enviar una petición, por si la ubicación cambió mientras esperaba. Los fallos aplican esperas de 5, 15, 30 y 60 minutos, manteniendo después los 60 minutos. Estas esperas se conservan al reiniciar y son globales para no multiplicar los intentos al moverse sin conexión. Una respuesta válida elimina la espera por fallos; el antiguo bloqueo fijo de una hora deja de utilizarse. Una petición interrumpida también conserva una espera de reintento. Al terminar el servicio, la esfera vuelve a leer Weather y comprueba si queda trabajo pendiente. Si la esfera no está activa, lo comprueba al volver a mostrarse.

Amanecer y puesta se calculan con Garmin Weather para la ubicación de la observación, sin activar GPS. Se consultan el día actual y los adyacentes para emparejar cada amanecer con la siguiente puesta real. Los resultados se conservan hasta que cambie la fecha o la ubicación redondeada; si faltan resultados, se reintenta el cálculo cada 15 minutos. Leer la temperatura cada minuto no repite estos cálculos. Se muestra el intervalo que contiene el instante actual: amanecer → puesta de día, puesta → siguiente amanecer de noche. Esto admite intervalos diurnos que cruzan medianoche en la zona horaria del reloj. Las horas se muestran en la zona horaria local del reloj. Durante el día, el sol avanza linealmente entre ambos extremos: es una aproximación temporal, no una trayectoria astronómica. De noche, una luna blanca recorre la barra proporcionalmente al tiempo transcurrido desde la puesta. El intervalo se vuelve a seleccionar cada minuto para cambiar de sol a luna justo en el límite. La luna es un marcador nocturno, no una representación de la fase lunar. Si faltan eventos que delimiten el intervalo (incluidas situaciones polares), se muestra `--:--` y no se dibuja una posición ficticia.

La temperatura se redondea al entero más cercano. Su icono es un termómetro para no sugerir cielo despejado independientemente del tiempo. Los nombres largos se recortan con puntos suspensivos dentro del espacio disponible.

## Pulsaciones y altitud

Se consulta SensorHistory al iniciar y después cada cinco minutos. Se busca la muestra válida más reciente dentro de un historial acotado, omitiendo muestras nulas y pulsaciones no positivas. La altitud admite cero y valores negativos, en metros. No se inicia GPS ni lectura óptica.

El texto bajo el corazón muestra la antigüedad real de la muestra (`<1 MIN`, `2 MIN`, etc.), no el intervalo de consulta. Se descartan pulsaciones de más de 15 minutos y altitudes de más de 30 minutos. Estos umbrales son decisiones de presentación de esta versión. La caducidad se comprueba cada minuto, incluso entre consultas. Historial vacío o permisos denegados producen `--` de manera independiente para cada sensor.

## Compilación

Setup comprobado: Connect IQ SDK 9.2.0, perfil `fenix7`, API mínima 5.2.0. El perfil admite las fuentes escalables y el texto radial utilizados; el límite de memoria para watchfaces es de 128 KB.

Con los ejecutables del SDK en `PATH`, desde la raíz del proyecto:

```sh
monkeyc -f monkey.jungle -d fenix7 -o bin/mountainsolarwatchface.prg -y /ruta/a/clave-local
```

La clave de desarrollador debe permanecer privada y fuera del repositorio. No es necesario regenerarla para cada compilación.

## Simulación e instalación USB

```sh
connectiq
monkeydo bin/mountainsolarwatchface.prg fenix7
```

En el simulador, comprobar que la fecha curva, la hora, los textos solares y las tres columnas no se recortan ni se solapan. Revisar también memoria y comportamiento en modo de bajo consumo antes de dar por terminada la validación en dispositivo.

Para instalar, conectar el reloj por USB, acceder a su almacenamiento (mediante un cliente MTP si el sistema lo necesita), copiar `bin/mountainsolarwatchface.prg` a `GARMIN/APPS`, desconectar de forma segura y seleccionar la esfera en el reloj. Esta versión conecta todos los campos previstos; las lecturas no disponibles se muestran con `--`.

## Validación de esta iteración

Compilación correcta para `fenix7` con Connect IQ SDK 9.2.0 y diez pruebas aprobadas en el simulador. Las pruebas cubren sol/luna, interpretación de ciudades, migración y límite de ocho ubicaciones, reintentos y recuperación, programación sin duplicados y actualización de Weather sin repetir los cálculos solares. El PRG se genera en `bin/mountainsolarwatchface.prg`. Hora, fecha, pasos, batería, pulsaciones y altitud han sido validados por el usuario en el simulador. Las lecturas reales por Garmin Connect, la memoria y el consumo en reloj físico siguen pendientes de comprobación.

Antes de conectar la siguiente etapa, comprobar:

- Cambio de minuto, medianoche, mes y fecha en español.
- Pasos a cero, objetivo alcanzado o superado, y cifras de seis dígitos.
- Batería al 9, 10, 29 y 30 %, y alternativa a porcentaje sin estimación de días.
- Legibilidad de la hora y batería, actualización en bajo consumo y memoria.

Para validar SensorHistory en el simulador, proporcionar un historial de pulsaciones y altitud (modificar solo un valor instantáneo puede no crear muestras históricas). Comprobar la primera lectura, el refresco tras cinco minutos, historial vacío, caducidad, altitud negativa y cifras largas. Confirmar las lecturas también en el reloj físico.

## Validación pendiente de Weather

En el simulador, proporcionar condiciones meteorológicas con fecha de observación y coordenadas mediante Settings → Set Weather. El nombre de estación de ese diálogo ya no se utiliza. Tras cambios en los permisos, recompilar y detener y volver a ejecutar la esfera. La temperatura puede estar disponible aunque falte la ubicación; en ese caso, las horas solares permanecen ausentes. Comprobar temperatura negativa, ciudad larga, datos ausentes o caducados, amanecer, mediodía, puesta, noche y cambio de fecha. Temperatura y coordenadas se leen en la siguiente actualización de minuto. Una ciudad guardada aparece entonces; una nueva necesita además la ejecución de fondo y la respuesta de Internet.

Para comprobar la ciudad, usar Simulation → Background Events → Temporal Event cuando haya una consulta pendiente y revisar la consola de ejecución. Los mensajes `CityService:` indican si faltan datos meteorológicos, si la observación ha caducado, si se reutiliza la caché, cuántos segundos quedan hasta poder reintentar, o el código de respuesta cuando falla la consulta. El evento manual también respeta las esperas por fallos. Comprobar A → B → A, permanencia sin nuevas peticiones y pérdida/recuperación de conexión.

Finalmente, validar todos los datos en reloj físico con Garmin Connect conectado y desconectado, y revisar memoria y comportamiento en bajo consumo antes de considerar cerrado el MVP.

## Geocodificación y atribución

Ciudad: datos © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), licencia ODbL, mediante [Nominatim](https://nominatim.org/). La consulta HTTPS envía únicamente coordenadas meteorológicas redondeadas y preferencia de idioma. El servicio identifica esta aplicación con su User-Agent y reutiliza hasta ocho ubicaciones guardadas. Solo solicita ubicaciones desconocidas, respetando el mínimo de cinco minutos entre eventos de Garmin y las esperas crecientes tras fallos. Su disponibilidad depende de Internet en el móvil y del servicio público. Condiciones: [política de uso](https://operations.osmfoundation.org/policies/nominatim/).

Pruebas de regresión (intervalos diurnos/nocturnos, límites, medianoche, respuestas de ciudad y caché por ubicación):

```sh
monkeyc -f tests/solar.jungle -d fenix7 -o bin/solar-tests.prg -y /ruta/a/clave-local -t
monkeydo bin/solar-tests.prg fenix7 -t
```
