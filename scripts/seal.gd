extends Node3D

var velocity = Vector3.ZERO
var gravity = Vector3.DOWN * 4
var on_ground = false
var dir = 0
var started = false
var jumping = false
var boost_frame = 0
var charging = false
var boost_success = false
var spinout = false
var spinout_timer = 0.0
var spinout_duration = 1.5
@onready var start_position = global_transform

@export var MAX_SPEED = 10.0
@export var STEERING_STRENGTH = 12
@export var player = 1

func _ready():
	$Seal/DirectionalLight3D.layers = player
	$Seal/DirectionalLight3D.light_cull_mask = player
	$Seal/Geo_Seal.layers = player
	$Timer.timeout.connect(show_reset_label)
	Events.start.connect(_on_start)
	Events.boost.connect(_on_boost)

	$LeftParticles.amount = 10
	$RightParticles.amount = 10
	$LeftParticles.process_material.spread = 50
	$RightParticles.process_material.spread = 50

func show_reset_label():
	Events.show_reset_label.emit(player)

func hide_reset_label():
	$Timer.stop()
	Events.hide_reset_label.emit(player)

func _on_start():
	started = true

	velocity = global_basis.x
	if charging and boost_success:
		velocity *= 6
		$BoostParticles.emitting = true
		$BoostParticles2.emitting = true
	elif charging:
		spinout = true
		velocity *= 1.5
	else:
		velocity *= 3

	$LeftParticles.amount = 30
	$RightParticles.amount = 30
	$LeftParticles.process_material.spread = 8.6
	$RightParticles.process_material.spread = 8.6

var JUMP_SPEED = 4.0
func jump():
	if player == 1:
		$LeftJump.play()
	elif player == 2:
		$RightJump.play()
	jumping = true
	on_ground = false
	velocity.y = JUMP_SPEED

func _physics_process(delta: float) -> void:
	if spinout and spinout_timer <= spinout_duration:
		spinout_timer += delta
		var t = spinout_timer / spinout_duration
		$Seal.rotation.y = Tween.interpolate_value(
			PI / 2, 3 * TAU, t, spinout_duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		return
	else:
		$Seal.rotation.y = PI / 2

	if Input.is_action_just_pressed("p%d_a" % player) && !jumping && on_ground && started:
		jump()

	if velocity.y <= 0.0:
		jumping = false

	if !on_ground && !jumping && $Timer.is_stopped():
		$Timer.start(2.0)

	$Camera3D.position.x = move_toward(
		$Camera3D.position.x, lerp(-2.4, -3.6, velocity.length() / MAX_SPEED), delta * 0.25)
	dir = move_toward(dir, Input.get_axis("p%d_left" % player, "p%d_right" % player), delta * 3)

	$LeftParticles.emitting = dir == 1.0 && velocity.length() > 5.0 && on_ground || !started
	$RightParticles.emitting = dir == -1.0 && velocity.length() > 5.0 && on_ground || !started
	$Seal.rotation.z = sign(dir) * sqrt(abs(dir)) * 0.5

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
		elif (abs(front_offset) < 0.1 || abs(back_offset) < 0.1) && !jumping:
			if !on_ground:
				$RightParticles2.emitting = true
				$LeftParticles2.emitting = true
				if player == 1:
					$LeftLand.play()
				elif player == 2:
					$RightLand.play()
				hide_reset_label()
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
	elif jumping && !on_ground:
		# var angle = -global_basis.x.normalized().angle_to(velocity.normalized()) + 0.3
		var angle = lerp(-PI / 4.0, PI / 2.5, remap(velocity.y, JUMP_SPEED, -JUMP_SPEED, 0.0, 1.0))
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

	var modifier = 1.0
	if !on_ground:
		modifier = 0.6
	velocity += global_basis.z * dir * delta * STEERING_STRENGTH * 0.1 * velocity.length() * modifier

	velocity = velocity.limit_length(MAX_SPEED)

	DebugDraw3D.draw_arrow(global_position, global_position + velocity, Color.GREEN, 0.1)
	var v_proj = Vector3(velocity.x, 0.0, velocity.z)
	if v_proj != Vector3.ZERO:
		var target = lerp(global_position + global_basis.x, global_position + v_proj, 0.01 * velocity.length())
		look_at(target, Vector3.UP, true)
		rotation.y -= PI / 2.0

	global_position += velocity * delta

func _on_boost(frame_number):
	boost_frame = frame_number

func _input(event):
	if !started:
		if event.is_action_pressed("p%d_a" % player):
			charging = true
			var curr_frame = Engine.get_frames_drawn()
			if boost_frame and (curr_frame - boost_frame <= 100):
				boost_success = true

			$LeftParticles.amount = 50
			$RightParticles.amount = 50
			$LeftParticles.process_material.spread = 8.6
			$RightParticles.process_material.spread = 8.6
		elif event.is_action_released("p%d_a" % player):
			charging = false
			boost_success = false

			$LeftParticles.amount = 10
			$RightParticles.amount = 10
			$LeftParticles.process_material.spread = 50
			$RightParticles.process_material.spread = 50


	elif event.is_action_pressed("p%d_b" % player):
		hide_reset_label()
		global_transform = start_position
		_on_start()
