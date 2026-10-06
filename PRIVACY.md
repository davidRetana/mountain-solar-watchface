# Mountain Solar privacy policy

Last updated: 6 October 2026. [Español](PRIVACY.es.md).

Mountain Solar is a Garmin Connect IQ watch face maintained by the owner of
[this repository](https://github.com/davidRetana/mountain-solar-watchface).
This policy describes the application's current behaviour. Garmin and
OpenStreetMap Foundation operate their own services under their own policies.

## Data used on the watch

The watch face reads the watch's time, date, language, step count and step goal,
battery level and estimated battery days, recent heart-rate and elevation
history, and Garmin Weather observations. Weather observations can include
temperature, observation time and the weather station's coordinates. These
coordinates may differ from the wearer's actual location.

The watch face does not start GPS positioning or optical heart-rate sensing.
It uses information already available through Garmin APIs. Heart rate,
elevation, steps, battery and watch language are not sent to the city service.
The application does not include advertising, analytics, account registration
or device-identifier tracking, and does not send data to a server operated by
its maintainer.

## City lookup and disclosure to a third party

When a current weather location has no saved city name, the watch face
automatically requests a city from the public Nominatim service operated by
OpenStreetMap Foundation, through Garmin Connect connectivity.

The HTTPS request sends the weather coordinates rounded to two decimal
places, a Spanish language preference, reverse-geocoding options, and an
application identifier containing the project name/version and repository
URL. Rounding reduces precision; it does not anonymise a location. Nominatim
can process or log requests according to
[OpenStreetMap Foundation's privacy policy](https://osmfoundation.org/wiki/Privacy_Policy).
The provider's [usage policy](https://operations.osmfoundation.org/policies/nominatim/)
also applies. City data is © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright),
available under the Open Database License (ODbL).

There is currently no separate in-app switch or confirmation for this lookup.
If you do not want weather coordinates sent to Nominatim, do not use this
version of the watch face. Changing the watch's interface language does not
change the existing Spanish preference used by the city request.

## Storage and retention

Current display readings are cached in working memory. The application
persistently stores up to eight recently used rounded coordinate pairs and
their city names on the watch. A new entry replaces the least recent entry
when the cache is full. It also stores retry state to avoid repeated requests
after network failures. Saved cities can remain until replaced or the
application's storage is removed; there is no time-based expiration or
separate cache-clearing control in this version.

Uninstall the watch face to remove its application storage using Garmin's
uninstall process. This does not delete health or activity records held by
the watch, Garmin Connect, or other applications, or request logs held by a
third-party provider. The maintainer does not have remote access to the watch's
stored city cache.

## Permissions and choices

The application declares `SensorHistory`, `Positioning`, `Communications` and
`Background`. These allow existing sensor-history reads, access to weather
coordinates, Internet city lookup and its background execution. They do not
cause this watch face to start GPS or heart-rate sensing. Garmin controls
permission availability; unavailable or expired data is shown as `--`.

## Contact and changes

For questions about this application or policy, contact the maintainer through
[the project issues](https://github.com/davidRetana/mountain-solar-watchface/issues).
Issues are public when the repository is public: do not post coordinates,
health data, credentials or other private information there. For data held by
Garmin or OpenStreetMap Foundation, use that organisation's privacy contact.

This policy will be updated when data use, providers or retention changes.
