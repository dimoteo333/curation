import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CuratorTab { home, ask, timeline, settings }

class CuratorAppShellState {
  const CuratorAppShellState({
    required this.currentTab,
    required this.askRequestId,
    this.askPrefill,
  });

  final CuratorTab currentTab;
  final int askRequestId;
  final String? askPrefill;

  CuratorAppShellState copyWith({
    CuratorTab? currentTab,
    int? askRequestId,
    String? askPrefill,
    bool clearAskPrefill = false,
  }) {
    return CuratorAppShellState(
      currentTab: currentTab ?? this.currentTab,
      askRequestId: askRequestId ?? this.askRequestId,
      askPrefill: clearAskPrefill ? null : askPrefill ?? this.askPrefill,
    );
  }
}

class CuratorAppShellController extends Notifier<CuratorAppShellState> {
  @override
  CuratorAppShellState build() {
    return const CuratorAppShellState(
      currentTab: CuratorTab.home,
      askRequestId: 0,
    );
  }

  void selectTab(CuratorTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  void composeQuestion({String? prefill, bool resetInput = false}) {
    state = state.copyWith(
      currentTab: CuratorTab.home,
      askRequestId: state.askRequestId + 1,
      askPrefill: resetInput ? '' : prefill,
      clearAskPrefill: !resetInput && prefill == null,
    );
  }
}

final curatorAppShellProvider =
    NotifierProvider<CuratorAppShellController, CuratorAppShellState>(
      CuratorAppShellController.new,
    );
