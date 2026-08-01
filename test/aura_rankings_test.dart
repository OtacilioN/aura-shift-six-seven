import 'dart:convert';

import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:aura_shift_six_seven/main.dart';
import 'package:aura_shift_six_seven/play_games/play_games_coordinator.dart';
import 'package:aura_shift_six_seven/play_games/play_games_models.dart';
import 'package:aura_shift_six_seven/ui/aura_rankings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'play_games_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows a non-blocking unauthenticated state', (tester) async {
    SharedPreferences.setMockInitialValues({
      'save-v1': jsonEncode({
        'total': '0',
        'available': '0',
        'journey': '0',
        'remainder': '0',
        'multiplier': '100',
      }),
    });
    final controller = await GameController.loadForTesting();
    final service = FakePlayGamesService()
      ..authenticated = false
      ..initialization = PlayGamesAvailability.unauthenticated;
    final coordinator = PlayGamesCoordinator(
      controller: controller,
      service: service,
      store: MemoryPlayGamesStore(),
    );
    await coordinator.initialize();
    final strings = await Strings.load('pt-BR');

    await tester.pumpWidget(MaterialApp(
      theme: auraTheme(false, 'pt-BR'),
      home: AuraRankingsScreen(
        coordinator: coordinator,
        strings: strings,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('play-games-auth-card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('rankings-unauthenticated')),
      findsOneWidget,
    );
    expect(find.text('Conectar'), findsWidgets);

    coordinator.dispose();
    controller.dispose();
  });

  testWidgets('renders friends without scores and compare actions',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'save-v1': jsonEncode({
        'total': '0',
        'available': '0',
        'journey': '0',
        'remainder': '0',
        'multiplier': '100',
      }),
    });
    final controller = await GameController.loadForTesting();
    final service = SocialFakePlayGamesService();
    final coordinator = PlayGamesCoordinator(
      controller: controller,
      service: service,
      store: MemoryPlayGamesStore(),
    );
    await coordinator.initialize();
    final strings = await Strings.load('en-US');

    await tester.pumpWidget(MaterialApp(
      theme: auraTheme(false, 'en-US'),
      home: AuraRankingsScreen(
        coordinator: coordinator,
        strings: strings,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('rankings-list')), findsOneWidget);
    expect(
      find.text('No score recorded on this leaderboard yet.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.compare_arrows), findsWidgets);

    coordinator.dispose();
    controller.dispose();
  });
}

class SocialFakePlayGamesService extends FakePlayGamesService {
  @override
  Future<LeaderboardPage> loadLeaderboard({
    required AuraLeaderboard leaderboard,
    required LeaderboardTimeScope timeScope,
    required LeaderboardPlayerScope playerScope,
    bool forceReload = false,
  }) async =>
      LeaderboardPage(entries: [
        LeaderboardEntry(
          playerId: 'friend-score',
          displayName: 'Aura Pro',
          rank: 1,
          encodedScore: 67000,
          auraValue: BigInt.from(67000),
        ),
      ]);

  @override
  Future<FriendsPage> loadFriends({bool forceReload = false}) async =>
      const FriendsPage(friends: [
        PlayGamesFriend(playerId: 'friend-score', displayName: 'Aura Pro'),
        PlayGamesFriend(playerId: 'friend-empty', displayName: 'New Friend'),
      ]);
}
