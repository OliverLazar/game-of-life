extends Node3D
@export var speed: Vector3 = Vector3(0,150,0)
var spinny_speed: Vector3 = Vector3.ZERO
var spin: bool = false 
var object_center = $".".global_transform.origin



func _process(delta: float) -> void:
	if spin == true:
		rotation_degrees += spinny_speed * delta
		print(object_center)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		spinny_speed = speed
		spin = not spin
		
		
