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

### Review and implementation for `alpha-release-0-0-4`

These requirements make sense for the fēnix 7 MIP display, with two qualifications:

- Garmin controls watch-face callbacks: low-power `onUpdate()` runs once per minute, but high-power mode and transitions can request additional full redraws. Cache the work behind those redraws; do not assume the previous framebuffer is intact. No timers, animations, or `onPartialUpdate()` are added.
- Caching trades some retained memory for fewer allocations and less CPU work. Keep caches bounded and small; a second full-screen bitmap is not justified for this simple layout without profiling. Fewer API calls alone do not establish a battery-life percentage.

| Work | Implemented policy |
| --- | --- |
| Clock, steps and reading expiry | Once per minute; date text changes only with the local date |
| Battery and local Weather | At startup, then every five minutes; refresh after a backwards clock correction |
| Background city result | Invalidate Weather/city immediately; do not repeat same-minute activity, battery or history queries |
| Heart rate and elevation history | Keep the existing five-minute reads and per-minute age validation; no sensor activation |
| City storage | Read on location change or background invalidation; retain the existing bounded persistent cache and network backoff |
| Background scheduling | Reconcile after Weather refresh, expiry or background completion; retry scheduling errors on the next minute |
| Solar events | Cache by local date and rounded location; retain the 15-minute retry for missing events |
| Solar interval and labels | Reuse the interval until its boundary; invalidate on new events; reformat labels on interval or time-zone/DST changes |
| Layout and resources | Select the time font in `onLayout()`; reuse fonts and fixed icon polygons |
| Display text | Prepare once per snapshot; measure city, steps and elevation only when their inputs or layout change |
| Low power | Preserve the readable MIP layout with the system's minute cadence and no extra wakeups |

Weather and battery changes can take up to approximately five minutes to appear. An expired Weather observation is still hidden on the next minute tick, even between reads. Successful background city completion bypasses the Weather interval. Returning after a long absence refreshes any overdue data.

Validation must cover repeated high-power callbacks, minute/five-minute boundaries, backwards clock changes, returning after an absence, background completion within the same minute, missing data, expiry, midnight, sunrise/sunset and presentation cache invalidation. Real battery consumption and peak memory still require measurement on the watch; do not infer them from reduced call counts.

References: [Garmin WatchFace lifecycle](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html), [View.onUpdate and transitions](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/View.html#onUpdate-instance_method).

### Compatibility phase 1

`WatchLayout` precomputes scaled integer geometry and icon polygons in `onLayout()`. Geometry is rebuilt only if the drawing surface dimensions change; text fonts also rebuild when the watch language changes; returning from an overlay invalidates presentation measurements without recreating the layout or fonts. Solar marker positions and battery/step fills remain data-dependent. Small bitmap glyphs use cached destination rectangles; there is no full-screen production buffer. Data refresh intervals and background scheduling are unchanged. The additional retained geometry requires memory measurement per device; these changes do not establish a battery-life improvement. AMOLED always-on rendering remains a separate pending phase.

### Watch language

The watch language is checked once per minute and when restoring the layout.
Garmin's localized calendar abbreviations are read only on a date or language
change. Minute/day labels and digit-group separators are loaded from localized
resources only on a language change. The presentation invalidates its measured
text when the locale revision changes; text fonts are rebuilt on a language
change without recreating geometry or the time font. This does not change
activity, battery, sensor-history or weather refresh intervals, nor the city
lookup service or its Spanish request language.
