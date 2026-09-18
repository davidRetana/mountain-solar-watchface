Quiero desarrollar una esfera para Garmin Connect IQ en Monkey C.

CONTEXTO
- Dispositivo inicial: Garmin fēnix 7 Solar de 47 mm.
- Pantalla: MIP redonda, 260 × 260 px y paleta limitada.
- El mockup adjunto es la referencia visual, se llama el archivo watcffacerender1.
- Prioridades: legibilidad exterior, bajo consumo, poco uso de memoria y tolerancia a datos ausentes.
- Primera versión solo para este dispositivo, sin opciones configurables.
- No publicar todavía en Connect IQ Store.

DISEÑO
- Fondo negro.
- Hora digital de 24 horas como elemento principal.
- Fecha: día de la semana y del mes.
- Ciudad y temperatura en °C.
- Pasos actuales / objetivo y barra de progreso ámbar.
- Barra diurna con amanecer, puesta del sol y posición aproximada del sol.
- Zona inferior:
  - Pulsaciones e icono de corazón en rojo.
  - Altitud con icono de montaña marrón.
  - Batería en días, o porcentaje si los días no están disponibles.
- Color de batería según porcentaje real:
  - Verde si es >=30%.
  - Naranja entre 10% y 29%.
  - Rojo si es <10%.
- El texto secundario será blanco cálido o gris.
- Sin animaciones ni segundos en la primera versión.

DATOS Y APIs
- Hora y fecha: tiempo local del sistema.
- Pasos y objetivo: ActivityMonitor.getInfo().
- Temperatura, ciudad, amanecer y puesta: Garmin Weather.
- Ciudad: observationLocationName, admitiendo que puede ser null o corresponder a una estación cercana.
- Pulsaciones: muestra más reciente de SensorHistory; refrescar la cifra cada cinco minutos. No intentar forzar una lectura óptica.
- Altitud: última muestra de elevation history; evitar activar GPS periódicamente.
- Batería: System.getSystemStats().battery.
- Usar batteryInDays cuando exista; fallback al porcentaje.
- Todos los valores externos deben aceptar null, datos antiguos, permisos denegados o teléfono desconectado.
- Evitar API meteorológica o servidor externo para el MVP.

PERMISOS PREVISTOS
- SensorHistory.
- Positioning solamente si finalmente resulta necesario.
- Añadir únicamente los permisos realmente utilizados.

ARQUITECTURA DESEADA
- manifest.xml
- monkey.jungle
- source/
  - MountainWatchApp.mc
  - MountainWatchView.mc
  - WatchData.mc
  - DataProvider.mc
  - SolarBar.mc
  - Formatters.mc
  - Theme.mc
- resources/
  - drawables/
  - fonts/
  - strings/
  - settings/
- resources-round-260x260/
- tests/
- README.md
- .gitignore

FORMA DE TRABAJO
1. Inspecciona el entorno, SDK instalado, perfil exacto del dispositivo y estado del directorio.
2. Antes de crear archivos, presenta un plan breve y señala cualquier incompatibilidad.
3. Crea el proyecto mínimo compilable.
4. Implementa primero una pantalla estática equivalente al mockup.
5. Compárala visualmente en el simulador y ajusta proporciones.
6. Conecta los datos por etapas:
   a. hora y fecha;
   b. pasos y batería;
   c. pulsaciones y altitud;
   d. Weather y barra solar.
7. Añade fallbacks claros como “--” sin provocar errores.
8. Verifica compilación, memoria y comportamiento de bajo consumo después de cada etapa.
9. No almacenes ni muestres claves de desarrollador, credenciales o secretos.
10. No publiques ni envíes nada externamente sin mi autorización.

CRITERIO DE FINALIZACIÓN DEL MVP
- Compila para el fēnix 7 Solar.
- Se ejecuta correctamente en el simulador.
- Puede instalarse mediante un archivo PRG en el reloj.
- Mantiene la jerarquía visual del mockup.
- Todos los datos tienen fallback.
- No hace peticiones externas.
- Quedan documentados los pasos de compilación, simulación e instalación USB.

Empieza verificando el setup y el modelo/perfil exacto. No implementes todo de golpe: primero estructura y render estático.
