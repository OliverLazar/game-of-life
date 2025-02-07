class_name Player extends Node3D

var car

var pDestination = Vector3.ZERO
var rDestination = Vector3(-90, 0, 0)

var lerpWeight = 0
var Speed = 0.01

func _ready():
	pass

func _process(delta: float):
	# lerp position
	if lerpWeight < 1:
		car.position = lerp(car.position, pDestination, lerpWeight)
		lerpWeight += Speed*delta

func setCar(Car):
	car = Car
	car.position = pDestination
	car.rotation_degrees = rDestination
