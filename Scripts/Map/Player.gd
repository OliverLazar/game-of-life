class_name Player extends Node3D

var car
var spot = 0
var spotExt = ""

var pDestination = Vector3.ZERO
var rDestination = Vector3(-90, 0, 0)

var lerpWeight = 0
var Speed = 0.2

# Game Variables
var Cash = 0
var Salary = 0
var Pegs = 0
var Job = "None"

func _ready():
	pass

func _process(delta: float):
	if car and car.has_node("carCamera"):
		var camera = car.get_node("carCamera")
		camera.position = Vector3(0, 0, 100)
		camera.rotation_degrees = Vector3(0, camera.rotation_degrees.y, 0)
	
	if lerpWeight < 1:
		car.position = lerp(car.position, pDestination, lerpWeight)
		car.rotation_degrees = lerp(car.rotation_degrees, rDestination, lerpWeight)
		lerpWeight += Speed*delta

func setCar(Car):
	car = Car
	car.position = pDestination
	car.rotation_degrees = rDestination
	
func teleport(dest, rot):
	pDestination = dest
	rDestination = rot
	car.position = dest
	car.rotation_degrees = rot
	lerpWeight = 0
	
func setDestination(dest, rot):
	pDestination = dest
	rDestination = rot
	lerpWeight = 0
	
func activateCamera():
	car.get_node("carCamera").current = true
