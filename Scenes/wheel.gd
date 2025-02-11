extends MeshInstance3D
@export var speed: Vector3 = Vector3(0,360,0)
var time: float = 0

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		rotation_degrees += speed * delta
		position = Vector3(0, 0.1*sin(time*20), 0)
	
	
