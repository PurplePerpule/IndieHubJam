extends RigidBody3D

@export var move_speed = 3.0  # Скорость движения ангела
@export var player_node: NodePath  # Путь к узлу игрока
@export var camera_node: NodePath  # Путь к камере игрока

var player: CharacterBody3D = null  # Ссылка на игрока
var player_camera: Camera3D = null  # Ссылка на камеру

func _ready():
	# Получаем узлы из указанных путей
	if player_node:
		player = get_node(player_node) as CharacterBody3D
	if camera_node:
		player_camera = get_node(camera_node) as Camera3D
	
	# Проверка на случай, если узлы не указаны
	if not player:
		print("Warning: Player node not set!")
	if not player_camera:
		print("Warning: Camera node not set!")

func _physics_process(delta):
	if not player or not player_camera:
		return
	
	# Проверяем, виден ли враг на экране
	var is_visible = is_in_camera_view(player_camera)
	
	if not is_visible:
		# Двигаемся к игроку, если не видны
		var direction_to_player = (player.global_transform.origin - global_transform.origin).normalized()
		linear_velocity = direction_to_player * move_speed
	else:
		# Останавливаемся, если видны
		linear_velocity = Vector3.ZERO

func is_in_camera_view(camera: Camera3D) -> bool:
	# Проецируем позицию врага в экранные координаты
	var screen_pos = camera.unproject_position(global_transform.origin)
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	
	# Проверяем, находится ли враг в пределах экрана
	var is_on_screen = (screen_pos.x >= 0 and screen_pos.x <= screen_size.x and 
						screen_pos.y >= 0 and screen_pos.y <= screen_size.y)
	
	# Проверяем, находится ли враг перед камерой
	var camera_forward = -camera.global_transform.basis.z
	var to_enemy = (global_transform.origin - camera.global_transform.origin).normalized()
	var is_in_front = camera_forward.dot(to_enemy) > 0
	
	return is_on_screen and is_in_front
