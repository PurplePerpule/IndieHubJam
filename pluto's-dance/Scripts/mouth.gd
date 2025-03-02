extends CharacterBody3D

@export var move_speed = 5.0  # Скорость преследования
@export var player_node: NodePath  # Путь к узлу игрока
@export var path_variation = 2.0  # Радиус случайного отклонения пути (в единицах)

var player: CharacterBody3D = null
@onready var nav_agent = $NavigationAgent3D
@onready var audio_player = $AudioStreamPlayer3D  # Ссылка на AudioStreamPlayer3D
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

	# Настраиваем звук
	audio_player.stream = load("res://Assets/Sounds/Bites.ogg")  # Замените на путь к звуковому файлу
	audio_player.volume_db = 20  # Настройте громкость
	audio_player.max_distance = 50.0  # Максимальная дистанция звука
	audio_player.unit_size = 1.0  # Масштаб звука (заменяет attenuation, определяет, как звук затухает с расстоянием)

func _physics_process(delta):
	if not player or not nav_agent or not $BigMouth/AnimationPlayer or not audio_player:
		return
	
	# Добавляем гравитацию
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	
	# Преследование игрока с случайным отклонением пути
	var target_position = player.global_transform.origin
	# Добавляем случайное отклонение к позиции игрока
	target_position.x += random.randf_range(-path_variation, path_variation)
	target_position.z += random.randf_range(-path_variation, path_variation)
	
	nav_agent.set_target_position(target_position)
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_transform.origin).normalized()
	
	# Устанавливаем скорость движения
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
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
	
	# Ориентируем врага в направлении движения
	if direction.length() > 0:
		look_at(global_transform.origin + direction, Vector3.UP)
		rotation.x = 0  # Фиксируем наклон по X
		rotation.z = 0  # Фиксируем наклон по Z
	
	# Применяем движение
	move_and_slide()
