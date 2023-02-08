import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:simple_audio_button/src/layout/icons/spining_icon.dart';
import 'package:simple_audio_button/src/layout/stateful.dart';
import 'package:ui_common_behaviors/ui_common_behaviors.dart';

import '../simple_audio_button.dart';
import 'audio_loader.dart'
    if (dart.library.io) 'mobile/audio_loader_for_mobile.dart'
    if (dart.library.js) 'web/audio_loader_for_web.dart';



enum EBtState {
  loading,
  playing,
  stopped,
  paused,
}


T Function(C) observerGuard<T, C>(T expression(), Object message) {
  return (C _) {
    try {
      return expression();
    } catch (e, s) {
      print("[ERROR] $message\n$e\n$s");
      rethrow;
    }
  };
}


class SimpleAudioProgress extends StatelessWidget {
  final double width;
  final double height;
  final SingleProgressAware awareness;
  final Color bgColor;
  final Color progressColor;

  const SimpleAudioProgress(
    this.awareness, {
    required this.width,
    required this.height,
    required this.bgColor,
    required this.progressColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Observer(
        builder: observerGuard(() {
      //OB:
      final progress = awareness.progress;
      print('progress: $progress - ${width * progress}');
      return Container(
          height: height,
          width: width,
          // set constraint with
          color: bgColor,
          alignment: AlignmentDirectional.center,
          child: Container(
              height: height,
              width: width * progress,
              color: progressColor));
    }, "SimpleAudioProgress.build"));
  }
}

// ignore: must_be_immutable
class SimpleAudioButton extends StatefulWidget
    implements SingleGroupAwareWidgetSketch<AudioModel> {
  final AudioModel model;
  final double height;
  final double width;
  final void Function(AudioModel model)? onPress;
  final AudioLoader audioLoader;

  final IconData spinIcon;
  late IconData? playIcon;
  late IconData? pauseIcon;
  late IconData? stopIcon;

  final Color activeIconColor;
  final Color inactiveIconColor;

  final TextStyle literalStyle;
  final TextStyle boldStyle;
  final TextStyle accentStyle;

  final Color progressBgColor;
  final Color inProgressColor;

  @override
  final SingleGroupAware<AudioModel> Function() awareness;

  SimpleAudioButton(
    this.model, {
    required this.width,
    this.height = 32,
    this.onPress,
    required this.awareness,
    required this.spinIcon,
    this.playIcon,
    this.stopIcon,
    this.pauseIcon,
    required this.boldStyle,
    required this.literalStyle,
    required this.accentStyle,
    required this.activeIconColor,
    required this.inactiveIconColor,
    required this.progressBgColor,
    required this.inProgressColor,
    Key? key,
  })  : audioLoader = AudioLoader(model),
        super(key: key);

  @override
  State<StatefulWidget> createState() => SimpleAudioButtonState();

  @override
  void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SimpleAudioButtonState extends State<SimpleAudioButton>
    with StatefulMixin {
  AudioPlayerState? get buttonState => widget.audioLoader.player.state;
  SimpleAudioProgress? progress;
  Size? contextSize;
  late SingleProgressAware<double> progressAware;

  @override
  void initState() {
    super.initState();
    print('initState on audioButton');
    progressAware = SingleProgressAware(total: widget.model.length, current: 0);
    addAllListeners();
    widget.audioLoader.initAudio();
  }

  void addAllListeners() {
    widget.audioLoader.onLoaded(() {
      print('onLoad: ${widget.audioLoader.model.url}, $buttonState');
      setStateSafe(() {});
    });
    widget.audioLoader.onStopped(() {
      print('onStopped: ${widget.audioLoader.model.url}, state $buttonState');
      setStateSafe(() {});
    });
    widget.audioLoader.onCompleted(() {
      print(
          'onCompleted: ${widget.audioLoader.model.url}, state $buttonState');
      setStateSafe(() {});
    });

    if (IS_MOBILE) {
      widget.audioLoader.onUpdate((dynamic d) {
        progressAware.current = (d as Duration).inSeconds.toDouble();
      });
    } else {
      widget.audioLoader.onUpdate((dynamic d) {
        progressAware.current = (d as num) / 1000;
      });
    }
    widget.audioLoader.onPaused(() {
      print('onPause: ${widget.audioLoader.model.url}, state $buttonState');
      setStateSafe(() {});
    });
    widget.audioLoader.onPlay(() {
      print('onPlay: ${widget.audioLoader.model.url}, state $buttonState');
      setStateSafe(() {});
    });
  }



  void _stop() {
    print('stop, $buttonState');
    widget.audioLoader.stop();
  }

  void _play() {
    print('play, $buttonState');
    widget.audioLoader.play();
  }

  void _pause() {
    print('pause, $buttonState');
    widget.audioLoader.pause();
  }

  void onPress() {
    if (buttonState == null) {
      print('block play back, since it"s still loading');
      return;
    }
    print('onPress: ${buttonState}');
    if (widget.audioLoader.isPlaying) {
      _pause();
    } else {
      _play();
    }
    widget.onPress?.call(widget.model);
  }

  Widget _buildButton(IconData icon, [bool spinning = false]) {
    final title = widget.model.title.split('-');
    final label = Text.rich(TextSpan(children: [
      TextSpan(text: title[0], style: widget.literalStyle),
      TextSpan(
          text: "\n${title[1]}",
          style: widget.awareness().isActivated(widget.model)
              ? widget.accentStyle
              : widget.boldStyle)
    ]));

    ///
    /// fetch context size on post frame...
    SchedulerBinding.instance.addPostFrameCallback((_) {
      contextSize = context.size;
      print('update contextSize: $contextSize');
    });

    final double w = contextSize == null ? 0 : (contextSize?.width ?? 0);

    final mainButton = Tooltip(
      message: widget.model.title,
      child: MaterialButton(
        onPressed: onPress,
        elevation: 2,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: spinning
              ? SpinningIcon(icon,
                  color: widget.awareness().isActivated(widget.model)
                      ? widget.activeIconColor
                      : widget.inactiveIconColor,
                  size: 24)
              : Icon(icon,
                  color: widget.awareness().isActivated(widget.model)
                      ? widget.activeIconColor
                      : widget.inactiveIconColor,
                  size: 24),
          label: label,
        ),
        //hoverColor: Colors.blueGrey[800],
      ),
    );

    return Column(
      key: ObjectKey(widget.audioLoader),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        mainButton,
        if (contextSize != null)
          progress ??= SimpleAudioProgress(
              progressAware,
              bgColor: widget.progressBgColor,
              progressColor: widget.inProgressColor,
              width: w,
              height: 2
          )
      ],
    );
  }

  Widget buildLoadingButton() {
    return _buildButton(widget.spinIcon, true);
  }

  Widget buildPlayingButton() {
    return _buildButton(widget.pauseIcon ?? Icons.pause);
  }

  Widget buildNormalButton() {
    return _buildButton(widget.playIcon ?? Icons.play_circle_outline);
  }

  Widget buildStoppedButton() {
    return _buildButton(widget.stopIcon ?? Icons.stop);
  }

  Widget buildButton() {
    switch (buttonState) {
      case AudioPlayerState.CONTINUE:
      case AudioPlayerState.PLAYING:
        return buildPlayingButton();
      case AudioPlayerState.SEEKED:
      case AudioPlayerState.LOADED:
      case AudioPlayerState.COMPLETED:
      case AudioPlayerState.STOPPED:
        return buildNormalButton();
      case AudioPlayerState.SUSPEND:
      case AudioPlayerState.PAUSED:
        return buildNormalButton();
      case AudioPlayerState.SEEKING:
      case AudioPlayerState.WAITING:
      case AudioPlayerState.LOADING:
        return buildLoadingButton();
      default:
        if (buttonState == null) {
          return buildLoadingButton();
        }
        throw Exception('Uncaught Enum... $buttonState');
    }
  }

  double property_progress = 0;

  @override
  Widget build(BuildContext context) {
    print(
        'build simple audio button, ${widget.audioLoader.model.url}, ${widget.audioLoader.player.state}');
    return buildButton();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    widget.audioLoader.dispose();
  }
}

// ignore: must_be_immutable
