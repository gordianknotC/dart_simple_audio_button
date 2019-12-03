import 'dart:async';
import 'dart:html';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as _path;
import 'package:common/common.dart';

import '../audio_model.dart';
import '../exceptions.dart';
import '../sketches/audio_loader.dart';
import 'audioplayer.dart';

final _D = Logger(name:'AU', levels: LEVEL0);

class AudioCache implements AudioCacheSketch{
	@override final String filepath;
	@override final String folder;
	@override final String filename;
	String _selectorKey;
	String get selectorKey => _selectorKey ??= filepath.replaceAll('/', '_');
	
	String rootId;
	DivElement _rootAudio;
	AudioElement _elt;
	
	AudioCache(this.filepath, {this.rootId = "simpleAudio"})
			: folder = _path.dirname(filepath),
				filename = _path.basename(filepath);
	
	@override bool get isCacheReady => _elt != null;
	@override AudioElement get material => _elt;
	@override Future init() {
		_D.debug('cache init');
		_rootAudio = document.querySelector('#$rootId') as DivElement;
		_D.warning('search root audio: $_rootAudio');
		if (_rootAudio == null){
			_rootAudio = document.createElement("div") as DivElement;
			_rootAudio.setAttribute("id", rootId);
			querySelector('body').append(_rootAudio);
			_D.warning('insert root audio: $_rootAudio');
		}
		
		_elt ??= _rootAudio.querySelector('audio[data-name="$selectorKey"]') as AudioElement;
		_D.warning('search sub audio $selectorKey, $_elt');
		if (_elt == null){
			_elt = document.createElement('audio') as AudioElement;
			_elt.setAttribute("data-name", selectorKey);
			_elt.setAttribute('src', _path.join("assets/assets/audio", filename));
			
			_rootAudio.append(_elt);
			_D.warning('create sub audio $selectorKey, $_elt');
		}
		return Future.value();
	}
}


class AudioLoader implements AudioLoaderSketch{
	
	@override AudioPlayerSketch player;
	@override final AudioModel model;
	AudioCache cache;
	@override bool get initialized => player?.initialized ?? false;
	@override bool get isLoaded 	=>  player?.cache?.material != null;
	@override bool get isPaused 	=>  player?.state == AudioPlayerState.PAUSED;
	@override bool get isPlaying 	=>  player?.state == AudioPlayerState.PLAYING || player?.state == AudioPlayerState.CONTINUE;
	@override bool get isCompleted=>  player?.state == AudioPlayerState.COMPLETED;
	@override bool get isStopped 	=>  player?.state == AudioPlayerState.STOPPED;
	@override AudioPlayerState get state {
		return player?.state;
	}
	
	AudioLoader(this.model): cache = AudioCache(model.url){
		player = AudioPlayer(cache);
	}
	
	void guard(){
		if (!initialized) {
			try {
				throw AudioNotInitializedError();
			} catch (e, s) {
				print('[ERROR] AudioLoader.guard failed: $e\n$s');
				rethrow;
			}
		}
	}
	@override Future<bool> initAudio() async {
		await player.initAudio();
		return Future.value(true);
	}
	
	@override void playFromStart(){
		guard();
		player.stop();
	}
	
	@override void play(){
		guard();
		player.play();
	}
	
	@override void pause(){
		guard();
		if (player != null){
			_D('pause ${model.url}');
			player.pause();
		}
	}
	@override void playOrPause(){
		guard();
		if (player != null){
			if (player.state == AudioPlayerState.PLAYING) {
			  pause();
			} else {
			  play();
			}
		}else{
			play();
		}
	}
	@override void stop(){
		guard();
		if (player != null){
			player.stop();
		}
	}
	
	StreamSubscription<AudioPlayerState> get _onPlayerStateSubscription =>
		(player as AudioPlayer).onPlayerStateChangedSubscription;
	
	void _log(){
	
	}
	
	void _playerStateMonitorInit(){
		if (_onPlayerStateSubscription != null) {
		  return;
		}
		(player as AudioPlayer).onPlayerStateChanged((state){
			switch(state){
				case AudioPlayerState.CONTINUE:
					_D.debug('contiue:  ${model.url}, call onPlay..., ${player.state}, $_onPlay');
					_onPlay?.call();
					break;
				case AudioPlayerState.PLAYING:
					_D.debug('playing: ${model.url}, ${player.state}, $_onPlay');
					_onPlay?.call();
					break;
				case AudioPlayerState.SUSPEND:
				case AudioPlayerState.PAUSED:
					_D.debug('paused:  ${model.url}, ${player.state}, $_onPaused');
					_onPaused?.call();
					break;
				case AudioPlayerState.LOADED:
				case AudioPlayerState.SEEKED:
				case AudioPlayerState.COMPLETED:
					_D.debug('ready/completed:  ${model.url}, ${player.state}, $_onCompleted');
					_onCompleted?.call();
					break;
				case AudioPlayerState.STOPPED:
					_D.debug('stopeed:  ${model.url}, ${player.state}, $_onStopped');
					_onStopped?.call();
					break;
				case AudioPlayerState.SEEKING:
				case AudioPlayerState.LOADING:
				case AudioPlayerState.WAITING:
					_D.debug('pending:  ${model.url}, ${player.state}, $_onLoading');
					_onLoading?.call();
					break;
			}
		});	}
	
	void Function() _onPlay;
	@override void onPlay(void onData()) {
		_playerStateMonitorInit();
		_onPlay = onData;
	}
	
	void Function() _onStopped;
	@override void onStopped(void onData()) {
		_onStopped = onData;
		_playerStateMonitorInit();
	}
	
	void Function() _onLoaded;
	@override void onLoaded(void onData()) {
		_onLoaded = onData;
		_playerStateMonitorInit();
	}
	
	void Function() _onLoading;
	@override void onLoading(void onData()) {
		_onLoading = onData;
		_playerStateMonitorInit();
	}
	
	void Function() _onPaused;
	@override void onPaused(void onData()) {
		_playerStateMonitorInit();
		_onPaused = onData;
	}
	
	void Function() _onCompleted;
	@override void onCompleted(void onData()) {
		_playerStateMonitorInit();
		_onCompleted = onData;
	}
	
	@override void onUpdate(void onData(e), {bool cancelOthers = true}) {
		_D.info('onUpdate init');
		(player as AudioPlayer).onAudioPositionChanged(onData);
	}
	
	@override void dispose(){
		_D.info('dispose audio player...');
		player.dispose();
	}
}





