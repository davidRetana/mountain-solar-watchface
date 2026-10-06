# Mountain Solar Watchface

Esfera dinámica para Garmin, inicialmente diseñada para fēnix 7 Solar de 47 mm (`fenix7`, MIP 260 × 260) y adaptada a los nueve perfiles del manifest. Capturas: [1](screenshots/screenshot1.jpeg) · [2](screenshots/screenshot2.jpeg).

## Ampliación de compatibilidad para la versión 1.0

El manifest conserva los nueve perfiles elegidos para la versión 1.0: `fenix7`, `fenix7s`, `fenix7x`, `fenix7pro`, `fenix7spro`, `fenix7xpro`, `fenix8solar47mm`, `fenix8solar51mm` y `fenix947mm`. El usuario ha confirmado la revisión visual de todos ellos. Tras añadir la localización, los nueve compilan y superan las 25 pruebas por perfil (225 aprobadas en total). Esta revisión visual no sustituye las mediciones de memoria y autonomía ni la validación de AOD en AMOLED, que siguen pendientes.

1. **Base gráfica adaptable:** `WatchLayout` calcula posiciones, tamaños y polígonos al preparar la pantalla, con el diseño de 260 × 260 como referencia. `WatchFonts` escala las fuentes y admite `BionicBold`, `BionicSemiBold` y una alternativa Roboto para la hora; las fuentes ausentes tienen una presentación alternativa. `WatchPresentation` invalida medidas al cambiar la geometría. Los iconos de ubicación y temperatura conservan sus píxeles originales en 260 × 260 y se dibujan con tamaño proporcional en otras resoluciones. Las cachés de datos y frecuencias de consulta se mantienen.
2. **Validación MIP por dispositivo:** compilación, pruebas automatizadas y revisión visual confirmadas para `fenix7`, `fenix7s`, `fenix7x` y `fenix8solar47mm`. `fenix7pro`, `fenix7spro`, `fenix7xpro` y `fenix8solar51mm` también tienen revisión visual confirmada y superan las 25 pruebas por perfil tras añadir la localización. Quedan la medición de memoria y las pruebas físicas de autonomía. Las variantes `fenix7pronowifi` y `fenix7xpronowifi` siguen pendientes de añadir al manifest y validar. Enduro 2 comparte `fenix7x`; Enduro 3 usa `enduro3`.
3. **AMOLED y AOD:** diseñar y probar la presentación de bajo consumo, las transiciones y la luminancia en `fenix843mm`, `fenix847mm` (47 y 51 mm), `fenix8pro47mm` y `fenix947mm` (47 y 51 mm). Este último ya está declarado y su revisión visual está confirmada; AOD sigue pendiente. Supera las 25 pruebas tras añadir la localización. La base proporcional por sí sola no certifica compatibilidad con AMOLED o MicroLED.
4. **Preparación pública:** idioma del reloj implementado, política de privacidad documentada y servicio de ciudad actual conservado por decisión del usuario. Quedan unidades/formato horario configurables, revisión del uso de Nominatim para distribución pública, recursos de lanzamiento, pruebas físicas de memoria y autonomía, y paquete de publicación.

Las pruebas de la primera fase dibujan sobre superficies de 240, 260, 280, 416 y 454 píxeles **dentro del perfil `fenix7`**. Comprueban fuentes ausentes, reutilización de geometría/fuentes, sol/luna y cambio de tamaño con la misma revisión de datos. No sustituyen la compilación, revisión visual y medición de memoria de cada perfil real. El modo AOD todavía está pendiente.

Para instalar los perfiles: abrir **Connect IQ SDK Manager → Devices** y descargar los identificadores anteriores. El SDK local 9.2.0 contiene la documentación de estos modelos, pero cada paquete de dispositivo se descarga por separado.

Validación de la fase 1: 20 pruebas aprobadas en el simulador `fenix7` con SDK 9.2.0 (`passed=20, failed=0, errors=0`). El lanzador `monkeydo` devuelve código 1 pese al resultado aprobado, como en la validación anterior. Se conserva el aviso del icono de lanzamiento de 48 × 48 escalado a 40 × 40. La revisión visual de todos los perfiles del manifest se ha confirmado posteriormente; la medición de memoria y autonomía sigue pendiente.

### Pruebas locales de la fase MIP

Con SDK 9.2.0, tras añadir la localización, la compilación de producción y las 25 pruebas automatizadas se han completado correctamente en cada uno de estos perfiles:

| Perfil | Resolución MIP | Compilación | Pruebas | Revisión visual del usuario |
| --- | --- | --- | --- | --- |
| `fenix7` | 260 × 260 | Correcta | 25 aprobadas | Confirmada |
| `fenix7s` | 240 × 240 | Correcta | 25 aprobadas | Confirmada |
| `fenix7x` | 280 × 280 | Correcta | 25 aprobadas | Confirmada |
| `fenix8solar47mm` | 260 × 260 | Correcta | 25 aprobadas | Confirmada |
| `fenix7pro` | 260 × 260 | Correcta | 25 aprobadas | Confirmada |
| `fenix7spro` | 240 × 240 | Correcta | 25 aprobadas | Confirmada |
| `fenix7xpro` | 280 × 280 | Correcta | 25 aprobadas | Confirmada |
| `fenix8solar51mm` | 280 × 280 | Correcta | 25 aprobadas | Confirmada |

Permanece el aviso del icono de lanzamiento escalado de 48 × 48 a 40 × 40. Esta matriz todavía no incluye medición de memoria de producción ni autonomía física.

Desde la raíz del proyecto, `tools/ciq.py` utiliza el SDK activo del SDK Manager en macOS y la clave local `developer_key`. También admite `--sdk /ruta/al/sdk` y `--key /ruta/a/clave-local`. Cada perfil genera un PRG separado, evitando instalar en un reloj un binario compilado para otro modelo.

Compilar los perfiles instalados:

```sh
python3 tools/ciq.py build fenix7 fenix7s fenix7x fenix8solar47mm
```

Abrir el simulador y ejecutar un modelo:

```sh
CIQ_SDK="$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")"
"$CIQ_SDK/bin/connectiq"
python3 tools/ciq.py run fenix7s
```

Detener la ejecución antes de cambiar de modelo. Repetir `run` con `fenix7x` y `fenix8solar47mm`. El comando recompila y ejecuta `bin/mountain-<perfil>.prg`. Para el reloj físico, copiar solamente el PRG correspondiente a su perfil.

Con el simulador abierto, ejecutar las pruebas automatizadas:

```sh
python3 tools/ciq.py test fenix7 fenix7s fenix7x fenix8solar47mm
```

El comando compila y ejecuta las pruebas en cada perfil, en secuencia. Solo acepta el código 1 peculiar de `monkeydo` si la última línea de resultados declara explícitamente pruebas aprobadas, sin fallos ni errores. Una compilación fallida, un simulador inaccesible o un resultado de pruebas fallido detienen el proceso.

La ampliación con `fenix7pro`, `fenix7spro`, `fenix7xpro` y `fenix8solar51mm` está compilada y supera las 25 pruebas por perfil con SDK 9.2.0, incluida la localización. La primera ejecución de `fenix8solar51mm` se quedó esperando al simulador; después de reiniciarlo, la ejecución aislada terminó con `passed=20, failed=0, errors=0`. Para repetir la validación, instalar los perfiles desde **SDK Manager → Devices** y ejecutar con el simulador abierto:

```sh
python3 tools/ciq.py build fenix7pro fenix7spro fenix7xpro fenix8solar51mm
python3 tools/ciq.py test fenix7pro fenix7spro fenix7xpro fenix8solar51mm
```

Para repetir la revisión visual confirmada, usar **Run Without Debugging → Elegir reloj** en VS Code o `python3 tools/ciq.py run fenix7pro`, cambiando el perfil en cada ejecución.

Para cada modelo, revisar:

- Fecha curva completa; hora sin recortes ni solapamiento con ciudad, temperatura o pasos. El fēnix 7S es la comprobación prioritaria de legibilidad por su pantalla de 240 × 240.
- Barra solar y barra de pasos, huellas y separación de las tres columnas inferiores. Comprobar objetivo alcanzado y cifras largas; los valores ausentes se muestran como `--`.
- En `fenix8solar47mm`, revisar especialmente el tamaño y la posición de la hora con la fuente `BionicSemiBold`.
- En **Settings → Set Weather**, introducir una observación reciente con coordenadas. Weather se consulta cada cinco minutos; detener y volver a ejecutar la esfera permite comprobar la nueva observación inmediatamente. Una ubicación sin ciudad guardada requiere además el evento de fondo y conexión.
- Reposo y vuelta al modo activo: la pantalla MIP debe mantener el diseño y actualizar la hora por minuto. Revisar la memoria del programa de producción en el simulador; los búferes de las pruebas no representan su consumo de memoria.

La revisión visual de los ocho perfiles MIP está confirmada. Queda medir memoria en los nueve perfiles del manifest, validar AMOLED/AOD y medir autonomía en reloj físico. Los nuevos idiomas requieren comprobar legibilidad por idioma, además de la revisión visual del diseño ya realizada.

### Pruebas iniciales de AMOLED: fēnix 9

El perfil instalado `fenix947mm` cubre fēnix 9 de 47 y 51 mm según `compiler.json` del paquete de dispositivo. Tiene pantalla AMOLED de 454 × 454 y un límite de memoria de 128 KiB para esferas. Se ha añadido al manifest para pruebas locales: la compilación de producción y las 25 pruebas automatizadas han terminado correctamente con SDK 9.2.0 (`passed=25, failed=0, errors=0`), incluida la localización.

La revisión visual está confirmada; la medición de memoria sigue pendiente. Estas pruebas no validan AOD: falta implementar y comprobar la presentación de bajo consumo, sus transiciones y los límites de luminancia. El compilador avisa de que el icono de lanzamiento actual de 48 × 48 se escala a 65 × 65 en este perfil.

Para revisar la esfera, elegir `fenix947mm` en **Run Without Debugging → Elegir reloj**, o ejecutar con el simulador abierto:

```sh
python3 tools/ciq.py run fenix947mm
```

Si el perfil instalado no aparece en el selector de VS Code, ejecutar **Developer: Reload Window** desde la paleta de comandos para recargar la extensión y sus datos. La configuración local `.vscode/launch.json` también incluye **fēnix 9 (47 / 51 mm)** con `device: "fenix947mm"`: seleccionar esa configuración en el panel **Run and Debug** y usar **Run Without Debugging** para lanzarlo directamente. `.vscode/` está ignorado por Git; esta opción es local al workspace.

## Ramas

- `main`: commit inicial vacío.
- `feature/static-version`: diseño estático aprobado, guardado en `c7980f8`.
- `feature/dynamic-data`: integración progresiva de datos reales.
- `alpha-release-0-0-4`: revisión de eficiencia desde el estado de `alpha-release-0-0-3`.

## Datos conectados

Hora local en formato de 24 horas y fecha en el idioma configurado en el reloj, pasos y objetivo de ActivityMonitor, y batería de System.getSystemStats(). Se muestran días completos de batería cuando están disponibles (`<1 d` para menos de un día), con porcentaje como alternativa. Color verde desde el 30 %, ámbar desde el 10 % y rojo por debajo. El relleno del icono refleja el porcentaje.

La hora se amplía proporcionalmente hasta un ancho máximo de 232 píxeles, sin estirar los números. Las huellas se dibujan sobre píxeles enteros a la izquierda de una barra de pasos de 156 × 7 píxeles. La barra de pasos se limita al 100 %. Un objetivo ausente o cero deja la barra vacía. El texto utiliza separadores de miles y reduce su tamaño si la fila resulta demasiado larga.

`DataProvider` actualiza la hora, los pasos y la caducidad de lecturas una vez por minuto. Batería y Weather se consultan al iniciar y después cada cinco minutos. Al recibir el resultado del servicio de ciudad, solo se invalidan Weather y la caché de ciudad. `WatchData` conserva la instantánea y `WatchPresentation` reutiliza los textos y las medidas entre redibujados. No hay actualizaciones parciales de segundos. El servicio de fondo solo se programa cuando falta el nombre de la ubicación actual; no hay un evento periódico de ciudad. Se declaran `SensorHistory`, `Positioning`, `Communications` y `Background`. `Positioning` permite leer las coordenadas de la estación meteorológica; no se solicita ninguna adquisición GPS. Las lecturas ausentes se muestran con `--`.

## Idioma del reloj

Los nombres abreviados de día y mes proceden de `Time.Gregorian.info(..., Time.FORMAT_MEDIUM)`, que Garmin localiza según el idioma del dispositivo. No se mantienen listas de fechas en español. `WatchLocale` carga las abreviaturas de minutos, días de batería y separadores de miles de recursos para los 36 idiomas declarados. El nombre **Mountain Solar** es el mismo en todos los idiomas; el recurso base de textos breves está en inglés.

Todos los recursos están agrupados bajo `resources`: los textos base están en `resources/strings/strings.xml` y las traducciones en `resources/strings/locales/<idioma>.xml`. `monkey.jungle` y `tests/solar.jungle` asignan cada traducción con `base.lang.<idioma>` para que Garmin la seleccione según el reloj. La lista de recursos compartidos incluye solo los textos base y las carpetas de imágenes, fuentes y ajustes; las traducciones se compilan como recursos de su idioma.

El idioma se comprueba una vez por minuto y al preparar o restaurar la pantalla. Un cambio de idioma actualiza fecha, textos y medidas sin repetir las consultas de datos ni recrear la geometría o la fuente de la hora. Los alfabetos árabe, hebreo, griego, cirílico y asiáticos usan fuentes del sistema; si el dispositivo no proporciona una fuente vectorial adecuada, la fecha se dibuja recta con una fuente del sistema. Las traducciones se incluyen por idioma sin cargar todas en memoria.

Esta fase conserva el formato de 24 horas, °C y metros. También conserva la preferencia `es` de la consulta de ciudad, como ha solicitado el usuario; los nombres de localidades no se traducen al cambiar el idioma de la interfaz.

Validación local: compilación de producción y 25 pruebas aprobadas en cada uno de los nueve perfiles del manifest (225 aprobadas, sin fallos ni errores). La ejecución por lotes se quedó esperando al cambiar a `fenix7x`; tras reiniciar el simulador, ese perfil pasó de forma aislada. Los seis perfiles restantes se validaron con una instancia limpia por perfil. Se conserva el aviso de escalado del icono de lanzamiento. Las pruebas cubren cambios de idioma simulados y comparación con los textos nativos del idioma activo; no certifican la legibilidad visual de los 36 idiomas.

Para comprobar los idiomas en el simulador, cambiar **Settings → Language** (o la opción equivalente de la versión del simulador), detener y volver a ejecutar la esfera. Revisar especialmente textos con tildes, cirílico, escrituras asiáticas y escritura de derecha a izquierda. Las pruebas automatizadas también cubren invalidación de cachés al cambiar de idioma y reutilización de recursos.

## Privacidad

Política de privacidad: [español](PRIVACY.es.md) · [English](PRIVACY.md).

La consulta de ciudades se conserva tal como estaba: para una ubicación meteorológica desconocida, la esfera envía automáticamente coordenadas redondeadas a Nominatim a través de Garmin Connect. Redondearlas no las anonimiza. La caché local conserva hasta ocho ubicaciones y sus ciudades; los datos de pulsaciones, altitud, pasos y batería no se envían a ese servicio. Esta versión no añade un consentimiento ni un interruptor específico para la consulta de ciudad.

La política describe los datos utilizados, su envío a terceros, la conservación local y la eliminación al desinstalar. Antes de distribuir públicamente, publicar una URL accesible de esta política y revisar los requisitos de consentimiento de Garmin y las condiciones de Nominatim. Conservar la configuración actual no resuelve por sí solo el límite global de tráfico de Nominatim ni su requisito de poder cambiar de proveedor sin actualizar la aplicación.

## Meteorología y barra solar

Garmin Weather proporciona temperatura en °C y coordenadas de la observación, que pueden diferir de la ubicación exacta del usuario. Se leen sus datos locales cada cinco minutos, sin forzar una descarga; su caducidad se comprueba cada minuto. Observaciones sin fecha, futuras o de más de dos horas se presentan como datos ausentes. Garmin exige el permiso `Positioning` para proporcionar `observationLocationPosition`, aunque se lea desde Weather. Ya no se utiliza el campo obsoleto `observationLocationName`.

Si falta el nombre de una ubicación, se obtiene mediante geocodificación inversa de Nominatim/OpenStreetMap a través de Garmin Connect. Las coordenadas enviadas se redondean a dos decimales; no se activa GPS. Se guardan hasta ocho ubicaciones, conservando las visitadas más recientemente. Volver a una ubicación guardada muestra su nombre sin Internet y cancela cualquier consulta pendiente. Mientras no haya un nombre para las coordenadas actuales, se muestra `--`; nunca se reutiliza el nombre de otra ubicación. El formato anterior de una sola ciudad sigue siendo legible.

`CityScheduler` programa un único evento para una ciudad pendiente, tan pronto como permita Garmin: al menos cinco minutos después del último evento temporal. Si no hay coordenadas válidas o la ciudad ya está guardada, elimina el evento. `CityService` vuelve a comprobar Weather y la caché antes de enviar una petición, por si la ubicación cambió mientras esperaba. Los fallos aplican esperas de 5, 15, 30 y 60 minutos, manteniendo después los 60 minutos. Estas esperas se conservan al reiniciar y son globales para no multiplicar los intentos al moverse sin conexión. Una respuesta válida elimina la espera por fallos; el antiguo bloqueo fijo de una hora deja de utilizarse. Una petición interrumpida también conserva una espera de reintento. Al terminar el servicio, la esfera vuelve a leer Weather y comprueba si queda trabajo pendiente. Si la esfera no está activa, lo comprueba al volver a mostrarse.

Amanecer y puesta se calculan con Garmin Weather para la ubicación de la observación, sin activar GPS. Se consultan el día actual y los adyacentes para emparejar cada amanecer con la siguiente puesta real. Los resultados se conservan hasta que cambie la fecha o la ubicación redondeada; si faltan resultados, se reintenta el cálculo cada 15 minutos. Actualizar la temperatura no repite estos cálculos; el cambio de fecha se comprueba cada minuto aunque no toque leer Weather. Se muestra el intervalo que contiene el instante actual: amanecer → puesta de día, puesta → siguiente amanecer de noche. Esto admite intervalos diurnos que cruzan medianoche en la zona horaria del reloj. Las horas se muestran en la zona horaria local del reloj. Durante el día, el sol avanza linealmente entre ambos extremos: es una aproximación temporal, no una trayectoria astronómica. De noche, una luna blanca recorre la barra proporcionalmente al tiempo transcurrido desde la puesta. El intervalo se reutiliza mientras siga vigente; en el primer refresco de minuto que alcance su límite se selecciona el siguiente para cambiar entre sol y luna. La luna es un marcador nocturno, no una representación de la fase lunar. Si faltan eventos que delimiten el intervalo (incluidas situaciones polares), se muestra `--:--` y no se dibuja una posición ficticia.

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

## Validación

La iteración anterior compiló para `fenix7` con Connect IQ SDK 9.2.0 y superó diez pruebas en el simulador. Las pruebas cubren sol/luna, interpretación de ciudades, migración y límite de ocho ubicaciones, reintentos y recuperación, programación sin duplicados y actualización de Weather sin repetir los cálculos solares. El PRG se genera en `bin/mountainsolarwatchface.prg`. Hora, fecha, pasos, batería, pulsaciones y altitud han sido validados por el usuario en el simulador. Las lecturas reales por Garmin Connect, la memoria y el consumo en reloj físico siguen pendientes de comprobación.

Antes de conectar la siguiente etapa, comprobar:

- Cambio de minuto, medianoche, mes y fecha en el idioma configurado en el reloj.
- Pasos a cero, objetivo alcanzado o superado, y cifras de seis dígitos.
- Batería al 9, 10, 29 y 30 %, y alternativa a porcentaje sin estimación de días.
- Legibilidad de la hora y batería, actualización en bajo consumo y memoria.

Para validar SensorHistory en el simulador, proporcionar un historial de pulsaciones y altitud (modificar solo un valor instantáneo puede no crear muestras históricas). Comprobar la primera lectura, el refresco tras cinco minutos, historial vacío, caducidad, altitud negativa y cifras largas. Confirmar las lecturas también en el reloj físico.

## Validación pendiente de Weather

En el simulador, proporcionar condiciones meteorológicas con fecha de observación y coordenadas mediante Settings → Set Weather. El nombre de estación de ese diálogo ya no se utiliza. Tras cambios en los permisos, recompilar y detener y volver a ejecutar la esfera. La temperatura puede estar disponible aunque falte la ubicación; en ese caso, las horas solares permanecen ausentes. Comprobar temperatura negativa, ciudad larga, datos ausentes o caducados, amanecer, mediodía, puesta, noche y cambio de fecha. Temperatura y coordenadas se leen en la siguiente consulta de Weather, en un plazo de aproximadamente cinco minutos. Una ciudad guardada aparece entonces; una nueva necesita además la ejecución de fondo y la respuesta de Internet.

Para comprobar la ciudad, usar Simulation → Background Events → Temporal Event cuando haya una consulta pendiente y revisar la consola de ejecución. Los mensajes `CityService:` indican si faltan datos meteorológicos, si la observación ha caducado, si se reutiliza la caché, cuántos segundos quedan hasta poder reintentar, o el código de respuesta cuando falla la consulta. El evento manual también respeta las esperas por fallos. Comprobar A → B → A, permanencia sin nuevas peticiones y pérdida/recuperación de conexión.

Finalmente, validar todos los datos en reloj físico con Garmin Connect conectado y desconectado, y revisar memoria y comportamiento en bajo consumo antes de considerar cerrado el MVP.

## Geocodificación y atribución

Ciudad: datos © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), licencia ODbL, mediante [Nominatim](https://nominatim.org/). La consulta HTTPS envía únicamente coordenadas meteorológicas redondeadas y preferencia de idioma. El servicio identifica esta aplicación con su User-Agent y reutiliza hasta ocho ubicaciones guardadas. Solo solicita ubicaciones desconocidas, respetando el mínimo de cinco minutos entre eventos de Garmin y las esperas crecientes tras fallos. Su disponibilidad depende de Internet en el móvil y del servicio público. Condiciones: [política de uso](https://operations.osmfoundation.org/policies/nominatim/).

Pruebas de regresión (intervalos diurnos/nocturnos, límites, medianoche, respuestas de ciudad y caché por ubicación):

```sh
monkeyc -f tests/solar.jungle -d fenix7 -o bin/solar-tests.prg -y /ruta/a/clave-local -t
monkeydo bin/solar-tests.prg fenix7 -t
```

## Eficiencia de batería: alpha-release-0-0-4

La revisión de [battery-efficiency-specs.md](battery-efficiency-specs.md) concreta las frecuencias y los límites de la caché. Batería y Weather pasan de 60 a 12 consultas normales por hora. El historial mantiene su periodo de cinco minutos y los datos caducados desaparecen en el siguiente minuto. Las consultas de ciudad a almacenamiento persistente se evitan mientras no cambie la ubicación ni llegue una respuesta de fondo.

El tamaño de la fuente horaria se calcula en `onLayout()`, y los polígonos de los iconos se crean una sola vez. `WatchPresentation` conserva los textos preparados y recalcula las medidas de ciudad, pasos y altitud al cambiar sus valores. Las horas solares se conservan hasta cambiar el intervalo o el desfase horario local. Los redibujados adicionales reutilizan esta presentación y una única referencia temporal de la instantánea.

Garmin controla la cadencia: solicita un redibujado por minuto en reposo y puede pedirlo cada segundo en modo activo o varias veces durante una transición. Se mantiene el redibujado completo para restaurar correctamente la pantalla, con la misma información visible en reposo y sin temporizadores ni actualizaciones parciales. No se añade un búfer de pantalla; las pequeñas cachés aumentan la memoria retenida a cambio de reducir objetos temporales y trabajo repetido. [Ciclo de vida de WatchFace](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html).

Las pruebas adicionales de `BatteryEfficiencyTest.mc` cubren la frecuencia de lectura, los saltos del reloj, el retorno tras una ausencia, los resultados de fondo dentro del mismo minuto, la caducidad entre consultas, medianoche, el cambio de intervalo solar y la reutilización de medidas de texto. La reducción de llamadas no implica un porcentaje equivalente de ahorro de batería. La comparación de autonomía y memoria máxima en el reloj físico sigue pendiente.

Validación de esta rama: compilación de producción y pruebas correcta para `fenix7` con SDK 9.2.0; 17 pruebas aprobadas en el simulador (`passed=17, failed=0, errors=0`), incluida una prueba de redibujado con la API gráfica real. El lanzador `monkeydo` terminó con código 1 pese a informar todas las pruebas como aprobadas. La compilación solo avisa del tamaño del icono de lanzamiento existente (48 × 48, escalado a 40 × 40). PRG actualizado: `bin/mountainsolarwatchface.prg`.
