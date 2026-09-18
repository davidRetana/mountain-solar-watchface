# Mountain Solar Watchface

Render estático para Garmin fēnix 7 Solar de 47 mm: perfil `fenix7`, pantalla MIP circular de 260 × 260 px. Referencia actual: [watchface2.jpg](watchface2.jpg).

## Diseño implementado

Fecha en arco, ciudad con marcador y temperatura con sol en una misma fila, hora grande, pasos con barra ámbar, barra solar con horas en los extremos y tres columnas inferiores con iconos sobre los valores. Los iconos son dibujos vectoriales, no caracteres dependientes de una fuente. Se usan fuentes del dispositivo, cargadas una sola vez, y colores de la paleta MIP. El blanco sustituye al blanco cálido del mockup por las limitaciones de color de la pantalla.

Todos los datos son ejemplos fijos: MIÉ 16 SEP, MADRID, 23°C, 14:37, 8.426 / 10.000 pasos, 07:52–20:17, 68 pulsaciones, 667 m y 12 d de batería. La barra de pasos representa el 84,26 %. La posición solar es ilustrativa. El texto «5 MIN» reproduce la referencia; todavía no existe un refresco de sensores. La batería verde tampoco representa una lectura real.

No se leen sensores, ubicación, hora del sistema ni Weather. No se declaran permisos, temporizadores, animaciones ni actualizaciones de segundos. `DataProvider.mc`, `WatchData.mc` y `Formatters.mc` quedan reservados para la fase dinámica.

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

Para instalar, conectar el reloj por USB, acceder a su almacenamiento (mediante un cliente MTP si el sistema lo necesita), copiar `bin/mountainsolarwatchface.prg` a `GARMIN/APPS`, desconectar de forma segura y seleccionar la esfera en el reloj. Esta versión muestra siempre los mismos valores, incluida la hora.

## Validación de esta iteración

- Compilación para `fenix7`: `BUILD SUCCESSFUL`.
- PRG generado en `bin/mountainsolarwatchface.prg`.
- Se intentó abrir el simulador y cargar el PRG, pero el entorno de ejecución no permitió obtener una captura ni confirmar la carga. La comparación visual, la memoria en ejecución y el consumo quedan pendientes; no se ha verificado la ejecución en reloj físico.

## Próximas etapas

Conectar por separado hora y fecha, pasos y batería, SensorHistory y finalmente Garmin Weather. Incorporar fallbacks `--`, colores de batería según porcentaje y refresco de pulsaciones cada cinco minutos al implementar los datos reales.
