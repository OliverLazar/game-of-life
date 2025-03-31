extends Button

@onready var sprite = $"../Loading"
@onready var sprite2 = $"../Helpscreen"
@onready var audio = $"../../AudioStreamPlayer"
@onready var map = "res://Scenes/Map.tscn"
@onready var audio2 = $"../../AudioStreamPlayer2"
var sound_button: TextureButton
var audiostatus = true
var has_processed = false
var help_button: TextureButton
# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	sound_button = $"../Sound"
	help_button = $"../Help"
	audio2.play()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if name == "Play" and button_pressed:
		sprite.visible = true
		audio2.stop()
		audio.play()
		await get_tree().create_timer(0.1).timeout
		get_tree().change_scene_to_file(map)
	if name == "Exit" and button_pressed:
		get_tree().quit()
	if sound_button and sound_button.button_pressed and not has_processed:
		if audiostatus == true and audio2.playing == true:
			audio2.playing = false
			audiostatus = false
			has_processed = true
	elif sound_button and not sound_button.button_pressed and has_processed:
		if audiostatus == false:
			audio2.playing = true
			audiostatus = true
			has_processed = false
	if help_button.button_pressed == true:
		sprite2.visible = true
	if help_button.button_pressed == false:
		sprite2.visible = false
		
