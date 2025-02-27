extends Node3D

# Node references to various elements in the scene, initialized via @onready
@onready var Map = $"NodeMapMath"  # The map that contains nodes for game movement
@onready var testCar = $"Game of Life Bus"  # Reference to a test car, may not be used
@onready var mainCamera = $"MainCamera"  # Reference to the main camera used in the scene
@onready var Garage = $"Garage"  # Reference to the Garage where cars are stored

# Start Menu UI elements
@onready var pSlider = $"UI/PlayerCount"  # Slider for selecting the number of players
@onready var start = $"UI/StartGame"  # Button to start the game

# Buttons for event options
@onready var opA = $"UI/OptionA"  # Option A button in the UI
@onready var opB = $"UI/OptionB"  # Option B button in the UI
var Asel = 0  # Option A selection index
var Bsel = 0  # Option B selection index

var PlayerCount = 3  # Default number of players

# Cooldown variables controlling the flow of the game
var cooldown_gameStart = 300  # Cooldown time before starting the game
var cooldown_movement = 30  # Cooldown time for each movement step
var cooldown_endMovement = 120  # Cooldown time before ending movement

# Player Movement variables
var currentPlayerID: int = 0  # Tracks the current player ID (index)
var Roll = 0  # Current roll value for the dice (spinner)
var RollStoage = 0  # Stores the roll value during a special blue event
var Target = 0  # Target destination for the current player's movement
var PathChoice = ""  # Stores the path choice for the player (for special squares)
var d = Vector3.ZERO  # Target position for the car to move to
var r = Vector3.ZERO  # Target rotation for the car

# Game state and player tracking variables
var Players = []  # List of all the player objects
var Cooldown: int  # General cooldown timer for the game
var gameState = 0  # Tracks the current state of the game (setup, moving, etc.)
var gameStateChanged = false  # Flag to indicate if the game state has changed
# Game States:
# 0 -> setup
# 1 -> spin spinner
# 2 -> move car 1 square
# 3 -> wait for car to move 1 square
# 4 -> regular square cards (yellow)
# 5 -> stop sign event (red)
# 6 -> branch selection (blue)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect the start button and option buttons to their respective functions
	start.pressed.connect(self._start_button)
	opA.pressed.connect(self._optionA)
	opB.pressed.connect(self._optionB)
	mainCamera.current = true  # Set the main camera as the active camera

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if gameStateChanged:
		gameStateChanged = false  # Reset the game state change flag

		if gameState == 1:  # Spin the spinner (prepare the camera)
			# Tween (smooth transition) the camera to the spinner's position and rotation
			var cameraTween1 = get_tree().create_tween()
			var cameraTween2 = get_tree().create_tween()
			cameraTween1.tween_property(mainCamera, "position", $"SpinnerCameraPOS".position, 3)
			cameraTween2.tween_property(mainCamera, "rotation", $"SpinnerCameraPOS".rotation, 3)
			cameraTween1.play()
			cameraTween2.play()
			
			await get_tree().create_timer(3).timeout  # Wait for the camera transition to finish

		if gameState == 2:  # Move the player's car
			Players[currentPlayerID].car.get_node("carCamera").current = true  # Set the player's car camera active
			Target = Players[currentPlayerID].spot + 1  # Set the target spot for the player's movement
			PathChoice = Players[currentPlayerID].spotExt  # Get the path choice from the player
			moveCar(Players[currentPlayerID], Target, PathChoice)  # Move the car to the target
			Roll -= 1  # Decrease roll after move
			gameState = 3  # Wait for the car to finish moving

		if gameState == 4:  # Regular event (choose between two options)
			print("Event")
			Asel = randi_range(0, len(DebugStandardChoices)-1)  # Randomly select option A
			Bsel = randi_range(0, len(DebugStandardChoices)-1)  # Randomly select option B
			while Bsel == Asel:  # Ensure the two options are different
				Bsel = randi_range(0, len(DebugStandardChoices)-1)
				
			# Set the text and value of each option
			opA.get_node("Text").set_text(DebugStandardChoices[Asel]["text"])
			opA.get_node("Value").set_text(DebugStandardChoices[Asel]["valueText"])
			opB.get_node("Text").set_text(DebugStandardChoices[Bsel]["text"])
			opB.get_node("Value").set_text(DebugStandardChoices[Bsel]["valueText"])
			
			opA.visible = true  # Make option A visible
			opB.visible = true  # Make option B visible

	# Handle movement and game state changes during the movement phase
	if gameState == 3:
		var p = Players[currentPlayerID]
		if p.lerpWeight >= 0.2:  # Check if the car has finished moving
			print("Next Square")
			var nodeType = Map.get_node(str(p.spot)+str(p.spotExt)).get_meta("Type")
			
			# Different actions based on the type of square the player lands on
			if nodeType == "payday":
				print("payday")
				p.Cash += p.Salary  # Pay the player their salary
			elif nodeType == "stop":
				print("stop")
				gameState = 5  # Transition to stop event
				gameStateChanged = true
				Roll = 0
			elif nodeType == "event":
				print("fork")
				gameState = 6  # Branch event
				gameStateChanged = true
				RollStoage = Roll  # Store the current roll value for use later
				Roll = 0

			# If there are still more moves to make, move to the next square
			if Roll > 0:
				gameState = 2
				gameStateChanged = true
			elif gameState == 3:
				print("Done Moving")
				if nodeType == "default":
					gameState = 4  # Return to regular event if no special event occurs
					gameStateChanged = true

	# Process all players each frame (if needed for player updates)
	for car in Players:
		car._process(delta)

# Handle input events, such as pressing the accept button (e.g., for rolling)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if gameState == 1:  # If the game is in the spin state
			Roll = randi_range(1, 1)  # Generate a random roll
			print("Roll: ", Roll)
			gameState = 2  # Start the movement phase
			gameStateChanged = true

# Move the car to the target position and rotation
func moveCar(player, target, ext):
	var node = Map.get_node(str(target)+str(ext))  # Get the node for the target square
	
	# Set the target rotation based on the node's rotation
	r = node.rotation_degrees + Vector3(-90, 180, 0)

	var yaw = deg_to_rad(r.y-90)
	var pitch = deg_to_rad(r.x+90)
	var roll = deg_to_rad(r.z)

	# Calculate the forward direction for the car's movement
	var forward = Vector3(
		cos(pitch) * sin(yaw),
		sin(pitch),
		cos(pitch) * cos(yaw)
	).normalized()

	# Set the target position for the car
	d = node.position + forward + Vector3.UP*0.1
	if target == 0: d += Vector3.UP*0.4  # Adjust position if it's the starting point

	# Move the car to the new destination
	player.spot = target
	player.spotExt = ext
	player.setDestination(d, r)

# Switch to the next player in the game
func nextPlayer():
	mainCamera.position = Players[currentPlayerID].car.get_node("carCamera").position
	mainCamera.rotation = Players[currentPlayerID].car.get_node("carCamera").rotation
	
	mainCamera.current = true  # Set the camera to follow the current player's car
	opA.visible = false  # Hide options A and B
	opB.visible = false
	
	currentPlayerID += 1  # Move to the next player
	
	if currentPlayerID >= len(Players):
		currentPlayerID = 0  # Loop back to the first player if we reach the end

# Start button handler, initializes the game with the selected number of players
func _start_button():
	$"UI/PlayerCount".visible = false  # Hide player count slider
	$"UI/pcountLabel".visible = false  # Hide player count label
	$"UI/StartGame".visible = false  # Hide start button
	
	PlayerCount = pSlider.value  # Get the number of players from the slider
	print("starting,", PlayerCount)

	# Initialize players
	for p in range(PlayerCount):
		var pp = Player.new()  # Create a new player object
		var car = Garage.get_node("Green").duplicate()  # Duplicate the car from the garage
		add_child(car)  # Add the car to the scene
		pp.setCar(car)  # Set the car for the player
		Players.append(pp)  # Add the player to the list of players
		$"PLayers".add_child(pp)  # Add the player to the Players group
		moveCar(pp, Target, PathChoice)  # Move the player to the starting point

	# Animate the camera to the start position
	var cameraTween1 = get_tree().create_tween()
	var cameraTween2 = get_tree().create_tween()
	cameraTween1.tween_property(mainCamera, "position", $"StartCameraPOS".position, 3)
	cameraTween2.tween_property(mainCamera, "rotation", $"StartCameraPOS".rotation, 3)
	cameraTween1.play()
	cameraTween2.play()
	
	await get_tree().create_timer(4).timeout  # Wait for the animation to complete

	# Set up each player's camera
	for p in range(PlayerCount):
		var cam = $"carCamera".duplicate()  # Duplicate the car camera
		var a = cam.position  # Store camera's position
		var b = cam.rotation  # Store camera's rotation
		
		Players[p].car.add_child(cam)  # Attach camera to the car
		Players[p].car.get_node("carCamera").position = a  # Set camera position
		Players[p].car.get_node("carCamera").rotation = b  # Set camera rotation
	
	# Start the game with the spinner phase
	gameState = 1
	gameStateChanged = true

# Option A button handler
func _optionA():
	if gameState == 4:  # If the game is in event state
		print(DebugStandardChoices[Asel]["text"])  # Display option A's text
		gameState = 1  # Move to spinner state
		gameStateChanged = true
		nextPlayer()  # Move to the next player

# Option B button handler
func _optionB():
	if gameState == 4:  # If the game is in event state
		print(DebugStandardChoices[Bsel]["text"])  # Display option B's text
		gameState = 1  # Move to spinner state
		gameStateChanged = true
		nextPlayer()  # Move to the next player

# Example of predefined standard choices for event options
var DebugStandardChoices = [
	{"text":"Daniel", "value":1000, "valueText": "$1000"},
	{"text":"Roderick", "value":26, "valueText": "$26"},
	{"text":"Ayoub", "value":-48, "valueText": "-$48"},
	{"text":"Oliver", "value":696969, "valueText": "$696969"}
]
