# Mountain Solar Watchface

Primera etapa dinámica para Garmin fēnix 7 Solar de 47 mm (`fenix7`, MIP 260 × 260). Diseño basado en [watchface3.jpg](watchface3.jpg).

## Ramas

- `main`: commit inicial vacío.
- `feature/static-version`: diseño estático aprobado, guardado en `c7980f8`.
- `feature/dynamic-data`: integración progresiva de datos reales.

## Datos conectados

Hora local en formato de 24 horas y fecha en español, pasos y objetivo de ActivityMonitor, y batería de System.getSystemStats(). Se muestran días completos de batería cuando están disponibles (`<1 d` para menos de un día), con porcentaje como alternativa. Color verde desde el 30 %, ámbar desde el 10 % y rojo por debajo. El relleno del icono refleja el porcentaje.

La barra de pasos se limita al 100 %. Un objetivo ausente o cero deja la barra vacía. El texto utiliza separadores de miles y reduce su tamaño si la fila resulta demasiado larga.

`DataProvider` consulta los datos como máximo una vez por minuto cuando Garmin solicita actualizar la esfera. `WatchData` conserva la instantánea y `Formatters` prepara textos y progreso. No hay temporizadores, peticiones externas, nuevos permisos ni actualizaciones parciales de segundos. Las consultas fallidas eliminan la lectura anterior y muestran `--`.

Ciudad, temperatura, pulsaciones, altitud y horas solares todavía muestran `--`. La barra solar permanece gris sin posición solar ficticia. Los iconos de esos campos se conservan para mantener la composición.

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

Para instalar, conectar el reloj por USB, acceder a su almacenamiento (mediante un cliente MTP si el sistema lo necesita), copiar `bin/mountainsolarwatchface.prg` a `GARMIN/APPS`, desconectar de forma segura y seleccionar la esfera en el reloj. Esta versión conecta hora, fecha, pasos y batería; los demás campos muestran datos ausentes.

## Validación de esta iteración

Compilación correcta para `fenix7` con Connect IQ SDK 9.2.0. El PRG se genera en `bin/mountainsolarwatchface.prg`. La ejecución y el consumo en simulador/reloj quedan pendientes de comprobación; compilar no verifica las lecturas reales.

Antes de conectar la siguiente etapa, comprobar:

- Cambio de minuto, medianoche, mes y fecha en español.
- Pasos a cero, objetivo alcanzado o superado, y cifras de seis dígitos.
- Batería al 9, 10, 29 y 30 %, y alternativa a porcentaje sin estimación de días.
- Legibilidad de la hora y batería, actualización en bajo consumo y memoria.

## Próximas etapas

Conectar SensorHistory para pulsaciones (cada cinco minutos) y altitud, sin forzar sensores ni GPS. Después integrar Garmin Weather, datos antiguos o ausentes, amanecer, puesta y posición solar, incluyendo la presentación nocturna.
