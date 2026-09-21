# Mountain Solar Watchface

Esfera dinámica para Garmin fēnix 7 Solar de 47 mm (`fenix7`, MIP 260 × 260). Diseño basado en [watchface3.jpg](watchface3.jpg).

## Ramas

- `main`: commit inicial vacío.
- `feature/static-version`: diseño estático aprobado, guardado en `c7980f8`.
- `feature/dynamic-data`: integración progresiva de datos reales.

## Datos conectados

Hora local en formato de 24 horas y fecha en español, pasos y objetivo de ActivityMonitor, y batería de System.getSystemStats(). Se muestran días completos de batería cuando están disponibles (`<1 d` para menos de un día), con porcentaje como alternativa. Color verde desde el 30 %, ámbar desde el 10 % y rojo por debajo. El relleno del icono refleja el porcentaje.

La barra de pasos se limita al 100 %. Un objetivo ausente o cero deja la barra vacía. El texto utiliza separadores de miles y reduce su tamaño si la fila resulta demasiado larga.

`DataProvider` consulta los datos como máximo una vez por minuto cuando Garmin solicita actualizar la esfera. `WatchData` conserva la instantánea y `Formatters` prepara textos y progreso. No hay temporizadores, peticiones externas ni actualizaciones parciales de segundos. Se declaran `SensorHistory` y `Positioning`. Este último permite leer el nombre y las coordenadas de la estación meteorológica; no se solicita ninguna adquisición GPS. Las consultas fallidas eliminan la lectura anterior y muestran `--`.

## Meteorología y barra solar

Garmin Weather proporciona temperatura en °C y nombre de la estación o ciudad, que puede diferir de la ubicación exacta del usuario. Se consulta la caché de Garmin cada 15 minutos y al cambiar de fecha local. Observaciones sin fecha, futuras o de más de dos horas se presentan como datos ausentes. No se realizan peticiones a servicios externos. Garmin exige el permiso `Positioning` para proporcionar `observationLocationName` y `observationLocationPosition`, aunque se lean desde Weather.

Amanecer y puesta se calculan con Garmin Weather para la ubicación de la observación, sin activar GPS. Se consultan el día actual y los adyacentes para emparejar cada amanecer con la siguiente puesta real. Se muestra el intervalo que contiene el instante actual o, de noche, el siguiente. Esto admite intervalos diurnos que cruzan medianoche en la zona horaria del reloj. Las horas se muestran en la zona horaria local del reloj. Durante el día, el sol avanza linealmente entre ambos extremos: es una aproximación temporal, no una trayectoria astronómica. Antes del amanecer y después de la puesta, el recorrido queda gris sin marcador solar. Si faltan eventos (incluidas situaciones polares), se muestran los disponibles y no se dibuja una posición ficticia.

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

Compilación correcta para `fenix7` con Connect IQ SDK 9.2.0. El PRG se genera en `bin/mountainsolarwatchface.prg`. Hora, fecha, pasos, batería, pulsaciones y altitud han sido validados por el usuario en el simulador. La nueva etapa de Weather compila; su ejecución y lecturas quedan pendientes de comprobación. La memoria y el consumo en reloj físico siguen pendientes.

Antes de conectar la siguiente etapa, comprobar:

- Cambio de minuto, medianoche, mes y fecha en español.
- Pasos a cero, objetivo alcanzado o superado, y cifras de seis dígitos.
- Batería al 9, 10, 29 y 30 %, y alternativa a porcentaje sin estimación de días.
- Legibilidad de la hora y batería, actualización en bajo consumo y memoria.

Para validar SensorHistory en el simulador, proporcionar un historial de pulsaciones y altitud (modificar solo un valor instantáneo puede no crear muestras históricas). Comprobar la primera lectura, el refresco tras cinco minutos, historial vacío, caducidad, altitud negativa y cifras largas. Confirmar las lecturas también en el reloj físico.

## Validación pendiente de Weather

En el simulador, proporcionar condiciones meteorológicas con fecha de observación y ubicación mediante Settings → Set Weather. Configurar tanto el nombre de la estación como sus coordenadas. Tras cambios en los permisos, recompilar y detener y volver a ejecutar la esfera. La temperatura puede estar disponible aunque falte la ubicación; en ese caso, las horas solares permanecen ausentes. El proveedor también puede no proporcionar un nombre de estación, incluso con el permiso habilitado. Comprobar temperatura negativa, ciudad larga, datos ausentes o caducados, amanecer, mediodía, puesta, noche y cambio de fecha. Los cambios en Weather pueden tardar hasta 15 minutos en aparecer; reiniciar la esfera fuerza una primera consulta.

Finalmente, validar todos los datos en reloj físico con Garmin Connect conectado y desconectado, y revisar memoria y comportamiento en bajo consumo antes de considerar cerrado el MVP.
