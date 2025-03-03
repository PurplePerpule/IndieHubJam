extends CharacterBody3D

@export var move_speed = 3.0  # Базовая скорость движения ангела
@export var player_node: NodePath  # Путь к узлу игрока
@export var camera_node: NodePath  # Путь к камере игрока
@export var catch_distance = 1.0  # Дистанция для захвата игрока
@export var path_variation = 2.0  # Максимальный радиус случайного отклонения пути (в единицах)
@export var speed_variation = 0.1  # Максимальная случайная вариация скорости (в процентах, 0.1 = ±10%)
@export var avoid_distance = 1.5  # Минимальное расстояние между врагами, чтобы они не касались друг друга
@export var detection_radius = 10.0  # Радиус зоны обнаружения игрока (в единицах)
@export var checkpoint_node: NodePath  # Путь к узлу контрольной точки (например, Marker3D)

var player: CharacterBody3D = null
var player_camera: Camera3D = null
@onready var nav_agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var random = RandomNumberGenerator.new()  # Генератор случайных чисел
var player_once_detected = false  # Флаг, указывающий, что игрок был хотя бы раз обнаружен

@onready var footstep_sound = $AudioStreamPlayer3D  # Ссылка на звук ходьбы
@onready var checkpoint = get_node(checkpoint_node) if checkpoint_node else null  # Ссылка на контрольную точку

func _ready():
	add_to_group("weeping_angels")  # Добавляем врага в группу для проверки столкновений
	if player_node:
		player = get_node(player_node) as CharacterBody3D
	if camera_node:
		player_camera = get_node(camera_node) as Camera3D
	if checkpoint_node and not checkpoint:
		print("Warning: Checkpoint node not found at path ", checkpoint_node)
	
	if not player:
		print("Warning: Player node not set!")
	if not player_camera:
		print("Warning: Camera node not set!")
	if not nav_agent:
		print("Warning: NavigationAgent3D not found!")
	if not $maskeed/AnimationPlayer:
		print("Warning: AnimationPlayer not found!")
	if not footstep_sound:
		print("Warning: AudioStreamPlayer3D (footstep sound) not found!")
	
	nav_agent.path_desired_distance = 1.0
	nav_agent.target_desired_distance = 2.0
	random.randomize()  # Инициализируем генератор случайных чисел

	# Убедитесь, что CollisionShape3D настроен
	if not $CollisionShape3D:
		print("Warning: CollisionShape3D not found! Adding default capsule shape.")
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = CapsuleShape3D.new()
		collision_shape.shape.height = 2.0  # Высота врага
		collision_shape.shape.radius = 0.5  # Радиус врага
		add_child(collision_shape)

	# Настраиваем звук ходьбы
	footstep_sound.stream = load("res://Assets/Sounds/brainless2.ogg")  # Замените на путь к звуковому файлу (например, шаги или скрежет)
	footstep_sound.volume_db = -10  # Настройте громкость
	footstep_sound.max_distance = 20.0  # Максимальная дистанция звука
	footstep_sound.unit_size = 1.0  # Масштаб звука (определяет затухание с расстоянием)

func _physics_process(delta):
	if not player or not player_camera or not nav_agent or not $maskeed/AnimationPlayer or not footstep_sound:
		return
	
	# Добавляем гравитацию
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	
	# Проверяем расстояние до игрока для обнаружения
	var distance_to_player = global_transform.origin.distance_to(player.global_transform.origin)
	
	# Устанавливаем флаг, если игрок впервые входит в зону обнаружения
	if distance_to_player <= detection_radius and not player_once_detected:
		player_once_detected = true
		print("Player detected! Angels will now pursue constantly.")
	
	var is_visible = is_in_camera_view(player_camera)
	
	if distance_to_player < catch_distance and not is_visible and (player_once_detected or distance_to_player <= detection_radius):
		# Захват игрока и телепортация на контрольную точку
		velocity = Vector3.ZERO
		if not $maskeed/AnimationPlayer.is_playing() or $maskeed/AnimationPlayer.current_animation != "catch":
			$maskeed/AnimationPlayer.play("catch")
			print("Player caught!")
			$"../Narkoman/CloseEyes/Eyes".play("close")
			await get_tree().create_timer(1.1).timeout
			teleport_player_to_checkpoint()
			$"../Narkoman/CloseEyes/Eyes".play_backwards("close")
			
	elif not is_visible and player_once_detected:
		# Движение к игроку с динамическим случайным отклонением пути (постоянное преследование после обнаружения)
		var target_position = player.global_transform.origin
		# Динамическое отклонение, зависящее от расстояния
		var dynamic_variation = min(path_variation, distance_to_player * 0.5)  # Отклонение зависит от расстояния
		target_position.x += random.randf_range(-dynamic_variation, dynamic_variation)
		target_position.z += random.randf_range(-dynamic_variation, dynamic_variation)
		
		nav_agent.set_target_position(target_position)
		var next_position = nav_agent.get_next_path_position()
		var direction = (next_position - global_transform.origin).normalized()
		
		# Применяем случайную вариацию скорости
		var effective_speed = move_speed * (1.0 + random.randf_range(-speed_variation, speed_variation))
		
		# Проверка столкновений с другими врагами
		var avoid_force = avoid_other_angels()
		if avoid_force.length() > 0:
			direction += avoid_force.normalized() * 0.5  # Лёгкое отклонение от других врагов
			direction = direction.normalized()  # Нормализуем, чтобы сохранить скорость
		
		velocity.x = direction.x * effective_speed
		velocity.z = direction.z * effective_speed
		look_at(player.global_transform.origin, Vector3.UP)
		rotation.x = 0  # Фиксируем наклон по X
		rotation.z = 0  # Фиксируем наклон по Z
		
		if not $maskeed/AnimationPlayer.is_playing() or $maskeed/AnimationPlayer.current_animation != "run":
			$maskeed/AnimationPlayer.play("run")
		# Воспроизводим звук ходьбы, если враг движется
		if velocity.length() > 0.1 and not footstep_sound.playing:
			footstep_sound.play()
	else:
		# Остановка, если игрок виден или не был обнаружен
		velocity.x = 0
		velocity.z = 0
		if not $maskeed/AnimationPlayer.is_playing() or $maskeed/AnimationPlayer.current_animation != "stand":
			$maskeed/AnimationPlayer.play("stand")
		# Останавливаем звук, если враг неподвижен
		if footstep_sound.playing:
			footstep_sound.stop()
	
	# Применяем движение
	move_and_slide()

# Проверка и избегание других врагов
func avoid_other_angels() -> Vector3:
	var avoidance_force = Vector3.ZERO
	var angels = get_tree().get_nodes_in_group("weeping_angels")
	
	for angel in angels:
		if angel != self:  # Пропускаем самого себя
			var distance = global_transform.origin.distance_to(angel.global_transform.origin)
			if distance < avoid_distance:
				# Вычисляем вектор отталкивания (направление от другого врага)
				var push_away = (global_transform.origin - angel.global_transform.origin).normalized()
				avoidance_force += push_away * (avoid_distance - distance) / avoid_distance  # Сила зависит от расстояния
	
	return avoidance_force

# Телепортация игрока на контрольную точку
func teleport_player_to_checkpoint():
	if checkpoint and player:
		player.global_transform.origin = checkpoint.global_transform.origin  # Телепортируем игрока
		print("Player teleported to checkpoint at ", checkpoint.global_transform.origin)

func is_obstructed(camera: Camera3D) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(camera.global_transform.origin, global_transform.origin)
	var result = space_state.intersect_ray(query)
	return result and result.collider != self and result.collider != player

func is_in_camera_view(camera: Camera3D) -> bool:
	var screen_pos = camera.unproject_position(global_transform.origin)
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	var is_on_screen = (screen_pos.x >= 0 and screen_pos.x <= screen_size.x and screen_pos.y >= 0 and screen_pos.y <= screen_size.y)
	var camera_forward = -camera.global_transform.basis.z
	var to_enemy = (global_transform.origin - camera.global_transform.origin).normalized()
	var is_in_front = camera_forward.dot(to_enemy) > 0
	return is_on_screen and is_in_front and not is_obstructed(camera)
