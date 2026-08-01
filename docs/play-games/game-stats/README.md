# Game Stats package

This directory is the upload source for the Aura Shift Game Stats configuration.
It follows the Google CSV schema available on 26 July 2026 and contains five
repetitive stats plus one progression stat.

## Files

- `PlayerGameEvent.csv`: `auraActivityDelta` and `progressUpdate` schemas.
- `RepetitiveStatsConfig.csv`: five repetitive stats.
- `ProgressionStatConfig.csv`: the single `Aura Level` progression.
- `StatLocalizations.csv`: Brazilian Portuguese and English.
- `icons/`: six 512 × 512 PNG files rasterized from the approved game artwork.

The icons are Play Console exports, not Flutter runtime assets. Their sources
remain under `sources/art/`.

## Before upload

1. Confirm that the Play Console CSV importer is available (scheduled for
   August 2026).
2. Review the competitive hourly `minLimit`/`maxLimit` values with real closed
   test telemetry. The current upper bounds are permissive bootstrap limits,
   not an anti-cheat guarantee.
3. ZIP the contents of this directory, with the three configuration CSVs and
   icon files at the layout required by the current Console UI.
4. Do not enable `PGS_GAME_STATS_ENABLED` until the stable Java SDK exposes
   `PlayerGameEvent`, `GameStatsClient`, `recordEvents`, and
   `requestEventsUpload`, and the Kotlin adapter is completed against that
   released artifact.

The Dart aggregation and persistent queue are active independently of the
native upload feature. `SUM` properties receive deltas, never cumulative
snapshots.
