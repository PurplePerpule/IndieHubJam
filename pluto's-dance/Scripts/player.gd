extends CharacterBody3D

# Настройки движения
@export var speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.3
@export var throw_force: float = 10.0
@export var bob_frequency: float = 2.0
@export var bob_amplitude_walk: float = 0.08
@export var bob_amplitude_sprint: float = 0.12

# Настройки камеры и интерактивных узлов
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera
@onready var raycast = $CameraPivot/RayCast3D
@onready var weapon_holder = $ModelWrapper/Deadman/Armature/Skeleton3D/BoneAttachment3D2/WeaponHolder
@onready var lantern_holder = $ModelWrapper/Deadman/Armature/Skeleton3D/BoneAttachment3D/LanternHolder
@onready var skeleton: Skeleton3D = $ModelWrapper/Deadman/Armature/Skeleton3D
@onready var audio_player = $AudioStreamPlayer3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $Deadman/AnimationPlayer

# --- Новые переменные для машины ---
var can_enter_vehicle = false
var vehicle = null
var is_in_vehicle = false

# Гравитация
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_sprinting = false
var held_object = null
var held_object_type = ""
var hold_distance = 1.5
var bob_timer = 0.0
var default_camera_y = 0.0
var is_aiming = false
var is_shooting = false
var torso_bone_index: int = -1

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

var last_sound_index: int = -1
var step_timer: float = 0.0
@export var step_interval: float = 1.3

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	default_camera_y = camera.position.y
	
	Data.change_sensitivity.connect(change_sensitivity_f)
	GlobalAudioServer.change_volume.connect(change_walk_volume)
	GlobalAudioServer.emit_signal("get_sound")
	
	if skeleton:
		torso_bone_index = skeleton.find_bone("Bone.001")
		if torso_bone_index == -1:
			print("Warning: Torso bone 'Bone.001' not found! Check bone name in Skeleton3D.")
	
	# --- Добавляем игрока в группу для обнаружения машиной ---
	add_to_group("player")

func _input(event):
	if is_in_vehicle:
		# Обрабатываем только ввод для выхода из машины
		if event.is_action_pressed("interact"):
			exit_vehicle()
		return
	
	if event is InputEventMouseMotion and camera_pivot:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		var new_rotation_x = camera_pivot.rotation.x + deg_to_rad(-event.relative.y * mouse_sensitivity)
		new_rotation_x = clamp(new_rotation_x, deg_to_rad(-90), deg_to_rad(90))
		camera_pivot.rotation.x = new_rotation_x
	
	if event.is_action_pressed("interact"):
		if can_enter_vehicle:
			enter_vehicle()
		elif held_object:
			drop_object()
		else:
			interact_with_object()
	if held_object:
		if event.is_action_pressed("left_click"):
			perform_left_action()
		if event.is_action_pressed("right_click"):
			perform_right_action()

func _physics_process(delta):
	if is_in_vehicle:
		# Отключаем физику игрока в машине
		velocity = Vector3.ZERO
		return
	
	# Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	# Прыжок
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Спринт
	is_sprinting = Input.is_action_pressed("sprint")
	var current_speed = sprint_speed if is_sprinting else speed

	# Получение направления ввода
	var input_dir = Vector3.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.z = Input.get_axis("move_forward", "move_backward")
	
	if input_dir.length() > 1:
		input_dir = input_dir.normalized()

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.z)).normalized()
	if is_aiming == true and !direction:
		$Crossfire/Label.visible = false
		$ModelWrapper/Deadman/Armature/Skeleton3D/BoneAttachment3D3/Camera3D.current = true
	else:
		camera.current = true
		$Crossfire/Label.visible = true

	# Движение
	if direction:
		camera.fov = lerp(camera.fov, 75.0, 0.1)
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		if held_object and held_object_type == "weapon":
			animation_tree.set("parameters/Stay/transition_request", "false")
			animation_tree.set("parameters/Walk_with_item/transition_request", "true")
			animation_tree.set("parameters/itemw/transition_request", "weapon")
		elif held_object and held_object_type == "lantern":
			animation_tree.set("parameters/Stay/transition_request", "false")
			animation_tree.set("parameters/Walk_with_item/transition_request", "true")
			animation_tree.set("parameters/itemw/transition_request", "lantern")
		else:
			animation_tree.set("parameters/Stay/transition_request", "false")
			animation_tree.set("parameters/Walk/transition_request", "true")
			animation_tree.set("parameters/Walk_with_item/transition_request", "false")
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		if held_object and held_object_type == "weapon":
			if is_aiming and not is_shooting:
				camera.fov = lerp(camera.fov, 50.0, 0.1)
				animation_tree.set("parameters/Stay/transition_request", "true")
				animation_tree.set("parameters/Stay_with_item/transition_request", "true")
				animation_tree.set("parameters/item/transition_request", "weapon")
				animation_tree.set("parameters/weapon/transition_request", "aim")
				sync_torso_with_camera()
			elif is_shooting:
				pass
			else:
				camera.fov = lerp(camera.fov, 75.0, 0.1)
				animation_tree.set("parameters/Stay/transition_request", "true")
				animation_tree.set("parameters/Stay_with_item/transition_request", "true")
				animation_tree.set("parameters/item/transition_request", "weapon")
				animation_tree.set("parameters/weapon/transition_request", "state")
				if skeleton and torso_bone_index != -1:
					skeleton.set_bone_pose_rotation(torso_bone_index, Quaternion.IDENTITY)
		elif held_object and held_object_type == "lantern":
			camera.fov = lerp(camera.fov, 75.0, 0.1)
			animation_tree.set("parameters/Stay/transition_request", "true")
			animation_tree.set("parameters/Stay_with_item/transition_request", "true")
			animation_tree.set("parameters/item/transition_request", "lantern")
		else:
			camera.fov = lerp(camera.fov, 75.0, 0.1)
			animation_tree.set("parameters/Stay/transition_request", "true")
			animation_tree.set("parameters/Stay_with_item/transition_request", "false")
			animation_tree.set("parameters/Walk/transition_request", "false")
			animation_tree.set("parameters/Walk_with_item/transition_request", "false")

	# Применяем движение
	move_and_slide()
	
	# Обновление позиции удерживаемого объекта
	if held_object and held_object_type == "normal":
		var target_pos = camera.global_transform.origin - camera.global_transform.basis.z * hold_distance
		held_object.set_linear_velocity((target_pos - held_object.global_transform.origin) * 15)

	update_camera_bob(delta)
	handle_footsteps(delta)

# --- Новые методы для работы с машиной ---
func enter_vehicle():
	if vehicle and not is_in_vehicle:
		is_in_vehicle = true
		vehicle.set_player_inside(true)
		camera.current = false
		$"../VehicleBody3D/CameraPivot/Camera3D".current = true
		global_transform.origin = vehicle.global_transform.origin  # Скрываем игрока
		set_physics_process(false)
		$ModelWrapper.hide()  # Скрываем модель персонажа
		if held_object:
			drop_object()  # Сбрасываем удерживаемый объект
		print("Entered vehicle")

func exit_vehicle():
	if is_in_vehicle and vehicle:
		print("Exiting vehicle, vehicle:", vehicle)
		is_in_vehicle = false
		vehicle.set_player_inside(false)
		camera.current = true
		$"../VehicleBody3D/CameraPivot/Camera3D".current = false
		var exit_pos = vehicle.global_transform.origin + Vector3(2, 1, 0)
		if not test_move(global_transform, exit_pos - global_transform.origin):
			global_transform.origin = exit_pos
		else:
			exit_pos = vehicle.global_transform.origin + Vector3(-2, 1, 0)
			if not test_move(global_transform, exit_pos - global_transform.origin):
				global_transform.origin = exit_pos
			else:
				print("Warning: No safe exit position found!")
				global_transform.origin = vehicle.global_transform.origin + Vector3(0, 1, 0)
		set_physics_process(true)
		$ModelWrapper.show()
		print("Exited vehicle")
	else:
		print("Failed to exit vehicle: vehicle is null or not in vehicle")

# --- Остальные методы без изменений ---
func sync_torso_with_camera():
	if skeleton and torso_bone_index != -1:
		var camera_rotation_x = camera_pivot.rotation.x
		camera_rotation_x = clamp(camera_rotation_x, deg_to_rad(-45), deg_to_rad(45))
		var torso_rotation = Quaternion.from_euler(Vector3(0, 0, camera_rotation_x))
		var rest_rotation = skeleton.get_bone_rest(torso_bone_index).basis.get_rotation_quaternion()
		var final_rotation = torso_rotation * rest_rotation
		skeleton.set_bone_pose_rotation(torso_bone_index, final_rotation)
	else:
		print("Error: Skeleton or torso bone index not set")

func update_camera_bob(delta):
	if is_on_floor() and velocity.length() > 0.1:
		var frequency = bob_frequency if bob_frequency != null else 2.0
		var current_speed = sprint_speed if is_sprinting else speed
		if current_speed == null:
			print("Warning: current_speed is null! Using default speed of 5.0")
			current_speed = 5.0
		bob_timer += delta * frequency * current_speed
		var bob_amplitude = bob_amplitude_sprint if is_sprinting else bob_amplitude_walk
		if bob_amplitude == null:
			print("Warning: bob_amplitude is null! Using default amplitude of 0.08")
			bob_amplitude = 0.08
		var bob_offset = sin(bob_timer) * bob_amplitude
		camera.position.y = default_camera_y + bob_offset
	else:
		bob_timer = 0.0
		camera.position.y = lerp(camera.position.y, default_camera_y, delta * 5)

func handle_footsteps(delta):
	if is_on_floor() and velocity.length() > 0.1:
		var current_speed = sprint_speed if is_sprinting else speed
		if current_speed == null:
			print("Warning: current_speed is null! Using default speed of 5.0")
			current_speed = 5.0
		step_timer += delta * current_speed / 2.0
		if step_timer >= step_interval:
			step_timer = 0.0
			play_step_sound()
	else:
		if audio_player.playing:
			audio_player.stop()

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
	if object.is_in_group("weapon"):
		held_object_type = "weapon"
		attach_to_holder(object, weapon_holder)
		is_aiming = false
		is_shooting = false
	elif object.is_in_group("lantern"):
		held_object_type = "lantern"
		attach_to_holder(object, lantern_holder)
	else:
		held_object_type = "normal"
		held_object.pickable()
	print("Picked up: ", held_object.name, " Type: ", held_object_type)

func attach_to_holder(held_object, holder):
	var old_parent = held_object.get_parent()
	if old_parent:
		old_parent.remove_child(held_object)
	holder.add_child(held_object)
	held_object.global_transform = holder.global_transform
	held_object.set_linear_velocity(Vector3.ZERO)
	if held_object is RigidBody3D:
		held_object.freeze = true

func drop_object():
	if held_object:
		if held_object_type == "weapon" and is_aiming:
			held_object.stop_aiming()
			is_aiming = false
		if held_object_type == "normal":
			held_object.throw()
			held_object.apply_central_impulse(-camera.global_transform.basis.z * throw_force)
		else:
			var holder = weapon_holder if held_object_type == "weapon" else lantern_holder
			holder.remove_child(held_object)
			get_tree().current_scene.add_child(held_object)
			held_object.global_transform = holder.global_transform
			if held_object is RigidBody3D:
				held_object.freeze = false
				held_object.apply_central_impulse(-camera.global_transform.basis.z * throw_force)
		held_object = null
		held_object_type = ""
		is_shooting = false
		print("Dropped object")

func perform_left_action():
	if held_object:
		if held_object_type == "weapon" and is_aiming and not is_shooting:
			if held_object.has_method("shoot"):
				print("Triggering shoot animation and action")
				is_shooting = true
				animation_tree.set("parameters/Stay/transition_request", "true")
				animation_tree.set("parameters/Stay_with_item/transition_request", "true")
				animation_tree.set("parameters/item/transition_request", "weapon")
				animation_tree.set("parameters/weapon/transition_request", "action")
				held_object.shoot()
				await get_tree().create_timer(0.21).timeout
				shoot_ready()
		elif held_object_type == "lantern":
			if held_object.has_method("toggle_light"):
				held_object.toggle_light()

func perform_right_action():
	if held_object:
		if held_object_type == "weapon":
			if held_object.has_method("aim"):
				is_aiming = !is_aiming
				if is_aiming:
					print("Switching to aim state")
					held_object.aim()
				else:
					print("Switching to state (non-aiming)")
					held_object.stop_aiming()
		elif held_object_type == "lantern":
			if held_object.has_method("adjust_brightness"):
				held_object.adjust_brightness()

func shoot_ready():
	print("Shoot animation finished, returning to state")
	is_shooting = false
	if is_aiming:
		animation_tree.set("parameters/weapon/transition_request", "aim")
	else:
		animation_tree.set("parameters/weapon/transition_request", "state")

func play_step_sound():
	if street_walk.is_empty():
		return
	var new_index: int = last_sound_index
	while new_index == last_sound_index:
		new_index = randi() % street_walk.size()
	last_sound_index = new_index
	audio_player.stream = street_walk[new_index]
	audio_player.play()

func change_sensitivity_f(value):
	mouse_sensitivity = value

func change_walk_volume(value):
	audio_player.volume_db = value + 7
