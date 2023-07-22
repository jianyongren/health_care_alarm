import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:health_care_alarm/timer.dart';
import 'package:local_notifier/local_notifier.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  AudioPlayer? _player;
  bool _isStart = false;
  bool _isSitting = true;
  final int _sittingMinutes = 2;
  final _standMinutes = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(
              height: 20,
            ),
            TimerWidget(
              seconds: _isStart
                  ? (_isSitting ? _sittingMinutes * 60 : _standMinutes * 60)
                  : 0,
              callback: _taskDone,
            ),
            const SizedBox(
              height: 20,
            ),
            OutlinedButton(
                onPressed: _sittingTask,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.circle,
                      color: _isSitting && _isStart ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text('坐姿开始'),
                  ],
                )),
            const SizedBox(
              height: 10,
            ),
            OutlinedButton(
                onPressed: _standTask,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.circle,
                      color: _isStart && !_isSitting ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text('站姿开始'),
                  ],
                )),
            const SizedBox(
              height: 10,
            ),
            TextButton(onPressed: _stopAll, child: const Text('结束')),
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
    if (_player == null) {
      AudioPlayer player = AudioPlayer();
      _player = player;
      await player.setSource(AssetSource('alarm_music.mp3'));
      player.setReleaseMode(ReleaseMode.loop);
      await player.resume();
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
          LocalNotificationAction(text: '继续'),
          LocalNotificationAction(text: '停止'),
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
