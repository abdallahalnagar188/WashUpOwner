import 'dart:async';

import 'package:flutter/widgets.dart';

/// Calls [tick] every [every] while it is started and the app is in the
/// foreground (GAP-099). In the background the phone relies on push, which
/// saves battery and server load.
class Poller with WidgetsBindingObserver {
  final Duration every;
  final void Function() tick;

  /// Also tick once when the app comes back, for screens that nothing else
  /// refreshes on resume.
  final bool tickOnResume;

  Poller(this.every, this.tick, {this.tickOnResume = false});

  Timer? _timer;
  bool _started = false;
  bool _observing = false;
  bool _foreground = true;

  /// A timer is running now.
  bool get isTicking => _timer != null;

  void start() {
    _started = true;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
      final state = WidgetsBinding.instance.lifecycleState;
      _foreground = state == null || _isForeground(state);
    }
    _schedule();
  }

  void stop() {
    _started = false;
    _schedule();
  }

  void dispose() {
    stop();
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
  }

  static bool _isForeground(AppLifecycleState state) =>
      state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = _isForeground(state);
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (foreground && _started && tickOnResume) tick();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (_started && _foreground) _timer = Timer.periodic(every, (_) => tick());
  }
}
