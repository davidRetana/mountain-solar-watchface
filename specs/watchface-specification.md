# Watchface Specification

I want to develop a Garmin Connect IQ watch face in Monkey C.

## Context

- Initial device: Garmin fēnix 7 Solar, 47 mm.
- Display: round MIP, 260 × 260 px, with a limited palette.
- The attached mockup is the visual reference; its filename is `watcffacerender1`.
- Priorities: outdoor readability, low power consumption, low memory use, and tolerance of missing data.
- The first version is for this device only, with no configurable options.
- Do not publish to the Connect IQ Store yet.

## Design

- Black background.
- Digital 24-hour time as the main element.
- Date: day of the week and day of the month.
- City and temperature in °C.
- Current steps / goal and an amber progress bar.
- Daylight bar with sunrise, sunset, and the approximate position of the sun.
- Bottom area:
  - Heart rate and a red heart icon.
  - Elevation with a brown mountain icon.
  - Battery life in days, or a percentage if days are unavailable.
- Battery color based on the actual percentage:
  - Green at >=30%.
  - Orange between 10% and 29%.
  - Red below 10%.
- Secondary text should be warm white or gray.
- No animations or seconds in the first version.

## Data and APIs

- Time and date: local system time.
- Steps and goal: `ActivityMonitor.getInfo()`.
- Temperature, city, sunrise, and sunset: Garmin Weather.
- City: `observationLocationName`, allowing for `null` or the name of a nearby station.
- Heart rate: the latest sample from SensorHistory; refresh the value every five minutes. Do not attempt to force an optical reading.
- Elevation: the latest elevation-history sample; avoid activating GPS periodically.
- Battery: `System.getSystemStats().battery`.
- Use `batteryInDays` when available; fall back to a percentage.
- All external values must handle `null`, stale data, denied permissions, or a disconnected phone.
- Avoid an external weather API or server for the MVP.

## Planned Permissions

- SensorHistory.
- Positioning only if it proves necessary.
- Add only the permissions actually used.

## Desired Architecture

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

## Workflow

1. Inspect the environment, installed SDK, exact device profile, and directory state.
2. Before creating files, present a brief plan and highlight any incompatibilities.
3. Create the smallest compilable project.
4. First implement a static screen matching the mockup.
5. Compare it visually in the simulator and adjust the proportions.
6. Connect the data in stages:
   1. Time and date.
   2. Steps and battery.
   3. Heart rate and elevation.
   4. Weather and the solar bar.
7. Add clear fallbacks such as `--` without causing errors.
8. Verify compilation, memory use, and low-power behavior after each stage.
9. Do not store or display developer keys, credentials, or secrets.
10. Do not publish or send anything externally without my authorization.

## MVP Completion Criteria

- Compiles for the fēnix 7 Solar.
- Runs correctly in the simulator.
- Can be installed on the watch using a PRG file.
- Preserves the mockup's visual hierarchy.
- All data has a fallback.
- Makes no external requests.
- Build, simulation, and USB installation steps are documented.

Start by verifying the setup and exact model/profile. Do not implement everything at once: begin with the structure and static rendering.
