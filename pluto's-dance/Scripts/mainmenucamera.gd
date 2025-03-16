extends Camera3D

# Настройки поворота
@export var rotation_speed = 2.0  # Скорость поворота камеры (увеличили для заметности)
@export var max_rotation_y = 0.2  # Максимальный угол поворота по Y (в радианах, ~11.5°)

# Переменные для плавного движения
var target_rotation = Vector3.ZERO
var viewport_center = Vector2.ZERO
var initial_rotation_y = 0.0  # Для учёта начального поворота

func _ready():
	# Приводим Vector2i к Vector2 с помощью Vector2()
	viewport_center = Vector2(get_viewport().size) / 2
	# Сохраняем начальный поворот камеры
	initial_rotation_y = rotation.y

func _process(delta):
	# Получаем позицию мыши относительно центра экрана
	var mouse_pos = get_viewport().get_mouse_position()
	# Убеждаемся, что оба операнда имеют тип Vector2
	var mouse_offset = (mouse_pos - viewport_center) / viewport_center
	
	# Вычисляем целевой поворот на основе положения курсора
	# Убираем минус, чтобы камера поворачивалась в сторону курсора
	target_rotation.y = clamp(-mouse_offset.x * max_rotation_y, -max_rotation_y, max_rotation_y)
	
	# Плавно интерполируем текущий поворот к целевому, учитывая начальный поворот
	var target_y = initial_rotation_y + target_rotation.y
	rotation.y = lerp(rotation.y, target_y, delta * rotation_speed)
