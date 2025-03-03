extends CharacterBody3D

@export var move_speed = 5.0  # Скорость преследования
@export var player_node: NodePath  # Путь к узлу игрока
@export var path_variation = 2.0  # Радиус случайного отклонения пути (в единицах)
@export var catch_distance = 1.0  # Дистанция для поимки игрока (горизонтальная)
@export var checkpoint_node: NodePath  # Путь к узлу контрольной точки (например, Marker3D)

var player: CharacterBody3D = null
@onready var nav_agent = $NavigationAgent3D
@onready var audio_player = $AudioStreamPlayer3D  # Ссылка на AudioStreamPlayer3D
@onready var checkpoint = get_node(checkpoint_node) if checkpoint_node else null  # Ссылка на контрольную точку
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var random = RandomNumberGenerator.new()  # Генератор случайных чисел

func _ready():
	if player_node:
		player = get_node(player_node) as CharacterBody3D
	
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
	random.randomize()  # Инициализируем генератор случайных чисел

	# Убедитесь, что CollisionShape3D настроен
	if not $CollisionShape3D:
		print("Warning: CollisionShape3D not found! Adding default box shape for crawling enemy.")
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = BoxShape3D.new()
		collision_shape.shape.extents = Vector3(0.5, 0.2, 0.5)  # Широкая и низкая форма для ползающего рта
		collision_shape.position.y = 0.1  # Немного выше земли
		add_child(collision_shape)

	# Настраиваем звук
	audio_player.stream = load("res://Assets/Sounds/Bites.ogg")  # Замените на путь к звуковому файлу
	audio_player.volume_db = 20  # Настройте громкость
	audio_player.max_distance = 50.0  # Максимальная дистанция звука
	audio_player.unit_size = 1.0  # Масштаб звука (определяет, как звук затухает с расстоянием)
	
	GlobalAudioServer.change_volume.connect(change_volume_f)
	GlobalAudioServer.emit_signal("get_sound")
	
	
func change_volume_f(value):
	$AudioStreamPlayer3D.volume_db = value + 7


func _physics_process(delta):
	if not player or not nav_agent or not $BigMouth/AnimationPlayer or not audio_player:
		return
	
	# Добавляем гравитацию (мягкую, чтобы ползающий враг не проваливался)
	if not is_on_floor():
		velocity.y -= gravity * delta * 0.5  # Уменьшаем гравитацию для ползающего врага
	else:
		velocity.y = 0  # Прижаты к земле
	
	# Преследование игрока с случайным отклонением пути
	var target_position = player.global_transform.origin
	# Убедимся, что цель на уровне земли (для ползающего врага)
	target_position.y = global_transform.origin.y  # Ограничиваем высоту движения
	target_position.x += random.randf_range(-path_variation, path_variation)
	target_position.z += random.randf_range(-path_variation, path_variation)
	
	nav_agent.set_target_position(target_position)
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_transform.origin).normalized()
	
	# Проверка, не ведёт ли путь в провал
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_transform.origin, next_position)
	var result = space_state.intersect_ray(query)
	if result and result.collider is StaticBody3D:  # Если путь упирается в пол или препятствие
		velocity.x = 0
		velocity.z = 0
	else:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	
	# Проверяем горизонтальное расстояние до игрока для поимки (только X и Z)
	var enemy_pos_2d = Vector2(global_transform.origin.x, global_transform.origin.z)
	var player_pos_2d = Vector2(player.global_transform.origin.x, player.global_transform.origin.z)
	var horizontal_distance = enemy_pos_2d.distance_to(player_pos_2d)
	
	# Поимка игрока, если он близко горизонтально
	if horizontal_distance < catch_distance:
		# Поимка игрока и телепортация на контрольную точку
		velocity = Vector3.ZERO
		if not $BigMouth/AnimationPlayer.is_playing() or $BigMouth/AnimationPlayer.current_animation != "OMOMOMOM":
			$BigMouth/AnimationPlayer.play("OMOMOMOM")  # Продолжаем играть анимацию поимки
		if not audio_player.playing:
			audio_player.play()  # Продолжаем играть звук
		teleport_player_to_checkpoint()
		print("Player caught and teleported to checkpoint!")
	else:
		# Воспроизводим анимацию и звук, если враг движется
		if velocity.length() > 0.1:  # Если враг движется (скорость больше минимальной)
			if not $BigMouth/AnimationPlayer.is_playing() or $BigMouth/AnimationPlayer.current_animation != "OMOMOMOM":
				$BigMouth/AnimationPlayer.play("OMOMOMOM")
			if not audio_player.playing:
				audio_player.play()
		else:
			if $BigMouth/AnimationPlayer.is_playing():
				$BigMouth/AnimationPlayer.stop()
			if audio_player.playing:
				audio_player.stop()
	
	# Ориентируем врага в направлении движения (по горизонтали)
	if direction.length() > 0:
		look_at(global_transform.origin + Vector3(direction.x, 0, direction.z), Vector3.UP)
		rotation.x = 0  # Фиксируем наклон по X
		rotation.z = 0  # Фиксируем наклон по Z
	
	# Применяем движение
	move_and_slide()

# Телепортация игрока на контрольную точку
func teleport_player_to_checkpoint():
	if checkpoint and player:
		player.global_transform.origin = checkpoint.global_transform.origin  # Телепортируем игрока
		print("Player teleported to checkpoint at ", checkpoint.global_transform.origin)
