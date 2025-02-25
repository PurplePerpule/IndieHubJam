extends CharacterBody3D

# Настройки движения
@export var speed = 5.0
@export var sprint_speed = 8.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.3

# Настройки камеры
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera

# Гравитация из настроек проекта
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_sprinting = false

func _ready():
	# Захват мыши
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Управление камерой с помощью мыши
	if event is InputEventMouseMotion:
		# Поворот персонажа по горизонтали
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		
		# Поворот камеры по вертикали
		camera_pivot.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		# Ограничение вертикального поворота
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta):
	# Добавляем гравитацию
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Прыжок
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Определяем, спринтим ли мы
	is_sprinting = Input.is_action_pressed("sprint")
	var current_speed = sprint_speed if is_sprinting else speed

	# Получаем направление ввода
	var input_dir = Vector3.ZERO
	var direction = Vector3.ZERO
	
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.z = Input.get_axis("move_forward", "move_backward")
	
	# Нормализуем направление для стабильной скорости по диагонали
	if input_dir.length() > 1:
		input_dir = input_dir.normalized()

	# Преобразуем направление относительно ориентации персонажа
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.z)).normalized()

	# Движение
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Затухание при остановке
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Применяем движение
	move_and_slide()

func _unhandled_input(event):
	# Выход по ESC
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
