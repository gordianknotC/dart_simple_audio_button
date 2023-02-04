

class AudioNotInitializedError extends Error{
	final Object message;
	AudioNotInitializedError([this.message = ""]);
	@override String toString() => "SimpleButton not initialized yet";
}