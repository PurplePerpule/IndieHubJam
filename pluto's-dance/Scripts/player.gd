extends CharacterBody3D

# Настройки движения
@export var speed = 5.0
@export var sprint_speed = 8.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.3
@export var throw_force = 10.0  # Сила броска

@export var bob_frequency = 2.0  # Частота покачивания (в циклах в секунду)
@export var bob_amplitude_walk = 0.08  # Амплитуда для ходьбы
@export var bob_amplitude_sprint = 0.12  # Амплитуда для бега

# Настройки камеры
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera
@onready var raycast = $CameraPivot/RayCast3D

# Гравитация из настроек проекта
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_sprinting = false
var held_object = null  # Ссылка на удерживаемый объект
var hold_distance = 1.5  # Расстояние от камеры, на котором держится объект
var bob_timer = 0.0  # Таймер для синусоиды
var default_camera_y = 0.0  # Исходная позиция камеры по Y

var walk_type = "street"

var street_walk = [
	load("res://Assets/Sounds/SandRoadStep1_Sound.mp3"),
	load("res://Assets/Sounds/SandRoadStep2_Sound.mp3"),
	load("res://Assets/Sounds/SandRoadStep3_Sound.mp3"),
	load("res://Assets/Sounds/SandRoadStep4_Sound.mp3"),
	load("res://Assets/Sounds/SandRoadStep5_Sound.mp3")
]

var grass_walk = [
	load("res://Assets/Sounds/GrassStep1_Sound.mp3"),
	load("res://Assets/Sounds/GrassStep2_Sound.mp3"),
	load("res://Assets/Sounds/GrassStep3_Sound.mp3"),
	load("res://Assets/Sounds/GrassStep4_Sound.mp3"),
	load("res://Assets/Sounds/GrassStep5_Sound.mp3")
]

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var walking: bool = false
var last_sound_index: int = -1
var step_position: int = -1  # Начальная позиция

func _ready():
	# Захват мыши
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	default_camera_y = camera.position.y
	print("CameraPivot: ", camera_pivot)
	print("Camera: ", camera)
	print("RayCast: ", raycast)
	
	Data.change_sensitivity.connect(change_sensitivity_f)
	GlobalAudioServer.change_volume.connect(change_walk_volume)

func _input(event):
	# Обработка только движения мыши
	if event is InputEventMouseMotion and camera_pivot:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera_pivot.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
	if Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") and is_on_floor():
		if not walking:
			walking = true
			play_step_sound()
	else:
		walking = false
		audio_player.stop()


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
	
	if held_object:
		var target_pos = camera.global_transform.origin - camera.global_transform.basis.z * hold_distance
		held_object.set_linear_velocity((target_pos - held_object.global_transform.origin) * 15)
	
	update_camera_bob(delta)
	
func update_camera_bob(delta):
	if is_on_floor() and velocity.length() > 0.1:  # Покачивание только при движении на земле
		bob_timer += delta * bob_frequency * (sprint_speed if is_sprinting else speed)
		var bob_amplitude = bob_amplitude_sprint if is_sprinting else bob_amplitude_walk
		var bob_offset = sin(bob_timer) * bob_amplitude
		camera.position.y = default_camera_y + bob_offset
	else:
		# Плавное возвращение камеры в исходное положение
		bob_timer = 0.0
		camera.position.y = lerp(camera.position.y, default_camera_y, delta * 5)

func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		if held_object:
			throw_object()
		else:
			interact_with_object()

func interact_with_object():
	if raycast.is_colliding():
		var collider = raycast.get_collider()

		if collider is RigidBody3D and collider.is_in_group("pickable"):
			pick_up_object(collider)

		elif collider.is_in_group("interactive"):
			collider.interact()

func pick_up_object(object):
	held_object = object
	held_object.freeze = false
	print("Picked up: ", held_object.name)

func throw_object():
	if held_object:
		held_object.apply_central_impulse(-camera.global_transform.basis.z * throw_force)
		held_object = null
		print("Thrown object")
		
func play_step_sound():
	if not walking or street_walk.is_empty():
		return

	var new_index: int = last_sound_index
	while new_index == last_sound_index:
		new_index = randi() % street_walk.size()
	
	last_sound_index = new_index
	audio_player.stream = street_walk[new_index]
	audio_player.play()

	step_position *= -1
	audio_player.position.x = step_position

	await audio_player.finished
	if walking:
		play_step_sound()
		
		
func change_sensitivity_f(value):
	mouse_sensitivity = value 
	
func change_walk_volume(value):
	$AudioStreamPlayer3D.volume_db = value + 15
