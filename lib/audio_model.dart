

enum AudioPlayerState {
	PLAYING,
	CONTINUE, // continue after having been paused by user or lack of data
	COMPLETED,
	PAUSED,
	STOPPED,
	LOADING,
	LOADED,
	SEEKING,
	SEEKED,
	WAITING,
	SUSPEND,
}

class AudioModel{
	final String url;
	final double length;
	final String title;
	AudioModel({this.url, this.length, this.title});
}
