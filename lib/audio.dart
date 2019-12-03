//import 'package:audioplayer/audioplayer.dart';
import 'package:common/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:behaviors/behaviors.dart';

import 'layout/widgets/icons/spiningIcon.dart';
import 'layout/widgets/stateful.dart';

import 'pseudo_audio_loader.dart'
	if (dart.library.io) 'mobile/audio_loader_for_mobile.dart'
	if (dart.library.html)  'web/audio_loader_for_web.dart';
	
import 'audio_model.dart';



final _D = Logger(name:'AU_WID', levels: LEVEL0);


enum EBtState{
	loading, playing, stopped, paused,
}


class SimpleAudioProgress extends StatelessWidget {
	final double width;
	final double height;
	final EdgeInsets padding;
	final SingleProgressAware awareness;
	final Color bgColor;
	final Color progressColor;
	const SimpleAudioProgress(this.awareness, {
		@required this.width, this.padding, this.height, Key key,
		this.bgColor, this.progressColor,
	}) : super(key: key);

  @override
  Widget build(BuildContext context) {
		return Observer(
				builder: observerGuard(() { //OB:
					final property_progress = awareness.property_progress;
					_D.debug('progress: $property_progress - ${width * property_progress}');
					return Container(
							height: height,
							width: width, // set constraint with
							color: bgColor,
							alignment: AlignmentDirectional.center,
							child: Container(
									height: height,
									width: width * property_progress,
									color: progressColor
							)
					);
				}, "SimpleAudioProgress.build"));
	
	}
}



// ignore: must_be_immutable
class SimpleAudioButton extends StatefulWidget implements SingleGroupAwareWidgetSketch<AudioModel>{
	final AudioModel model;
	final double height;
	final double width;
	final void Function(AudioModel model) onPress;
	final AudioLoader audioLoader;
	
	final IconData spinIcon;
	final IconData playIcon;
	final IconData pauseIcon;
	final IconData stopIcon;
	
	final Color activeIconColor;
	final Color inactiveIconColor;
	
	final TextStyle literalStyle;
	final TextStyle boldStyle;
	final TextStyle accentStyle;
	
	final Color progressBgColor;
	final Color inProgressColor;
	
	
	@override SingleGroupAware<AudioModel> Function() awareness;
	
	SimpleAudioButton(this.model, {
		@required this.width, this.height = 32, this.onPress,
		this.awareness, this.spinIcon,  this.playIcon,
		this.stopIcon, this.pauseIcon,
		this.boldStyle, this.literalStyle, this.accentStyle,
		this.activeIconColor, this.inactiveIconColor,
		this.progressBgColor, this.inProgressColor, Key key,
	}):audioLoader = AudioLoader(model) ,super(key: key);
	
	@override State<StatefulWidget> createState() => SimpleAudioButtonState();
  @override void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SimpleAudioButtonState extends State<SimpleAudioButton> with StatefulMixin {
	AudioPlayerState get buttonState  => widget.audioLoader.player.state;
	SimpleAudioProgress progress;
	Size contextSize;
	
	void addAllListeners(){
		widget.audioLoader.onLoaded((){
			_D.sys('onLoad: ${widget.audioLoader.model.url}, $buttonState');
			setStateSafe((){});
		});
		widget.audioLoader.onStopped((){
			_D.sys('onStopped: ${widget.audioLoader.model.url}, state $buttonState');
			setStateSafe((){});
		});
		widget.audioLoader.onCompleted((){
			_D.sys('onCompleted: ${widget.audioLoader.model.url}, state $buttonState');
			setStateSafe((){});
		});
 
		if (IS_MOBILE){
			widget.audioLoader.onUpdate((d) {
				progressAware.current = (d as Duration).inSeconds.toDouble();
			});
		}else {
			widget.audioLoader.onUpdate((d){
				progressAware.current = (d as num) /1000;
			});
		}
		widget.audioLoader.onPaused((){
			_D.sys('onPause: ${widget.audioLoader.model.url}, state $buttonState');
			setStateSafe((){});
		});
		widget.audioLoader.onPlay((){
			_D.sys('onPlay: ${widget.audioLoader.model.url}, state $buttonState');
			setStateSafe((){});
		});
	}
	
	SingleProgressAware<double> progressAware;

	@override
  void initState() {
    super.initState();
    _D.debug('initState on audioButton');
		progressAware ??= SingleProgressAware(total: widget.model.length, current: 0);
		addAllListeners();
		widget.audioLoader.initAudio();
	}
 
	void _stop(){
		_D.debug('stop, $buttonState');
		widget.audioLoader.stop();
	}
	void _play(){
		_D.debug('play, $buttonState');
		widget.audioLoader.play();
	}
	void _pause(){
		_D.debug('pause, $buttonState');
		widget.audioLoader.pause();
	}
	void onPress(){
		if (buttonState == null){
			_D.debug('block play back, since it"s still loading');
			return;
		}
		_D.sys('onPress: ${buttonState}');
		if (widget.audioLoader.isPlaying) {
		  _pause();
		}else{
			_play();
		}
		widget.onPress?.call(widget.model);
	}
	Widget _buildButton(IconData icon, [bool spining = false]){
		final title = widget.model.title.split('-');
		final label = Text.rich(
			TextSpan(children:[
				TextSpan(text: title[0],        style: widget.literalStyle),
				TextSpan(text: "\n${title[1]}", style: widget.awareness().isActivated(widget.model) ? widget.accentStyle : widget.boldStyle)
			])
		);
		double length = widget.model.length;
		///
		/// fetch context size on post frame...
		SchedulerBinding.instance.addPostFrameCallback((_) {
			contextSize = context?.size;
			_D.info('update contextSize: $contextSize');
		});
		
		final double w = contextSize == null
				? 0
				: contextSize.width;
		
		final mainButton = Tooltip(
			message: widget.model.title,
			child: MaterialButton(
				onPressed: onPress,
				elevation: 2,
				child:  FlatButton.icon(
					onPressed: null,
					icon: spining
							? SpiningIcon(icon, color: widget.awareness().isActivated(widget.model) ? widget.activeIconColor : widget.inactiveIconColor, size: 24)
							: Icon(icon,        color: widget.awareness().isActivated(widget.model) ? widget.activeIconColor : widget.inactiveIconColor, size: 24),
					label: label,
				),
				//hoverColor: Colors.blueGrey[800],
			),
		);
		
		return  Column(
			key: ObjectKey(widget.audioLoader),
			crossAxisAlignment: CrossAxisAlignment.start,
			children: <Widget>[
				mainButton,
				if (contextSize != null)
					progress ??= SimpleAudioProgress(progressAware,
						bgColor			 : widget.progressBgColor,
						progressColor: widget.inProgressColor,
						width: w, height: 2)
			],
		);
	}
	
  Widget buildLoadingButton(){
		return _buildButton(widget.spinIcon, true);
	}
	Widget buildPlayingButton(){
		return _buildButton(widget.pauseIcon ?? Icons.pause);
	}
	Widget buildNormalButton(){
		return _buildButton(widget.playIcon ?? Icons.play_circle_outline);
	}
	Widget buildStoppedButton(){
		return _buildButton(widget.stopIcon ?? Icons.stop);
	}
  Widget buildButton(){
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
	@override Widget build(BuildContext context) {
		_D.debug('build simple audio button, ${widget.audioLoader.model.url}, ${widget.audioLoader.player.state}');
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



