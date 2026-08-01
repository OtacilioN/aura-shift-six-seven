import 'package:flutter/material.dart';

import '../achievements/achievement_sync_service.dart';
import '../play_games/play_games_models.dart';

class AuraAchievementsScreen extends StatelessWidget {
  const AuraAchievementsScreen({
    super.key,
    required this.coordinator,
    required this.locale,
  });

  final AchievementSyncService coordinator;
  final String locale;

  bool get _pt => locale == 'pt-BR';
  String _text(String pt, String en) => _pt ? pt : en;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_text('Conquistas', 'Achievements')),
        ),
        body: AnimatedBuilder(
          animation: coordinator,
          builder: (context, _) => ListView(
            key: const ValueKey('achievements-screen'),
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _icon,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _statusTitle,
                              key: ValueKey(
                                'achievements-${coordinator.availability.name}',
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (coordinator.loading)
                            const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(_statusBody),
                      const SizedBox(height: 18),
                      LinearProgressIndicator(
                        value: coordinator.totalCount == 0
                            ? 0
                            : coordinator.eligibleCount /
                                coordinator.totalCount,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _text(
                          '${coordinator.eligibleCount} de '
                              '${coordinator.totalCount} elegíveis',
                          '${coordinator.eligibleCount} of '
                              '${coordinator.totalCount} eligible',
                        ),
                      ),
                      if (coordinator.hasPending) ...[
                        const SizedBox(height: 8),
                        Text(
                          _text(
                            '${coordinator.pendingCount} atualizações pendentes',
                            '${coordinator.pendingCount} pending updates',
                          ),
                          key: const ValueKey('achievements-pending'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('open-native-achievements'),
                onPressed: coordinator.loading ||
                        coordinator.availability ==
                            PlayGamesAvailability.unsupportedPlatform ||
                        !coordinator.idsConfigured
                    ? null
                    : () => coordinator.showNativeAchievements(),
                icon: const Icon(Icons.emoji_events_outlined),
                label: Text(
                  _text(
                    'Abrir no Google Play Games',
                    'Open in Google Play Games',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('sync-achievements'),
                onPressed: coordinator.loading
                    ? null
                    : () => coordinator.retryPendingUpdates(),
                icon: const Icon(Icons.sync),
                label: Text(_text('Sincronizar agora', 'Sync now')),
              ),
              if (coordinator.availability ==
                  PlayGamesAvailability.unauthenticated) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const ValueKey('connect-achievements'),
                  onPressed:
                      coordinator.loading ? null : () => coordinator.signIn(),
                  icon: const Icon(Icons.login),
                  label: Text(
                    _text('Conectar ao Play Games', 'Connect to Play Games'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                _text(
                  'O progresso é calculado a partir do seu save. Quando você '
                      'está offline ele permanece pendente e será enviado após '
                      'a reconexão.',
                  'Progress is calculated from your save. While offline it '
                      'stays pending and is uploaded after reconnection.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );

  IconData get _icon => switch (coordinator.availability) {
        PlayGamesAvailability.available => coordinator.hasPending
            ? Icons.cloud_upload_outlined
            : Icons.cloud_done_outlined,
        PlayGamesAvailability.offline => Icons.cloud_off_outlined,
        PlayGamesAvailability.unauthenticated => Icons.person_off_outlined,
        PlayGamesAvailability.notConfigured => Icons.construction_outlined,
        PlayGamesAvailability.unsupportedPlatform => Icons.block_outlined,
        _ => Icons.error_outline,
      };

  String get _statusTitle {
    if (coordinator.loading) {
      return _text('Carregando', 'Loading');
    }
    if (coordinator.hasPending &&
        coordinator.availability == PlayGamesAvailability.available) {
      return _text('Sincronização pendente', 'Sync pending');
    }
    return switch (coordinator.availability) {
      PlayGamesAvailability.available =>
        _text('Sincronização concluída', 'Sync complete'),
      PlayGamesAvailability.unauthenticated =>
        _text('Não autenticado', 'Not authenticated'),
      PlayGamesAvailability.offline => _text('Sem conexão', 'Offline'),
      PlayGamesAvailability.notConfigured =>
        _text('IDs não configurados', 'IDs not configured'),
      PlayGamesAvailability.unsupportedPlatform =>
        _text('Plataforma não suportada', 'Unsupported platform'),
      PlayGamesAvailability.permissionDenied =>
        _text('Play Games indisponível', 'Play Games unavailable'),
      _ => _text('Erro recuperável', 'Recoverable error'),
    };
  }

  String get _statusBody => switch (coordinator.availability) {
        PlayGamesAvailability.available => coordinator.hasPending
            ? _text(
                'Seu progresso está seguro e aguardando envio.',
                'Your progress is safe and waiting to be uploaded.',
              )
            : _text(
                'Seu progresso local foi reconciliado com o Play Games.',
                'Your local progress was reconciled with Play Games.',
              ),
        PlayGamesAvailability.unauthenticated => _text(
            'Você pode continuar jogando e conectar sua conta quando quiser.',
            'You can keep playing and connect your account whenever you want.',
          ),
        PlayGamesAvailability.offline => _text(
            'Continue jogando. As conquistas serão sincronizadas depois.',
            'Keep playing. Achievements will sync later.',
          ),
        PlayGamesAvailability.notConfigured => _text(
            'A integração local está pronta mas os IDs do Console ainda não '
                'estão incluídos neste build.',
            'The local integration is ready but Console IDs are not included '
                'in this build yet.',
          ),
        PlayGamesAvailability.unsupportedPlatform => _text(
            'As conquistas do Google Play Games estão disponíveis no Android.',
            'Google Play Games achievements are available on Android.',
          ),
        _ => _text(
            'Não foi possível sincronizar agora. Seu progresso local está seguro.',
            'Sync is unavailable right now. Your local progress is safe.',
          ),
      };
}
