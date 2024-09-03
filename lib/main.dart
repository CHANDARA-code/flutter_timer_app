import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class TimerState {
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration remainingTime;
  final bool isRunning;

  TimerState({
    this.startTime,
    this.endTime,
    this.remainingTime = Duration.zero,
    this.isRunning = false,
  });

  TimerState copyWith({
    DateTime? startTime,
    DateTime? endTime,
    Duration? remainingTime,
    bool? isRunning,
  }) {
    return TimerState(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      remainingTime: remainingTime ?? this.remainingTime,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier() : super(TimerState()) {
    _loadTimerState();
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final startTimeString = prefs.getString('start_time');
    final endTimeString = prefs.getString('end_time');

    if (startTimeString != null && endTimeString != null) {
      final startTime = DateTime.parse(startTimeString);
      final endTime = DateTime.parse(endTimeString);
      final remainingTime = endTime.difference(DateTime.now());

      if (remainingTime.isNegative) {
        state = TimerState();
      } else {
        state = TimerState(
          startTime: startTime,
          endTime: endTime,
          remainingTime: remainingTime,
          isRunning: true,
        );
        _tick();
      }
    }
  }

  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.startTime != null && state.endTime != null) {
      await prefs.setString('start_time', state.startTime!.toIso8601String());
      await prefs.setString('end_time', state.endTime!.toIso8601String());
    }
  }

  Future<void> _clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('start_time');
    await prefs.remove('end_time');
  }

  void startTimer(Duration duration) {
    final startTime = DateTime.now();
    final endTime = startTime.add(duration);

    state = TimerState(
      startTime: startTime,
      endTime: endTime,
      remainingTime: duration,
      isRunning: true,
    );

    _saveTimerState();
    _tick();
  }

  void _tick() {
    Future.delayed(Duration(seconds: 1), () {
      if (!state.isRunning) return;

      final now = DateTime.now();
      final remainingTime = state.endTime!.difference(now);

      if (remainingTime.isNegative) {
        state = TimerState(
          startTime: state.startTime,
          endTime: state.endTime,
          remainingTime: Duration.zero,
          isRunning: false,
        );
        _clearTimerState();
      } else {
        state = TimerState(
          startTime: state.startTime,
          endTime: state.endTime,
          remainingTime: remainingTime,
          isRunning: true,
        );
        _tick();
      }
    });
  }

  void stopTimer() {
    state = state.copyWith(isRunning: false);
    _saveTimerState();
  }

  void resetTimer() {
    state = TimerState();
    _clearTimerState();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier();
});

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TimerScreen(),
    );
  }
}

class TimerScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Timer App'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Remaining Time: ${timerState.remainingTime.inSeconds} seconds',
            style: TextStyle(fontSize: 32),
          ),
          SizedBox(height: 20),
          if (!timerState.isRunning)
            ElevatedButton(
              onPressed: () => timerNotifier.startTimer(Duration(seconds: 30)),
              child: Text('Start Timer'),
            ),
          if (timerState.isRunning)
            ElevatedButton(
              onPressed: () => timerNotifier.stopTimer(),
              child: Text('Stop Timer'),
            ),
          ElevatedButton(
            onPressed: () => timerNotifier.resetTimer(),
            child: Text('Reset Timer'),
          ),
        ],
      ),
    );
  }
}
