extends Control

@export var inviteContainer : ScrollContainer
@export var inviteList : VBoxContainer
@export var popupSection : Control
@export var playerListSection : Control
@export var signupSection : Control
@export var menuButton : Button
@export var incomingButton : Button
@export var outgoingButton : Button
@export var buttonHighlightAnimator : AnimationPlayer
@export var crtMenu : Panel
@export var userList : VBoxContainer
@export var usernameInput : LineEdit
@export var signupButton : Button
@export var opponentUsernameLabel : Label
@export var gameReadySection : Control
@export var joiningGameSection : Control
@export var timerAccept : AnimationPlayer
@export var timerJoin : AnimationPlayer
@export var errorLabel : Label
@export var title : Label
@export var underline : Label
@export var chat_parent : Control
@export var chat_array : Array[Label]
@export var chat_background : ColorRect
@export var chat_input : LineEdit

signal serverInviteList(invites)
signal connectionSuccess

var popupInvite
var inviteShowQueue = []
var multiplayerManager
var mrm
var cursorManager
var interactionManager
var menuIsVisible = false
var selectedInput
var lefting = false
var righting = false
var backspacing = false
var deleting = false
var moveTimer
var canMove = true
var chatTimer_array = [10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0]
var chatTimer = true
var markForFocus = false
var popupVisible = false
var deniedUsers = []

const HACKED_NAME := "Cheater"

signal inviteFinished

func _ready():
	ModLoaderLog.warning("Chat hacked! Now can chat in lobby after logged in.", HACKED_NAME)
	cursorManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/cursor manager")
	multiplayerManager = get_tree().root.get_node("MultiplayerManager")
	mrm = get_tree().root.get_node("MultiplayerManager/MultiplayerRoundManager")
	multiplayerManager.inviteMenu = self
	multiplayerManager.loginStatus.connect(processLoginStatus)
	multiplayerManager.opponentActive = false
	menuButton.button_down.connect(toggleMenu)
	signupButton.button_down.connect(requestUsername)
	incomingButton.button_down.connect(func(): updateInviteList("incoming", false))
	outgoingButton.button_down.connect(func(): updateInviteList("outgoing", false))

	cursorManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/cursor manager")
	interactionManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/interaction manager")
	var buttons = [menuButton, incomingButton, outgoingButton]
	for button_toConnect in buttons:
		button_toConnect.focus_entered.connect(func(): setCursorImage("hover"))
		button_toConnect.mouse_entered.connect(func(): setCursorImage("hover"))
		button_toConnect.focus_exited.connect(func(): setCursorImage("point"))
		button_toConnect.mouse_exited.connect(func(): setCursorImage("point"))

	var menuTexture = ImageTexture.create_from_image(Image.load_from_file("res://mods-unpacked/GlitchedData-MultiPlayer/media/burger.png"))
	menuButton.set_button_icon(menuTexture)

	chat_parent.visible = multiplayerManager.chat_enabled
	selectedInput = usernameInput
	chat_input.text_changed.connect(onChatEdit)

func _process(delta):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE and multiplayerManager.loggedIn and not multiplayerManager.inMatch:
		menuButton.visible = true
		if menuIsVisible:
			inviteContainer.visible = true
			incomingButton.visible = true
			outgoingButton.visible = true
			buttonHighlightAnimator.get_parent().visible = true
	else:
		menuButton.visible = false
		inviteContainer.visible = false
		incomingButton.visible = false
		outgoingButton.visible = false
		buttonHighlightAnimator.get_parent().visible = false

	if canMove and moveTimer > 0.45 and lefting and selectedInput.caret_column > 0:
		selectedInput.caret_column -= 1
	if canMove and moveTimer > 0.45 and righting and selectedInput.caret_column < selectedInput.text.length():
		selectedInput.caret_column += 1
	if canMove and backspacing and selectedInput.caret_column > 0:
		selectedInput.delete_char_at_caret()
	if canMove and deleting and selectedInput.caret_column < selectedInput.text.length():
		selectedInput.caret_column += 1
		selectedInput.delete_char_at_caret()
	if lefting or righting or backspacing or deleting:
		moveTimer += get_process_delta_time()
	if moveTimer > 0 and moveTimer <= 0.45:
		canMove = false
	if moveTimer > 0.45:
		canMove = !canMove
	if chatTimer:
		for i in range(10):
			if chatTimer_array[i] < 10.0: chatTimer_array[i] += get_process_delta_time()
			if chatTimer_array[i] > 10.0: chatTimer_array[i] = 10.0
			if chatTimer_array[i] >= 7.0: chat_array[i].modulate.a = (10.0 - chatTimer_array[i])/3.0
	if markForFocus:
		markForFocus = false
		chat_input.grab_focus()
	
func _input(event):
	if multiplayerManager.chat_enabled and multiplayerManager.loggedIn:
		if (event.is_action_pressed("mp_chat") and chatTimer):
			chatTimer = false
			chat_background.visible = multiplayerManager.chat_enabled
			chat_input.visible = multiplayerManager.chat_enabled
			for i in range(10):
				if chat_array[i].text != "":
					if chatTimer_array[i] > 7.0: chatTimer_array[i] = 7.0
					chat_array[i].modulate.a = 1.0
			markForFocus = true
		if (event.is_action_pressed("ui_accept") and not chatTimer):
			sendChat(chat_input.text)
			chat_input.text = ""
			chatTimer = true
			chat_background.visible = false
			chat_input.visible = false
		if (event.is_action_pressed("exit game") and not chatTimer):
			chat_input.text = ""
			chatTimer = true
			chat_background.visible = false
			chat_input.visible = false
	if signupSection.visible or not chatTimer:
		if (event.is_action_pressed("ui_cancel")):
			canMove = true
			moveTimer = 0.0
			lefting = false
			righting = false
			deleting = false
			backspacing = true
		if (event.is_action_released("ui_cancel")):
			moveTimer = 0.0
			backspacing = false
		if (event.is_action_pressed("mp_delete")):
			canMove = true
			moveTimer = 0.0
			lefting = false
			righting = false
			backspacing = false
			deleting = true
		if (event.is_action_released("mp_delete")):
			moveTimer = 0.0
			deleting = false
		if (event.is_action_pressed("ui_left")):
			canMove = true
			moveTimer = 0.0
			righting = false
			backspacing = false
			deleting = false
			lefting = true
			if not chatTimer and chat_input.caret_column > 0:
				chat_input.caret_column -= 1
		if (event.is_action_released("ui_left")):
			moveTimer = 0.0
			lefting = false
		if (event.is_action_pressed("ui_right")):
			canMove = true
			moveTimer = 0.0
			lefting = false
			backspacing = false
			deleting = false
			righting = true
			if not chatTimer and chat_input.caret_column < chat_input.text.length():
				chat_input.caret_column += 1
		if (event.is_action_released("ui_right")):
			moveTimer = 0.0
			righting = false

func requestUsername():
	multiplayerManager.connectToServer()
	await multiplayer.connected_to_server
	multiplayerManager.requestNewUser.rpc(usernameInput.text)

func setCursorImage(alias):
	match alias:
		"hover": interactionManager.checking = false
		"point": interactionManager.checking = true
	cursorManager.SetCursorImage(alias)

func toggleMenu():
	if menuIsVisible:
		menuIsVisible = false
		inviteContainer.visible = false
		incomingButton.visible = false
		outgoingButton.visible = false
		buttonHighlightAnimator.get_parent().visible = false
	else:
		menuIsVisible = true
		inviteContainer.visible = true
		incomingButton.visible = true
		outgoingButton.visible = true
		buttonHighlightAnimator.get_parent().visible = true
		buttonHighlightAnimator.play("RESET")
		updateInviteList("incoming", true)

func receiveInvite(fromUsername, fromID):
	if deniedUsers.has(fromUsername):
		multiplayerManager.denyInvite.rpc(fromID)
	else:
		inviteShowQueue.push_back(fromID)
		print(inviteShowQueue.find(fromID))
		if inviteShowQueue.find(fromID) > 0:
			while inviteShowQueue.find(fromID) != 0:
				await inviteFinished
		
		popupInvite = load("res://mods-unpacked/GlitchedData-MultiPlayer/components/invite.tscn").instantiate()
		popupInvite.setup(fromUsername, fromID, self)
		popupSection.add_child(popupInvite)
		print(popupInvite)
		popupInvite.animationPlayer.play("progress")
		popupVisible = true

func removeInvite(from):
	for invite in inviteList.get_children():
		if invite.inviteFromID == from:
			inviteList.remove_child(invite)
	for invite in popupSection.get_children():
		if invite.inviteFromID == from:
			popupSection.remove_child(invite)

func showReady(username):
	setupMatch()
	multiplayerManager.crtManager.intro.dealerName.text = username.to_upper()
	mrm.opponent = username.to_upper()
	gameReadySection.visible = true
	opponentUsernameLabel.text = username
	timerAccept.play("countdown")
	
func showJoin():
	setupMatch()
	joiningGameSection.visible = true
	timerJoin.play("countdown")

func setupMatch():
	multiplayerManager.opponentActive = true
	multiplayerManager.openedBriefcase = false
	multiplayerManager.crtManager.viewing = false
	multiplayerManager.crtManager.branch_exit.interactionAllowed = false
	selectedInput = chat_input
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func updateInviteList(type, reset):
	for invite in inviteList.get_children():
		invite.queue_free()
	var isOutgoing = false
	match type:
		"incoming":
			if not reset: buttonHighlightAnimator.play_backwards("toggle")
			multiplayerManager.getInvites.rpc("incoming")
		"outgoing":
			buttonHighlightAnimator.play("toggle")
			multiplayerManager.getInvites.rpc("outgoing")
			isOutgoing = true
	var list = await serverInviteList
	for invite in list:
		var newMenuInvite = load("res://mods-unpacked/GlitchedData-MultiPlayer/components/invite.tscn").instantiate()
		newMenuInvite.isInMenu = true
		newMenuInvite.setup(invite.find_key("username"), invite.find_key("id"), self, isOutgoing)
		inviteList.add_child(newMenuInvite)
		await get_tree().create_timer(.1, false).timeout
		
func updateUserList(list):
	multiplayerManager.getInvites.rpc("outgoing")
	var inviteList = await serverInviteList
	list.erase(list.find_key(multiplayer.get_unique_id()))
	for user in userList.get_children():
		user.queue_free()
	for user in list:
		var username = user
		var id = list[user]
		var newUserItem = load('res://mods-unpacked/GlitchedData-MultiPlayer/components/user.tscn').instantiate()
		for invite in inviteList:
			if invite.find_key("id") == id:
				newUserItem.setup(username, id, multiplayerManager, true)
				userList.add_child(newUserItem)
				return
		newUserItem.setup(username, id, multiplayerManager, false)
		userList.add_child(newUserItem)
		
func processLoginStatus(reason):
	if reason == "success":
		title.text = "欢迎, " + multiplayerManager.accountName.to_upper()
		underline.text = "---  "
		for i in range(multiplayerManager.accountName.length()): underline.text = underline.text + "-"
		crtMenu.visible = true
		playerListSection.visible = true
		signupSection.visible = false
		usernameInput.release_focus()
		multiplayerManager.requestPlayerList.rpc()
		return
	else:
		crtMenu.visible = true
		playerListSection.visible = false
		signupSection.visible = true
		match reason:
			"invalidUsername":
				errorLabel.text = "用户名无效"
				print("用户名无效")
			"userAlreadyExists":
				errorLabel.text = "用户名已被占用"
				print("用户名已被占用")
			"nonExistentUser":
				errorLabel.text = "无法登录到\n不存在的用户"
				print("无法登录到\n不存在的用户")
			"databaseError":
				errorLabel.text = "服务器数据库错误"
				print("服务器数据库错误")
			"malformedKey":
				errorLabel.text = "你的用户KEY已损坏"
				print("你的用户KEY已损坏")
			"invalidCreds":
				errorLabel.text = "提供的KEY不匹配对应账户"
				print("提供的KEY不匹配对应账户")
			"noKey":
				errorLabel.text = "未找到用户KEY"
				print("未找到用户KEY")
			"outdatedClient":
				errorLabel.text = "过期的客户端！请在\n BUCKSHOTMULTIPLAYER.NET 更新"
				print("过期的客户端")
		usernameInput.grab_focus()
	errorClear()
	signupSection.visible = true

func errorClear():
	if errorLabel.text != "":
		await get_tree().create_timer(10, false).timeout
		errorLabel.text = ""

func sendChat(message):
	multiplayerManager.sendChat.rpc(message)
	addChatMessage(message, true)

func addChatMessage(message, isPlayer):
	for i in range(9):
		chat_array[i].text = chat_array[i + 1].text
		chat_array[i].modulate.a = chat_array[i + 1].modulate.a
		chatTimer_array[i] = chatTimer_array[i + 1]
	var sender = multiplayerManager.accountName.to_upper() if isPlayer else mrm.opponent
	chat_array[9].text = "<" + sender + "> " + message
	chat_array[9].modulate.a = 1.0
	chatTimer_array[9] = 0.0

func onChatEdit(text):
	var column = chat_input.caret_column
	chat_input.size.x = 0
	if chat_input.size.x >= 523:
		chat_input.max_length = chat_input.text.length()
	else:
		chat_input.max_length = 0
	chat_input.caret_column = column