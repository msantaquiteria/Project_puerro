extends CharacterBody3D

@export var monster_stats: EnemyResource
@export var player_stats: PlayerStats

signal monster_health_changed(new_health: int)

@onready var attack_cd_timer: Timer = $AACD #referencia al timer

var can_attack: bool = true
var player_node: CharacterBody3D = null #referencia al jugador

func _ready() -> void:
	if player_node == null:
		player_node = get_tree().get_first_node_in_group("player")
	#El monstruo debe estar en un grupo para facilitar su selección
	add_to_group("monstruos")
	attack_cd_timer.wait_time = monster_stats.attack_cooldown
	
func _physics_process(_delta: float) -> void:	
	if player_node != null:
		var distance_to_player = global_position.distance_to(player_node.global_position)
		if distance_to_player < monster_stats.detection_range:
			#comportamiento, seguimos al jugador
			var direction = (player_node.global_position - global_position).normalized()
			
			#rotamos al bicho sólo en el eje y
			look_at_from_position(global_position, player_node.global_position)
			rotation.x = 0 
			rotation.z = 0
			
			if distance_to_player > monster_stats.attack_range:
				velocity = direction * monster_stats.move_speed
			
			else:
				velocity = Vector3.ZERO
				if can_attack:
					attack_player()
		else:
			velocity = Vector3.ZERO
			#quizás cambiar a patrullar
	move_and_slide()
		
func attack_player() -> void:
	can_attack = false
	attack_cd_timer.start()
	#Aquí habría una animación
	player_node.take_damage(monster_stats.attack_damage)

func take_damage(amount: int) -> void:
	monster_stats.current_health = max(0, monster_stats.current_health - amount)
	print("Monster took ", amount, " damage. Current health: ", monster_stats.current_health)
	#Enviamos señal para el HUD
	emit_signal("monster_health_changed", monster_stats.current_health)
	if monster_stats.current_health <= 0:
		die()
		
func die():
	print("Monster ", monster_stats.enemy_name, " has died!")
	#Aquí habría animación
	queue_free()

func _on_aacd_timeout() -> void:
	#el temporizador termina y el monstruo puede atacar de nuevo
	can_attack = true
