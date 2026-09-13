# Hazri — working rules

These are the implementation rules from the PRD (`docs/PRD.md` §0). They apply
to every session in this repository.

1. **The design files are the visual spec, not code to port.**
   `design/html/NN-*.{light,dark}.html` are 390 x 844 CSS px = 390 x 844 dp.
   Match layout, spacing, radii, colours and type; build with Flutter widgets.
   `design/tokens.json` is the source of truth for colour, type and shape, and
   is mirrored in `lib/core/theme/`.
2. **Behaviour comes from the PRD.** Where a design and the PRD disagree, the
   PRD wins; note the conflict in the PR description.
3. **Never create, paraphrase, auto-translate or AI-generate Gurbani text,
   Gurbani audio, meanings, or images of the Gurus.** Every line of Gurbani and
   every meaning in the app comes from `content/source/` through
   `tools/content_pipeline/build_content_db.py`. Nothing Gurbani-related is
   typed into Dart.
4. **No ad SDKs, no login, no own server, no tracking SDKs.** This build makes
   no network requests at all; `INTERNET` is removed from the merged manifest.
5. **All UI strings are localised** in `pa`, `hi` and `en` from day one. No
   hard-coded user-facing strings; `test/core/l10n_test.dart` fails on a
   missing or untranslated key.
6. **Keep platform-specific code behind interfaces** so the iOS app in Phase 3
   needs new adapters, not rewrites (`HukamnamaSource`, `ReminderService`).
7. Every change ends with `flutter analyze` clean and `flutter test` passing.

## Layout

```
lib/
  app/          MaterialApp.router, routes, bottom-nav shell
  core/
    theme/      tokens -> HazriColors (ThemeExtension), type, icons
    l10n/       ARB files (pa, hi, en) + generated
    db/         drift: content.db (read-only, bundled) and user.db
    settings/   AppSettings + SettingsController (shared_preferences)
    time/       Clock, NOAA SolarService, Nanakshahi calendar, formatting
    widgets/    AppMark, DayArc, ProgressRing, cards, chips, buttons
  features/     onboarding today nitnem reader diary reminders hukamnama
                simran gurpurab goals settings about
                each: data/ (repos, controllers) domain/ (models, logic) ui/
tools/content_pipeline/   builds assets/content/content.db
content/source/           the reviewed source files the pipeline reads
design/                   tokens.json, screens.json, HTML specs, PNG renders
```

## Regenerating

```bash
python3 tools/content_pipeline/build_content_db.py   # assets/content/content.db
flutter gen-l10n                                      # lib/core/l10n/gen
dart run build_runner build                           # drift *.g.dart
```

## Known gaps in this build

- **Audio** is not implemented. The reader, Nitnem list and setup say so; the
  follow-audio state and player screens are not built yet.
- **Only Japji Sahib has text.** The other eight banis are real rows with a
  "not in this build" reader state, waiting on reviewed text.
- **No Hukamnama source is configured.** `HukamnamaSource` has an
  `Unconfigured` implementation; the screen, cache and share card are built.
- **The Nanakshahi calendar covers 17 Aug - 15 Dec 2026 only**, derived from
  the supplied SGPC sample. Dates outside it report that rather than guessing.
