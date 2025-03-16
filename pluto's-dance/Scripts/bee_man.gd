extends CharacterBody3D

var has_ingredients = false  # Состояние квеста: получены ли ингредиенты
var quest_completed = false  # Состояние квеста: завершён ли квест

@export var flowerfind = 0
@export var quest_completed_all = false

var started = false
var findflowers = false
var end = false
var flag = false

func _physics_process(delta: float) -> void:
	if flag == false:
		$AnimationTree.set("parameters/has_ingredients/transition_request", "False")
	

func interact():
	if flowerfind == 3:
		findflowers = true
	
	if started == false:
		Dialogic.timeline_ended.connect(start)
		Dialogic.start("HelpBeeMan")
	elif started == true and findflowers == false and end == false:
		Dialogic.start("WaitFlowers")
		
	elif findflowers == true:
		Dialogic.start("FindFlowers")
		Dialogic.timeline_ended.connect(flowers)
	if end == true:
		Dialogic.start("EndBee")
		$AnimationTree.set("parameters/why?/transition_request", "True")
		await get_tree().create_timer(1).timeout
		$AnimationTree.set("parameters/why?/transition_request", "False")
		
		
		
func start():
	Dialogic.timeline_ended.disconnect(start)
	started = true
	
func flowers():
	Dialogic.timeline_ended.disconnect(flowers)
	$"../Narkoman/CloseEyes/Eyes".play("close")
	flag = true
	$AnimationTree.set("parameters/has_ingredients/transition_request", "True")
	await get_tree().create_timer(1).timeout
	$"../sounds/bee".playing = false
	$BeeWorm.visible = false
	$AnimationTree.set("parameters/quest_completed/transition_request", "False")
	$"../Narkoman/CloseEyes/Eyes".play_backwards("close")
	Dialogic.start("FindFlowers2")
	Dialogic.timeline_ended.connect(ended)
	flowerfind += 1
	findflowers = false
	
func ended():
	quest_completed_all = true
	Dialogic.timeline_ended.disconnect(ended)
	end = true
	$AnimationTree.set("parameters/quest_completed/transition_request", "True")
	$AnimationTree.set("parameters/why?/transition_request", "False")

func unvitain():
	$beeman/Armature/Skeleton3D/BoneAttachment3D/Unvitain.visible = true
	await get_tree().create_timer(1.0).timeout
	$beeman/Armature/Skeleton3D/BoneAttachment3D/Unvitain.visible = false
