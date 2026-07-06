extends Node3D

var velocity = Vector3.ZERO
var gravity = Vector3.DOWN
var on_ground = false

@export var MAX_SPEED = 10.0
@export var STEERING_STRENGTH = 5.0

func _physics_process(delta: float) -> void:
	var front = 2.0
	var normal = []
	if $Front.is_colliding():
		front = ($Front.global_position - $Front.get_collision_point()).y
		normal.append($Front.get_collision_normal())
	var back = 2.0
	if $Back.is_colliding():
		back = ($Back.global_position - $Back.get_collision_point()).y
		normal.append($Back.get_collision_normal())


	if on_ground:
		var avg = Vector3.ZERO
		for n in normal:
			avg += n
		if normal.size():
			avg /= normal.size()

		DebugDraw3D.draw_arrow(global_position, global_position + avg, Color.RED, 0.1)
		var right = avg.cross(Vector3.DOWN)
		var down = right.cross(avg) * 5.0
		velocity += down * delta
		DebugDraw3D.draw_arrow(global_position, global_position + down, Color.BLUE, 0.1)

	if normal.size() == 2:
		var front_offset = front - 1
		var back_offset = back - 1

		if on_ground:
			if front_offset < back_offset:
				global_position.y -= front_offset
				velocity.y = -front_offset
			else:
				global_position.y -= back_offset
				velocity.y = -back_offset
		elif abs(front_offset) < 0.2 || abs(back_offset) < 0.2:
			on_ground = true
		else:
			velocity += gravity * delta
	else:
		on_ground = false
		velocity += gravity * delta


	var dir = Input.get_axis("p1_left", "p1_right")
	velocity += global_basis.z * dir * delta * STEERING_STRENGTH

	velocity = velocity.limit_length(MAX_SPEED)



	DebugDraw3D.draw_arrow(global_position, global_position + velocity, Color.GREEN, 0.1)
	var v_proj = Vector3(velocity.x, 0.0, velocity.z)
	if v_proj != Vector3.ZERO:
		look_at(global_position + v_proj, Vector3.UP, true)
		rotation.y -= PI / 2.0

	global_position += velocity * delta
