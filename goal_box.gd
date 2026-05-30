extends Area3D

# We grab references to the UI and the Lava that are in the main level
@onready var win_ui = $"../../WinUI"
@onready var win_label = $"../../WinUI/Label"

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
		
	# We only want the computer of the player who actually crossed the finish line 
	# to send the winning message to everyone else.
	if body.name == str(multiplayer.get_unique_id()):
		# This tells every connected computer to run the "declare_winner" function!
		rpc("declare_winner", body.name)

# The @rpc tag allows this function to be called over the network.
# "call_local" means it runs on the winner's screen AND the loser's screen.
# "any_peer" means anyone who touches the goal is allowed to trigger it.
@rpc("any_peer", "call_local")
func declare_winner(winner_id: String) -> void:
	# 1. Show the text!
	win_label.text = "Player " + winner_id + " reached the top!"
	win_ui.show()
	
	# 2. Stop the lava so the loser doesn't die while reading the win screen!
	var rising_floor = get_node_or_null("../RisingFloor")
	if rising_floor:
		# Turning off physics processing completely stops the floor's script from running
		rising_floor.set_physics_process(false)
