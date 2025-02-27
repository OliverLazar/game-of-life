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
var Asel = 0
var Bsel = 0

var PlayerCount = 3

var cooldown_gameStart = 300
var cooldown_movement = 30
var cooldown_endMovement = 120

# Player Movement
var currentPlayerID: int = 0
var Roll = 0
var RollStoage = 0   # store roll during blue event
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
	opA.pressed.connect(self._optionA)
	opB.pressed.connect(self._optionB)
	mainCamera.current = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:	
	if gameStateChanged:
		gameStateChanged = false
		
		if gameState == 1:			
			var cameraTween1 = get_tree().create_tween()
			var cameraTween2 = get_tree().create_tween()
			cameraTween1.tween_property(mainCamera, "position", $"SpinnerCameraPOS".position, 3)
			cameraTween2.tween_property(mainCamera, "rotation", $"SpinnerCameraPOS".rotation, 3)
			cameraTween1.play()
			cameraTween2.play()
			
			await get_tree().create_timer(3).timeout			
		if gameState == 2:
			Players[currentPlayerID].car.get_node("carCamera").current = true
			Target = Players[currentPlayerID].spot + 1
			PathChoice = Players[currentPlayerID].spotExt
			moveCar(Players[currentPlayerID], Target, PathChoice)
			Roll -= 1
			gameState = 3
		if gameState == 4:
			print("Event")
			Asel = randi_range(0, len(DebugStandardChoices)-1)
			Bsel = randi_range(0, len(DebugStandardChoices)-1)
			while Bsel == Asel:
				Bsel = randi_range(0, len(DebugStandardChoices)-1)
				
			opA.get_node("Text").set_text(DebugStandardChoices[Asel]["text"])
			opA.get_node("Value").set_text(DebugStandardChoices[Asel]["valueText"])
			opB.get_node("Text").set_text(DebugStandardChoices[Bsel]["text"])
			opB.get_node("Value").set_text(DebugStandardChoices[Bsel]["valueText"])
			
			opA.visible = true
			opB.visible = true
			
	if gameState == 3:
		var p = Players[currentPlayerID]
		if p.lerpWeight >= 0.2: #move finished
			print("Next Square")
			var nodeType = Map.get_node(str(p.spot)+str(p.spotExt)).get_meta("Type")
			if nodeType == "payday":
				print("payday")
				p.Cash += p.Salary
			elif nodeType == "stop":
				print("stop")
				gameState = 5
				gameStateChanged = true
				Roll = 0
			elif nodeType == "event":
				print("fork")
				gameState = 6
				gameStateChanged = true
				RollStoage = Roll
				Roll = 0
			
			if Roll > 0:
				gameState = 2
				gameStateChanged = true
			elif gameState == 3:
				print("Done Moving")
				if nodeType == "default":
					gameState = 4
					gameStateChanged = true
			
			
	for car in Players:
		car._process(delta)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if gameState == 1:
			Roll = randi_range(1, 1)
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
	player.spot = target
	player.spotExt = ext
	player.setDestination(d, r)
	
func nextPlayer():
	mainCamera.position = Players[currentPlayerID].car.get_node("carCamera").position
	mainCamera.rotation = Players[currentPlayerID].car.get_node("carCamera").rotation
	
	mainCamera.current = true
	opA.visible = false
	opB.visible = false
	
	currentPlayerID += 1
	
	if currentPlayerID >= len(Players):
		currentPlayerID = 0
	
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
	
	await get_tree().create_timer(4).timeout
	
	for p in range(PlayerCount):
		var cam = $"carCamera".duplicate()
		var a = cam.position
		var b = cam.rotation
		
		Players[p].car.add_child(cam)
		Players[p].car.get_node("carCamera").position = a
		Players[p].car.get_node("carCamera").rotation = b
	
	gameState = 1
	gameStateChanged = true
	
func _optionA():
	if gameState == 4:
		print(DebugStandardChoices[Asel]["text"])
		gameState = 1
		gameStateChanged = true
		nextPlayer()
	
func _optionB():
	if gameState == 4:
		print(DebugStandardChoices[Bsel]["text"])
		gameState = 1
		gameStateChanged = true
		nextPlayer()
	
	
var DebugStandardChoices = [
	{"text":"Daniel", "value":1000, "valueText": "$1000"},
	{"text":"Roderick", "value":26, "valueText": "$26"},
	{"text":"Ayoub", "value":-48, "valueText": "-$48"},
	{"text":"Oliver", "value":696969, "valueText": "$696969"}
]
