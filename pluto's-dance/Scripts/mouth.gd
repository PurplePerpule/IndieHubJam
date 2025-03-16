extends CharacterBody3D

enum State { WANDERING, CHASING }  # Состояния монстра

@export var move_speed = 5.0  # Скорость движения
@export var player_node: NodePath  # Путь к узлу игрока
@export var path_variation = 2.0  # Радиус случайного отклонения пути
@export var catch_distance = 1.0  # Дистанция для поимки игрока
@export var checkpoint_node: NodePath  # Путь к контрольной точке
@export var wander_radius = 10.0  # Радиус блуждания
@export var detection_range = 15.0  # Дистанция обнаружения игрока

var player: CharacterBody3D = null
@onready var nav_agent = $NavigationAgent3D
@onready var audio_player = $AudioStreamPlayer3D
@onready var checkpoint = get_node(checkpoint_node) if checkpoint_node else null
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var random = RandomNumberGenerator.new()
var current_state = State.WANDERING  # Начальное состояние — блуждание
var wander_target = Vector3.ZERO  # Текущая цель для блуждания
var time_to_new_wander = 0.0  # Таймер для смены точки блуждания

func _ready():
	if player_node:
		player = get_node(player_node) as CharacterBody3D
	
	# Проверка узлов
	if not player:
		print("Warning: Player node not set!")
	if not nav_agent:
		print("Warning: NavigationAgent3D not found!")
	if not $BigMouth/AnimationPlayer:
		print("Warning: AnimationPlayer not found!")
	if not audio_player:
		print("Warning: AudioStreamPlayer3D not found!")
	if checkpoint_node and not checkpoint:
		print("Warning: Checkpoint node not found at path ", checkpoint_node)
	
	nav_agent.path_desired_distance = 1.0
	nav_agent.target_desired_distance = 2.0
	random.randomize()

	# Настройка CollisionShape3D
	if not $CollisionShape3D:
		print("Warning: CollisionShape3D not found! Adding default box shape.")
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = BoxShape3D.new()
		collision_shape.shape.extents = Vector3(0.5, 0.2, 0.5)
		collision_shape.position.y = 0.1
		add_child(collision_shape)

	# Настройка звука
	audio_player.stream = load("res://Assets/Sounds/Bites.ogg")
	audio_player.volume_db = 20
	audio_player.max_distance = 50.0
	audio_player.unit_size = 1.0
	
	GlobalAudioServer.change_volume.connect(change_volume_f)
	GlobalAudioServer.emit_signal("get_sound")
	
	# Устанавливаем начальную точку блуждания
	_set_new_wander_target()

func change_volume_f(value):
	$AudioStreamPlayer3D.volume_db = value + 7

func _physics_process(delta):
	if not player or not nav_agent or not $BigMouth/AnimationPlayer or not audio_player:
		return
	
	# Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta * 0.5
	else:
		velocity.y = 0
	
	# Проверяем дистанцию до игрока
	var distance_to_player = global_transform.origin.distance_to(player.global_transform.origin)
	
	# Переключение состояний
	if distance_to_player < detection_range:
		current_state = State.CHASING  # Игрок в зоне видимости — преследуем
	else:
		current_state = State.WANDERING  # Игрок далеко — блуждаем
	
	# Обработка текущего состояния
	match current_state:
		State.WANDERING:
			_handle_wandering(delta)
		State.CHASING:
			_handle_chasing(delta)
	
	# Применяем движение
	move_and_slide()

func _handle_wandering(delta):
	# Уменьшаем таймер для смены точки блуждания
	time_to_new_wander -= delta
	if time_to_new_wander <= 0 or nav_agent.is_target_reached():
		_set_new_wander_target()
		time_to_new_wander = random.randf_range(2.0, 5.0)  # Новая точка каждые 2-5 секунд
	
	# Движение к цели блуждания
	nav_agent.set_target_position(wander_target)
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_transform.origin).normalized()
	
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	# Анимация и звук при движении
	if velocity.length() > 0.1:
		if not $BigMouth/AnimationPlayer.is_playing() or $BigMouth/AnimationPlayer.current_animation != "OMOMOMOM":
			$BigMouth/AnimationPlayer.play("OMOMOMOM")
		if not audio_player.playing:
			audio_player.play()
	else:
		if $BigMouth/AnimationPlayer.is_playing():
			$BigMouth/AnimationPlayer.stop()
		if audio_player.playing:
			audio_player.stop()
	
	# Ориентация
	if direction.length() > 0:
		look_at(global_transform.origin + Vector3(direction.x, 0, direction.z), Vector3.UP)
		rotation.x = 0
		rotation.z = 0

func _handle_chasing(delta):
	# Преследование игрока
	var target_position = player.global_transform.origin
	target_position.y = global_transform.origin.y  # Ограничиваем высоту
	target_position.x += random.randf_range(-path_variation, path_variation)
	target_position.z += random.randf_range(-path_variation, path_variation)
	
	nav_agent.set_target_position(target_position)
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_transform.origin).normalized()
	
	# Проверка пути
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_transform.origin, next_position)
	var result = space_state.intersect_ray(query)
	if result and result.collider is StaticBody3D:
		velocity.x = 0
		velocity.z = 0
	else:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	
	# Проверка расстояния для поимки
	var enemy_pos_2d = Vector2(global_transform.origin.x, global_transform.origin.z)
	var player_pos_2d = Vector2(player.global_transform.origin.x, player.global_transform.origin.z)
	var horizontal_distance = enemy_pos_2d.distance_to(player_pos_2d)
	
	if horizontal_distance < catch_distance:
		velocity = Vector3.ZERO
		if not $BigMouth/AnimationPlayer.is_playing() or $BigMouth/AnimationPlayer.current_animation != "OMOMOMOM":
			$BigMouth/AnimationPlayer.play("OMOMOMOM")
		if not audio_player.playing:
			audio_player.play()
		teleport_player_to_checkpoint()
		print("Player caught and teleported to checkpoint!")
	else:
		if velocity.length() > 0.1:
			if not $BigMouth/AnimationPlayer.is_playing() or $BigMouth/AnimationPlayer.current_animation != "OMOMOMOM":
				$BigMouth/AnimationPlayer.play("OMOMOMOM")
			if not audio_player.playing:
				audio_player.play()
		else:
			if $BigMouth/AnimationPlayer.is_playing():
				$BigMouth/AnimationPlayer.stop()
			if audio_player.playing:
				audio_player.stop()
	
	# Ориентация
	if direction.length() > 0:
		look_at(global_transform.origin + Vector3(direction.x, 0, direction.z), Vector3.UP)
		rotation.x = 0
		rotation.z = 0

func _set_new_wander_target():
	# Выбираем случайную точку в радиусе блуждания
	var random_angle = random.randf_range(0, TAU)  # TAU = 2 * PI
	var random_distance = random.randf_range(0, wander_radius)
	wander_target = global_transform.origin + Vector3(
		cos(random_angle) * random_distance,
		0,
		sin(random_angle) * random_distance
	)
	# Убеждаемся, что цель на уровне земли
	wander_target.y = global_transform.origin.y

func teleport_player_to_checkpoint():
	if checkpoint and player:
		player.global_transform.origin = checkpoint.global_transform.origin
		print("Player teleported to checkpoint at ", checkpoint.global_transform.origin)
