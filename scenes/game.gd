class_name Game
extends Node

static var instance: Game

# This file contains modified version of the Godot demo project "multiplayer_bomber"
# https://github.com/godotengine/godot-demo-projects/tree/8be477ce38d9f877e5fb32d773a19683fca83d7a/networking/multiplayer_bomber
#
# Copyright (c) 2014-present Godot Engine contributors.
# Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

# Max number of players.
const MAX_PEERS = 12

@export var world_home: Node
@export var current_world: World

var peer: ENetMultiplayerPeer = null

# Name for my player.
var player_name: String = "unnamed"

# Names for remote players in id:name format.
var players: Dictionary[int, String] = {}

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what: String)


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


# Callback from SceneTree.
func _player_connected(id: int) -> void:
	# Registration of a client beings here, tell the connected player that we are here.
	register_player.rpc_id(id, player_name)


# Callback from SceneTree.
func _player_disconnected(id: int) -> void:
	print("Player ", id, " disconnected from the game")
	if has_node("/root/World"): # Game is in progress.
		if multiplayer.is_server():
			game_error.emit("Player " + players[id] + " disconnected")
			end_game()
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok() -> void:
	# We just connected to a server
	print("Connected to game")
	connection_succeeded.emit()


# Callback from SceneTree, only for clients (not server).
func _server_disconnected() -> void:
	print("Disconnected from game")
	game_error.emit("Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail() -> void:
	connection_failed.emit()


# Lobby management functions.
@rpc("any_peer")
func register_player(new_player_name: String) -> void:
	var id: int = multiplayer.get_remote_sender_id()
	players[id] = new_player_name
	player_list_changed.emit()


func unregister_player(id: int) -> void:
	players.erase(id)
	player_list_changed.emit()


func host_game(new_player_name: String, port: int) -> void:
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	print("Hosting game on port ", port)
	peer.create_server(port, MAX_PEERS)
	multiplayer.set_multiplayer_peer(peer)


func join_game(ip: String, port: int, new_player_name: String) -> void:
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	print("Joining game on address ", ip, ":", port)
	peer.create_client(ip, port)
	multiplayer.set_multiplayer_peer(peer)


func get_player_list() -> Array[String]:
	return players.values()


func get_player_name() -> String:
	return player_name


func start_game() -> void:
	var lobby: Lobby = get_tree().get_root().get_node("Game/Menu/UI")
	lobby.set_view(Lobby.VIEW_NONE)

	if multiplayer.is_server():
		# Only load world on server. Clients will get world via the spawner.
		load_world.call_deferred(load("res://scenes/world.tscn"))


func unload_world() -> void:
	for child in world_home.get_children():
		world_home.remove_child(child)
		child.queue_free()


func load_world(scene: PackedScene) -> void:
	print("Loading world")

	# Remove old world (if any)
	unload_world()

	# Change scene.
	var world: Node = scene.instantiate()
	world_home.add_child(world)

	var player_scene: PackedScene = load("res://scenes/player.tscn")

	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points: Dictionary[int, int] = {}
	spawn_points[1] = 0 # Server in spawn point 0.
	var spawn_point_idx: int = 1
	for p in players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1

	for p_id in spawn_points:
		var spawn_pos: Node3D = world.get_node("SpawnPoints/" + str(spawn_points[p_id]))
		var player: Player = player_scene.instantiate()
		player.player_id = p_id
		player.position = spawn_pos.global_position
		player.rotation = spawn_pos.global_rotation
		player.name = "Player " + str(p_id)
		world.get_node("Players").add_child(player)

	# Set up score.
	#world.get_node("Score").add_player(multiplayer.get_unique_id(), player_name)
	#for pn in players:
	#	world.get_node("Score").add_player(pn, players[pn])
	#get_tree().set_pause(false) # Unpause and unleash the game!


func end_game() -> void:
	print("Ending game")

	unload_world()
	game_ended.emit()
	players.clear()


func _ready() -> void:
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)
