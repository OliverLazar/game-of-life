extends Node3D

@onready var Map = $"NodeMapMath"
@onready var testCar = $"Game of Life Bus"

@onready var mainCamera = $"MainCamera"

@onready var Garage = $"Garage"

# Start Menu
@onready var pSlider = $"UI/PlayerCount"
@onready var start = $"UI/StartGame"

# Buttons
@onready var opA = $"UI/OptionA"
@onready var opB = $"UI/OptionB"

var PlayerCount = 3

var cooldown_gameStart = 300
var cooldown_movement = 30
var cooldown_endMovement = 120

# Player Movement
var currentPlayerID: int = 0
var Roll = 0
var Target = 0
var PathChoice = ""
var d = Vector3.ZERO
var r = Vector3.ZERO

# Game
var Players = []
var Cooldown: int
var gameState = 0
var gameStateChanged = false
# 0 -> setup
# 1 -> spin spinner
# 2 -> move car 1 square
# 3 -> wait for car to move 1 square
# 4 -> regular square cards (yellow)
# 5 -> stop sign event (red)
# 6 -> branch selection (blue)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start.pressed.connect(self._start_button)
	mainCamera.current = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:	
	if gameStateChanged:
		gameStateChanged = false
		
		if gameState == 3:
			opA.visible = true
			opB.visible = true
		if gameState == 1:
			var cameraTween1 = get_tree().create_tween()
			var cameraTween2 = get_tree().create_tween()
			cameraTween1.tween_property(mainCamera, "position", $"SpinnerCameraPOS".position, 3)
			cameraTween2.tween_property(mainCamera, "rotation", $"SpinnerCameraPOS".rotation, 3)
			cameraTween1.play()
			cameraTween2.play()
		if gameState == 2:
			Players[currentPlayerID].get_node("carCamera").current = true
			Target = Players[currentPlayerID].spot + 1
			PathChoice = Players[currentPlayerID].spotExt
			moveCar(Players[currentPlayerID], Target, PathChoice)
			gameState = 3
			
	if gameState == 3:
		if Players[currentPlayerID].lerpWeight:
			gameState = 2
			gameStateChanged = true
			
			
	for car in Players:
		car._process(delta)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if gameState == 1:
			Roll = randi_range(1, 10)
			print("Roll: ", Roll)
			gameState = 2
			gameStateChanged = true
	
func moveCar(player, target, ext):
	var node = Map.get_node(str(target)+str(ext))
	
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
	
func _start_button():
	$"UI/PlayerCount".visible = false
	$"UI/pcountLabel".visible = false
	$"UI/StartGame".visible = false
	
	PlayerCount = pSlider.value
	print("starting,", PlayerCount)
	
	for p in range(PlayerCount):
		var pp = Player.new()
		var car = Garage.get_node("Green").duplicate()
		add_child(car)
		pp.setCar(car)
		Players.append(pp)
		$"PLayers".add_child(pp)
		moveCar(pp, Target, PathChoice)
		
	var cameraTween1 = get_tree().create_tween()
	var cameraTween2 = get_tree().create_tween()
	cameraTween1.tween_property(mainCamera, "position", $"StartCameraPOS".position, 3)
	cameraTween2.tween_property(mainCamera, "rotation", $"StartCameraPOS".rotation, 3)
	cameraTween1.play()
	cameraTween2.play()
	
	await get_tree().create_timer(5).timeout
	
	for p in range(PlayerCount):
		var cam = $"carCamera".duplicate()
		Players[p].add_child(cam)
	
	gameState = 1
	gameStateChanged = true
