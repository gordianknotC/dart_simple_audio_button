import 'audio_model.dart';
import 'sketches/audio_loader.dart';

class AudioCache implements AudioCacheSketch{
	@override String  filepath;
	@override String  folder;
	@override String  filename;
	
	@override Future init(){}// ignore: missing_return
	@override bool  isCacheReady;
	@override dynamic material;
}

class AudioPlayer implements AudioPlayerSketch{
	@override AudioCacheSketch cache;
	@override Future<bool> initAudio(){} // ignore: missing_return
	@override Future play(){}// ignore: missing_return
	@override Future seek(time){}// ignore: missing_return
	@override Future pause(){}// ignore: missing_return
	@override Future stop(){}// ignore: missing_return
	@override Stream<AudioPlayerState> stateStream;
	@override Stream positionChangedStream;
	@override AudioPlayerState state;
	@override void onReady(void cb()){}
	@override void dispose(){}
}

class AudioLoader implements AudioLoaderSketch{
	@override AudioPlayerSketch player;
	@override AudioModel model;
	AudioLoader(AudioModel model);
	@override bool isLoaded 	;
	@override bool isPaused 	;
	@override bool isPlaying 	;
	@override bool isCompleted;
	@override bool isStopped 	;
	
	@override AudioPlayerState state;
	@override Future<bool> initAudio(){}// ignore: missing_return
	
	@override void playFromStart(){}
	@override void play(){}
	@override void pause(){}
	@override void playOrPause(){}
	@override void stop(){}
	
	@override void onPlay(void onData()){}
	@override void onStopped(void onData()){}
	@override void onPaused(void onData()){}
	@override void onCompleted(void onData()){}
	@override void onLoaded(void onData()){}
	
	@override void onUpdate(void onData(e), {bool cancelOthers = true}){}
	@override void dispose(){}
}
