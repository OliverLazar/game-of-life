extends Button

@onready var sprite = $"../Loading"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if button_pressed:
		sprite.visible = true
		await get_tree().create_timer(0.1).timeout
		get_tree().change_scene_to_file("res://Scenes/Map.tscn")
