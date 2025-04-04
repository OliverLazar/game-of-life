# The Player class controls the player's car, its movement, camera handling, 
# and manages basic game-related variables (like Cash, Salary, etc.).
class_name Player extends Node3D

# Reference to the player's car node
var car

# The player's current spot (could refer to their position in some context)
var spot = 0

# Extended spot info, likely used for more specific location data
var spotExt = ""

# The target destination for the car's position (Vector3 for 3D coordinates)
var pDestination = Vector3.ZERO

# The target rotation for the car (Vector3 for 3D rotation in degrees)
var rDestination = Vector3(-90, 0, 0)

# Weight for linear interpolation (lerp) to gradually move the car towards its destination
var lerpWeight = 0

# The speed of the car's movement and rotation (used in lerp)
var Speed = 0.2

# Game variables related to the player's progress
var Cash = 0  # Player's cash amount
var Salary = 0  # Player's salary
var Pegs = 0  # Progress or achievements (purpose not clear)
var pegList = []
var Job = "None"  # The player's current job, initially set to "None"
var PassTurns = 0
var Done = false

# Called when the player node is ready and added to the scene
func _ready():
	pass  # Currently no setup logic when the player is initialized

# Called every frame to update the player
func _process(delta: float):
	# Check if the car exists and has a camera node attached to it
	if car and car.has_node("carCamera"):
		var camera = car.get_node("carCamera")  # Get the car's camera node
		
		# Set the camera's position to be in front of the car (100 units along Z-axis)
		camera.position = Vector3(0, 0, 100)
		
		# Set the camera's rotation to match the car's Y-rotation, but keep X and Z rotations at 0
		camera.rotation_degrees = Vector3(0, camera.rotation_degrees.y, 0)
	
	# If lerpWeight is less than 1, it means the car is still moving towards its destination
	if lerpWeight < 1:
		# Use linear interpolation (lerp) to gradually move the car towards its destination
		car.position = lerp(car.position, pDestination, lerpWeight)
		
		# Interpolate the car's rotation towards the target rotation
		car.rotation_degrees = lerp(car.rotation_degrees, rDestination, lerpWeight)
		
		# Increment lerpWeight based on Speed and delta time to control the smoothness
		lerpWeight += Speed * delta
		
	# bring pegs
	for i in range(len(self.pegList)):
		var x = i % 2
		var y = floor(i / 2)
		self.pegList[i].position = self.car.position + Vector3.UP
		self.pegList[i].rotation = self.car.rotation + Vector3.RIGHT*deg_to_rad(90)
		
		#self.pegList[i].position += self.pegList[i].transform.basis.x*5
		
		self.pegList[i].position += -self.pegList[i].transform.basis.x*8.3 - self.pegList[i].transform.basis.z*0.8\
		 + self.pegList[i].transform.basis.x*5*y - self.pegList[i].transform.basis.z*5*x

# Sets the car to the specified Car node, and positions it at the target destination
func setCar(Car):
	car = Car  # Assign the Car object to the player
	car.position = pDestination  # Set the car's position to the target destination
	car.rotation_degrees = rDestination  # Set the car's rotation to the target rotation

# Teleports the car immediately to a new position (dest) and rotation (rot), bypassing interpolation
func teleport(dest, rot):
	pDestination = dest  # Update the target destination
	rDestination = rot  # Update the target rotation
	car.position = dest  # Set the car's position immediately
	car.rotation_degrees = rot  # Set the car's rotation immediately
	lerpWeight = 0  # Reset lerpWeight to 0, stopping any ongoing movement interpolation

# Sets a new target destination and rotation for the car
# The car will begin moving towards this new position with smooth interpolation
func setDestination(dest, rot):
	pDestination = dest  # Update the target position for the car
	rDestination = rot  # Update the target rotation for the car
	lerpWeight = 0  # Reset lerpWeight to start moving smoothly from the current position

# Activates the car's camera to make it the active camera for the scene
func activateCamera():
	car.get_node("carCamera").current = true  # Set the car's camera node to be the active one

func PegTheCar(adultPegs, childPegs):
	var peg 
	if self.Pegs < 10:		
		if self.Pegs < 2:
			peg = adultPegs.pick_random()
		else:
			peg = childPegs.pick_random()
		
		self.Pegs += 1
			
		#var x = self.Pegs % 2
		#var y = floor(self.Pegs / 2)
		
		var dpeg = peg.duplicate()
		dpeg.name = str(self.Pegs)
		#self.car.add_child(dpeg)
		
		#dpeg.position = Vector3.ZERO + Vector3.UP #self.pDestination #self.car.position
		self.pegList.append(dpeg)
		return dpeg
		
	
func Disadoption():
	if self.Pegs > 2:
		var killed = self.pegList.pop_back()
		killed.queue_free()
		self.Pegs -= 1
