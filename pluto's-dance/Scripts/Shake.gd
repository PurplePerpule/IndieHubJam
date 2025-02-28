extends Node

func _ready():
	# Проверяем, есть ли Dialogic в сцене
	if !Dialogic.has_method("get_text_processor"):
		push_error("Dialogic TextProcessor not found!")
		return

	# Получаем обработчик текста в Dialogic
	var text_processor = Dialogic.get_text_processor()
	
	if text_processor:
		# Добавляем кастомную BBCode-команду "[shake]"
		text_processor.add_custom_command("shake", _shake_text)
	else:
		push_error("Не удалось получить TextProcessor Dialogic")

func _shake_text(text, args):
	var new_text = ""
	for i in range(text.length()):
		var size = 24 + randf_range(-3, 3)  # Случайный размер букв
		new_text += "[font_size=%d]%s[/font_size]" % [size, text[i]]
	return new_text
