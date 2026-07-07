extends Node3D

var velocity = Vector3.ZERO
var gravity = Vector3.DOWN * 4
var on_ground = false
var dir = 0
var started = false
@onready var start_position = global_transform

@export var MAX_SPEED = 10.0
@export var STEERING_STRENGTH = 12
@export var player = 1

func _ready():
	$Seal/DirectionalLight3D.layers = player
	$Seal/DirectionalLight3D.light_cull_mask = player
	$Seal/Geo_Seal.layers = player

	Events.start.connect(_on_start)


func _on_start():
	started = true
	velocity = global_basis.x * 2

func _physics_process(delta: float) -> void:

	dir = move_toward(dir, Input.get_axis("p%d_left" % player, "p%d_right" % player), delta * 3)
	$Seal.rotation.z = dir * 0.5

	var front = $Front.target_position.length()
	var normal = []
	if $Front.is_colliding():
		front = ($Front.global_position - $Front.get_collision_point()).y
		normal.append($Front.get_collision_normal())
	var back = $Back.target_position.length()
	if $Back.is_colliding():
		back = ($Back.global_position - $Back.get_collision_point()).y
		normal.append($Back.get_collision_normal())

	if normal.size() >= 1:
		var front_offset = front - 1
		var back_offset = back - 1

		if on_ground:
			if front_offset < back_offset:
				global_position.y -= front_offset
				velocity.y = -front_offset
			else:
				global_position.y -= back_offset
				velocity.y = -back_offset
		elif abs(front_offset) < 0.1 || abs(back_offset) < 0.1:
			on_ground = true
		else:
			velocity += gravity * delta
	else:
		on_ground = false
		velocity += gravity * delta

	if on_ground and normal.size() == 2:
		var h = abs(front - back)
		var a = abs($Front.position.x - $Back.position.x)

		var angle = atan(h / a)
		$Seal.rotation.x = lerp_angle($Seal.rotation.x, angle, 0.5) + 0.1

	if !started:
		global_position += velocity * delta
		return

	if on_ground:
		var avg = Vector3.ZERO
		for n in normal:
			avg += n
		if normal.size():
			avg /= normal.size()

		DebugDraw3D.draw_arrow(global_position, global_position + avg, Color.RED, 0.1)
		var right = avg.cross(Vector3.DOWN)
		var down = right.cross(avg) * 5.0
		velocity += down * delta * 1.5
		DebugDraw3D.draw_arrow(global_position, global_position + down, Color.BLUE, 0.1)


	velocity += global_basis.z * dir * delta * STEERING_STRENGTH * 0.1 * velocity.length()

	velocity = velocity.limit_length(MAX_SPEED)

	DebugDraw3D.draw_arrow(global_position, global_position + velocity, Color.GREEN, 0.1)
	var v_proj = Vector3(velocity.x, 0.0, velocity.z)
	if v_proj != Vector3.ZERO:
		var target = lerp(global_position + global_basis.x, global_position + v_proj, 0.01 * velocity.length())
		look_at(target, Vector3.UP, true)
		rotation.y -= PI / 2.0

	global_position += velocity * delta

func _input(event):
	if event.is_action_pressed("p%d_b" % player):
		if started:
			global_transform = start_position
			_on_start()
