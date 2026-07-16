import 'package:in_app_review/in_app_review.dart';

/// Best-effort bridge to the store-owned review sheet.
///
/// Store quotas decide whether the sheet is actually displayed. This class
/// intentionally has no fallback redirect, so a milestone never takes the
/// player out of the game.
class StoreReview {
  StoreReview({InAppReview? review}) : _review = review ?? InAppReview.instance;

  final InAppReview _review;

  Future<void> request() async {
    if (!await _review.isAvailable()) return;
    await _review.requestReview();
  }
}
