extends Node
## The game's root: shows the title, runs the opening for a new game or loads the save, then the overworld.

var _screen: Node


func _ready() -> void:
	InputSetup.register()
	get_window().theme = UiKit.build_theme()
	if TestRunner.active():
		return
	show_title()


func show_title() -> void:
	var title := TitleScreen.new()
	_swap(title)
	var option: String = await title.chosen
	if option == "continue" and SaveSystem.load_game():
		start_overworld()
	else:
		await start_new_game()


func start_new_game() -> void:
	Game.new_game()
	var intro := IntroScene.new()
	_swap(intro)
	await intro.run()
	start_overworld()


func start_overworld() -> Overworld:
	var world := Overworld.new()
	_swap(world)
	return world


func _swap(next: Node) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = next
	add_child(next)
