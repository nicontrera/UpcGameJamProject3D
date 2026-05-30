func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta

	_camera_input_direction = Vector2.ZERO

	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	velocity.y = y_velocity + _gravity * delta

	var is_starting_jump := Input.is_action_just_pressed("jump") and is_on_floor()
	if is_starting_jump:
		velocity.y += jump_impulse

	move_and_slide()

	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	_playerSkin.global_rotation.y = lerp_angle(_playerSkin.rotation.y, target_angle, rotation_speed * delta)

	if is_starting_jump:
		anim_player.play("Jump_Full_Short")
	elif not is_on_floor() and velocity.y < 0:
		anim_player.play("Jump_Land")
	elif is_on_floor():
		var ground_speed := velocity.length()
		if ground_speed > 0.0:
			anim_player.play("Running_A")
		else:
			anim_player.play("Idle")