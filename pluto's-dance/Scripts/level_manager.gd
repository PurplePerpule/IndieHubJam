extends Node

func load_level(level_path: String):
	print("Loading level at path: ", level_path)  # Отладка пути
	# Создаём чёрный фон для загрузки
	var loading_screen = ColorRect.new()
	loading_screen.color = Color.BLACK  # Чёрный фон (#000000)
	loading_screen.anchor_right = 1.0
	loading_screen.anchor_bottom = 1.0
	get_tree().root.add_child(loading_screen)
	get_tree().paused = true  # Приостанавливаем игру (опционально)

	# Асинхронная загрузка уровня
	ResourceLoader.load_threaded_request(level_path)

	# Ожидаем загрузку
	while ResourceLoader.load_threaded_get_status(level_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		print("Loading status: ", ResourceLoader.load_threaded_get_status(level_path))  # Отладка статуса
		await get_tree().create_timer(0.1).timeout  # Проверяем каждые 0.1 секунды

	# Получаем загруженный ресурс
	var loaded_resource = ResourceLoader.load_threaded_get(level_path)
	if loaded_resource == null:
		push_error("Failed to load level at path: ", level_path)
		loading_screen.queue_free()
		get_tree().paused = false
		return

	# Уровень загружен, создаём экземпляр
	var new_level = loaded_resource.instantiate()
	if new_level == null:
		push_error("Failed to instantiate level at path: ", level_path)
		loading_screen.queue_free()
		get_tree().paused = false
		return

	for child in get_tree().root.get_children():
		if child != loading_screen and child != self and !child.is_in_group("Persistent"):
			child.queue_free()

	# Добавляем новый уровень
	get_tree().root.add_child(new_level)
	loading_screen.queue_free()  # Удаляем чёрный экран
	print("Level loaded and black screen removed")  # Отладка
	get_tree().paused = false  # Возобновляем игру

# Пример вызова из другого скрипта
func _on_transition_triggered(level_path: String):
	load_level(level_path)
