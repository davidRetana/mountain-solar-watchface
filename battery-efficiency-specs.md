### Battery Efficiency

The watch face shall minimize CPU usage, screen updates, memory allocations, and unnecessary access to sensors or external data.

- **Update frequency:** Default to once-per-minute updates. Avoid seconds and animations unless explicitly enabled.
- **Minimal `onUpdate()`:** Keep the update path lightweight and perform only operations required for data that has changed.
- **Cache slow-changing data:** Weather, battery, activity data, sunrise/sunset, and similar information shall not be refreshed more frequently than necessary.
- **Precompute layout:** Screen scaling, coordinates, dimensions, and other static geometry shall be calculated during initialization/layout rather than every update.
- **Cache resources:** Fonts, bitmaps, icons, and other resources shall be loaded once and reused.
- **Minimize allocations:** Avoid unnecessary creation of strings, arrays, objects, and other temporary values inside frequently executed code.
- **Efficient rendering:** Avoid redrawing or recalculating static elements when possible. Separate static and dynamic content conceptually.
- **Sensors and connectivity:** Avoid unnecessary sensor polling, GPS usage, network requests, and phone communication.
- **Low-power behavior:** Reduce dynamic content and processing when the watch face enters low-power/inactive mode.
- **Optimization priority:** Prioritize reducing wakeups, sensor/network operations, and rendering work over micro-optimizing simple arithmetic.

**Design principle:** *Calculate once, cache whenever possible, update only when necessary, and keep each screen refresh as lightweight as possible.*