extends Button

@onready var sprite = $"../Loading"
@onready var audio = $"../../AudioStreamPlayer"
@onready var map = "res://Scenes/Map.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if name == "Play" and button_pressed:
		sprite.visible = true
		audio.play()
		await get_tree().create_timer(0.1).timeout
		get_tree().change_scene_to_file(map)
	if name == "Exit" and button_pressed:
		get_tree().quit()
