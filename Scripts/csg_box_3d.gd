extends CSGBox3D

@export var speed: Vector3 = Vector3(25,50,40)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotation_degrees += speed * delta
