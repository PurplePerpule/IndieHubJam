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

var player_shader_material: ShaderMaterial

var player: CharacterBody3D = null
var player_camera: Camera3D = null
@onready var nav_agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var random = RandomNumberGenerator.new()  # Генератор случайных чисел
var player_once_detected = false  # Флаг, указывающий, что игрок был хотя бы раз обнаружен

@onready var checkpoint = get_node(checkpoint_node) if checkpoint_node else null  # Ссылка на контрольную точку

func _ready():
	var playershd = get_tree().get_first_node_in_group("player")
	if playershd:
		player_shader_material = playershd.get_node("Crossfire/PixelShader").material
	add_to_group("weeping_angels")
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
	
	nav_agent.path_desired_distance = 1.0
	nav_agent.target_desired_distance = 2.0
	random.randomize()

	if not $CollisionShape3D:
		print("Warning: CollisionShape3D not found! Adding default capsule shape.")
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = CapsuleShape3D.new()
		collision_shape.shape.height = 2.0
		collision_shape.shape.radius = 0.5
		add_child(collision_shape)

	GlobalAudioServer.change_music.connect(change_music_f)
	GlobalAudioServer.emit_signal("get_sound")

func change_music_f(value):
	pass  # Оставляем пустой, так как он больше не управляет звуком

func _physics_process(delta):
	if not player or not player_camera or not nav_agent or not $maskeed/AnimationPlayer:
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	
	var distance_to_player = global_transform.origin.distance_to(player.global_transform.origin)
	
	if distance_to_player <= detection_radius and not player_once_detected:
		player_once_detected = true
		print("Player detected! Angels will now pursue constantly.")
	
	var is_visible = is_in_camera_view(player_camera)
	
	if distance_to_player < catch_distance and not is_visible and (player_once_detected or distance_to_player <= detection_radius):
		velocity = Vector3.ZERO
		if not $maskeed/AnimationPlayer.is_playing() or $maskeed/AnimationPlayer.current_animation != "catch":
			$maskeed/AnimationPlayer.play("catch")
			print("Player caught!")
			$"../Narkoman/CloseEyes/Eyes".play("close")
			await get_tree().create_timer(1.1).timeout
			teleport_player_to_checkpoint()
			$"../Narkoman/CloseEyes/Eyes".play_backwards("close")
			
	elif not is_visible and player_once_detected:
		var target_position = player.global_transform.origin
		var dynamic_variation = min(path_variation, distance_to_player * 0.5)
		target_position.x += random.randf_range(-dynamic_variation, dynamic_variation)
		target_position.z += random.randf_range(-dynamic_variation, dynamic_variation)
		
		nav_agent.set_target_position(target_position)
		var next_position = nav_agent.get_next_path_position()
		var direction = (next_position - global_transform.origin).normalized()
		
		var effective_speed = move_speed * (1.0 + random.randf_range(-speed_variation, speed_variation))
		
		var avoid_force = avoid_other_angels()
		if avoid_force.length() > 0:
			direction += avoid_force.normalized() * 0.5
			direction = direction.normalized()
		
		velocity.x = direction.x * effective_speed
		velocity.z = direction.z * effective_speed
		look_at(player.global_transform.origin, Vector3.UP)
		rotation.x = 0
		rotation.z = 0
		
		if not $maskeed/AnimationPlayer.is_playing() or $maskeed/AnimationPlayer.current_animation != "run":
			$maskeed/AnimationPlayer.play("run")
		
	else:
		velocity.x = 0
		velocity.z = 0
		if not $maskeed/AnimationPlayer.is_playing() or $maskeed/AnimationPlayer.current_animation != "stay":
			$maskeed/AnimationPlayer.play("stay")
	
	move_and_slide()

func avoid_other_angels() -> Vector3:
	var avoidance_force = Vector3.ZERO
	var angels = get_tree().get_nodes_in_group("weeping_angels")
	
	for angel in angels:
		if angel != self:
			var distance = global_transform.origin.distance_to(angel.global_transform.origin)
			if distance < avoid_distance:
				var push_away = (global_transform.origin - angel.global_transform.origin).normalized()
				avoidance_force += push_away * (avoid_distance - distance) / avoid_distance
	
	return avoidance_force

func teleport_player_to_checkpoint():
	if checkpoint and player:
		player.global_transform.origin = checkpoint.global_transform.origin
		print("Player teleported to checkpoint at ", checkpoint.global_transform.origin)
		if player_shader_material:
			player_shader_material.set_shader_parameter("shake", 0.5)
			player_shader_material.set_shader_parameter("grainIntensity", 1.0)
			await get_tree().create_timer(0.5).timeout
			player_shader_material.set_shader_parameter("grainIntensity", 0.0)

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
