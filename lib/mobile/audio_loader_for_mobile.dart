import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:common/common.dart';
import 'package:flutter/services.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:path/path.dart' as _path;
import 'package:path_provider/path_provider.dart';

import '../audio_model.dart' as _Model;
import '../sketches/audio_loader.dart';


final _D = Logger(name:'AuLoad', levels: LEVEL0);

_Model.AudioPlayerState mapState(AudioPlayerState state){
	switch(state){
	  case AudioPlayerState.STOPPED:
	    return _Model.AudioPlayerState.STOPPED;
	  case AudioPlayerState.PLAYING:
			return _Model.AudioPlayerState.PLAYING;
	  case AudioPlayerState.PAUSED:
			return _Model.AudioPlayerState.PAUSED;
	  case AudioPlayerState.COMPLETED:
			return _Model.AudioPlayerState.COMPLETED;
	}
	return null;
}



class AudioCache implements AudioCacheSketch{
	@override final String filepath;
	@override final String folder;
	@override final String filename;
	
	String _cacheString;
	AudioCache(this.filepath): folder = _path.dirname(filepath), filename = _path.basename(filepath);
	
	@override bool get isCacheReady => _cacheString != null;
	@override String get material => _cacheString;
	
	@override Future init() async {
		if (_cacheString != null) {
		  return;
		}
		final ByteData data = await rootBundle.load(filepath);
		Directory tempDir = await getTemporaryDirectory();
		File tempFile = File(_path.join(tempDir.path, filename));
		await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
		_cacheString = tempFile.uri.toString();
	}
}



class _SingleAudioLocalPlayer implements AudioPlayerSketch{
	static final Map<String, _SingleAudioLocalPlayer> _allplayers = {};
	static final AudioPlayer _player = AudioPlayer();
	
	final String filepath;
	@override AudioCacheSketch cache;
	bool activated = false;
	
	_SingleAudioLocalPlayer._(this.filepath, this.cache);
	
	factory _SingleAudioLocalPlayer(String filepath, AudioCache cache){
		if (_allplayers.containsKey(filepath)) {
		  return _allplayers[filepath];
		}
		final result = _SingleAudioLocalPlayer._(filepath, cache);
		return _allplayers[filepath] = result;
	}
	
	@override Future play(){
		_allplayers.forEach((k, v){
			if (v.activated && v.filepath != filepath){
				_D('stop activated player: ${v.filepath}');
				v.stop();
			}
		});
		activated = true;
		return cache.init().then((_){
			_D('play $filepath');
			return _player.play(cache.material as String, isLocal: true);
		});
	}
	
	@override Future pause(){
		return _player.pause();
	}
	
	@override Future stop(){
		activated = false;
		return _player.stop();
	}
	
	@override Future seek(double t){
		throw UnimplementedError("seek method");
	}
	
	@override Future<bool> initAudio() async {
		if (!cache.isCacheReady){
			await cache.init();
			_onLoadController.add(true);
			return true;
		}
		return false;
	}
	
	@override _Model.AudioPlayerState get state {
		if (!cache.isCacheReady) {
		  return null;
		}
		if (activated) {
		  return mapState(_player.state);
		}
		return mapState(AudioPlayerState.STOPPED);
	}
	
	@override Stream<_Model.AudioPlayerState> get stateStream {
		return _player.onPlayerStateChanged.where((d){
			if (d == AudioPlayerState.STOPPED) {
			  return true;
			}
			return activated;
		}).map(mapState);
	}
	@override Stream<Duration> get positionChangedStream {
		return _player.onAudioPositionChanged.where((d){
			return activated;
		});
	}
	
	
	
	final StreamController<bool> _onLoadController = StreamController<bool>.broadcast();
	StreamSubscription<bool> _onLoadSubscription;
	void Function() _onLoad;
	@override void onReady(void onData()) {
		_onLoad = onData;
		_onLoadSubscription = _onLoadController.stream.listen((_){
			_onLoad();
		});
	}
	
	@override void dispose(){
		_onLoadSubscription?.cancel();
	}
}


class AudioLoader implements AudioLoaderSketch{
	@override final AudioPlayerSketch player;
	@override final _Model.AudioModel model;
	
	@override bool get isLoaded 	=>  player?.cache?.material != null;
	@override bool get isPaused 	=>  player?.state == _Model.AudioPlayerState.PAUSED;
	@override bool get isPlaying 	=>  player?.state == _Model.AudioPlayerState.PLAYING;
	@override bool get isCompleted=>  player?.state == _Model.AudioPlayerState.COMPLETED;
	@override bool get isStopped 	=>  player?.state == _Model.AudioPlayerState.STOPPED;
	@override _Model.AudioPlayerState get state {
		return player?.state;
	}
	
	AudioLoader(this.model): player = _SingleAudioLocalPlayer(model.url, AudioCache(model.url));
	
	@override Future<bool> initAudio() async {
		return player.initAudio();
	}
	
	@override Future playFromStart(){
		player.stop();
		return player.play();
	}
	
	@override Future play(){
		return player.play();
	}
	
	@override void pause(){
		if (player != null){
			_D('pause ${model.url}');
			player.pause();
		}
	}
	@override void playOrPause(){
		if (player != null){
			if (player.state == _Model.AudioPlayerState.PLAYING) {
			  pause();
			} else {
			  play();
			}
		}else{
			play();
		}
	}
	@override void stop(){
		if (player != null){
			player.stop();
		}
	}
	
	StreamSubscription<_Model.AudioPlayerState> _onPlayerStateSubscription;
	void _playerStateMonitorInit(){
		if (_onPlayerStateSubscription == null){
			_onPlayerStateSubscription ??= player.stateStream.listen((state){
				switch(state){
					case _Model.AudioPlayerState.STOPPED:
						_D('stopeed ${model.url}');
						_onStopped?.call();
						break;
					case _Model.AudioPlayerState.PLAYING:
						_D('playing ${model.url}');
						_onPlay?.call();
						break;
					case _Model.AudioPlayerState.PAUSED:
						_D('paused ${model.url}');
						_onPaused?.call();
						break;
					case _Model.AudioPlayerState.COMPLETED:
						_D('completed ${model.url}');
						_onCompleted?.call();
						break;
				  case _Model.AudioPlayerState.LOADING:
						_onLoading?.call();// TODO: Handle this case.
				    break;
				    
					/// followings only supported on web...
					case _Model.AudioPlayerState.CONTINUE:
				  case _Model.AudioPlayerState.LOADED:
				  case _Model.AudioPlayerState.SEEKING:
				  case _Model.AudioPlayerState.SEEKED:
				  case _Model.AudioPlayerState.WAITING:
				  case _Model.AudioPlayerState.SUSPEND:
				    throw UnsupportedError('unsupported event $state for mobile');
				}
			});
			_D.info('_playerStateMonitorInit: $_onPlayerStateSubscription');
		}
	}
	
	void Function() _onLoading;
	void onLoading(void onData()) {
		_playerStateMonitorInit();
		_onLoading = onData;
	}
	
	void Function() _onPlay;
	@override void onPlay(void onData()) {
		_playerStateMonitorInit();
		_onPlay = onData;
	}
	
	void Function() _onStopped;
	@override void onStopped(void onData()) {
		_playerStateMonitorInit();
		_onStopped = onData;
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
	
	@override void onLoaded(void onData()) {
		player.onReady(onData);
	}
	
	StreamSubscription<Duration> onUpdateSubscription;
	void Function(Duration) _onUpdate;
	@override void onUpdate(void onData(e), {bool cancelOthers = true}) {
		_D.info('onUpdate init');
		if (cancelOthers) onUpdateSubscription?.cancel?.call();
		_onUpdate = onData;
		onUpdateSubscription = (player as _SingleAudioLocalPlayer).positionChangedStream
			.where((e) => (player as _SingleAudioLocalPlayer).activated)
			.listen(_onUpdate);
	}
	
	@override void dispose(){
		_D.info('dispose audio player...');
		_onPlayerStateSubscription?.cancel();
		onUpdateSubscription?.cancel();
		(player as _SingleAudioLocalPlayer)._onLoadSubscription?.cancel();
	}
}





