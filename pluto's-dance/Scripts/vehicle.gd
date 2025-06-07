extends VehicleBody3D

@export var max_engine_force = 200.0
@export var max_brake_force = 10.0
@export var max_steering = 0.8
@export var steering_speed = 2.0
@export var drift_factor = 0.9
@export var drift_friction = 0.3  # Уменьшенное трение для скольжения
@export var normal_friction = 1.0  # Нормальная фрикция колес
@export var drift_steering_boost = 1.5  # Увеличенный угол поворота при дрифте
@export var drift_side_force = 100.0  # Сила бокового скольжения
@export var drift_angular_damp = 0.5  # Уменьшение углового сопротивления для заноса

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var skid_particles: GPUParticles3D = $SkidParticles  # Опционально: частицы для следов шин
@onready var drift_sound: AudioStreamPlayer3D = $DriftSound  # Опционально: звук дрифта

var look_at
var current_steering = 0.0
var is_player_inside = false
var player = null
var is_drifting = false

func _ready() -> void:
	look_at = global_position
	# Сохраняем начальное значение углового демпфирования
	if skid_particles:
		skid_particles.emitting = false
	if drift_sound:
		drift_sound.playing = false

func _physics_process(delta):
	if is_player_inside:
		# Управление движением
		engine_force = Input.get_axis("move_backward", "move_forward") * max_engine_force
		brake = Input.get_action_strength("ui_select") * max_brake_force

		# Управление поворотом
		var target_steering = Input.get_axis("move_right", "move_left") * max_steering
		if Input.is_action_pressed("drift"):
			target_steering *= drift_steering_boost  # Увеличение угла поворота
		steering = move_toward(steering, target_steering, delta * steering_speed)

		# Камера
		camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 20.0)
		camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta * 5.0)
		look_at = look_at.lerp(global_position + linear_velocity, delta * 5.0)
		camera_3d.look_at(look_at)

		# Механика дрифта
		is_drifting = Input.is_action_pressed("drift") and linear_velocity.length() > 5.0
		for wheel in get_children():
			if wheel is VehicleWheel3D:
				if is_drifting:
					wheel.wheel_friction_slip = lerp(wheel.wheel_friction_slip, drift_friction, drift_factor)
					wheel.wheel_roll_influence = 0.05  # Минимальное боковое сопротивление
				else:
					wheel.wheel_friction_slip = lerp(wheel.wheel_friction_slip, normal_friction, drift_factor)
					wheel.wheel_roll_influence = 0.0

		# Уменьшаем угловое демпфирование для заноса
		if is_drifting:
			var tilt = Input.get_axis("move_right", "move_left") * 10.0  # Угол наклона в градусах
			camera_3d.rotation_degrees.z = lerp(camera_3d.rotation_degrees.z, tilt, delta * 5.0)
			engine_force += max_engine_force * 0.3
			angular_damp = drift_angular_damp  # Уменьшаем сопротивление повороту
			var drift_direction = -transform.basis.x.normalized() * Input.get_axis("move_right", "move_left")
			apply_central_force(drift_direction * linear_velocity.length() * drift_side_force * delta)
			# Добавляем вращение для усиления заноса
			var yaw_torque = Input.get_axis("move_right", "move_left") * linear_velocity.length() * 10.0
			apply_torque_impulse(Vector3(0, yaw_torque * delta, 0))
		else:
			camera_3d.rotation_degrees.z = lerp(camera_3d.rotation_degrees.z, 0.0, delta * 5.0)
			angular_damp = -1.0  # Возвращаем нормальное демпфирование (-1 означает значение по умолчанию)

		# Визуальные и звуковые эффекты дрифта
		if skid_particles:
			skid_particles.emitting = is_drifting
		if drift_sound:
			if is_drifting and not drift_sound.playing:
				drift_sound.play()
			elif not is_drifting and drift_sound.playing:
				drift_sound.stop()

func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		print("Player entered Area3D, body:", body)
		player = body
		player.can_enter_vehicle = true
		player.vehicle = self

func _on_area_3d_body_exited(body):
	if body.is_in_group("player"):
		print("Player exited Area3D, body:", body)
		if not is_player_inside:
			player.can_enter_vehicle = false
			player.vehicle = null
			player = null

func set_player_inside(value: bool):
	is_player_inside = value
	print("set_player_inside called, value:", value)
