import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:health_care_alarm/timer.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '健康时钟'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const String _prefSittingMinutesName = 'sitting_minutes';
const String _prefStandingMinutesName = 'standing_minutes';
const String _prefEnableBellName = 'enable_bell';

class _MyHomePageState extends State<MyHomePage> {
  AudioPlayer? _player;
  bool _isStart = false;
  bool _isSitting = true;
  int _sittingMinutes = 30;
  int _standMinutes = 15;
  SharedPreferences? _prefs;
  bool _enableBell = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _prefs = prefs;
        _sittingMinutes =
            prefs.getInt(_prefSittingMinutesName) ?? _sittingMinutes;
        _standMinutes = prefs.getInt(_prefStandingMinutesName) ?? _standMinutes;
        _enableBell = prefs.getBool(_prefEnableBellName) ?? true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(
              height: 20,
            ),
            TimerWidget(
              //当站姿和坐姿时间相同时会导致无法更新，所以添加key
              key: Key(_isSitting ? 'heal_care_sitting' : 'heal_care_standing'),
              seconds: _isStart
                  ? (_isSitting ? _sittingMinutes * 60 : _standMinutes * 60)
                  : 0,
              callback: _taskDone,
            ),
            const SizedBox(
              height: 20,
            ),
            OutlinedButton(
                onPressed: () {
                  if (_isStart && _isSitting) {
                    _stopAll();
                  } else {
                    _sittingTask();
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      _isSitting && _isStart ? Icons.pause : Icons.play_arrow,
                      color: _isSitting && _isStart ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    const Text('坐姿计时'),
                  ],
                )),
            const SizedBox(
              height: 10,
            ),
            OutlinedButton(
                onPressed: () {
                  if (_isStart && !_isSitting) {
                    _stopAll();
                  } else {
                    _standTask();
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      _isStart && !_isSitting ? Icons.pause : Icons.play_arrow,
                      color: _isStart && !_isSitting ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    const Text('站姿计时'),
                  ],
                )),
            const SizedBox(
              height: 10,
            ),
            const SizedBox(
              height: 10,
            ),
            _NumberInputWidget(
              title: '坐姿时间',
              units: '分钟',
              defaultValue: _sittingMinutes,
              listener: (value) {
                if (value > 0) {
                  _sittingMinutes = value;
                  _prefs?.setInt(_prefSittingMinutesName, value);
                }
              },
            ),
            _NumberInputWidget(
              title: '站姿时间',
              units: '分钟',
              defaultValue: _standMinutes,
              listener: (value) {
                if (value > 0) {
                  _standMinutes = value;
                  _prefs?.setInt(_prefStandingMinutesName, value);
                }
              },
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '启用铃声',
                ),
                const SizedBox(
                  width: 10,
                ),
                Checkbox(
                    value: _enableBell,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _enableBell = value;
                          _prefs?.setBool(_prefEnableBellName, value);
                        });
                      }
                    }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sittingTask() {
    setState(() {
      _isSitting = true;
      _isStart = true;
    });
  }

  void _standTask() {
    setState(() {
      _isSitting = false;
      _isStart = true;
    });
  }

  void _stopAll() {
    setState(() {
      _isStart = false;
      _stopAlarmMusic();
    });
  }

  void _continueNextTask() {
    _stopAlarmMusic();
    if (_isSitting) {
      _standTask();
    } else {
      _sittingTask();
    }
  }

  //参考资料：https://blog.csdn.net/yikezhuixun/article/details/130660544
  void _playAlarmMusic() async {
    if (_enableBell && _player == null) {
      AudioPlayer player = AudioPlayer();
      _player = player;
      await player.setSource(AssetSource('alarm_music.mp3'));
      player.setReleaseMode(ReleaseMode.loop);
      await player.resume();
      Future.delayed(const Duration(minutes: 2), () {
        _stopAlarmMusic();
      });
    }
  }

  void _stopAlarmMusic() {
    if (_player != null) {
      _player?.stop();
      _player?.dispose();
      _player = null;
    }
  }

  void _taskDone() {
    _playAlarmMusic();
    _notify();
  }

  ///参考资料：https://juejin.cn/post/7074482758747160590
  void _notify() async {
    // Add in main method.
    await localNotifier.setup(
      appName: '健康时钟',
      // The parameter shortcutPolicy only works on Windows
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );

    LocalNotification notification = LocalNotification(
        title: _isSitting ? "【坐】姿时间结束" : "【站】姿时间结束",
        // body: _isSitting ? "坐姿时间结束" : "站立结束",
        actions: [
          LocalNotificationAction(text: _isSitting ? '切换站姿' : '切换坐姿'),
          LocalNotificationAction(text: '停止计时'),
        ]);
    notification.onShow = () {
      print('onShow ${notification.identifier}');
    };
    notification.onClose = (closeReason) {
      // Only supported on windows, other platforms closeReason is always unknown.
      switch (closeReason) {
        case LocalNotificationCloseReason.userCanceled:
          _stopAll();
          break;
        case LocalNotificationCloseReason.timedOut:
          // do something
          if (_isStart) {
            _notify();
          }
          break;
        default:
      }
      print('onClose - $closeReason');
    };
    notification.onClick = () {
      print('onClick ${notification.identifier}');
      _continueNextTask();
    };
    notification.onClickAction = (actionIndex) {
      print('onClickAction ${notification.identifier} - $actionIndex');
      if (actionIndex == 0) {
        _continueNextTask();
      } else {
        _stopAll();
      }
    };

    notification.show();
  }

  @override
  void dispose() {
    _stopAlarmMusic();
    super.dispose();
  }
}

class _NumberInputWidget extends StatefulWidget {
  const _NumberInputWidget(
      {required this.title,
      required this.defaultValue,
      required this.listener,
      required this.units});

  final String title;
  final int defaultValue;
  final ValueChanged<int> listener;
  final String? units;

  @override
  State<StatefulWidget> createState() => _NumberInputWidgetState();
}

class _NumberInputWidgetState extends State<_NumberInputWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.defaultValue.toString());
  }

  @override
  void didUpdateWidget(covariant _NumberInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultValue != widget.defaultValue) {
      _controller.text = widget.defaultValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('${widget.title} : '),
        SizedBox(
          width: 30,
          child: TextField(
            textAlign: TextAlign.end,
            controller: _controller,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              isDense: true,
            ),
            onChanged: (value) {
              widget.listener.call(int.parse(value));
            },
          ),
        ),
        if (widget.units != null) Text(widget.units.toString()),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
