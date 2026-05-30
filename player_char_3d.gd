extends CharacterBody3D

@export var sync_anim: String = "Idle"
@export var sync_rotation: float = 0.0

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0
@export var jump_impulse := 12.0

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 8.0

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
var _gravity := -30.0

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _playerSkin: Node3D = %Skeleton_Minion

@onready var anim_player = $Skeleton_Minion/AnimationPlayer


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity

# This runs the exact millisecond the node is added to the scene, before anything else!
func _enter_tree() -> void:
	# Converts the node's name (e.g., "1" or "84392") back into a number 
	# and assigns authority to that specific computer.
	set_multiplayer_authority(name.to_int())


# Runs right after the node enters the tree and is fully loaded
func _ready() -> void:
	# If this specific computer does NOT own this character...
	if not is_multiplayer_authority():
		# Destroy the camera attached to this remote player so it doesn't override yours!
		$CameraPivot.queue_free()

#func _physics_process(delta: float) -> void:
	#var is_starting_jump := Input.is_action_just_pressed("jump") and is_on_floor()
#
#
	#if $Skeleton_Minion/AnimationPlayer.current_animation != sync_anim:
		#$Skeleton_Minion/AnimationPlayer.play(sync_anim)
		#
	#_playerSkin.global_rotation.y = lerp_angle(_playerSkin.global_rotation.y, sync_rotation, rotation_speed * delta)
	#
	#if not is_multiplayer_authority():
		#return
#
	#_camera_pivot.rotation.x += _camera_input_direction.y * delta
	#_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	#_camera_pivot.rotation.y -= _camera_input_direction.x * delta
#
	#_camera_input_direction = Vector2.ZERO
#
	#var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	#var forward := _camera.global_basis.z
	#var right := _camera.global_basis.x
	#var move_direction := forward * raw_input.y + right * raw_input.x
	#move_direction.y = 0.0
	#move_direction = move_direction.normalized()
#
	#var y_velocity := velocity.y
	#velocity.y = 0.0
	#velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	#velocity.y = y_velocity + _gravity * delta
#
	#if is_starting_jump:
		#velocity.y += jump_impulse
#
	#move_and_slide()
#
	#if move_direction.length() > 0.2:
		#_last_movement_direction = move_direction
	#var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	##_playerSkin.global_rotation.y = lerp_angle(_playerSkin.rotation.y, target_angle, rotation_speed * delta)
	#
	## Calculate the angle we WANT to face, and save it to the network variable!
	#sync_rotation = Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	#
	## HOST DECIDES THE ANIMATION STATE
	#if is_starting_jump:
		#sync_anim = "Jump_Full_Short"
	#elif not is_on_floor() and velocity.y < 0:
		#sync_anim = "Jump_Land"
	#elif is_on_floor():
		#var ground_speed := velocity.length()
		#if ground_speed > 0.0:
			#sync_anim = "Running_A"
		#else:
			#sync_anim = "Idle"


func _physics_process(delta: float) -> void:
	
	# ==========================================
	# 1. VISUALS (Runs for EVERYONE)
	# Both Host and Client read the synced animation and rotation
	# ==========================================
	if $Skeleton_Minion/AnimationPlayer.current_animation != sync_anim:
		$Skeleton_Minion/AnimationPlayer.play(sync_anim)
		
	# Smoothly rotate the character model to match the synced network angle!
	_playerSkin.global_rotation.y = lerp_angle(_playerSkin.global_rotation.y, sync_rotation, rotation_speed * delta)

	
	# ==========================================
	# 2. THE AUTHORITY BARRIER
	# ==========================================
	if not is_multiplayer_authority():
		return

	# ==========================================
	# 3. MOVEMENT MATH (Runs ONLY for the owner)
	# ==========================================
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

	# If the player lets go of the jump button AND they are still moving up...
	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		# Immediately cut their upward speed in half!
		velocity.y *= 0.5

	move_and_slide()

	# ==========================================
	# 4. DECIDE ROTATION & ANIMATION (Runs ONLY for the owner)
	# ==========================================
	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction
		
	# Calculate the angle we WANT to face, and save it to the network variable!
	sync_rotation = Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	
	
	if is_starting_jump:
		sync_anim = "Jump_Full_Short"
	elif not is_on_floor() and velocity.y < 0:
		sync_anim = "Jump_Land"
	elif is_on_floor():
		var ground_speed := velocity.length()
		if ground_speed > 0.0:
			sync_anim = "Running_A"
		else:
			sync_anim = "Idle"
