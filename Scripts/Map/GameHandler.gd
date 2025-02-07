extends Node3D

@onready var Map = $"NodeMapMath"
@onready var testCar = $"Game of Life Bus"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var playerObject = Player.new()
	playerObject.setCar(testCar)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
