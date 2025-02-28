extends CharacterBody3D

var has_ingredients = false  # Состояние квеста: получены ли ингредиенты
var quest_completed = false  # Состояние квеста: завершён ли квест

func _ready() -> void:
	$AnimationTree.set("parameters/has_ingredients/transition_request", "False")

func interact():
	Dialogic.start_timeline("HelpBeeMan")
