package com.otaciliomaia.aurashiftsixseven

import android.app.Activity
import android.content.Intent
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.games.FriendsResolutionRequiredException
import com.google.android.gms.games.GamesClientStatusCodes
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.SnapshotsClient
import com.google.android.gms.games.achievement.Achievement
import com.google.android.gms.games.leaderboard.LeaderboardVariant
import com.google.android.gms.games.snapshot.Snapshot
import com.google.android.gms.games.snapshot.SnapshotMetadata
import com.google.android.gms.games.snapshot.SnapshotMetadataChange
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

class PlayGamesBridge(
    private val activity: MainActivity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private companion object {
        const val CHANNEL = "com.otaciliomaia.aurashiftsixseven/play_games"
        const val FRIENDS_CONSENT_REQUEST = 6701
        const val NATIVE_UI_REQUEST = 6702
        const val CLOUD_SAVE_SLOT = "aura_shift_primary"
        const val CLOUD_SAVE_MAX_BYTES = 3 * 1024 * 1024
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val cloudSaveExecutor: ExecutorService =
        Executors.newSingleThreadExecutor { runnable ->
            Thread(runnable, "aura-cloud-save").apply { isDaemon = true }
        }
    private val pendingCloudConflicts =
        mutableMapOf<String, SnapshotsClient.SnapshotConflict>()
    private var friendsResolution: android.app.PendingIntent? = null
    private var consentResult: MethodChannel.Result? = null
    private var cloudOperationInFlight = false
    private var disposed = false

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> initialize(result)
            "isAuthenticated" -> isAuthenticated(result)
            "signIn" -> signIn(result)
            "loadCurrentPlayer" -> loadCurrentPlayer(result)
            "submitScore" -> submitScore(call, result)
            "loadLeaderboard" -> loadLeaderboard(call, result)
            "showNativeLeaderboard" -> showNativeLeaderboard(call, result)
            "achievementUnlock" -> achievementUnlock(call, result)
            "achievementReveal" -> achievementReveal(call, result)
            "achievementSetSteps" -> achievementSetSteps(call, result)
            "achievementLoad" -> achievementLoad(call, result)
            "showNativeAchievements" -> showNativeAchievements(result)
            "loadFriends" -> loadFriends(call, result)
            "requestFriendsConsent" -> requestFriendsConsent(result)
            "showCompareProfile" -> showCompareProfile(call, result)
            "cloudSaveOpen" -> cloudSaveOpen(result)
            "cloudSaveCommit" -> cloudSaveCommit(call, result)
            "cloudSaveResolveConflict" -> cloudSaveResolveConflict(call, result)
            "cloudSaveAbandonConflict" -> cloudSaveAbandonConflict(call, result)
            "recordGameStats", "requestEventsUpload" ->
                result.error(
                    "not_configured",
                    "Game Stats Java APIs are not present in play-services-games-v2:21.0.0.",
                    null,
                )
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        if (disposed) return
        disposed = true
        channel.setMethodCallHandler(null)
        val conflicts = pendingCloudConflicts.values.toList()
        pendingCloudConflicts.clear()
        val snapshotsClient =
            if (configured()) PlayGames.getSnapshotsClient(activity) else null
        conflicts.forEach { conflict ->
            snapshotsClient?.discardAndClose(conflict.snapshot)
            snapshotsClient?.discardAndClose(conflict.conflictingSnapshot)
        }
        cloudSaveExecutor.shutdown()
        consentResult = null
        friendsResolution = null
    }

    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != FRIENDS_CONSENT_REQUEST) return false
        val pending = consentResult ?: return true
        consentResult = null
        friendsResolution = null
        if (resultCode == Activity.RESULT_OK) {
            pending.success(null)
        } else {
            pending.error("permission_denied", "Friends access was denied.", null)
        }
        return true
    }

    private fun configured(): Boolean =
        activity.getString(R.string.game_services_project_id).isNotBlank() &&
            activity.getString(R.string.game_services_project_id) != "0"

    private fun initialize(result: MethodChannel.Result) {
        if (!configured()) {
            result.error("not_configured", "Play Games project ID is missing.", null)
            return
        }
        val availability =
            GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(activity)
        if (availability != ConnectionResult.SUCCESS) {
            val code =
                if (availability == ConnectionResult.SERVICE_DISABLED ||
                    availability == ConnectionResult.SERVICE_VERSION_UPDATE_REQUIRED
                ) {
                    "unsupported"
                } else {
                    "temporarily_unavailable"
                }
            result.error(code, "Google Play services is unavailable ($availability).", null)
            return
        }
        PlayGames.getGamesSignInClient(activity)
            .isAuthenticated
            .addOnSuccessListener { authentication ->
                if (authentication.isAuthenticated) {
                    result.success(null)
                } else {
                    result.error("unauthenticated", "Player is not authenticated.", null)
                }
            }
            .addOnFailureListener { error(result, it) }
    }

    private fun isAuthenticated(result: MethodChannel.Result) {
        if (!configured()) {
            result.success(false)
            return
        }
        PlayGames.getGamesSignInClient(activity)
            .isAuthenticated
            .addOnSuccessListener { result.success(it.isAuthenticated) }
            .addOnFailureListener { result.success(false) }
    }

    private fun signIn(result: MethodChannel.Result) {
        if (!configured()) {
            result.error("not_configured", "Play Games project ID is missing.", null)
            return
        }
        PlayGames.getGamesSignInClient(activity)
            .signIn()
            .addOnSuccessListener {
                if (it.isAuthenticated) {
                    result.success(null)
                } else {
                    result.error("unauthenticated", "Sign-in was not completed.", null)
                }
            }
            .addOnFailureListener { error(result, it) }
    }

    private fun loadCurrentPlayer(result: MethodChannel.Result) {
        if (!configured()) {
            result.success(null)
            return
        }
        PlayGames.getPlayersClient(activity)
            .currentPlayer
            .addOnSuccessListener { player ->
                result.success(
                    mapOf(
                        "playerId" to player.playerId,
                        "displayName" to player.displayName,
                        "avatarUrl" to player.hiResImageUri?.toString(),
                        "avatarBytes" to avatarBytes(player.hiResImageUri),
                    ),
                )
            }
            .addOnFailureListener { error(result, it) }
    }

    private fun submitScore(call: MethodCall, result: MethodChannel.Result) {
        val leaderboardId = call.argument<String>("leaderboardId")
        val score = call.argument<Number>("score")?.toLong()
        if (leaderboardId.isNullOrBlank() || score == null || score < 0) {
            result.error("not_configured", "Leaderboard ID or score is invalid.", null)
            return
        }
        PlayGames.getLeaderboardsClient(activity)
            .submitScoreImmediate(
                leaderboardId,
                score,
                call.argument<String>("scoreTag") ?: "",
            )
            .addOnSuccessListener { result.success(null) }
            .addOnFailureListener { error(result, it) }
    }

    private fun loadLeaderboard(call: MethodCall, result: MethodChannel.Result) {
        val leaderboardId = call.argument<String>("leaderboardId")
        if (leaderboardId.isNullOrBlank()) {
            result.error("not_configured", "Leaderboard ID is missing.", null)
            return
        }
        val span =
            when (call.argument<String>("timeScope")) {
                "daily" -> LeaderboardVariant.TIME_SPAN_DAILY
                "weekly" -> LeaderboardVariant.TIME_SPAN_WEEKLY
                else -> LeaderboardVariant.TIME_SPAN_ALL_TIME
            }
        val collection =
            if (call.argument<String>("playerScope") == "friends") {
                LeaderboardVariant.COLLECTION_FRIENDS
            } else {
                LeaderboardVariant.COLLECTION_PUBLIC
            }
        val forceReload = call.argument<Boolean>("forceReload") == true
        PlayGames.getPlayersClient(activity)
            .currentPlayerId
            .addOnSuccessListener { currentPlayerId ->
                PlayGames.getLeaderboardsClient(activity)
                    .loadTopScores(
                        leaderboardId,
                        span,
                        collection,
                        25,
                        forceReload,
                    )
                    .addOnSuccessListener { annotated ->
                        val loaded = annotated.get()
                        if (loaded == null) {
                            result.success(mapOf("entries" to emptyList<Any>()))
                            return@addOnSuccessListener
                        }
                        val entries =
                            try {
                            val buffer = loaded.scores
                                (0 until buffer.count).map { index ->
                                    val score = buffer[index]
                                    val player = score.scoreHolder
                                    mapOf(
                                        "playerId" to (player?.playerId ?: ""),
                                        "displayName" to score.scoreHolderDisplayName,
                                        "avatarUrl" to
                                            score.scoreHolderHiResImageUri.toString(),
                                        "avatarBytes" to
                                            avatarBytes(score.scoreHolderHiResImageUri),
                                        "rank" to score.rank,
                                        "score" to score.rawScore,
                                        "isCurrentPlayer" to
                                            (player?.playerId == currentPlayerId),
                                    )
                                }.toMutableList()
                            } finally {
                                loaded.release()
                            }
                        PlayGames.getLeaderboardsClient(activity)
                            .loadCurrentPlayerLeaderboardScore(
                                leaderboardId,
                                span,
                                collection,
                            )
                            .addOnSuccessListener { currentAnnotated ->
                                val current = currentAnnotated.get()
                                if (current != null &&
                                    entries.none { it["playerId"] == currentPlayerId }
                                ) {
                                    entries.add(
                                        mapOf(
                                            "playerId" to currentPlayerId,
                                            "displayName" to current.scoreHolderDisplayName,
                                            "avatarUrl" to
                                                current.scoreHolderHiResImageUri.toString(),
                                            "avatarBytes" to
                                                avatarBytes(
                                                    current.scoreHolderHiResImageUri,
                                                ),
                                            "rank" to current.rank,
                                            "score" to current.rawScore,
                                            "isCurrentPlayer" to true,
                                        ),
                                    )
                                }
                                result.success(mapOf("entries" to entries))
                            }
                            .addOnFailureListener {
                                // The top page remains useful if the player's
                                // separate rank is hidden or unavailable.
                                result.success(mapOf("entries" to entries))
                            }
                    }
                    .addOnFailureListener { error(result, it) }
            }
            .addOnFailureListener { error(result, it) }
    }

    private fun showNativeLeaderboard(call: MethodCall, result: MethodChannel.Result) {
        val leaderboardId = call.argument<String>("leaderboardId")
        if (leaderboardId.isNullOrBlank()) {
            result.error("not_configured", "Leaderboard ID is missing.", null)
            return
        }
        PlayGames.getLeaderboardsClient(activity)
            .getLeaderboardIntent(leaderboardId)
            .addOnSuccessListener {
                activity.startActivityForResult(it, NATIVE_UI_REQUEST)
                result.success(null)
            }
            .addOnFailureListener { error(result, it) }
    }

    private fun achievementUnlock(call: MethodCall, result: MethodChannel.Result) {
        val achievementId = achievementId(call, result) ?: return
        PlayGames.getAchievementsClient(activity)
            .unlockImmediate(achievementId)
            .addOnSuccessListener { result.success(null) }
            .addOnFailureListener { error(result, it) }
    }

    private fun achievementReveal(call: MethodCall, result: MethodChannel.Result) {
        val achievementId = achievementId(call, result) ?: return
        PlayGames.getAchievementsClient(activity)
            .revealImmediate(achievementId)
            .addOnSuccessListener { result.success(null) }
            .addOnFailureListener { error(result, it) }
    }

    private fun achievementSetSteps(call: MethodCall, result: MethodChannel.Result) {
        val achievementId = achievementId(call, result) ?: return
        val steps = call.argument<Number>("steps")?.toInt()
        if (steps == null || steps !in 0..10000) {
            result.error("not_configured", "Achievement steps are invalid.", null)
            return
        }
        if (steps == 0) {
            result.success(null)
            return
        }
        PlayGames.getAchievementsClient(activity)
            .setStepsImmediate(achievementId, steps)
            .addOnSuccessListener { result.success(null) }
            .addOnFailureListener { error(result, it) }
    }

    private fun achievementLoad(call: MethodCall, result: MethodChannel.Result) {
        val forceReload = call.argument<Boolean>("forceReload") == true
        PlayGames.getAchievementsClient(activity)
            .load(forceReload)
            .addOnSuccessListener { annotated ->
                val buffer = annotated.get()
                if (buffer == null) {
                    result.success(emptyList<Any>())
                    return@addOnSuccessListener
                }
                try {
                    result.success(
                        (0 until buffer.count).map { index ->
                            val achievement = buffer[index]
                            mapOf(
                                "id" to achievement.achievementId,
                                "state" to
                                    when (achievement.state) {
                                        Achievement.STATE_HIDDEN -> "hidden"
                                        Achievement.STATE_UNLOCKED -> "unlocked"
                                        else -> "revealed"
                                    },
                                "type" to
                                    if (achievement.type == Achievement.TYPE_INCREMENTAL) {
                                        "incremental"
                                    } else {
                                        "standard"
                                    },
                                "currentSteps" to
                                    if (achievement.type == Achievement.TYPE_INCREMENTAL) {
                                        achievement.currentSteps
                                    } else {
                                        0
                                    },
                                "totalSteps" to
                                    if (achievement.type == Achievement.TYPE_INCREMENTAL) {
                                        achievement.totalSteps
                                    } else {
                                        0
                                    },
                            )
                        },
                    )
                } finally {
                    buffer.release()
                }
            }
            .addOnFailureListener { error(result, it) }
    }

    private fun showNativeAchievements(result: MethodChannel.Result) {
        PlayGames.getAchievementsClient(activity)
            .getAchievementsIntent()
            .addOnSuccessListener {
                activity.startActivityForResult(it, NATIVE_UI_REQUEST)
                result.success(null)
            }
            .addOnFailureListener { error(result, it) }
    }

    private fun achievementId(
        call: MethodCall,
        result: MethodChannel.Result,
    ): String? {
        val achievementId = call.argument<String>("achievementId")
        if (achievementId.isNullOrBlank()) {
            result.error("not_configured", "Achievement ID is missing.", null)
            return null
        }
        return achievementId
    }

    private fun loadFriends(call: MethodCall, result: MethodChannel.Result) {
        val pageSize = (call.argument<Number>("pageSize")?.toInt() ?: 25).coerceIn(1, 200)
        val forceReload = call.argument<Boolean>("forceReload") == true
        PlayGames.getPlayersClient(activity)
            .loadFriends(pageSize, forceReload)
            .addOnSuccessListener { annotated ->
                val buffer = annotated.get()
                if (buffer == null) {
                    result.success(emptyList<Any>())
                    return@addOnSuccessListener
                }
                try {
                    val friends =
                        (0 until buffer.count).map { index ->
                            val player = buffer[index]
                            mapOf(
                                "playerId" to player.playerId,
                                "displayName" to player.displayName,
                                "avatarUrl" to player.hiResImageUri?.toString(),
                                "avatarBytes" to avatarBytes(player.hiResImageUri),
                            )
                        }
                    result.success(friends)
                } finally {
                    buffer.release()
                }
            }
            .addOnFailureListener { throwable ->
                if (throwable is FriendsResolutionRequiredException) {
                    friendsResolution = throwable.resolution
                    result.error(
                        "consent_required",
                        "Friends access requires player consent.",
                        null,
                    )
                } else {
                    error(result, throwable)
                }
            }
    }

    private fun requestFriendsConsent(result: MethodChannel.Result) {
        val resolution = friendsResolution
        if (resolution == null) {
            result.error(
                "temporarily_unavailable",
                "No unused friends consent resolution is available.",
                null,
            )
            return
        }
        if (consentResult != null) {
            result.error("temporarily_unavailable", "Consent is already open.", null)
            return
        }
        consentResult = result
        try {
            activity.startIntentSenderForResult(
                resolution.intentSender,
                FRIENDS_CONSENT_REQUEST,
                null,
                0,
                0,
                0,
            )
        } catch (throwable: Throwable) {
            consentResult = null
            friendsResolution = null
            error(result, throwable)
        }
    }

    private fun showCompareProfile(call: MethodCall, result: MethodChannel.Result) {
        val playerId = call.argument<String>("playerId")
        if (playerId.isNullOrBlank()) {
            result.error("temporarily_unavailable", "Player ID is missing.", null)
            return
        }
        val otherName = call.argument<String>("otherPlayerInGameName")
        val currentName = call.argument<String>("currentPlayerInGameName")
        val task =
            if (!otherName.isNullOrBlank() && !currentName.isNullOrBlank()) {
                PlayGames.getPlayersClient(activity)
                    .getCompareProfileIntentWithAlternativeNameHints(
                        playerId,
                        otherName,
                        currentName,
                    )
            } else {
                PlayGames.getPlayersClient(activity).getCompareProfileIntent(playerId)
            }
        task
            .addOnSuccessListener {
                activity.startActivityForResult(it, NATIVE_UI_REQUEST)
                result.success(null)
            }
            .addOnFailureListener { error(result, it) }
    }

    private fun cloudSaveOpen(result: MethodChannel.Result) {
        withCloudSaveClient(result) { snapshotsClient ->
            snapshotsClient
                .open(
                    CLOUD_SAVE_SLOT,
                    true,
                    SnapshotsClient.RESOLUTION_POLICY_MANUAL,
                )
                .addOnSuccessListener {
                    handleCloudOpenResult(snapshotsClient, it, result)
                }
                .addOnFailureListener { finishCloudFailure(result, it) }
        }
    }

    private fun cloudSaveCommit(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val payload = call.argument<ByteArray>("payload")
        if (payload == null) {
            result.error("invalid_payload", "Cloud save payload is missing.", null)
            return
        }
        if (payload.size > CLOUD_SAVE_MAX_BYTES) {
            result.error(
                "payload_too_large",
                "Cloud save payload exceeds the 3 MiB application limit.",
                mapOf("size" to payload.size, "maxSize" to CLOUD_SAVE_MAX_BYTES),
            )
            return
        }
        val metadataChange = metadataChange(call)
        withCloudSaveClient(result) { snapshotsClient ->
            snapshotsClient.maxDataSize
                .addOnSuccessListener { serviceMaxBytes ->
                    if (payload.size > minOf(CLOUD_SAVE_MAX_BYTES, serviceMaxBytes)) {
                        finishCloudError(
                            result,
                            "payload_too_large",
                            "Cloud save payload exceeds the Saved Games limit.",
                            mapOf(
                                "size" to payload.size,
                                "maxSize" to minOf(CLOUD_SAVE_MAX_BYTES, serviceMaxBytes),
                            ),
                        )
                        return@addOnSuccessListener
                    }
                    snapshotsClient
                        .open(
                            CLOUD_SAVE_SLOT,
                            true,
                            SnapshotsClient.RESOLUTION_POLICY_MANUAL,
                        )
                        .addOnSuccessListener { opened ->
                            if (opened.isConflict) {
                                emitCloudConflict(
                                    snapshotsClient,
                                    opened.conflict,
                                    result,
                                )
                            } else {
                                val snapshot = opened.data
                                if (snapshot == null) {
                                    finishCloudError(
                                        result,
                                        "temporarily_unavailable",
                                        "Saved Games returned no snapshot.",
                                    )
                                } else {
                                    writeAndCommitCloudSnapshot(
                                        snapshotsClient,
                                        snapshot,
                                        payload,
                                        metadataChange,
                                        result,
                                    )
                                }
                            }
                        }
                        .addOnFailureListener { finishCloudFailure(result, it) }
                }
                .addOnFailureListener { finishCloudFailure(result, it) }
        }
    }

    private fun cloudSaveResolveConflict(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val token = call.argument<String>("conflictToken")
        val payload = call.argument<ByteArray>("payload")
        if (token.isNullOrBlank() || payload == null) {
            result.error(
                "invalid_payload",
                "Conflict token and resolved payload are required.",
                null,
            )
            return
        }
        if (payload.size > CLOUD_SAVE_MAX_BYTES) {
            result.error(
                "payload_too_large",
                "Resolved payload exceeds the 3 MiB application limit.",
                mapOf("size" to payload.size, "maxSize" to CLOUD_SAVE_MAX_BYTES),
            )
            return
        }
        val metadataChange = metadataChange(call)
        withCloudSaveClient(result, allowPendingConflict = true) { snapshotsClient ->
            snapshotsClient.maxDataSize
                .addOnSuccessListener { serviceMaxBytes ->
                    if (payload.size > minOf(CLOUD_SAVE_MAX_BYTES, serviceMaxBytes)) {
                        finishCloudError(
                            result,
                            "payload_too_large",
                            "Resolved payload exceeds the Saved Games limit.",
                            mapOf(
                                "size" to payload.size,
                                "maxSize" to minOf(CLOUD_SAVE_MAX_BYTES, serviceMaxBytes),
                            ),
                        )
                        return@addOnSuccessListener
                    }
                    val conflict = pendingCloudConflicts.remove(token)
                    if (conflict == null) {
                        finishCloudError(
                            result,
                            "conflict_expired",
                            "The Saved Games conflict is no longer open.",
                        )
                        return@addOnSuccessListener
                    }
                    val snapshotId = conflict.snapshot.metadata.snapshotId
                    if (snapshotId.isBlank()) {
                        closeCloudConflict(snapshotsClient, conflict) {
                            finishCloudError(
                                result,
                                "conflict_expired",
                                "The Saved Games conflict has no snapshot ID.",
                            )
                        }
                        return@addOnSuccessListener
                    }
                    executeCloudSaveIo(
                        onRejected = {
                            closeCloudConflict(snapshotsClient, conflict) {
                                finishCloudError(
                                    result,
                                    "temporarily_unavailable",
                                    "Cloud save worker is unavailable.",
                                )
                            }
                        },
                    ) {
                        val writeResult =
                            runCatching {
                                conflict.resolutionSnapshotContents.writeBytes(payload)
                            }
                        activity.runOnUiThread {
                            if (writeResult.getOrDefault(false).not()) {
                                closeCloudConflict(snapshotsClient, conflict) {
                                    finishCloudError(
                                        result,
                                        "write_failed",
                                        writeResult.exceptionOrNull()?.message
                                            ?: "Could not write the resolved cloud save.",
                                    )
                                }
                                return@runOnUiThread
                            }
                            snapshotsClient
                                .resolveConflict(
                                    conflict.conflictId,
                                    snapshotId,
                                    metadataChange,
                                    conflict.resolutionSnapshotContents,
                                )
                                .addOnSuccessListener { resolved ->
                                    if (resolved.isConflict) {
                                        emitCloudConflict(
                                            snapshotsClient,
                                            resolved.conflict,
                                            result,
                                        )
                                    } else {
                                        val snapshot = resolved.data
                                        if (snapshot == null) {
                                            finishCloudError(
                                                result,
                                                "temporarily_unavailable",
                                                "Saved Games returned no resolved snapshot.",
                                            )
                                        } else {
                                            closeResolvedCloudSnapshot(
                                                snapshotsClient,
                                                snapshot,
                                                result,
                                            )
                                        }
                                    }
                                }
                                .addOnFailureListener {
                                    closeCloudConflict(snapshotsClient, conflict) {
                                        finishCloudFailure(result, it)
                                    }
                                }
                        }
                    }
                }
                .addOnFailureListener { finishCloudFailure(result, it) }
        }
    }

    private fun cloudSaveAbandonConflict(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val token = call.argument<String>("conflictToken")
        if (token.isNullOrBlank()) {
            result.error("conflict_expired", "Conflict token is missing.", null)
            return
        }
        if (!beginCloudOperation(result, allowPendingConflict = true)) return
        val conflict = pendingCloudConflicts.remove(token)
        if (conflict == null) {
            finishCloudError(
                result,
                "conflict_expired",
                "The Saved Games conflict is no longer open.",
            )
            return
        }
        val snapshotsClient = PlayGames.getSnapshotsClient(activity)
        closeCloudConflict(snapshotsClient, conflict) {
            finishCloudSuccess(result, null)
        }
    }

    private fun withCloudSaveClient(
        result: MethodChannel.Result,
        allowPendingConflict: Boolean = false,
        action: (SnapshotsClient) -> Unit,
    ) {
        if (!beginCloudOperation(result, allowPendingConflict)) return
        PlayGames.getGamesSignInClient(activity)
            .isAuthenticated
            .addOnSuccessListener { authentication ->
                if (!authentication.isAuthenticated) {
                    finishCloudError(
                        result,
                        "unauthenticated",
                        "Player is not authenticated.",
                    )
                    return@addOnSuccessListener
                }
                action(PlayGames.getSnapshotsClient(activity))
            }
            .addOnFailureListener { finishCloudFailure(result, it) }
    }

    private fun beginCloudOperation(
        result: MethodChannel.Result,
        allowPendingConflict: Boolean = false,
    ): Boolean {
        if (disposed) {
            result.error("temporarily_unavailable", "Play Games bridge is disposed.", null)
            return false
        }
        if (!configured()) {
            result.error("not_configured", "Play Games project ID is missing.", null)
            return false
        }
        if (cloudOperationInFlight) {
            result.error("busy", "A cloud save operation is already in progress.", null)
            return false
        }
        if (!allowPendingConflict && pendingCloudConflicts.isNotEmpty()) {
            result.error(
                "conflict_pending",
                "A Saved Games conflict must be resolved or abandoned first.",
                null,
            )
            return false
        }
        cloudOperationInFlight = true
        return true
    }

    private fun handleCloudOpenResult(
        snapshotsClient: SnapshotsClient,
        opened: SnapshotsClient.DataOrConflict<Snapshot>,
        result: MethodChannel.Result,
    ) {
        if (opened.isConflict) {
            emitCloudConflict(snapshotsClient, opened.conflict, result)
            return
        }
        val snapshot = opened.data
        if (snapshot == null) {
            finishCloudError(
                result,
                "temporarily_unavailable",
                "Saved Games returned no snapshot.",
            )
            return
        }
        val metadata = cloudMetadata(snapshot.metadata)
        executeCloudSaveIo(
            onRejected = {
                snapshotsClient
                    .discardAndClose(snapshot)
                    .addOnCompleteListener {
                        finishCloudError(
                            result,
                            "temporarily_unavailable",
                            "Cloud save worker is unavailable.",
                        )
                    }
            },
        ) {
            val readResult = runCatching { snapshot.snapshotContents.readFully() }
            activity.runOnUiThread {
                if (readResult.isFailure) {
                    snapshotsClient
                        .discardAndClose(snapshot)
                        .addOnCompleteListener {
                            finishCloudError(
                                result,
                                "content_unavailable",
                                readResult.exceptionOrNull()?.message
                                    ?: "Could not read the cloud save.",
                            )
                        }
                    return@runOnUiThread
                }
                snapshotsClient
                    .discardAndClose(snapshot)
                    .addOnSuccessListener {
                        val payload = readResult.getOrThrow()
                        finishCloudSuccess(
                            result,
                            mapOf(
                                "kind" to "snapshot",
                                "slot" to CLOUD_SAVE_SLOT,
                                "exists" to payload.isNotEmpty(),
                                "payload" to payload,
                                "metadata" to metadata,
                            ),
                        )
                    }
                    .addOnFailureListener { finishCloudFailure(result, it) }
            }
        }
    }

    private fun emitCloudConflict(
        snapshotsClient: SnapshotsClient,
        conflict: SnapshotsClient.SnapshotConflict?,
        result: MethodChannel.Result,
    ) {
        if (conflict == null) {
            finishCloudError(
                result,
                "conflict_expired",
                "Saved Games returned an empty conflict.",
            )
            return
        }
        val server = conflict.snapshot
        val conflicting = conflict.conflictingSnapshot
        val serverMetadata = cloudMetadata(server.metadata)
        val conflictingMetadata = cloudMetadata(conflicting.metadata)
        executeCloudSaveIo(
            onRejected = {
                closeCloudConflict(snapshotsClient, conflict) {
                    finishCloudError(
                        result,
                        "temporarily_unavailable",
                        "Cloud save worker is unavailable.",
                    )
                }
            },
        ) {
            val readResult =
                runCatching {
                    Pair(
                        server.snapshotContents.readFully(),
                        conflicting.snapshotContents.readFully(),
                    )
                }
            activity.runOnUiThread {
                if (readResult.isFailure) {
                    closeCloudConflict(snapshotsClient, conflict) {
                        finishCloudError(
                            result,
                            "content_unavailable",
                            readResult.exceptionOrNull()?.message
                                ?: "Could not read both conflict versions.",
                        )
                    }
                    return@runOnUiThread
                }
                if (disposed) {
                    closeCloudConflict(snapshotsClient, conflict)
                    cloudOperationInFlight = false
                    return@runOnUiThread
                }
                val token = UUID.randomUUID().toString()
                pendingCloudConflicts[token] = conflict
                val payloads = readResult.getOrThrow()
                finishCloudSuccess(
                    result,
                    mapOf(
                        "kind" to "conflict",
                        "slot" to CLOUD_SAVE_SLOT,
                        "conflictToken" to token,
                        "server" to
                            mapOf(
                                "payload" to payloads.first,
                                "metadata" to serverMetadata,
                            ),
                        "conflicting" to
                            mapOf(
                                "payload" to payloads.second,
                                "metadata" to conflictingMetadata,
                            ),
                    ),
                )
            }
        }
    }

    private fun writeAndCommitCloudSnapshot(
        snapshotsClient: SnapshotsClient,
        snapshot: Snapshot,
        payload: ByteArray,
        metadataChange: SnapshotMetadataChange,
        result: MethodChannel.Result,
    ) {
        executeCloudSaveIo(
            onRejected = {
                snapshotsClient
                    .discardAndClose(snapshot)
                    .addOnCompleteListener {
                        finishCloudError(
                            result,
                            "temporarily_unavailable",
                            "Cloud save worker is unavailable.",
                        )
                    }
            },
        ) {
            val writeResult =
                runCatching { snapshot.snapshotContents.writeBytes(payload) }
            activity.runOnUiThread {
                if (writeResult.getOrDefault(false).not()) {
                    snapshotsClient
                        .discardAndClose(snapshot)
                        .addOnCompleteListener {
                            finishCloudError(
                                result,
                                "write_failed",
                                writeResult.exceptionOrNull()?.message
                                    ?: "Could not write the cloud save.",
                            )
                        }
                    return@runOnUiThread
                }
                snapshotsClient
                    .commitAndClose(snapshot, metadataChange)
                    .addOnSuccessListener { metadata ->
                        finishCloudSuccess(
                            result,
                            mapOf(
                                "kind" to "committed",
                                "slot" to CLOUD_SAVE_SLOT,
                                "metadata" to cloudMetadata(metadata),
                            ),
                        )
                    }
                    .addOnFailureListener {
                        snapshotsClient
                            .discardAndClose(snapshot)
                            .addOnCompleteListener { _ ->
                                finishCloudFailure(result, it)
                            }
                    }
            }
        }
    }

    private fun executeCloudSaveIo(
        onRejected: () -> Unit,
        action: () -> Unit,
    ) {
        try {
            cloudSaveExecutor.execute(action)
        } catch (_: RejectedExecutionException) {
            onRejected()
        }
    }

    private fun closeResolvedCloudSnapshot(
        snapshotsClient: SnapshotsClient,
        snapshot: Snapshot,
        result: MethodChannel.Result,
    ) {
        val metadata = cloudMetadata(snapshot.metadata)
        snapshotsClient
            .discardAndClose(snapshot)
            .addOnSuccessListener {
                finishCloudSuccess(
                    result,
                    mapOf(
                        "kind" to "resolved",
                        "slot" to CLOUD_SAVE_SLOT,
                        "metadata" to metadata,
                    ),
                )
            }
            .addOnFailureListener { finishCloudFailure(result, it) }
    }

    private fun closeCloudConflict(
        snapshotsClient: SnapshotsClient,
        conflict: SnapshotsClient.SnapshotConflict,
        onComplete: (() -> Unit)? = null,
    ) {
        var remaining = 2
        val completed = {
            remaining -= 1
            if (remaining == 0) onComplete?.invoke()
        }
        snapshotsClient
            .discardAndClose(conflict.snapshot)
            .addOnCompleteListener { completed() }
        snapshotsClient
            .discardAndClose(conflict.conflictingSnapshot)
            .addOnCompleteListener { completed() }
    }

    private fun metadataChange(call: MethodCall): SnapshotMetadataChange {
        val builder = SnapshotMetadataChange.Builder()
        call.argument<String>("description")?.let(builder::setDescription)
        call.argument<Number>("playedTimeMs")
            ?.toLong()
            ?.takeIf { it >= 0 }
            ?.let(builder::setPlayedTimeMillis)
        call.argument<Number>("progressValue")
            ?.toLong()
            ?.takeIf { it >= 0 }
            ?.let(builder::setProgressValue)
        return builder.build()
    }

    private fun cloudMetadata(metadata: SnapshotMetadata): Map<String, Any?> =
        mapOf(
            "snapshotId" to metadata.snapshotId,
            "uniqueName" to metadata.uniqueName,
            "description" to metadata.description,
            "lastModifiedAtMs" to metadata.lastModifiedTimestamp,
            "playedTimeMs" to metadata.playedTime.coerceAtLeast(0),
            "progressValue" to metadata.progressValue.coerceAtLeast(0),
            "deviceName" to metadata.deviceName,
        )

    private fun finishCloudSuccess(
        result: MethodChannel.Result,
        value: Any?,
    ) {
        cloudOperationInFlight = false
        if (!disposed) result.success(value)
    }

    private fun finishCloudError(
        result: MethodChannel.Result,
        code: String,
        message: String,
        details: Any? = null,
    ) {
        cloudOperationInFlight = false
        if (!disposed) result.error(code, message, details)
    }

    private fun finishCloudFailure(
        result: MethodChannel.Result,
        throwable: Throwable,
    ) {
        finishCloudError(
            result,
            errorCode(throwable),
            throwable.message ?: "Saved Games request failed.",
        )
    }

    private fun error(result: MethodChannel.Result, throwable: Throwable) {
        result.error(
            errorCode(throwable),
            throwable.message ?: "Play Games request failed.",
            null,
        )
    }

    private fun errorCode(throwable: Throwable): String {
        if (throwable is SnapshotsClient.SnapshotContentUnavailableApiException) {
            return "content_unavailable"
        }
        val api = throwable as? ApiException
        return when (api?.statusCode) {
            4 -> "unauthenticated"
            7,
            GamesClientStatusCodes.NETWORK_ERROR_NO_DATA,
            GamesClientStatusCodes.NETWORK_ERROR_OPERATION_FAILED,
            -> "offline"
            10,
            GamesClientStatusCodes.APP_MISCONFIGURED,
            GamesClientStatusCodes.GAME_NOT_FOUND,
            GamesClientStatusCodes.ACHIEVEMENT_UNKNOWN,
            GamesClientStatusCodes.ACHIEVEMENT_NOT_INCREMENTAL,
            GamesClientStatusCodes.ACHIEVEMENT_UNLOCK_FAILURE,
            -> "not_configured"
            GamesClientStatusCodes.SNAPSHOT_NOT_FOUND -> "not_found"
            GamesClientStatusCodes.SNAPSHOT_CREATION_FAILED -> "commit_failed"
            GamesClientStatusCodes.SNAPSHOT_CONTENTS_UNAVAILABLE -> "content_unavailable"
            GamesClientStatusCodes.SNAPSHOT_COMMIT_FAILED -> "commit_failed"
            GamesClientStatusCodes.SNAPSHOT_FOLDER_UNAVAILABLE -> "not_configured"
            GamesClientStatusCodes.SNAPSHOT_CONFLICT_MISSING -> "conflict_expired"
            GamesClientStatusCodes.OPERATION_IN_FLIGHT -> "busy"
            else -> "temporarily_unavailable"
        }
    }

    private fun avatarBytes(uri: android.net.Uri?): ByteArray? {
        if (uri?.scheme != "content") return null
        return try {
            activity.contentResolver.openInputStream(uri)?.use { it.readBytes() }
        } catch (_: Throwable) {
            null
        }
    }
}
