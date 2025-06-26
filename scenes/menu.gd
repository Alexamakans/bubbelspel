class_name Lobby
extends Control

const VIEW_NONE = ""
const VIEW_MAIN_MENU = "MainMenu"
const VIEW_HOST_GAME = "HostGame"
const VIEW_JOIN_GAME = "JoinGame"
const VIEW_LOBBY = "Lobby"

var current_view: String = VIEW_MAIN_MENU

@onready var gamestate: Game = Game.instance

@onready var main_menu_control: Control = $MainMenu

@onready var error_dialog: AcceptDialog = $ErrorDialog

@onready var host_game_control: Control = $HostGame
@onready var host_game_player_name: TextEdit = $HostGame/VBox/PlayerName
@onready var host_game_port: TextEdit = $HostGame/VBox/Port
@onready var host_game_error_label: Label = $HostGame/VBox/ErrorLabel
@onready var host_game_button: Button = $HostGame/VBox/Host
@onready var host_game_back: Button = $HostGame/Control/Back

@onready var join_game_control: Control = $JoinGame
@onready var join_game_player_name: TextEdit = $JoinGame/VBox/PlayerName
@onready var join_game_ip: TextEdit = $JoinGame/VBox/Address/IP
@onready var join_game_port: TextEdit = $JoinGame/VBox/Address/Port
@onready var join_game_error_label: Label = $JoinGame/VBox/ErrorLabel
@onready var join_game_button: Button = $JoinGame/VBox/Join
@onready var join_game_back: Button = $JoinGame/Control/Back

@onready var lobby_control: Control = $Lobby
@onready var lobby_player_list: ItemList = $Lobby/VBox/PlayerList
@onready var lobby_start_button: Button = $Lobby/VBox/Start
@onready var lobby_waiting_label: Label = $Lobby/VBox/WaitingLabel


func set_view(view: String) -> void:
	visible = view != VIEW_NONE
	$"../World".visible = view != VIEW_NONE
	main_menu_control.visible = view == VIEW_MAIN_MENU
	host_game_control.visible = view == VIEW_HOST_GAME
	if view == VIEW_HOST_GAME:
		set_host_game_error("")
		set_host_game_interactible(true)
	join_game_control.visible = view == VIEW_JOIN_GAME
	if view == VIEW_JOIN_GAME:
		set_join_game_error("")
		set_join_game_interactible(true)
	lobby_control.visible = view == VIEW_LOBBY


func _ready():
	# Called every time the node is added to the scene.
	gamestate.connection_failed.connect(_on_connection_failed)
	gamestate.connection_succeeded.connect(_on_connection_success)
	gamestate.player_list_changed.connect(refresh_lobby)
	gamestate.game_ended.connect(_on_game_ended)
	gamestate.game_error.connect(_on_game_error)
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		set_default_player_name(OS.get_environment("USERNAME"))
	elif OS.has_environment("USER"):
		set_default_player_name(OS.get_environment("USER"))
	else:
		var desktop_path = OS.get_system_dir(OS.SystemDir.SYSTEM_DIR_DCIM).replace("\\", "/").split("/")
		set_default_player_name(desktop_path[desktop_path.size() - 2])


func set_default_player_name(playerName: String) -> void:
	join_game_player_name.text = playerName
	host_game_player_name.text = playerName


func _on_host_pressed():
	var player_name = host_game_player_name.text.strip_edges().strip_escapes()
	if player_name == "":
		set_host_game_error("Invalid name")
		return
	var port: String = host_game_port.text.strip_edges()
	if port == "":
		set_host_game_error("Invalid port")
		return

	set_view(VIEW_LOBBY)

	gamestate.host_game(player_name, port.to_int())
	refresh_lobby()


func set_host_game_interactible(interactible: bool) -> void:
	host_game_back.disabled = not interactible
	host_game_button.disabled = not interactible
	host_game_player_name.editable = interactible
	host_game_port.editable = interactible


func set_host_game_error(error: String) -> void:
	host_game_error_label.text = error


func _on_join_pressed():
	var player_name: String = join_game_player_name.text.strip_edges().strip_escapes()
	if player_name == "":
		set_join_game_error("Invalid name!")
		return

	var ip: String = join_game_ip.text.strip_edges()
	if not ip.is_valid_ip_address():
		set_join_game_error("Invalid IP address!")
		return

	var port: String = join_game_port.text.strip_edges()
	if not port.is_valid_int():
		set_join_game_error("Invalid address port!")
		return

	set_join_game_error("")
	set_join_game_interactible(false)

	gamestate.join_game(ip, port.to_int(), player_name)


func set_join_game_interactible(interactible: bool) -> void:
	join_game_back.disabled = not interactible
	join_game_button.disabled = not interactible
	join_game_player_name.editable = interactible
	join_game_ip.editable = interactible
	join_game_port.editable = interactible


func set_join_game_error(error: String) -> void:
	join_game_error_label.text = error


func _on_connection_success():
	set_view(VIEW_LOBBY)


func _on_connection_failed():
	set_join_game_interactible(true)
	set_join_game_error("Connection failed.")


func _on_game_ended():
	set_view(VIEW_MAIN_MENU)


func _on_game_error(error: String):
	error_dialog.dialog_text = error
	error_dialog.popup_centered()
	set_view(current_view) # resets the interactability


func refresh_lobby():
	var players: Array[String] = gamestate.get_player_list()
	players.sort()
	lobby_player_list.clear()
	lobby_player_list.add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		lobby_player_list.add_item(p)

	var is_server: bool = multiplayer.is_server()
	lobby_waiting_label.visible = not is_server
	lobby_start_button.visible = is_server


func _on_lobby_leave_pressed() -> void:
	pass # Replace with function body.


func _on_start_pressed():
	gamestate.start_game()
