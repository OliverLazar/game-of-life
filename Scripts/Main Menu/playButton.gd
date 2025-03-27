extends Button

@onready var sprite = $"../Loading"
@onready var audio = $"../../AudioStreamPlayer"
@onready var map = "res://Scenes/Map.tscn"
@onready var audio2 = $"../../AudioStreamPlayer2"
var sound_button: TextureButton

# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	sound_button = $"../Sound"
	audio2.play()
	if sound_button == null:
		print("null")
	else:
		print("hello")
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
	if sound_button and sound_button.button_pressed:
		print("hi")
