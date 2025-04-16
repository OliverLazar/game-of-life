extends Node3D

@onready var mainMenu = "res://Scenes/Main Menu.tscn"

# Node references to various elements in the scene, initialized via @onready
@onready var Map = $"NodeMapMath"  # The map that contains nodes for game movement
@onready var testCar = $"Game of Life Bus"  # Reference to a test car, may not be used
@onready var mainCamera = $"MainCamera"  # Reference to the main camera used in the scene
@onready var Garage = $"Garage"  # Reference to the Garage where cars are stored
@onready var Spinner = $"Spinner"
@onready var spinnerPlayer = $"Spinner/AudioStreamPlayer3D"
var SFX
var spinRotVel = 0
var spinTickNumberTracker = 0

# Start Menu UI elements
@onready var pSlider = $"UI/PlayerCount"  # Slider for selecting the number of players
@onready var start = $"UI/StartGame"  # Button to start the game

# Buttons for event options
@onready var opA = $"UI/OptionA"  # Option A button in the UI
@onready var opB = $"UI/OptionB"  # Option B button in the UI
@onready var opC = $"UI/OptionC"  # Option B button in the UI
var Asel = 0  # Option A selection index
var Bsel = 0  # Option B selection index
var Csel = 0

# Topleft UI
@onready var PlayerInfo = $"UI/PlayerHeader"
var statusText

# audio
@onready var audio2 = $"AudioStreamPlayer2"
@onready var sound_button = $"UI/Sound"
var audiostatus = true
var has_processed = false

var PlayerCount = 3  # Default number of players

# Cooldown variables controlling the flow of the game
var cooldown_gameStart = 60*5  # Cooldown time before starting the game
var cooldown_movement = 30  # Cooldown time for each movement step
var cooldown_endMovement = 60*2  # Cooldown time before ending movement

# Player Movement variables
var currentPlayerID: int = 0  # Tracks the current player ID (index)
var Roll = 0  # Current roll value for the dice (spinner)
var RollStoage = 0  # Stores the roll value during a special blue event
#var Target = 0  # Target destination for the current player's movement
#var PathChoice = ""  # Stores the path choice for the player (for special squares)
var d = Vector3.ZERO  # Target position for the car to move to
var r = Vector3.ZERO  # Target rotation for the car

var SubEvent  # the blue/red subevent that is currently happening
var BlueExtA
var BlueExtB

var rollMaxMaxMax = 10 # spinner debug roll 1-rollMax
var currentPlayerTurnAgain = false # to fix camera bug on bonus turn

@onready var abp = $"BluePeg"
@onready var app = $"PinkPeg"
@onready var cbp = $"BlueChildPeg"
@onready var cpp = $"PinkChildPeg"

@onready var adultPegs = [abp, app]
@onready var childPegs = [cbp, cpp]

var PoorEnd = 1
var RichEnd = 1

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
# 7 -> Game Over

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio2.play()
	
	SFX = AudioStreamPlayer3D.new()
	$"MainCamera".add_child(SFX)
	#SFX.loop = false
	
	statusText = Label.new()
	statusText.name = "statusText"
	
	statusText.size = Vector2(557, 112)
	statusText.position = Vector2(300, 20)
	statusText.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	statusText.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var ls = LabelSettings.new()
	ls.font_size = 50
	statusText.label_settings = ls
	$"UI".add_child(statusText)
	#statusText.label_settings.font_color = Color.
	
	statusText.create_tween()
	
	PlayerInfo.get_node("Player").visible = false
	PlayerInfo.get_node("Money").visible = false
	PlayerInfo.get_node("Sprite2D").modulate.a = 0.96
	PlayerInfo.get_node("Sprite2D").visible = false
	
	#spinnerPlayer.stream = "res://Media/minecraft_click.mp3"
		
	# Connect the start button and option buttons to their respective functions
	start.pressed.connect(self._start_button)
	opA.pressed.connect(self._optionA)
	opB.pressed.connect(self._optionB)
	opC.pressed.connect(self._optionC)
	mainCamera.current = true  # Set the main camera as the active camera

func sortNet(p):
	return p.NET

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:	
	# Audio
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
			
	if Cooldown:
		Cooldown -= 1
		return
		
	var gamedone = len(Players) > 0 and not gameState == 7
	for p in Players:
		if not p.Done:
			gamedone = false
	if gamedone:
		print("Game Over")
		
		Players.sort_custom(sortNet)
		for i in range(len(Players)):
			moveCar(Players[i], i+1, "Podium")
			
		var cameraTween1 = get_tree().create_tween()
		var cameraTween2 = get_tree().create_tween()
		cameraTween1.tween_property(mainCamera, "position", $"endCamera".position, 1.5)
		cameraTween2.tween_property(mainCamera, "rotation", $"endCamera".rotation, 1.5)
		cameraTween1.play()
		cameraTween2.play()
		
		statusText.text = "Player "+str((currentPlayerID+1))+" Won!"
		statusText.modulate = Color(0.0, 1.0, 0.0,1.0)
		statusText.label_settings.outline_color = Color(0.0,0.0,0.0,1.0)
		statusText.label_settings.outline_size = 10
		var lower_taper_fade = get_tree().create_tween()
		lower_taper_fade.tween_property(statusText, "modulate", Color(0.0, 1.0, 0.0, 0.0), 10)
		lower_taper_fade.play()
		
		gameState = 7
		gameStateChanged = true
		
	if len(Players) - 1 >= currentPlayerID:
		PlayerInfo.get_node("Money").set_text("$" + str(Players[currentPlayerID].Cash))
	
	if gameStateChanged:
		gameStateChanged = false  # Reset the game state change flag

		if gameState == 1:  # Spin the spinner (prepare the camera)
			# Set player text
			PlayerInfo.get_node("Player").visible = true
			PlayerInfo.get_node("Money").visible = true
			PlayerInfo.get_node("Sprite2D").visible = true
			PlayerInfo.get_node("Player").set_text("Player " + str(currentPlayerID%len(Players)+1))		
			# Tween (smooth transition) the camera to the spinner's position and rotation
			var cameraTween1 = get_tree().create_tween()
			var cameraTween2 = get_tree().create_tween()
			cameraTween1.tween_property(mainCamera, "position", $"SpinnerCameraPOS".position, 1.5)
			cameraTween2.tween_property(mainCamera, "rotation", $"SpinnerCameraPOS".rotation, 1.5)
			cameraTween1.play()
			cameraTween2.play()
			
			await get_tree().create_timer(3).timeout  # Wait for the camera transition to finish

		if gameState == 2:  # Move the player's car
			opA.visible = false
			opB.visible = false
			opC.visible = false
			
			Players[currentPlayerID].car.get_node("carCamera").current = true  # Set the player's car camera active
			
			#Target = Players[currentPlayerID].spot
			#PathChoice = Players[currentPlayerID].spotExt
			#print("-", currentPlayerID, " ", Players[currentPlayerID].Target, Players[currentPlayerID].PathChoice)
			
			var n = Map.get_node(str(Players[currentPlayerID].Target)+str(Players[currentPlayerID].PathChoice))
			if n.has_meta("teleport"):
				Players[currentPlayerID].Target = n.get_meta("teleport")
				Players[currentPlayerID].PathChoice = n.get_meta("teleportExt")
			else:
				Players[currentPlayerID].Target = Players[currentPlayerID].spot + 1  # Set the target spot for the player's movement
				Players[currentPlayerID].PathChoice = Players[currentPlayerID].spotExt  # Get the path choice from the player
			#print(currentPlayerID, " ", Players[currentPlayerID].Target, Players[currentPlayerID].PathChoice)
			moveCar(Players[currentPlayerID], Players[currentPlayerID].Target, Players[currentPlayerID].PathChoice)  # Move the car to the target
			Roll -= 1  # Decrease roll after move
			gameState = 3  # Wait for the car to finish moving
			
			if not SFX.playing:
				SFX.stream = load("res://Media/square.mp3")
				SFX.volume_db = 2
				if audiostatus: SFX.play()

		if gameState == 4:  # Regular event (choose between two options)
			Players[currentPlayerID].ActionCards += 1
			
			SFX.stream = load("res://Media/get_card.mp3")
			SFX.volume_db = 50
			if audiostatus: SFX.play(0.4)
			
			Csel = randi_range(0, len(ActionCards)-1)  # Randomly select option C
				
			# Set the text and value of each option
			opC.get_node("image").texture = load(ActionCards[Csel]["path"])
			
			opC.visible = true  # Make option A visible
			
		if gameState == 5:
			if SubEvent == "marriage":
				SFX.stream = load("res://Media/weddingmarchpiano.mp3")
				audio2.volume_db = -80
				if audiostatus: SFX.play()
				add_child(Players[currentPlayerID].PegTheCar(adultPegs, childPegs))
				Players[currentPlayerID]._process(delta)
				await get_tree().create_timer(8).timeout
				audio2.volume_db = 0
				nextPlayer()
				gameState = 1
				gameStateChanged = true
			
		if gameState == 6:
			SFX.stream = load("res://Media/get_card.mp3")
			SFX.volume_db = 20
			
			if SubEvent == "career": # choose career or college
				# Set the text and value of each option
				opA.get_node("image").texture = load("res://Cards/CARD BACK (CAREER).jpg")
				opB.get_node("image").texture = load("res://Cards/CARD BACK (COLLEGE).jpg")
				
				opA.visible = true  # Make option A visible
				opB.visible = true  # Make option B visible
			if SubEvent == "poorJob":
				BlueExtA = randi_range(0, len(PoorJobs)-1)  # Randomly select option A
				BlueExtB = randi_range(0, len(PoorJobs)-1)  # Randomly select option B
				while BlueExtB == BlueExtA:  # Ensure the two options are different
					BlueExtB = randi_range(0, len(PoorJobs)-1)
					
				# Set the text and value of each option
				opA.get_node("image").texture = load(PoorJobs[BlueExtA]["path"])
				opB.get_node("image").texture = load(PoorJobs[BlueExtB]["path"])
				
				opA.visible = true  # Make option A visible
				opB.visible = true  # Make option B visible
			if SubEvent == "richJob":
				BlueExtA = randi_range(0, len(RichJobs)-1)  # Randomly select option A
				BlueExtB = randi_range(0, len(RichJobs)-1)  # Randomly select option B
				while BlueExtB == BlueExtA:  # Ensure the two options are different
					BlueExtB = randi_range(0, len(RichJobs)-1)
					
				# Set the text and value of each option
				print(BlueExtA, RichJobs[BlueExtA]["path"])
				var test = load(RichJobs[BlueExtA]["path"])
				print(test)
				opA.get_node("image").texture = test
				opB.get_node("image").texture = load(RichJobs[BlueExtB]["path"])
				
				opA.visible = true  # Make option A visible
				opB.visible = true  # Make option B visible
			if SubEvent == "fork":
				# Set the text and value of each option
				opA.get_node("image").texture = load("res://Media/Left.jpg")
				opB.get_node("image").texture = load("res://Media/Right.jpg")
				
				opA.visible = true  # Make option A visible
				opB.visible = true  # Make option B visible
			if SubEvent == "house":
				var run = false
				
				var safe = []
				for House in Housing:
					if Players[currentPlayerID].Cash >= House["price"]:
						safe.append(House)
						
				var upperbound = len(safe)
				run = upperbound >= 2
				
				#print(run, upperbound, safe)
				
				if run == true:
					BlueExtA = randi_range(0, upperbound - 1)  # Randomly select option A
					BlueExtB = randi_range(0, upperbound - 1)  # Randomly select option B
					while BlueExtB == BlueExtA:  # Ensure the two options are different
						BlueExtB = randi_range(0, upperbound - 1)
						
					# Set the text and value of each option
					opA.get_node("image").texture = load(Housing[BlueExtA]["path"])
					opB.get_node("image").texture = load(Housing[BlueExtB]["path"])
					
					opA.visible = true  # Make option A visible
					opB.visible = true  # Make option B visible
				else:
					SFX.volume_db = -50
					if RollStoage > 0:
						gameState = 2
						Roll = RollStoage
					else:
						gameState = 1
					gameStateChanged = true
					
			if SubEvent == "baby":
				var children = randi_range(1, 3)
				
				if children == 1:
					statusText.text = "+1 Child"
				elif children == 2:
					statusText.text = "Twins!"
				else:
					statusText.text = "Triplets!"
					
				statusText.modulate = Color(0.2, 0.4, 0.8,1.0)
				statusText.label_settings.outline_color = Color(0.0,0.0,0.0,1.0)
				statusText.label_settings.outline_size = 10
				var lower_taper_fade = get_tree().create_tween()
				lower_taper_fade.tween_property(statusText, "modulate", Color(0.2, 0.4, 0.0, 0.0), 2)
				lower_taper_fade.play()
				
				for i in range(children):
					add_child(Players[currentPlayerID].PegTheCar(adultPegs, childPegs))
				if RollStoage > 0:
					gameState = 2
					Roll = RollStoage
				else:
					gameState = 1
				gameStateChanged = true
			if SubEvent == "end":
				# Set the text and value of each option
				opA.get_node("image").texture = load("res://Media/Left.jpg")
				opB.get_node("image").texture = load("res://Media/Right.jpg")
				
				opA.visible = true  # Make option A visible
				opB.visible = true  # Make option B visible
				
			if audiostatus: SFX.play(0.4)
	
	# spin the spiiner
	if gameState == 1 and spinRotVel > 0:
		Spinner.rotate_y(spinRotVel*delta)
		spinRotVel -= 0.1
		
		var num = (((180 - (int(Spinner.rotation_degrees.y) % 180)) / 36 - 1) % 10)
		if num == 0: num = 10
		if num == -1: num = 9
		
		num *= 1
		#num = 14
		
		if num != spinTickNumberTracker:
			if audiostatus: spinnerPlayer.play(0.6)
			spinTickNumberTracker = num
		
		if spinRotVel <= 0:
			print(num)
			Roll = num
			gameState = 2  # Start the movement phase
			gameStateChanged = true
			Cooldown = 60
			
			statusText.text = str(Roll)
			statusText.modulate = Color(0.9, 0.9, 0.9,1.0)
			statusText.label_settings.outline_color = Color(0.0,0.0,0.0,1.0)
			statusText.label_settings.outline_size = 10
			var lower_taper_fade = get_tree().create_tween()
			lower_taper_fade.tween_property(statusText, "modulate", Color(0.9, 0.9, 0.9, 0.0), 2)
			lower_taper_fade.play()
			

	# Handle movement and game state changes during the movement phase
	if gameState == 3:		
		var p = Players[currentPlayerID]
		if p.lerpWeight >= 0.2:  # Check if the car has finished moving
			var node = Map.get_node(str(p.spot)+str(p.spotExt))
			var nodeType = node.get_meta("Type")
			
			# Different actions based on the type of square the player lands on
			if nodeType == "payday":
				p.Cash += p.Salary  # Pay the player their salary
				SFX.stream = load("res://Media/get_money.mp3")
				SFX.volume_db = 50
				if audiostatus: SFX.play()
				
				statusText.text = "+" + str(p.Salary)
				statusText.modulate = Color(0.0, 1.0, 0.0,1.0)
				statusText.label_settings.outline_color = Color(0.0,0.0,0.0,1.0)
				statusText.label_settings.outline_size = 10
				var lower_taper_fade = get_tree().create_tween()
				lower_taper_fade.tween_property(statusText, "modulate", Color(0.0, 1.0, 0.0, 0.0), 2)
				lower_taper_fade.play()
			elif nodeType == "stop":
				SubEvent = node.get_meta("Subevent")
				gameState = 5  # Transition to stop event
				gameStateChanged = true
				Roll = 0
			elif nodeType == "event":				
				SubEvent = node.get_meta("Subevent")
				BlueExtA = node.get_meta("extA")
				BlueExtB = node.get_meta("extB")
				
				gameState = 6  # Branch event
				gameStateChanged = true
				RollStoage = Roll  # Store the current roll value for use later
				Roll = 0
			elif nodeType == "END":
				print("Player ", currentPlayerID, " reached END")
				Roll = 0
				Players[currentPlayerID].Done = true

			# If there are still more moves to make, move to the next square
			if Roll > 0:
				gameState = 2
				gameStateChanged = true
			elif gameState == 3:
				if nodeType == "default":
					gameState = 4  # Return to regular event if no special event occurs
					gameStateChanged = true
				elif nodeType == "payday":
					nextPlayer()
					gameState = 1
					gameStateChanged = true

	# Process all players each frame (if needed for player updates)
	for car in Players:
		car._process(delta)

# Handle input events, such as pressing the accept button (e.g., for rolling)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if gameState == 1 and spinRotVel < 1:  # If the game is in the spin state
			#Roll = randi_range(1, rollMaxMaxMax)  # Generate a random roll
			#print("Roll: ", Roll)
			#gameState = 2  # Start the movement phase
			#gameStateChanged = true
			
			spinRotVel = 20.0 + randf_range(-1.5, 1.5)
		if gameState == 7:
			get_tree().change_scene_to_file(mainMenu)

# Move the car to the target position and rotation
func moveCar(player, target, ext):
	target = int(target)
	
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
var nextPlayerLoop = false
var depth = 0
func nextPlayer():
	depth += 1
	if depth == 5:
		return
	
	var adjust = 0
	if currentPlayerTurnAgain:
		adjust = 1
		currentPlayerTurnAgain = false
	
	if not nextPlayerLoop:
		PlayerInfo.get_node("Money").set_text("$" + str(Players[currentPlayerID + adjust].Cash))
		
		mainCamera.position = Players[currentPlayerID + adjust].car.position + Vector3.UP*5
		mainCamera.rotation = Players[currentPlayerID + adjust].car.rotation
		
		mainCamera.current = true  # Set the camera to follow the current player's car
		opA.visible = false  # Hide options A and B
		opB.visible = false
		opC.visible = false
	
	currentPlayerID += 1  # Move to the next player
	if currentPlayerID >= len(Players):
		currentPlayerID = 0
	
	if Players[currentPlayerID].PassTurns > 0:
		Players[currentPlayerID].PassTurns -= 1
		statusText.text = "Skip Player "+str((currentPlayerID+1))

		statusText.modulate = Color(1.0, 0.1, 0.0,1.0)
		statusText.label_settings.outline_color = Color(0.0,0.0,0.0,1.0)
		statusText.label_settings.outline_size = 10
		var lower_taper_fade = get_tree().create_tween()
		lower_taper_fade.tween_property(statusText, "modulate", Color(1.0, 0.1, 0.0, 0.0), 2)
		lower_taper_fade.play()
		
		nextPlayer()
	elif Players[currentPlayerID].Done:
		#currentPlayerID += 1  # Move to the next player
		Players[currentPlayerID].NET += round(Players[currentPlayerID].Salary*0.30)
		nextPlayer()
		
	nextPlayerLoop = false
	depth = 0
	Cooldown = cooldown_endMovement

# Start button handler, initializes the game with the selected number of players
func _start_button():
	$"UI/PlayerCount".visible = false  # Hide player count slider
	$"UI/pcountLabel".visible = false  # Hide player count label
	$"UI/StartGame".visible = false  # Hide start button
	
	SFX.stream = load("res://Media/powerUp.wav")
	SFX.volume_db = 5
	if audiostatus: SFX.play()
	
	PlayerCount = pSlider.value  # Get the number of players from the slider
	print("starting,", PlayerCount)
	
	var car_possbile = Garage.get_children()
	# Initialize players
	for p in range(PlayerCount):
		var pp = Player.new()  # Create a new player object
		var n = randi_range(0,len(car_possbile)-1)
		var car = car_possbile[n].duplicate()  # Duplicate the car from the garage
		car.name = car_possbile[n].name
		car_possbile.pop_at(n)
		add_child(car)  # Add the car to the scene
		pp.setCar(car)  # Set the car for the player
		Players.append(pp)  # Add the player to the list of players
		$"PLayers".add_child(pp)  # Add the player to the Players group
		moveCar(pp, Players[currentPlayerID].Target, Players[currentPlayerID].PathChoice)  # Move the player to the starting point

	# Animate the camera to the start position
	var cameraTween1 = get_tree().create_tween()
	var cameraTween2 = get_tree().create_tween()
	cameraTween1.tween_property(mainCamera, "position", $"StartCameraPOS".position, 1)
	cameraTween2.tween_property(mainCamera, "rotation", $"StartCameraPOS".rotation, 1)
	cameraTween1.play()
	cameraTween2.play()
	
	await get_tree().create_timer(1.4).timeout  # Wait for the animation to complete

	# Set up each player's camera
	for p in range(PlayerCount):
		var cam = $"carCamera".duplicate()  # Duplicate the car camera
		var a = cam.position  # Store camera's position
		var b = cam.rotation  # Store camera's rotation
		
		Players[p].car.add_child(cam)  # Attach camera to the car
		Players[p].car.get_node("carCamera").position = a  # Set camera position
		Players[p].car.get_node("carCamera").rotation = b  # Set camera rotation
	
		var peh = Players[p].PegTheCar(adultPegs, childPegs)
		add_child(peh)
		Players[p].Disadoption()
	
	# Start the game with the spinner phase
	gameState = 1
	gameStateChanged = true

# Option A button handler
func _optionA():
	if gameState == 4:  # If the game is in event state
		gameState = 1  # Move to spinner state
		gameStateChanged = true
		nextPlayer()  # Move to the next player
	if gameState == 6:
		if SubEvent == "career":
			# career
			pass
		if SubEvent == "poorJob":
			Players[currentPlayerID].Salary = PoorJobs[BlueExtA]["salary"]
		if SubEvent == "richJob":
			Players[currentPlayerID].Salary = RichJobs[BlueExtA]["salary"]
		if SubEvent == "fork":
			Players[currentPlayerID].spotExt = BlueExtA
		if SubEvent == "house":
			Players[currentPlayerID].Cash -= Housing[BlueExtA]["price"]
			Players[currentPlayerID].HouseValue =Housing[BlueExtA]["price"]
			statusText.text = "-" + str(Housing[BlueExtA]["price"])
			statusText.modulate = Color(1.0, 0.0, 0.0,1.0)
			statusText.label_settings.outline_color = Color(0.0,0.0,0.0,1.0)
			statusText.label_settings.outline_size = 10
			var lower_taper_fade = get_tree().create_tween()
			lower_taper_fade.tween_property(statusText, "modulate", Color(1.0, 0.0, 0.0, 0.0), 2)
			lower_taper_fade.play()
			SFX.stream = load("res://Media/lose_money.mp3")
			SFX.volume_db = 5
			if audiostatus: SFX.play()
		if SubEvent == "end":
			moveCar(Players[currentPlayerID], PoorEnd, "poor")
			PoorEnd += 1
			Players[currentPlayerID].Done = true
			Roll = 0
			RollStoage = 0
			
			Players[currentPlayerID].NET += (Players[currentPlayerID].Pegs-2)*30000
			Players[currentPlayerID].NET += round(Players[currentPlayerID].HouseValue*1.25)
			Players[currentPlayerID].NET += Players[currentPlayerID].ActionCards * 5000
			
		if RollStoage > 0:
			Roll = RollStoage
			gameState = 2
			gameStateChanged = true
		else:
			gameState = 1  # Move to spinner state
			gameStateChanged = true
			nextPlayer()  # Move to the next player
			

# Option B button handler
func _optionB():
	if gameState == 4:  # If the game is in event state
		gameState = 1  # Move to spinner state
		gameStateChanged = true
		nextPlayer()  # Move to the next player
	if gameState == 6:
		if SubEvent == "career":
			# college
			Players[currentPlayerID].spotExt = BlueExtB
			Players[currentPlayerID].Cash -= 100000
		if SubEvent == "poorJob":
			Players[currentPlayerID].Salary = PoorJobs[BlueExtB]["salary"]
		if SubEvent == "richJob":
			Players[currentPlayerID].Salary = RichJobs[BlueExtB]["salary"]
		if SubEvent == "fork":
			Players[currentPlayerID].spotExt = BlueExtB
		if SubEvent == "house":
			Players[currentPlayerID].Cash -= Housing[BlueExtB]["price"]
			Players[currentPlayerID].HouseValue =Housing[BlueExtB]["price"]
			statusText.text = "-" + str(Housing[BlueExtB]["price"])
			statusText.modulate = Color(1.0, 0.0, 0.0,1.0)
			statusText.label_settings.outline_color = Color(0.0,0.0,0.0,1.0)
			statusText.label_settings.outline_size = 10
			var lower_taper_fade = get_tree().create_tween()
			lower_taper_fade.tween_property(statusText, "modulate", Color(1.0, 0.0, 0.0, 0.0), 2)
			lower_taper_fade.play()
			SFX.stream = load("res://Media/lose_money.mp3")
			SFX.volume_db = 5
			if audiostatus: SFX.play()
		if SubEvent == "end":
			moveCar(Players[currentPlayerID], RichEnd, "rich")
			RichEnd += 1
			Players[currentPlayerID].Done = true
			Roll = 0
			RollStoage = 0
			
			Players[currentPlayerID].NET += (Players[currentPlayerID].Pegs-2)*15000
			Players[currentPlayerID].NET += round(Players[currentPlayerID].HouseValue*2)
			Players[currentPlayerID].NET += Players[currentPlayerID].ActionCards * 5000
			
		if RollStoage > 0:
			Roll = RollStoage
			gameState = 2
			gameStateChanged = true
		else:
			gameState = 1  # Move to spinner state
			gameStateChanged = true
			nextPlayer()  # Move to the next player
			
			
func _optionC():
	Players[currentPlayerID].ActionCards += 1
	Csel = ActionCards[Csel]
	for type in Csel["types"]:
		if type == 0: #money
			var lower_taper_fade = get_tree().create_tween()
			if Csel["value"] > 0:
				statusText.text = "+" + str(Csel["value"])
				statusText.modulate = Color(0.0, 1.0, 0.0,1.0)
				statusText.label_settings.outline_color = Color(0.0,0.0,0.0,1.0)
				statusText.label_settings.outline_size = 10
				lower_taper_fade.tween_property(statusText, "modulate", Color(0.0, 1.0, 0.0, 0.0), 2)
				lower_taper_fade.play()
			else:
				statusText.text = "-" + str(Csel["value"])
				statusText.modulate = Color(1.0, 0.0, 0.0, 1.0)
				statusText.label_settings.outline_color = Color(0.0,0.0,0.0,1.0)
				statusText.label_settings.outline_size = 10
				lower_taper_fade.tween_property(statusText, "modulate", Color(1.0, 0.0, 0.0, 0.0), 2)
				lower_taper_fade.play()
			Players[currentPlayerID].Cash += Csel["value"]
			if Csel["value"] > 0:
				SFX.stream = load("res://Media/get_money.mp3")
				SFX.volume_db = 5
				if audiostatus: SFX.play()
			else:
				SFX.stream = load("res://Media/lose_money.mp3")
				SFX.volume_db = 5
				if audiostatus: SFX.play()
		if type == 1: #bonus turn
			currentPlayerID -= 1
			currentPlayerTurnAgain = true
			
			statusText.text = "Bonus Turn"
			statusText.modulate = Color(0.0, 1.0, 0.0,1.0)
			statusText.label_settings.outline_color = Color(0.0,0.0,0.0,1.0)
			statusText.label_settings.outline_size = 10
			var lower_taper_fade = get_tree().create_tween()
			lower_taper_fade.tween_property(statusText, "modulate", Color(0.0, 1.0, 0.0, 0.0), 2)
			lower_taper_fade.play()
		if type == 2: #miss a turn
			Players[currentPlayerID].PassTurns += 1
		if type == 3: #money per child
			var a = Csel["value"] * max(Players[currentPlayerID].Pegs-2, 0)
			Players[currentPlayerID].Cash += a
			if Players[currentPlayerID].Pegs > 2:
				SFX.stream = load("res://Media/get_money.mp3")
				SFX.volume_db = 5
				if audiostatus: SFX.play()
				
				statusText.text = "+" + str(a)
				statusText.modulate = Color(0.0, 1.0, 0.0,1.0)
				statusText.label_settings.outline_color = Color(0.0,0.0,0.0,1.0)
				statusText.label_settings.outline_size = 10
				var lower_taper_fade = get_tree().create_tween()
				lower_taper_fade.tween_property(statusText, "modulate", Color(0.0, 1.0, 0.0, 0.0), 2)
				lower_taper_fade.play()
		if type == 4: #procreate
			Players[currentPlayerID].Pegs += 1
		if type == 5 and Players[currentPlayerID].Pegs > 2: #adoption
			statusText.text = "-1 Child ~ Bonus Turn"
			statusText.modulate = Color(1.0, 0.2, 0.0,1.0)
			statusText.label_settings.outline_color = Color(0.0,0.0,0.0,1.0)
			statusText.label_settings.outline_size = 10
			var lower_taper_fade = get_tree().create_tween()
			lower_taper_fade.tween_property(statusText, "modulate", Color(1.0, 0.2, 0.0, 0.0), 2)
			lower_taper_fade.play()
			
			Players[currentPlayerID].Disadoption()
		if type == 6 and Players[currentPlayerID].Pegs > 2: # child = turn
			statusText.text = "-1 Child"
			statusText.modulate = Color(1.0, 0.0, 0.0,1.0)
			statusText.label_settings.outline_color = Color(0.0,0.0,0.0,1.0)
			statusText.label_settings.outline_size = 10
			var lower_taper_fade = get_tree().create_tween()
			lower_taper_fade.tween_property(statusText, "modulate", Color(1.0, 0.0, 0.0, 0.0), 2)
			lower_taper_fade.play()
			
			Players[currentPlayerID].Disadoption()
			currentPlayerID -= 1
			currentPlayerTurnAgain = true
			
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

# 0 = money
# 1 = bonus turn
# 2 = lose turn
# 3 = child benefits
# 4 = give birth
# 5 = lose child
var ActionCards = [
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (2).jpg", "value":5000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (3).jpg", "value":5000, "types":[0,1]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (4).jpg", "value":15000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (5).jpg", "value":20000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (6).jpg", "value":20000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (7).jpg", "value":25000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (8).jpg", "value":30000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (9).jpg", "value":30000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (10).jpg", "value":35000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (11).jpg", "value":45000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (12).jpg", "value":65000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (13).jpg", "value":80000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (14).jpg", "value":100000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (15).jpg", "value":100000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (16).jpg", "value":100000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (17).jpg", "value":30000, "types":[3]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (18).jpg", "value":35000, "types":[3]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (19).jpg", "value":-5000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (20).jpg", "value":-10000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (21).jpg", "value":-10000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (22).jpg", "value":-15000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (23).jpg", "value":-25000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (24).jpg", "value":-25000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (25).jpg", "value":-40000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (26).jpg", "value":-50000, "types":[0]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (27).jpg", "value":0, "types":[1]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (28).jpg", "value":0, "types":[1]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (29).jpg", "value":0, "types":[1]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (30).jpg", "value":0, "types":[1]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (31).jpg", "value":0, "types":[2]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (32).jpg", "value":0, "types":[2]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (33).jpg", "value":0, "types":[2]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (34).jpg", "value":0, "types":[2]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (35).jpg", "value":0, "types":[5]},
	{"path":"res://Cards/CARD TEMPLATE (ACTION) (36).jpg", "value":0, "types":[6]},
]

# Jobs that dont pay well
var PoorJobs = [
	{"path":"res://Cards/CARD TEMPLATE (COLLEGE) (9).jpg", "name":"Salesperson", "salary":40000},
	{"path":"res://Cards/CARD TEMPLATE (COLLEGE) (10).jpg", "name":"Hairstylist", "salary":45000},
	{"path":"res://Cards/CARD TEMPLATE (COLLEGE) (11).jpg", "name":"Police Officer", "salary":55000},
	{"path":"res://Cards/CARD TEMPLATE (COLLEGE) (12).jpg", "name":"Mechanic", "salary":55000},
	{"path":"res://Cards/CARD TEMPLATE (COLLEGE) (13).jpg", "name":"Athlete", "salary":60000},
	{"path":"res://Cards/CARD TEMPLATE (COLLEGE) (14).jpg", "name":"Entertainment", "salary":65000}
]

# Jobs that do pay well
var RichJobs = [
	{"path":"res://Cards/CARD TEMPLATE (COLLEGE) (2).jpg", "name":"Teacher", "salary":65000},
	{"path":"res://Cards/CARD TEMPLATE (COLLEGE) (3).jpg", "name":"Computer Designer", "salary":75000},
	{"path":"res://Cards/CARD TEMPLATE (COLLEGE) (4).jpg", "name":"Accountant", "salary":85000},
	{"path":"res://Cards/CARD TEMPLATE (COLLEGE) (5).jpg", "name":"Veterinarian", "salary":95000},
	{"path":"res://Cards/CARD TEMPLATE (COLLEGE) (6).jpg", "name":"Lawyer", "salary":110000},
	{"path":"res://Cards/CARD TEMPLATE (COLLEGE) (7).jpg", "name":"Doctor", "salary":125000}
]

var Housing = [
	{"path":"res://Cards/CARD TEMPLATE (HOUSE) (2).jpg", "price":1000},
	{"path":"res://Cards/CARD TEMPLATE (HOUSE) (3).jpg", "price":5000},
	{"path":"res://Cards/CARD TEMPLATE (HOUSE) (4).jpg", "price":20000},
	{"path":"res://Cards/CARD TEMPLATE (HOUSE) (5).jpg", "price":35000},
	{"path":"res://Cards/CARD TEMPLATE (HOUSE) (6).jpg", "price":50000},
	{"path":"res://Cards/CARD TEMPLATE (HOUSE) (7).jpg", "price":65000},
	{"path":"res://Cards/CARD TEMPLATE (HOUSE) (8).jpg", "price":85000},
	{"path":"res://Cards/CARD TEMPLATE (HOUSE) (9).jpg", "price":125000},
	{"path":"res://Cards/CARD TEMPLATE (HOUSE) (10).jpg", "price":150000},
	{"path":"res://Cards/CARD TEMPLATE (HOUSE) (11).jpg", "price":200000},
	{"path":"res://Cards/CARD TEMPLATE (HOUSE) (12).jpg", "price":300000},
	{"path":"res://Cards/CARD TEMPLATE (HOUSE) (13).jpg", "price":400000},
	{"path":"res://Cards/CARD TEMPLATE (HOUSE) (14).jpg", "price":500000}
]
