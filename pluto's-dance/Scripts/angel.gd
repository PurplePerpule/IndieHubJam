extends RigidBody3D

@export var move_speed = 3.0  # Скорость движения ангела
@export var player_node: NodePath  # Путь к узлу игрока
@export var camera_node: NodePath  # Путь к камере игрока

var player: CharacterBody3D = null
var player_camera: Camera3D = null
@onready var nav_agent = $NavigationAgent3D

func _ready():
	if player_node:
		player = get_node(player_node) as CharacterBody3D
	if camera_node:
		player_camera = get_node(camera_node) as Camera3D
	
	if not player:
		print("Warning: Player node not set!")
	if not player_camera:
		print("Warning: Camera node not set!")
	if not nav_agent:
		print("Warning: NavigationAgent3D not found!")

	# Настраиваем NavigationAgent
	nav_agent.path_desired_distance = 1.0  # Расстояние до точки пути
	nav_agent.target_desired_distance = 2.0  # Расстояние остановки от цели

func _physics_process(delta):
	if not player or not player_camera or not nav_agent:
		return
	
	# Проверяем, виден ли враг на экране
	var is_visible = is_in_camera_view(player_camera)
	
	if not is_visible:
		# Обновляем цель навигации (позиция игрока)
		nav_agent.set_target_position(player.global_transform.origin)
		
		# Получаем следующую точку пути
		var next_position = nav_agent.get_next_path_position()
		var direction = (next_position - global_transform.origin).normalized()
		
		# Двигаемся к следующей точке
		linear_velocity = direction * move_speed
	else:
		# Останавливаемся, если видны
		linear_velocity = Vector3.ZERO

func is_obstructed(camera: Camera3D) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(camera.global_transform.origin, global_transform.origin)
	var result = space_state.intersect_ray(query)
	return result and result.collider != self and result.collider != player

func is_in_camera_view(camera: Camera3D) -> bool:
	var screen_pos = camera.unproject_position(global_transform.origin)
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	var is_on_screen = (screen_pos.x >= 0 and screen_pos.x <= screen_size.x and 
						screen_pos.y >= 0 and screen_pos.y <= screen_size.y)
	var camera_forward = -camera.global_transform.basis.z
	var to_enemy = (global_transform.origin - camera.global_transform.origin).normalized()
	var is_in_front = camera_forward.dot(to_enemy) > 0
	return is_on_screen and is_in_front and not is_obstructed(camera)
