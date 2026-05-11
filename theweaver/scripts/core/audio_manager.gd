## AudioManager.gd
## Autoload — musique + SFX.
## Dev 2 · Jour 4
extends Node

@onready var _music: AudioStreamPlayer = $MusicPlayer
@onready var _sfx:   AudioStreamPlayer = $SFXPlayer

func play_music(stream: AudioStream, from: float = 0.0) -> void:
	if _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	_music.play(from)

func stop_music() -> void:
	_music.stop()

func play_sfx(stream: AudioStream) -> void:
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.stream     = stream
	p.volume_db  = _sfx.volume_db
	p.play()
	p.finished.connect(p.queue_free)

func set_volume(volume: float) -> void:
	var db := linear_to_db(clampf(volume, 0.0, 1.0))
	_music.volume_db = db
	_sfx.volume_db   = db
