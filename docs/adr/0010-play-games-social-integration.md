# ADR 0010 — Google Play Games social integration

Status: accepted by explicit product request on 26 July 2026.

This decision supersedes the earlier MVP exclusion of rankings and social Play
Games features. The four-root navigation, offline-first economy, local-first
save, and no-new-backend constraints remain unchanged.

Google Play Games Services v2 is integrated behind a testable Android adapter.
Competitive data is described as best effort because the client-side save
is not authoritative. A separate sync store prevents account/consent/event
acknowledgement state from travelling in the cloud game-state payload. Game Stats stays feature
flagged until the stable Java SDK and Play Console configuration are available.
