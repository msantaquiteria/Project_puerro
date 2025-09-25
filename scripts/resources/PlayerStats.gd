class_name PlayerStats extends Resource

@export_group("Core Stats")
@export var max_health: int = 100
@export var current_health: int = 100
@export var max_mana: int = 50
@export var current_mana: int = 50

@export_group("Combat Stats")
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1 #Attack Speed
@export var attack_range: float = 3
@export var current_attack_cooldown: float
@export var defense: int = 5
@export var critical_chance: float = 0.05 #5%
@export var critical_damage: float = 1.5 #150%

@export_group("Utility Stats")
@export var move_speed: float = 5.0

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		current_health = 0
		print("El jugador ha muerto!")
	print("Salud restante: ", current_health)
	
func heal(amount: int):
	current_health += amount
	if current_health >= max_health:
		current_health = max_health
	print("Salud curada, nueva salud: ", current_health)
	
func can_attack() -> bool:
	if current_attack_cooldown <= 0.0:
		current_attack_cooldown = attack_cooldown
		print("El personaje ataca")
		return true
	else:
		print("Ataque en cooldown. Tiempo restante: ", current_attack_cooldown)
		return false
	
func update_cooldown(delta: float):
	if current_attack_cooldown > 0.0:
		current_attack_cooldown -= delta
		if current_attack_cooldown <= 0.0:
			current_attack_cooldown = 0.0
