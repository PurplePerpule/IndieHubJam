extends Control

@onready var Settings = $Settings
@onready var Pause = $"Pause Menu"


func _ready() -> void:
	set_visible(false)
	Settings.visible = false
	Pause.visible = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		set_visible(!get_tree().paused)
		get_tree().paused = !get_tree().paused

func _on_continue_pressed() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_visible(false)


func _on_settings_pressed() -> void:
	Settings.visible = true
	Pause.visible = false
	GlobalAudioServer.emit_signal("move_sliders")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	Settings.visible = false
	Pause.visible = true
