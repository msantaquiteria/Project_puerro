extends Node

signal enemy_health_changed(enemy_node: CharacterBody3D, current_health: int, max_health: int, enemy_name: String)
signal enemy_died(enemy_node: CharacterBody3D)

var last_hit_enemy: CharacterBody3D = null #Referencia al último enemigo golpeado
var hud_node: Control #Referencia al nodo HUD

func _ready() -> void:
	#Conecta las señales globales para que el HUD pueda escucharlas
	pass #Las conexiones al HUD se harán cuando el HUD esté listo

func set_hud_node(node: Control):
	hud_node = node
	#Conecta las señales del GameManager al HUD para manejar la barra de vida
	enemy_health_changed.connect(_on_enemy_health_changed)
	enemy_died.connect(_on_enemy_died)
	
func _on_enemy_health_changed(enemy_node: CharacterBody3D, current_health: int, max_health: int, enemy_name: String):
	#Esto se llama cuando cualquier enemigo emite health_changed
	#Actualizamos el HUD sólo si es el "last_hit_enemy" o si no había ninguno antes
	if enemy_node == last_hit_enemy or last_hit_enemy == null:
		last_hit_enemy = enemy_node
		if hud_node:
			hud_node.show_enemy_health(enemy_name, current_health, max_health)

func _on_enemy_died(enemy_node: CharacterBody3D):
	if enemy_node == last_hit_enemy:
		last_hit_enemy = null
		if hud_node:
			hud_node.hide_enemy_health()
