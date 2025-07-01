import 'package:flutter_riverpod/flutter_riverpod.dart';

class BehaviorSettings {
  final bool refreshNews;
  final bool openInWebView;

  BehaviorSettings({
    required this.refreshNews,
    required this.openInWebView,
  });

  BehaviorSettings copyWith({
    bool? refreshNews,
    bool? openInWebView,
  }) {
    return BehaviorSettings(
      refreshNews: refreshNews ?? this.refreshNews,
      openInWebView: openInWebView ?? this.openInWebView,
    );
  }
}

class BehaviorSettingsNotifier extends StateNotifier<BehaviorSettings> {
  BehaviorSettingsNotifier()
      : super(BehaviorSettings(
    refreshNews: true,
    openInWebView: false,
  ));

  void setRefreshNews(bool value) {
    state = state.copyWith(refreshNews: value);
  }

  void setOpenInWebView(bool value) {
    state = state.copyWith(openInWebView: value);
  }
}

final behaviorSettingsProvider =
StateNotifierProvider<BehaviorSettingsNotifier, BehaviorSettings>(
      (ref) => BehaviorSettingsNotifier(),
);
