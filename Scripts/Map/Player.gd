class_name Player extends Node3D

var car
var spot = 0
var spotExt = ""

var pDestination = Vector3.ZERO
var rDestination = Vector3(-90, 0, 0)

var lerpWeight = 0
var Speed = 0.01

func _ready():
	pass

func _process(delta: float):
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
	
func setDestination(dest, rot):
	pDestination = dest
	rDestination = rot
	
func activateCamera():
	car.get_node("carCamera").current = true
