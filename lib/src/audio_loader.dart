import './audio_model.dart';
import './sketches/audio_loader.dart';

class AudioCache implements AudioCacheSketch{
	@override late String  filepath;
	@override late String  folder;
	@override late String  filename;
	
	@override Future init() async {}// ignore: missing_return
	@override late bool isCacheReady;
	@override dynamic material;
}

class AudioPlayer implements AudioPlayerSketch{
	@override late AudioCacheSketch cache;
	@override Future<bool> initAudio()async{return Future.value(true);} // ignore: missing_return
	@override Future play()async{}// ignore: missing_return
	@override Future seek(time)async{}// ignore: missing_return
	@override Future pause()async{}// ignore: missing_return
	@override Future stop()async{}// ignore: missing_return
	@override late Stream<AudioPlayerState> stateStream;
	@override late Stream positionChangedStream;
	@override AudioPlayerState? state;
	@override void onReady(void cb()){}
	@override void dispose(){}
  @override bool get initialized => false;
}

class AudioLoader implements AudioLoaderSketch{
	@override late AudioPlayerSketch player;
	@override late AudioModel model;
	AudioLoader(AudioModel model);
	@override late bool isLoaded 	;
	@override late bool isPaused 	;
	@override late bool isPlaying 	;
	@override late bool isCompleted;
	@override late bool isStopped 	;
	
	@override AudioPlayerState? state;
	@override Future<bool> initAudio(){return Future.value(true);}// ignore: missing_return
	
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
	
	@override void onUpdate(void onData(dynamic e), {bool cancelOthers = true}){}
	@override void dispose(){}

  // ignore: avoid_returning_null
  @override late bool initialized;
  @override void onLoading(void Function() onData) {  }
}









