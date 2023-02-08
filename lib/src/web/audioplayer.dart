import 'dart:async';
import 'dart:html';

import '../audio_model.dart';
import '../sketches/audio_loader.dart';


class AudioPlayer implements AudioPlayerSketch{
	static final Map<String, AudioPlayer> _allplayers = {};
	final bool showLoadingTilFullyLoaded;
	
	@override AudioCacheSketch cache;
	@override AudioPlayerState get state => _state;
	@override bool get initialized => _initialized;
	bool _initialized = false;
	
	AudioElement get currentElt => cache.material as AudioElement;
	AudioPlayerState _state = AudioPlayerState.LOADING;
	
	bool get isPlaying{
		switch(state){
		  case AudioPlayerState.PLAYING:
		  case AudioPlayerState.CONTINUE:
		    return true;
			default:
				return false;
		}
	}
	
	AudioPlayer._(this.cache,{ this.showLoadingTilFullyLoaded = false});
	
	factory AudioPlayer(AudioCacheSketch cache){
		if (_allplayers.containsKey(cache.filepath)) {
			return _allplayers[cache.filepath]!;
		}
		final result = AudioPlayer._(cache);
		return _allplayers[cache.filepath] = result;
	}
	
	
	void load(){
		print('load audio resource for ${cache.filepath}');
		currentElt.load();
	}
	
	void pauseAll(){
		_allplayers.values.forEach((p){
			p.pause();
			/*if (p.isPlaying) {
				p.pause();
				print('pause ${p.cache.filename}');
			}else{
				print('continue ${p.cache.filename}, ${p.state}');
			}*/
		});
	}
	
	@override Future<dynamic> play() {
		pauseAll();
		currentElt.play();
		return Future<dynamic>.value();
	}
	
	@override Future<dynamic> seek(num time){
		currentElt.currentTime = time;
		return Future<dynamic>.value();
	}
	@override Future<dynamic> pause(){
		currentElt.pause();
		return Future<dynamic>.value();
	}
	@override Future<dynamic> stop(){
		seek(0);
		currentElt.pause();
		return Future<dynamic>.value();
	}
	
	@override Future<bool> initAudio() async {
		print('initAudio.. ');
		await cache.init();
		_initialized = true;
		print('cache init finished.. ');
		_onCanPlay();
		_onContinuePlaying();
		_onEnded();
		_onInfoLoaded();
		_onLoaded();
		_onSeeked();
		_onSeeking();
		_onStalled();
		_onSuspend();
		_onWaiting();
		_onPause();
		
		await Future.delayed(Duration(seconds: 2), load);
		return Future.value(true);
	}
	
	@override void onReady(void cb()){
		throw UnimplementedError('onReady is not Implemented, listen to stateStream instead');
	}
	/*
	*
	* 			P U B L I C    S T R E A M
	*
	* */
	final StreamController<AudioPlayerState> _stateController = StreamController<AudioPlayerState>.broadcast();
	@override Stream<AudioPlayerState> get stateStream  => _stateController.stream;
	
	
	
	StreamSubscription<AudioPlayerState>? onPlayerStateChangedSubscription;
	void Function(AudioPlayerState e)? _onPlayerStateChanged;
	void onPlayerStateChanged(void onData(AudioPlayerState e), {bool cancelOthers = true}) {
		if (cancelOthers) onPlayerStateChangedSubscription?.cancel();
		_onPlayerStateChanged = onData;
		onPlayerStateChangedSubscription = stateStream.listen((s){
			_state = s;
			print('receive ${cache.filename} state: $state');
			_onPlayerStateChanged!(s);
		});
	}
	
	StreamSubscription<Event>? onAudioPositionChangedSubscription;
	@override Stream<num> get positionChangedStream  => currentElt.onTimeUpdate.map((_) => currentElt.currentTime);
	void Function(dynamic e)? _onAudioPositionChanged;
	void onAudioPositionChanged(void onData(dynamic e), {bool cancelOthers = true}) {
		if (cancelOthers) onAudioPositionChangedSubscription?.cancel();
		_onAudioPositionChanged = onData;
		onAudioPositionChangedSubscription ??= currentElt.onTimeUpdate.listen((e){
			_onAudioPositionChanged!(currentElt.currentTime);
		});
	}
	
	StreamSubscription<Event>? onVolumeSubscription;
	void Function(Event e)? _onVolume;
	void onVolume(void onData(Event e), {bool cancelOthers = true}) {
		if (cancelOthers) onVolumeSubscription?.cancel();
		_onVolume = onData;
		onVolumeSubscription ??= currentElt.onVolumeChange.listen(_onVolume);
	}
	
	/*
	*
	* 				P R I V A T E...
	*
	*
	* */
	
	/// [AudioPlayerState.LOADING]/ [AudioPlayerState.PLAYING]
	/// The canplay event is fired when the user agent can play the media,
	/// but estimates that not enough data has been loaded to play the
	/// media up to its end without having to stop for further buffering
	/// of content.
	StreamSubscription<Event>? onCanPlaySubscription;
	void _onCanPlay({bool cancelOthers = true}) {
		if (cancelOthers) onCanPlaySubscription?.cancel();
		onCanPlaySubscription = currentElt.onCanPlay.listen((_){
			if (showLoadingTilFullyLoaded){
				_stateController.add(AudioPlayerState.LOADING);
			}else{
				_stateController.add(AudioPlayerState.LOADED);
			}
		});
	}
	
	/// [AudioPlayerState.CONTINUE]
	/// The playing event is fired when playback is ready to start after having
	/// been paused or delayed due to lack of data.
	StreamSubscription<Event>? onContinuePlayingSubscription;
	void _onContinuePlaying({bool cancelOthers = true}) {
		if (cancelOthers) onContinuePlayingSubscription?.cancel();
		onContinuePlayingSubscription = currentElt.onPlaying.listen((_){
			_stateController.add(AudioPlayerState.CONTINUE);
		});
	}
	
	/// [AudioPlayerState.SEEKING]
	/// The seeking event is fired when a seek operation starts, meaning the Boolean
	/// seeking attribute has changed to true and the media is seeking a new position.
	StreamSubscription<Event>? onSeekingSubscription;
	void _onSeeking({bool cancelOthers = true}) {
		if (cancelOthers) onSeekingSubscription?.cancel();
		onSeekingSubscription = currentElt.onSeeking.listen((_){
			_stateController.add(AudioPlayerState.SEEKING);
		});
	}
	
	/// [AudioPlayerState.SEEKED]
	///
	StreamSubscription<Event>? onSeekedSubscription;
	void _onSeeked({bool cancelOthers = true}) {
		if (cancelOthers) onSeekingSubscription?.cancel();
		onSeekedSubscription = currentElt.onSeeked.listen((_){
			_stateController.add(AudioPlayerState.SEEKED);
		});
	}
	
	/// [AudioPlayerState.WAITING]
	///
	/// The waiting event is fired when playback has stopped because
	/// of a temporary lack of data.
	StreamSubscription<Event>? onWaitingSubscription;
	void _onWaiting({bool cancelOthers = true}) {
		if (cancelOthers) onWaitingSubscription?.cancel();
		onWaitingSubscription = currentElt.onWaiting.listen((_){
			_stateController.add(AudioPlayerState.WAITING);
		});
	}
	
	/// [AudioPlayerState.COMPLETED]
	///
	/// The ended event is fired when playback or streaming has stopped because
	/// the end of the media was reached or because no further data is available.
	/// This event occurs based upon HTMLMediaElement (<audio> and <video>) fire
	/// ended when playback of the media reaches the end of the media.
	StreamSubscription<Event>? onFinishedSubscription;
	void _onEnded({bool cancelOthers = true}) {
		if (cancelOthers) onFinishedSubscription?.cancel();
		onFinishedSubscription = currentElt.onEnded.listen((_){
			_stateController.add(AudioPlayerState.COMPLETED);
		});
	}
	
	/// [AudioPlayerState.LOADING]
	///
	/// The loadedmetadata event is fired when the metadata has been loaded.(duration, size....)
	StreamSubscription<Event>? onInfoLoadedSubscription;
	void _onInfoLoaded({bool cancelOthers = true}) {
		if (cancelOthers) onInfoLoadedSubscription?.cancel();
		onInfoLoadedSubscription = currentElt.onLoadedMetadata.listen((_){
			_stateController.add(AudioPlayerState.LOADING);
		});
	}
	
	/// [AudioPlayerState.LOADED]
	///
	/// The loadeddata event is fired when the frame at the current playback
	/// position of the media has finished loading; often the first frame.
	StreamSubscription<Event>? onLoadedSubscription;
	void _onLoaded({bool cancelOthers = true}) {
		if (cancelOthers) onLoadedSubscription?.cancel();
		onLoadedSubscription = currentElt.onLoadedData.listen((_){
			_stateController.add(AudioPlayerState.LOADED);
		});
	}
	
	
	/// [AudioPlayerState.SUSPEND]
	///
	/// The stalled event is fired when the user agent is trying to
	/// fetch media data, but data is unexpectedly not forthcoming.
	StreamSubscription<Event>? onStalledSubscription;
	void _onStalled({bool cancelOthers = true}) {
		if (cancelOthers) onStalledSubscription?.cancel();
		onStalledSubscription  = currentElt.onStalled.listen((_){
			_stateController.add(AudioPlayerState.SUSPEND);
		});
	}
	
	/// [AudioPlayerState.SUSPEND]
	///
	/// The suspend event is fired when media data loading has been suspended.
	StreamSubscription<Event>? onSuspendedSubscription;
	void _onSuspend( {bool cancelOthers = true}) {
		if (cancelOthers) onSuspendedSubscription?.cancel();
		onSuspendedSubscription = currentElt.onSuspend.listen((_){
			_stateController.add(AudioPlayerState.SUSPEND);
		});
	}
	
	
	StreamSubscription<Event>? onPausedSubscription;
	void _onPause({bool cancelOthers = true}) {
		if (cancelOthers) onPausedSubscription?.cancel();
		onPausedSubscription  = currentElt.onPause.listen((_){
			_stateController.add(AudioPlayerState.PAUSED);
		});
	}
	
	@override void dispose(){
		onPausedSubscription?.cancel();
		onAudioPositionChangedSubscription?.cancel();
		onCanPlaySubscription?.cancel();
		onContinuePlayingSubscription?.cancel();
		onFinishedSubscription?.cancel();
		onInfoLoadedSubscription?.cancel();
		onLoadedSubscription?.cancel();
		onPlayerStateChangedSubscription?.cancel();
		onSeekedSubscription?.cancel();
		onSeekingSubscription?.cancel();
		onStalledSubscription?.cancel();
		onSuspendedSubscription?.cancel();
		onVolumeSubscription?.cancel();
		onWaitingSubscription?.cancel();
	}
}




