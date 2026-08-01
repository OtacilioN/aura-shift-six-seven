# Google Play Games Services

## Implemented architecture

Aura Shift uses its existing manual dependency injection and `ChangeNotifier`
architecture:

- `GameController` remains the only authority for local game economy.
- `PlayGamesCoordinator` observes stable progression snapshots, performs the
  UTC-7 weekly rollover, aggregates Game Stats deltas, throttles submissions
  to 45-second checkpoints, and flushes on pause/resume/authentication.
- `PlayGamesStore` persists device-local sync state under
  `play-games-v1`. It is intentionally separate from `save-v1`, so account
  identity, consent, last acknowledgements, and pending deltas are not copied
  into the cloud game-state payload.
- `PlayGamesService` is testable. Android uses a dedicated `MethodChannel`;
  other platforms use a safe no-op adapter.
- `PlayGamesBridge.kt` uses Play Games Services v2 for sign-in, leaderboards,
  raw friends, consent, and native profile comparison. Platform calls do not
  live in widgets.

Failures never block gameplay. Scores and stat deltas remain queued while the
player is offline or unauthenticated.

## Fixed dependency

Android uses:

```text
com.google.android.gms:play-services-games-v2:21.0.0
```

No dynamic `+` version is used. The project currently builds with Flutter
3.44.6, Dart 3.12.2, Java 17, AGP 9.0.1, Kotlin 2.3.20, and Gradle 9.1.0.

## IDs and build configuration

| Override | Purpose | Checked-in production default |
| --- | --- | --- |
| `PGS_GAME_PROJECT_ID` | Play Games project/application ID | `293539263998` |
| `PGS_WEEKLY_AURA_LEADERBOARD_ID` | Farmador da Semana / Weekly Aura Farmer | `CgkI_uu2wsUIEAIQAQ` |
| `PGS_MAX_APS_LEADERBOARD_ID` | Maior Produção de Aura / Highest Aura Production | `CgkI_uu2wsUIEAIQAg` |
| `PGS_MAX_MOVEMENT_LEADERBOARD_ID` | Maior Movimento de Aura / Highest Aura per Movement | `CgkI_uu2wsUIEAIQAw` |

The public identifiers are checked in because they are not secrets. Environment
variables and Dart defines remain available for alternate Play Games projects:

```bash
PGS_GAME_PROJECT_ID=ALTERNATE_PROJECT_ID \
flutter build apk --debug \
  --dart-define=PGS_GAME_PROJECT_ID=ALTERNATE_PROJECT_ID \
  --dart-define=PGS_WEEKLY_AURA_LEADERBOARD_ID=ALTERNATE_ID \
  --dart-define=PGS_MAX_APS_LEADERBOARD_ID=ALTERNATE_ID \
  --dart-define=PGS_MAX_MOVEMENT_LEADERBOARD_ID=ALTERNATE_ID
```

The production defaults were created and published in Play Console on 26 July
2026. Builds with explicitly empty overrides still fail safely with the
`notConfigured` state rather than crashing.

## Leaderboards

Create all three as **larger is better** and enable tamper protection in the
Play Console:

| Console name | Submitted value | Default period |
| --- | --- | --- |
| Farmador da Semana | Aura produced during the current PGS week | Weekly |
| Maior Produção de Aura | Highest whole passive Aura/second reached | All time |
| Maior Movimento de Aura | Highest Aura credited by one completed Six-Seven movement | All time |

The PGS week begins Sunday 00:00 UTC-7 (Sunday 07:00 UTC). Only the weekly
counter resets. Lifetime Aura and other save progress are never reset.

The in-game screen supports daily, weekly, and all-time views and public or
friends collections. It formats decoded Aura using `AuraFormat`, not Google's
encoded integer.

## Arbitrary-size scores

Aura is a Dart `BigInt`, while PGS accepts signed 64-bit integers.
`AuraLeaderboardScoreCodec` keeps values through 15 decimal digits exact. For
larger values it stores a decimal digit bucket plus the 15 most significant
digits. Encoding is deterministic and monotonic. At int64 saturation, larger
values tie instead of overflowing. Native PGS display should use a neutral
label such as **Aura Power** because compressed values are not raw Aura; the
game UI shows the approximate decoded Aura.

## Sign-in and friends

PGS v2 attempts automatic sign-in. Aura Shift checks authentication at startup
without forcing UI and offers a manual Connect action when needed.

Friends flow:

1. Load friends or a friends leaderboard.
2. Store `FriendsResolutionRequiredException.resolution` as a single-use
   `PendingIntent`.
3. Show the official Google consent UI only after the explicit in-game action.
4. Retry after approval.
5. Persist denial and never reopen the prompt on every launch.
6. Keep a manual retry button.

Friend profiles use the native compare intent and do not require preloading the
entire friend list. Player ID is only a join key for PGS data; it is not an
internal account identifier.

## Game Stats

The prepared schema is in `docs/play-games/game-stats/`:

- `auraActivityDelta`: `auraEarnedDelta` (DOUBLE),
  `manualActionsDelta` (INT), encoded `maxAuraPerSecond` (INT),
  `prestigesDelta` (INT), and `itemsUnlockedDelta` (INT).
- `progressUpdate`: `currentProgress` (INT) and `auraTier` (STRING).

`currentProgress` is the decimal magnitude of lifetime Aura: 0 before any Aura,
1 for one-digit totals, 4 for thousands, etc. This is small, monotonic, and
does not change balance.

The timeline known on 26 July 2026 is: Java/client integration GA in July,
Play Console CSV upload expected in August, and Gamer Profile display expected
in September. Do not claim profile visibility before those Console stages.

### Current SDK limitation and feature flag

The stable Java artifact `play-services-games-v2:21.0.0` does not yet contain
`PlayerGameEvent` or `GameStatsClient`. Therefore the Android Game Stats
adapter is a compiling `notConfigured` boundary. Models, aggregation,
idempotent persisted checkpoints, CSVs, icons, and tests are implemented.

`PGS_GAME_STATS_ENABLED` defaults to `false`. Activate it only after upgrading
to a stable fixed SDK version that contains the documented Java API and
implementing the isolated Kotlin calls to `recordEvents` and
`requestEventsUpload`.

## Console and credential status

Completed on 26 July 2026:

1. Linked `com.otaciliomaia.aurashiftsixseven` to the Play Games project
   `293539263998`.
2. Published the external OAuth consent configuration with the `games`,
   `games_lite`, and `drive.appdata` scopes.
3. Created the production Android OAuth credential with the Play App Signing
   SHA-1 and enabled PGS anti-piracy.
4. Created and published all three leaderboards with larger-is-better ordering
   and tamper protection.
5. Published the Play Games project for all users.

Remaining runtime/release validation:

1. Add local debug or other distribution SHA-1 credentials only when those
   non-Play-distributed builds need live PGS access.
2. Add tester accounts and publish to an internal or closed track. PGS sign-in
   must be tested from a Play-installed build; a sideloaded APK is insufficient
   evidence for production credentials.
3. Upload the Game Stats CSV/icon package when the Console UI is available.
4. Publish Game Stats configuration, then enable the flag only with a stable
   Java client adapter.

Obtain SHA-1 fingerprints with `keytool -list -v` without committing keystore
paths or passwords. The Play App Signing SHA-1 is shown in Play Console under
App integrity.

## Physical-device validation

- Install from the configured internal/closed Play track.
- Confirm automatic sign-in does not interrupt gameplay.
- Disconnect/reconnect manually.
- Produce Aura offline, pause, resume, and verify one queued flush.
- Cross Sunday 07:00 UTC in a controlled test and verify only weekly Aura
  resets.
- Load global/friends and daily/weekly/all-time combinations.
- Approve friends once, compare a profile, and verify a friend without score.
- Deny friends, relaunch, and verify there is no prompt loop.
- Test missing/outdated Play services and airplane mode.
- Confirm no network request is emitted per touch.
- Restore an old save and verify no lifetime `SUM` snapshot is duplicated.

## Security limits

The existing save is local and portable, so these rankings are casual,
best-effort competition. PGS tamper protection should be enabled, negative and
non-finite values are rejected, records are monotonic, and platform errors are
logged without personal data. This does not make the local save authoritative.
The validation boundary is isolated for a future Play Integrity or server-side
design; no backend was added in this delivery.
