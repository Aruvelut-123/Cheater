extends Node

@onready var buttle_display : Control = $"../buttle display"
var shellspawner = null

func _process(delta):
	var scene = GlobalVariables.get_current_scene_node()
	if scene.name == "main":
		shellspawner = scene.get_node("standalone managers/shell spawner")
	var current_sequence = shellspawner.sequenceArray
	var amount_displayer = buttle_display.get_children()[0]
	var live_amount : int = 0
	var blank_amount : int = 0
	for i in current_sequence:
		if i == "live":
			live_amount += 1
		elif i == "blank":
			blank_amount += 1
	var next : String
	if not current_sequence == []:
		if current_sequence[0] == "live":
			next = "实弹"
		elif current_sequence[0] == "blank":
			next = "空弹"
		else:
			next = current_sequence[0]
	else:
		next = "无"
	amount_displayer.text = "实弹: "+str(live_amount)+"\n空弹: "+str(blank_amount)+"\n下一发: "+next
