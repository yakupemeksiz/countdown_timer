// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

final controller = CountdownController(
  autoPlay: false,
  isReversed: true,
  duration: const Duration(seconds: 5),
  onStarted: () {
    print('onStarted');
  },
  onPaused: () {
    print('onPaused');
  },
  onResumed: () {
    print('onResumed');
  },
  onCompleted: () {
    print('onCompleted');
  },
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OrientationBuilder(builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return CountdownTimer(
            controller: controller,
          );
        } else {
          return CountdownTimer(
            controller: controller,
          );
        }
      }),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.red),
      ),
    );
  }
}

class CountdownController extends ChangeNotifier {
  Duration duration;
  final bool isReversed;
  final bool autoPlay;
  final VoidCallback? onStarted;
  final VoidCallback? onPaused;
  final VoidCallback? onResumed;
  final VoidCallback? onCompleted;

  late AnimationController controller;
  CountdownController({
    required this.duration,
    this.autoPlay = false,
    this.onStarted,
    this.onPaused,
    this.onResumed,
    this.onCompleted,
    this.isReversed = false,
  });

  void stop() {
    if (controller.isAnimating) {
      controller.stop();
      onPaused?.call();
    }
  }

  void endTimer() {
    controller.fling(velocity: isReversed ? -1.0 : 1.0);
  }

  void addDuration(Duration duration) {
    final elapsedDuration = Duration(
      milliseconds: this.elapsedDuration.inMilliseconds,
    );
    final newDuration = rawDuration + duration;
    final isAnimating = !!controller.isAnimating;

    if (controller.duration == null) {
      this.duration += duration;
    } else {
      controller.duration = newDuration;
    }

    if (isReversed) {
      controller.value =
          1 - (elapsedDuration.inMilliseconds / newDuration.inMilliseconds);
    } else {
      controller.value =
          (elapsedDuration.inMilliseconds / newDuration.inMilliseconds);
    }

    if (isAnimating) {
      play();
    } else {
      controller.stop();
    }
  }

  void play() {
    if (isReversed) {
      controller.reverse();
    } else {
      controller.forward();
    }

    onResumed?.call();
  }

  Duration get rawDuration => controller.duration ?? Duration.zero;
  Duration get currentDuration => rawDuration * controller.value;
  Duration get elapsedDuration =>
      isReversed ? controller.duration! - currentDuration : currentDuration;
}

class CountdownTimer extends StatefulWidget {
  final CountdownController controller;

  const CountdownTimer({
    required this.controller,
    super.key,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with TickerProviderStateMixin {
  AnimationController get controller => widget.controller.controller;
  CountdownController get countdownController => widget.controller;

  String get timerString {
    Duration duration = controller.duration! * controller.value;
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    countdownController.controller = AnimationController(
      vsync: this,
      duration: widget.controller.duration,
    );

    if (countdownController.isReversed) {
      controller.value = 1;
    }

    controller.addStatusListener((status) {
      switch (status) {
        case AnimationStatus.forward:
        case AnimationStatus.reverse:
          countdownController.onStarted?.call();
          break;

        case AnimationStatus.dismissed:
          if (countdownController.isReversed) {
            countdownController.onCompleted?.call();
          }
          break;
        case AnimationStatus.completed:
          if (!countdownController.isReversed) {
            countdownController.onCompleted?.call();
          }
          break;
        default:
        // Do nothing
      }
    });

    if (countdownController.autoPlay) {
      countdownController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Scaffold(
      floatingActionButton: Row(
        children: [
          FloatingActionButton(
            onPressed: () {
              if (controller.isAnimating) {
                countdownController.stop();
              } else {
                countdownController.play();
              }
            },
          ),
          FloatingActionButton(
            onPressed: () {
              countdownController.addDuration(const Duration(seconds: 20));
            },
          ),
          FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: countdownController.endTimer,
          ),
        ],
      ),
      backgroundColor: Colors.green,
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Stack(
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: FractionalOffset.center,
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: CustomPaint(
                                  painter: CustomTimerPainter(
                                animation: controller,
                                backgroundColor: Colors.white,
                                color: themeData.indicatorColor,
                              )),
                            ),
                            Align(
                              alignment: FractionalOffset.center,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Text(
                                        timerString,
                                        style: const TextStyle(
                                            fontSize: 112.0,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class CustomTimerPainter extends CustomPainter {
  final Animation<double> animation;
  final Color backgroundColor, color;
  final bool isReversed;

  const CustomTimerPainter({
    required this.animation,
    required this.backgroundColor,
    required this.color,
    this.isReversed = true,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2.0, paint);
    paint.color = color;

    if (isReversed) {
      double progress = (animation.value) * 2 * math.pi;
      canvas.drawArc(Offset.zero & size, math.pi * 1.5, progress, false, paint);
    } else {
      double progress = (1 - animation.value) * 2 * math.pi;
      canvas.drawArc(
        Offset.zero & size,
        math.pi * 1.5,
        -progress,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomTimerPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value ||
        color != oldDelegate.color ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}


