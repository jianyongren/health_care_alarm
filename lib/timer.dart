import 'dart:async';

import 'package:flutter/material.dart';

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key, required this.seconds, required this.callback});

  final int seconds;
  final VoidCallback callback;

  @override
  State<StatefulWidget> createState() => TimerWidgetState();
}

class TimerWidgetState extends State<TimerWidget> {
  late int _process;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    print('TimerWidgetState initState');
    _init();
  }

  void _init() {
    _process = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _process--;
      });
      if (_process == 0) {
        widget.callback.call();
        _timer.cancel();
      }
    });
    if (widget.seconds == 0) {
      _timer.cancel();
    }
  }

  @override
  void didUpdateWidget(covariant TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('TimerWidgetState didUpdateWidget');
    if (oldWidget.seconds != widget.seconds) {
      _timer.cancel();
      _init();
    }
  }

  @override
  Widget build(BuildContext context) {
    Duration duration = Duration(seconds: _process);
    int minutes = duration.inMinutes;
    int seconds = _process - minutes * 60;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: 120,
          child: CircularProgressIndicator(
            value: widget.seconds > 0 ? _process / widget.seconds : 0,
            backgroundColor: Colors.grey,
            strokeWidth: 8,
          ),
        ),
        Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        )
      ],
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
