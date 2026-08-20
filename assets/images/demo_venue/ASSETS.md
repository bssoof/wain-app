# Demo venue — asset pack

All six shots are installed, and `demoVenueAssetPackInstalled` in
`lib/features/demo/data/demo_venue_catalog.dart` records that. The demo venue no
longer borrows food photography from `assets/images/demo_menu/`.

| # | File | Shot |
|---|------|------|
| 1 | `storefront.jpg` | Exterior / shopfront, daylight |
| 2 | `indoor_seating.jpg` | Indoor seating area, wide |
| 3 | `coffee_bar.jpg` | Espresso bar / barista station |
| 4 | `food_table.jpg` | Table set with food, overhead |
| 5 | `workspace.jpg` | Laptop-friendly corner |
| 6 | `outdoor_terrace.jpg` | Outdoor seating |

`demo_isolation_test` fails if any of these goes missing, if the gallery stops
serving them, or if one grows past 600 KB.

Requirements for a replacement: 4:3 or 1:1, at least 1200px on the long edge,
consistent white balance, no readable third-party branding, no identifiable
faces.

**Provenance rule:** these must be original photographs, images the project holds
a licence for, or — as with the current set — synthetic images generated for this
demo. They depict no existing business. Google Maps / Places imagery may not be
copied here: that requires the Google Places photo contract and its attribution,
which this directory does not carry.
