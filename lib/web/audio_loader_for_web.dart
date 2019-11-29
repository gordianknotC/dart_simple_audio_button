import 'dart:async';
import 'dart:html';
import 'package:path/path.dart' as _path;
import 'package:common/common.dart';

import '../audio_model.dart';
import '../sketches/audio_loader.dart';
import 'audioplayer.dart';

final _D = Logger(name:'AuLoad', levels: LEVEL0);

class AudioCache implements AudioCacheSketch{
	@override final String filepath;
	@override final String folder;
	@override final String filename;
	
	String rootId;
	DivElement _rootAudio;
	AudioElement _elt;
	
	AudioCache(this.filepath, {this.rootId = "simpleAudio"})
			: folder = _path.dirname(filepath),
				filename = _path.basename(filepath);
	
	@override bool get isCacheReady => _elt != null;
	@override AudioElement get material => _elt;
	
	void _createRootNode(){
		_rootAudio = document.querySelector('#$rootId') as DivElement;
		if (_rootAudio == null){
			_rootAudio = document.createElement("div") as DivElement;
			_rootAudio.setAttribute("id", rootId);
			querySelector('body').append(_rootAudio);
		}
	}
	
	void _createAudioNode(){
		_elt ??= _rootAudio.querySelector('audio[data-name=$filepath]') as AudioElement;
		if (_elt == null){
			final audio = document.createElement('audio');
			audio.setAttribute("data-name", filepath);
			_rootAudio.append(audio);
		}
	}
	
	@override Future init() async {
		_createRootNode();
		_createAudioNode();
		
		document.querySelector('#audio');
		if (_elt != null) {
		  return;
		}
	}
}


/*

class _SingleAudioLocalPlayer {
	static final Map<String, _SingleAudioLocalPlayer> _allplayers = {};
	static final AudioPlayer _player = AudioPlayer();
	final String filepath;
	final _AudioCache cache;
	bool activated = false;
	
	_SingleAudioLocalPlayer._(this.filepath, this.cache);
	
	factory _SingleAudioLocalPlayer(String filepath, _AudioCache cache){
		if (_allplayers.containsKey(filepath)) {
		  return _allplayers[filepath];
		}
		final result = _SingleAudioLocalPlayer._(filepath, cache);
		return _allplayers[filepath] = result;
	}
	
	Future<bool> initAudio() async {
		if (cache.elt == null){
			await cache.init();
			_onLoadController.add(true);
			return true;
		}
		return false;
	}
	
	AudioPlayerState get state {
		if (cache.elt == null) {
		  return null;
		}
		if (activated) {
		  return _player.state;
		}
		return AudioPlayerState.STOPPED;
	}
	
	Stream<AudioPlayerState> get onPlayerStateChanged {
		return _player.stateStream;
	}
	Stream<num> get onAudioPositionChanged {
		return _player.positionChangedStream;
	}
	
	Future play(){
		_allplayers.forEach((k, v){
			if (v.activated && v.filepath != filepath){
				_D('stop activated player: ${v.filepath}');
				v.stop();
			}
		});
		activated = true;
		return cache.init().then((_){
			_D('play $filepath');
			return _player.play(cache.elt);
		});
	}
	
	void pause(){
		_player.pause();
	}
	
	void stop(){
		activated = false;
		_player.stop();
	}
	
	final StreamController<bool> _onLoadController = StreamController<bool>.broadcast();
	StreamSubscription<bool> _onLoadSubscription;
	void Function() _onLoad;
	void onLoad(void onData()) {
		_onLoad = onData;
		_onLoadSubscription = _onLoadController.stream.listen((_){
			_onLoad();
		});
	}
	
	void dispose(){
		_onLoadSubscription?.cancel();
	}
}
*/


class AudioLoader implements AudioLoaderSketch{
	@override AudioPlayerSketch player;
	@override final AudioModel model;
	final AudioCache cache;
	
	@override bool get isLoaded 	=>  player?.cache?.material != null;
	@override bool get isPaused 	=>  player?.state == AudioPlayerState.PAUSED;
	@override bool get isPlaying 	=>  player?.state == AudioPlayerState.PLAYING;
	@override bool get isCompleted=>  player?.state == AudioPlayerState.COMPLETED;
	@override bool get isStopped 	=>  player?.state == AudioPlayerState.STOPPED;
	@override AudioPlayerState get state {
		return player?.state;
	}
	
	AudioLoader(this.model): cache = AudioCache(model.url){
		player = AudioPlayer(cache);
	}
	
	@override Future<bool> initAudio() async {
		await player.initAudio();
		return Future.value(true);
	}
	
	@override void playFromStart(){
		player.stop();
	}
	
	@override void play(){
		player.play();
	}
	
	@override void pause(){
		if (player != null){
			_D('pause ${model.url}');
			player.pause();
		}
	}
	@override void playOrPause(){
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
		if (player != null){
			player.stop();
		}
	}
	
	StreamSubscription<AudioPlayerState> get _onPlayerStateSubscription =>
		(player as AudioPlayer).onPlayerStateChangedSubscription;
	
	void _playerStateMonitorInit(){
		if (_onPlayerStateSubscription != null) {
		  return;
		}
		(player as AudioPlayer).onPlayerStateChanged((state){
			switch(state){
				case AudioPlayerState.PLAYING:
					_D('playing ${model.url}');
					_onPlay?.call();
					break;
				case AudioPlayerState.PAUSED:
					_D('paused ${model.url}');
					_onPaused?.call();
					break;
				case AudioPlayerState.COMPLETED:
					_D('completed ${model.url}');
					_onCompleted?.call();
					break;
				case AudioPlayerState.CONTINUE:
				// TODO: Handle this case.
					break;
				case AudioPlayerState.STOPPED:
					_D('stopeed ${model.url}');
					_onStopped?.call();
					break;
				case AudioPlayerState.LOADING:
				// TODO: Handle this case.
					break;
				case AudioPlayerState.LOADED:
				// TODO: Handle this case.
					break;
				case AudioPlayerState.SEEKING:
				// TODO: Handle this case.
					break;
				case AudioPlayerState.SEEKED:
				// TODO: Handle this case.
					break;
				case AudioPlayerState.WAITING:
				// TODO: Handle this case.
					break;
				case AudioPlayerState.SUSPEND:
				// TODO: Handle this case.
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





