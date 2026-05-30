extends Control

@onready var host_button = $VBoxContainer/HostButton
@onready var client_button = $VBoxContainer/ClientButton
@onready var ip_input = $VBoxContainer/IPInput
@onready var join_button = $VBoxContainer/JoinButton

# --- NEW: Drag these into the Inspector! ---
@export var player_scene: PackedScene
@export var players_container: Node3D 

const PORT = 7000

func _ready():
	ip_input.hide()
	join_button.hide()

func _on_host_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, 2) 
	multiplayer.multiplayer_peer = peer
	
	# NEW: Tell the server to listen for new clients joining/leaving
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	# NEW: Spawn the Host's own player
	add_player(multiplayer.get_unique_id())
	
	hide() 
	print("Server Started!")

func _on_client_button_pressed() -> void:
	host_button.hide()
	client_button.hide()
	ip_input.show()
	join_button.show()

func _on_join_button_pressed() -> void:
	var ip = ip_input.text
	if ip == "":
		ip = "127.0.0.1" 
		
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	
	hide()
	print("Client Joining...")
	# NOTE: Clients do NOT call add_player(). The Host handles all spawning!

# --- NEW: Spawning Logic ---

func add_player(id: int):
	var player = player_scene.instantiate()
	
	# 1. Name MUST match ID for network sync
	player.name = str(id) 
	
	# 2. CRITICAL: Give the player control over their own character!
	player.set_multiplayer_authority(id) 
	
	# 3. Because the PlayersContainer is already hovering over the platform at (6, 2, -37),
	# we just add a small random offset so they don't spawn inside each other.
	player.position = Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
	players_container.add_child(player)

func remove_player(id: int):
	# If a player disconnects, destroy their character
	if players_container.has_node(str(id)):
		players_container.get_node(str(id)).queue_free()
