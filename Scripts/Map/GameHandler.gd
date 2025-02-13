extends Node3D

@onready var Map = $"NodeMapMath"
@onready var testCar = $"Game of Life Bus"

@onready var mainCamera = $"MainCamera"

var d = Vector3.ZERO
var r = Vector3.ZERO
var playerObject
var Target = 0

var MoveAmount = 4
var MoveCooldownReset = 30
var MoveCooldown = 300

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mainCamera.current = true
	
	playerObject = Player.new()
	playerObject.setCar(testCar)
	moveCar(playerObject, Target)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if MoveAmount > 0:
		MoveCooldown -= 1
		if MoveCooldown == 0:
			playerObject.activateCamera()
			MoveCooldown = MoveCooldownReset
			Target += 1
			MoveAmount -= 1
			moveCar(playerObject, Target)
	
	playerObject._process(delta)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		Target += 1
		moveCar(playerObject, Target)
	
func moveCar(player, target):
	var node = Map.get_node(str(target))
	
	# Target Rotation
	r = node.rotation_degrees + Vector3(-90, 180, 0)
	
	var yaw = deg_to_rad(r.y-90)
	var pitch = deg_to_rad(r.x+90)
	var roll = deg_to_rad(r.z)

	var forward = Vector3(
		cos(pitch) * sin(yaw),
		sin(pitch),
		cos(pitch) * cos(yaw)
	).normalized()
	
	# Target Position
	d = node.position + forward + Vector3.UP*0.1
	if target == 0: d += Vector3.UP*0.4
	
	# Move car
	player.setDestination(d, r)
