import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/formatting.dart';
import '../main.dart';
import '../play_games/play_games_coordinator.dart';
import '../play_games/play_games_models.dart';

class AuraRankingsScreen extends StatefulWidget {
  const AuraRankingsScreen({
    super.key,
    required this.coordinator,
    required this.strings,
  });

  final PlayGamesCoordinator coordinator;
  final Strings strings;

  @override
  State<AuraRankingsScreen> createState() => _AuraRankingsScreenState();
}

class _AuraRankingsScreenState extends State<AuraRankingsScreen> {
  AuraLeaderboard leaderboard = AuraLeaderboard.weeklyAura;
  LeaderboardTimeScope timeScope = LeaderboardTimeScope.weekly;
  LeaderboardPlayerScope playerScope = LeaderboardPlayerScope.global;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool forceReload = false}) =>
      widget.coordinator.loadLeaderboard(
        leaderboard: leaderboard,
        timeScope: timeScope,
        playerScope: playerScope,
        forceReload: forceReload,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_t('title')),
          actions: [
            IconButton(
              tooltip: _t('native'),
              onPressed: () =>
                  widget.coordinator.showNativeLeaderboard(leaderboard),
              icon: const Icon(Icons.sports_esports_outlined),
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: widget.coordinator,
          builder: (context, _) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: RefreshIndicator(
                onRefresh: () => _load(forceReload: true),
                child: ListView(
                  key: const ValueKey('aura-rankings-scroll'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _AuthCard(
                      coordinator: widget.coordinator,
                      status: _availabilityText(
                        widget.coordinator.availability,
                      ),
                      connectLabel: _t('connect'),
                    ),
                    const SizedBox(height: 12),
                    _selectors(),
                    const SizedBox(height: 12),
                    _content(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _selectors() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<AuraLeaderboard>(
                key: const ValueKey('ranking-selector'),
                initialValue: leaderboard,
                decoration: InputDecoration(labelText: _t('ranking')),
                items: [
                  for (final value in AuraLeaderboard.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(_leaderboardName(value)),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    leaderboard = value;
                    timeScope = value == AuraLeaderboard.weeklyAura
                        ? LeaderboardTimeScope.weekly
                        : LeaderboardTimeScope.allTime;
                  });
                  unawaited(_load());
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<LeaderboardPlayerScope>(
                key: const ValueKey('player-scope-selector'),
                segments: [
                  ButtonSegment(
                    value: LeaderboardPlayerScope.global,
                    icon: const Icon(Icons.public),
                    label: Text(_t('global')),
                  ),
                  ButtonSegment(
                    value: LeaderboardPlayerScope.friends,
                    icon: const Icon(Icons.people_outline),
                    label: Text(_t('friends')),
                  ),
                ],
                selected: {playerScope},
                onSelectionChanged: (selection) {
                  setState(() => playerScope = selection.single);
                  unawaited(_load());
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<LeaderboardTimeScope>(
                key: const ValueKey('time-scope-selector'),
                initialValue: timeScope,
                decoration: InputDecoration(labelText: _t('period')),
                items: [
                  DropdownMenuItem(
                    value: LeaderboardTimeScope.daily,
                    child: Text(_t('daily')),
                  ),
                  DropdownMenuItem(
                    value: LeaderboardTimeScope.weekly,
                    child: Text(_t('weekly')),
                  ),
                  DropdownMenuItem(
                    value: LeaderboardTimeScope.allTime,
                    child: Text(_t('all_time')),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => timeScope = value);
                  unawaited(_load());
                },
              ),
            ],
          ),
        ),
      );

  Widget _content() {
    final coordinator = widget.coordinator;
    if (coordinator.loading) {
      return const Card(
        key: ValueKey('rankings-loading'),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final page = coordinator.leaderboardPage;
    final coordinatorAvailability = coordinator.availability;
    final availability =
        coordinatorAvailability == PlayGamesAvailability.available
            ? page?.availability ?? coordinatorAvailability
            : coordinatorAvailability;
    if (availability == PlayGamesAvailability.consentRequired ||
        coordinator.friendsConsentState == FriendsConsentState.required) {
      return _StateCard(
        key: const ValueKey('rankings-consent-required'),
        icon: Icons.group_add_outlined,
        title: _t('consent_title'),
        body: _t('consent_body'),
        action: FilledButton(
          onPressed: () async {
            if (await coordinator.requestFriendsConsent()) {
              await _load(forceReload: true);
            }
          },
          child: Text(_t('authorize')),
        ),
      );
    }
    if (coordinator.friendsConsentState == FriendsConsentState.denied &&
        playerScope == LeaderboardPlayerScope.friends) {
      return _StateCard(
        key: const ValueKey('rankings-consent-denied'),
        icon: Icons.person_off_outlined,
        title: _t('denied_title'),
        body: _t('denied_body'),
        action: OutlinedButton(
          onPressed: () async {
            if (await coordinator.requestFriendsConsent()) {
              await _load(forceReload: true);
            }
          },
          child: Text(_t('try_authorize')),
        ),
      );
    }
    if (availability != PlayGamesAvailability.available) {
      return _StateCard(
        key: ValueKey('rankings-${availability.name}'),
        icon: _availabilityIcon(availability),
        title: _availabilityText(availability),
        body: _availabilityBody(availability),
        action: availability == PlayGamesAvailability.unauthenticated
            ? FilledButton(
                onPressed: coordinator.signIn,
                child: Text(_t('connect')),
              )
            : OutlinedButton(
                onPressed: () => _load(forceReload: true),
                child: Text(_t('retry')),
              ),
      );
    }
    if (page == null || page.entries.isEmpty) {
      return _StateCard(
        key: const ValueKey('rankings-empty'),
        icon: Icons.leaderboard_outlined,
        title: _t('empty_title'),
        body: _t('empty_body'),
        action: OutlinedButton(
          onPressed: () => _load(forceReload: true),
          child: Text(_t('retry')),
        ),
      );
    }
    return Card(
      key: const ValueKey('rankings-list'),
      child: Column(
        children: [
          for (var index = 0; index < page.entries.length; index++) ...[
            _RankingTile(
              entry: page.entries[index],
              locale: widget.strings.locale,
              noScore: _t('no_score'),
              onCompare: playerScope == LeaderboardPlayerScope.friends &&
                      !page.entries[index].isCurrentPlayer &&
                      page.entries[index].playerId.isNotEmpty
                  ? () => coordinator.showCompareProfile(page.entries[index])
                  : null,
            ),
            if (index != page.entries.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  String _leaderboardName(AuraLeaderboard value) => switch (value) {
        AuraLeaderboard.weeklyAura => _t('farmer_week'),
        AuraLeaderboard.maxAuraPerSecond => _t('max_production'),
        AuraLeaderboard.maxAuraPerMovement => _t('max_movement'),
      };

  String _availabilityText(PlayGamesAvailability value) => switch (value) {
        PlayGamesAvailability.available => _t('connected'),
        PlayGamesAvailability.unsupportedPlatform => _t('unsupported'),
        PlayGamesAvailability.notConfigured => _t('not_configured'),
        PlayGamesAvailability.unauthenticated => _t('not_authenticated'),
        PlayGamesAvailability.permissionDenied => _t('denied_title'),
        PlayGamesAvailability.consentRequired => _t('consent_title'),
        PlayGamesAvailability.offline => _t('offline'),
        PlayGamesAvailability.temporarilyUnavailable => _t('unavailable'),
      };

  String _availabilityBody(PlayGamesAvailability value) => switch (value) {
        PlayGamesAvailability.unsupportedPlatform => _t('unsupported_body'),
        PlayGamesAvailability.notConfigured => _t('not_configured_body'),
        PlayGamesAvailability.unauthenticated => _t('not_authenticated_body'),
        PlayGamesAvailability.offline => _t('offline_body'),
        _ => _t('error_body'),
      };

  IconData _availabilityIcon(PlayGamesAvailability value) => switch (value) {
        PlayGamesAvailability.offline => Icons.cloud_off_outlined,
        PlayGamesAvailability.notConfigured => Icons.construction_outlined,
        PlayGamesAvailability.unauthenticated => Icons.login_outlined,
        PlayGamesAvailability.unsupportedPlatform => Icons.block_outlined,
        _ => Icons.sync_problem_outlined,
      };

  String _t(String key) {
    final pt = widget.strings.locale == 'pt-BR';
    return (pt ? _pt : _en)[key] ?? _en[key] ?? key;
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.coordinator,
    required this.status,
    required this.connectLabel,
  });

  final PlayGamesCoordinator coordinator;
  final String status;
  final String connectLabel;

  @override
  Widget build(BuildContext context) => Card(
        key: const ValueKey('play-games-auth-card'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _Avatar(
                url: coordinator.currentPlayer?.avatarUrl,
                bytes: coordinator.currentPlayer?.avatarBytes,
                radius: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coordinator.currentPlayer?.displayName ??
                          'Google Play Games',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(status),
                  ],
                ),
              ),
              if (!coordinator.authenticated)
                TextButton(
                  onPressed: coordinator.loading ? null : coordinator.signIn,
                  child: Text(connectLabel),
                ),
            ],
          ),
        ),
      );
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({
    required this.entry,
    required this.locale,
    required this.noScore,
    required this.onCompare,
  });

  final LeaderboardEntry entry;
  final String locale;
  final String noScore;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: entry.isCurrentPlayer
            ? Theme.of(context).colorScheme.primary.withValues(alpha: .08)
            : Colors.transparent,
        child: ListTile(
          key: ValueKey('ranking-player-${entry.playerId}'),
          leading: SizedBox(
            width: 64,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    entry.rank == null ? '—' : '${entry.rank}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 6),
                _Avatar(
                  url: entry.avatarUrl,
                  bytes: entry.avatarBytes,
                  radius: 16,
                ),
              ],
            ),
          ),
          title: Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            entry.hasScore && entry.auraValue != null
                ? AuraFormat.integer(entry.auraValue!, locale: locale)
                : noScore,
          ),
          trailing: onCompare == null
              ? null
              : IconButton(
                  tooltip: 'Google Play Games',
                  onPressed: onCompare,
                  icon: const Icon(Icons.compare_arrows),
                ),
        ),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.bytes,
    required this.radius,
  });

  final String? url;
  final Uint8List? bytes;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url ?? '');
    final usable =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    final memory = bytes != null && bytes!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      foregroundImage: memory
          ? MemoryImage(bytes!)
          : usable
              ? NetworkImage(url!)
              : null,
      child: memory || usable ? null : const Icon(Icons.person_outline),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon,
                  size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              action,
            ],
          ),
        ),
      );
}

const _pt = <String, String>{
  'title': 'Rankings de Aura',
  'native': 'Abrir ranking no Google Play Games',
  'ranking': 'Ranking',
  'period': 'Período',
  'global': 'Global',
  'friends': 'Amigos',
  'daily': 'Diário',
  'weekly': 'Semanal',
  'all_time': 'Histórico',
  'farmer_week': 'Farmador da Semana',
  'max_production': 'Maior Produção de Aura',
  'max_movement': 'Maior Movimento de Aura',
  'connected': 'Conectado ao Play Games',
  'connect': 'Conectar',
  'retry': 'Tentar novamente',
  'authorize': 'Autorizar amigos',
  'try_authorize': 'Tentar autorizar novamente',
  'consent_title': 'Autorize o acesso aos amigos',
  'consent_body':
      'O Google mostrará a tela oficial de consentimento. O jogo continua funcionando se você preferir não autorizar.',
  'denied_title': 'Acesso aos amigos negado',
  'denied_body':
      'Você pode usar os rankings globais ou tentar autorizar novamente quando quiser.',
  'unsupported': 'Play Games indisponível nesta plataforma',
  'unsupported_body':
      'Os rankings sociais estão disponíveis primeiro no Android.',
  'not_configured': 'IDs do Play Games não configurados',
  'not_configured_body':
      'A integração está pronta, mas os IDs dos três rankings ainda precisam ser fornecidos.',
  'not_authenticated': 'Não conectado ao Play Games',
  'not_authenticated_body':
      'Conecte seu perfil Gamer para enviar pontuações e comparar com amigos.',
  'offline': 'Sem conexão',
  'offline_body':
      'Sua pontuação ficará na fila e será enviada quando a conexão voltar.',
  'unavailable': 'Play Games temporariamente indisponível',
  'error_body':
      'Não foi possível carregar o ranking agora. Seu progresso local está seguro.',
  'empty_title': 'Nenhuma pontuação registrada',
  'empty_body': 'Jogue um pouco e volte para aparecer neste ranking.',
  'no_score': 'Ainda não registrou pontuação neste ranking.',
};

const _en = <String, String>{
  'title': 'Aura Leaderboards',
  'native': 'Open leaderboard in Google Play Games',
  'ranking': 'Leaderboard',
  'period': 'Period',
  'global': 'Global',
  'friends': 'Friends',
  'daily': 'Daily',
  'weekly': 'Weekly',
  'all_time': 'All time',
  'farmer_week': 'Farmer of the Week',
  'max_production': 'Highest Aura Production',
  'max_movement': 'Highest Aura Movement',
  'connected': 'Connected to Play Games',
  'connect': 'Connect',
  'retry': 'Try again',
  'authorize': 'Allow friends access',
  'try_authorize': 'Try authorization again',
  'consent_title': 'Allow access to friends',
  'consent_body':
      'Google will show its official consent screen. The game keeps working if you choose not to allow access.',
  'denied_title': 'Friends access denied',
  'denied_body':
      'You can use global leaderboards or try authorization again whenever you want.',
  'unsupported': 'Play Games is unavailable on this platform',
  'unsupported_body': 'Social leaderboards are available on Android first.',
  'not_configured': 'Play Games IDs are not configured',
  'not_configured_body':
      'The integration is ready, but IDs for the three leaderboards still need to be provided.',
  'not_authenticated': 'Not connected to Play Games',
  'not_authenticated_body':
      'Connect your Gamer profile to submit scores and compare with friends.',
  'offline': 'Offline',
  'offline_body':
      'Your score will remain queued and will sync when the connection returns.',
  'unavailable': 'Play Games is temporarily unavailable',
  'error_body':
      'The leaderboard could not be loaded now. Your local progress is safe.',
  'empty_title': 'No score recorded yet',
  'empty_body': 'Play for a while and come back to appear on this leaderboard.',
  'no_score': 'No score recorded on this leaderboard yet.',
};
