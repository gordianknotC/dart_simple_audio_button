import 'dart:async';
import '../audio_model.dart';



abstract class AudioCacheSketch{
	String get filepath;
	String get folder;
	String get filename;
	
	Future<dynamic> init();
	bool get isCacheReady;
	dynamic get material;
}

abstract class AudioPlayerSketch{
	late AudioCacheSketch cache;
	Future<bool> initAudio();
	Future play();
	Future seek(double time);
	Future pause();
	Future stop();
	bool get initialized;
	Stream<AudioPlayerState> get stateStream;
	Stream get positionChangedStream;
	AudioPlayerState? get state;
	void onReady(void cb());
	void dispose();
}


abstract class AudioLoaderSketch{
	AudioPlayerSketch get player;
	AudioModel get model;
	AudioLoaderSketch(AudioModel model);
	
	bool get initialized;
	bool get isLoaded 	;
	bool get isPaused 	;
	bool get isPlaying 	;
	bool get isCompleted;
	bool get isStopped 	;
	
	AudioPlayerState? get state;
	Future<bool> initAudio();
	
	void playFromStart();
	void play();
	void pause();
	void playOrPause();
	void stop();
	
	void onLoading(void onData());
	void onPlay(void onData());
	void onStopped(void onData());
	void onPaused(void onData());
	void onCompleted(void onData());
	void onLoaded(void onData());
	
	void onUpdate(void onData(dynamic e), {bool cancelOthers = true});
	void dispose();
}
