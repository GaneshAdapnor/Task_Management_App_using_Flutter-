import 'dart:async';

/// Delays executing [action] until [delay] has elapsed since the last call.
/// Useful for search-as-you-type without hammering the filter on every keystroke.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}
