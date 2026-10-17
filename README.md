# howdoi_notes_export

Pure Dart package for Google Maps URL field rules and complete Markdown roadbook rendering.

The host app creates a `RoadbookSnapshot` from its own trip and planner data. This package has no Flutter, database, geocoding, or network dependency. It validates HTTPS URLs locally and renders the supplied locations as Markdown links; flights never receive map fields or links.

## Use

The package is pure Dart and can be used independently of Flutter. The host app converts its trip data into a `RoadbookSnapshot`, then calls the renderer to create the Markdown note. The package deliberately knows nothing about HowDoI's database or model classes.

The HowDoI adapter is maintained in the main app repository. When upstream changes its data model, update that adapter and verify the supported app version there; the package API should only change when the shared export rules need to change.

## License

No license has been selected or included. All rights remain with the copyright holder; do not assume permission to reuse or redistribute this code.
