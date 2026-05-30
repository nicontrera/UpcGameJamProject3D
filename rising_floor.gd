extends Area3D

@export var rise_speed: float = 2.0
@export var start_y: float = -10.0 # Set this in the inspector to wherever your floor starts

func _physics_process(delta: float) -> void:
	# Only the Server is allowed to move the floor upward.
	# The Synchronizer automatically copies this movement to the Client's screen!
	if multiplayer.is_server():
		position.y += rise_speed * delta

func _on_body_entered(body: Node3D) -> void:
	# If the thing touching the floor isn't in the player group, ignore it
	if not body.is_in_group("player"):
		return

	# 1. TELEPORT THE PLAYER
	# We check if the body that fell in belongs to the computer running this specific code.
	# If it is YOUR character, you teleport YOURSELF back to the spawn container.
	if body.name == str(multiplayer.get_unique_id()):
		body.position = Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
		# Note: Because your player is childed to the PlayersContainer at (6, 2, -37),
		# teleporting to (0,0,0) safely drops you right back on the starting platform!

	# 2. RESET THE FLOOR
	# Only the server is allowed to reset the floor's position for everyone.
	if multiplayer.is_server():
		position.y = start_y
