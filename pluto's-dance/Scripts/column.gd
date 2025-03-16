extends Node3D

@export var rise_speed = 2.0  # Скорость подъёма/опускания
@export var max_height = 0.0  # Высота, до которой поднимается колонна
@export var min_height = -5.0  # Высота, куда опускается колонна
@export var shake_amplitude = 0.1  # Амплитуда тряски
@export var shake_frequency = 10.0  # Частота тряски

@onready var mesh = $CSGCylinder3D51  # Ссылка на модель колонны
@onready var area = $Area3D  # Ссылка на триггер
@onready var audio = $AudioStreamPlayer3D  # Ссылка на аудиоплеер

@export var rise_sound: AudioStream  # Звук подъёма
@export var fall_sound: AudioStream  # Звук опускания

var is_player_nearby = false  # Флаг, находится ли игрок рядом
var shake_time = 0.0  # Время для расчёта тряски
var is_moving = false  # Флаг движения колонны

func _ready():
	# Изначально колонна под землёй
	mesh.position.y = min_height
	# Назначаем звуки (если они заданы в инспекторе)
	if rise_sound:
		audio.stream = rise_sound
	if fall_sound:
		audio.stream = fall_sound

func _physics_process(delta):
	# Обновляем время для тряски
	shake_time += delta * shake_frequency
	
	# Проверяем, движется ли колонна
	var previous_y = mesh.position.y
	
	if is_player_nearby:
		# Поднимаем колонну
		if mesh.position.y < max_height:
			mesh.position.y += rise_speed * delta
			_apply_shake()  # Добавляем тряску
			_play_sound(rise_sound)  # Воспроизводим звук подъёма
		else:
			mesh.position.y = max_height
			_stop_shake()  # Останавливаем тряску
			_stop_sound()  # Останавливаем звук
	else:
		# Опускаем колонну
		if mesh.position.y > min_height:
			mesh.position.y -= rise_speed * delta
			_apply_shake()  # Добавляем тряску
			_play_sound(fall_sound)  # Воспроизводим звук опускания
		else:
			mesh.position.y = min_height
			_stop_shake()  # Останавливаем тряску
			_stop_sound()  # Останавливаем звук
	
	# Проверяем, движется ли колонна
	is_moving = abs(mesh.position.y - previous_y) > 0.001

func _apply_shake():
	# Используем шум Перлина для случайной, но плавной тряски
	var shake_x = sin(shake_time) * shake_amplitude
	var shake_z = cos(shake_time * 1.5) * shake_amplitude
	mesh.position.x = shake_x
	mesh.position.z = shake_z

func _stop_shake():
	# Возвращаем колонну в центр по X и Z
	mesh.position.x = 0
	mesh.position.z = 0

func _play_sound(sound: AudioStream):
	if sound and audio.stream != sound:
		audio.stream = sound
	if is_moving and not audio.playing:
		audio.play()

func _stop_sound():
	if audio.playing and not is_moving:
		audio.stop()

func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		is_player_nearby = true

func _on_area_3d_body_exited(body):
	if body.is_in_group("player"):
		is_player_nearby = false
