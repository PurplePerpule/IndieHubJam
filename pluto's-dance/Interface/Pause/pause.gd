extends Control


func _ready() -> void:
	set_visible(false)
	$MarginContainer/VBoxContainer2/B_Settings.visible = false
	$MarginContainer/VBoxContainer2/Settings.visible = false


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
	$MarginContainer/VBoxContainer2/Settings.visible = true
	$MarginContainer/VBoxContainer2/B_Settings.visible = true
	$MarginContainer/VBoxContainer2/Pause.visible = false
	$MarginContainer/VBoxContainer2/Pause_B.visible = false


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	$MarginContainer/VBoxContainer2/Settings.visible = false
	$MarginContainer/VBoxContainer2/B_Settings.visible = false
	$MarginContainer/VBoxContainer2/Pause.visible = true
	$MarginContainer/VBoxContainer2/Pause_B.visible = true
