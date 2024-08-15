extends Node

const AUTHORNAME_MODNAME_DIR := "Baymaxawa-Cheater"
const MOD_NAME := "Cheater"
const MOD_VERSION := "0.0.1"

var mod_dir_path := ""

func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir()+(AUTHORNAME_MODNAME_DIR)+"/"

var injected = false
var tested = false

func _process(delta):
	var scene = GlobalVariables.get_current_scene_node()
	var root = get_tree().root
	if not tested:
		tested = true
		ModLoaderLog.fatal("Cheat injected!", MOD_NAME)
	if scene.name == "menu" && injected:
		injected = false
		ModLoaderLog.warning("Stop cheat display server", MOD_NAME)
	if scene.name == "main" && not injected:
		ModLoaderLog.warning("Start cheat display server", MOD_NAME)
		var bdm = load("res://mods-unpacked/Baymaxawa-Cheater/bdm.tscn").instantiate()
		scene.get_node("Camera").add_child(bdm)
		ModLoaderLog.info("Completed!", MOD_NAME)
		ModLoaderLog.warning("Any cheating may against the rules of some mods. We will not responsible for anything happend because of cheating except for bugs.", MOD_NAME)
		injected = true
