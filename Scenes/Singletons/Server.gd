extends Node

var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var port = 1909

func _ready():
	ConnectToServer(ip, port)
	
func ConnectToServer(ip, port):
	print("Client Started")
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	
	network.connect("connection_failed", self, "_OnConnectionFailed")
	network.connect("connection_succeeded", self, "_OnConnectionSucceeded")
	

func _OnConnectionFailed():
	print("Failed to connect")
	
func _OnConnectionSucceeded():
	print("Succesfully connected")
	
func fetch_skill_damage(skill_name, requester):
	rpc_id(1, "fetch_skill_damage", skill_name, requester)

remote func return_skill_damage(s_damage, requester):
	instance_from_id(requester).set_damage(s_damage)

remote func spawn_new_player(player_id, spawn_position):
	get_node("../Map").spawn_new_player(player_id, spawn_position)
	
remote func despawn_player(player_id):
	print("trying to remove player: " + str(player_id))
	get_node("../Map").despawn_player(player_id)

func send_player_state(player_state):
	rpc_unreliable_id(1, "receive_player_state", player_state)
	
remote func receive_world_state(world_state):
	get_node("../Map").update_world_state(world_state)
