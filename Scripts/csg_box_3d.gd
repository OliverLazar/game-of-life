extends CSGBox3D

@export var speed: Vector3 = Vector3(25,50,40)
var time: float = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotation_degrees += speed * delta
	position = Vector3(0, 0.1*sin(time*20), 0)
	time += delta
