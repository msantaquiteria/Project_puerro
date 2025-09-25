class_name EnemyResource extends Resource

@export_group("Information")
@export var id: String = ""
@export var enemy_name: String = ""
@export var experience_on_death: int = 10
@export var drop_table_id: String = ""

@export_group("Core Stats")
@export var max_health: int = 100
@export var current_health: int = 100
@export var max_mana: int = 50
@export var current_mana: int = 50

@export_group("Combat Stats")
@export var attack_damage: int = 5
@export var attack_cooldown: float = 2
@export var defense: int = 5
@export var critical_chance: float = 0.05 #5%
@export var critical_damage: float = 1.5 #150%

@export_group("Utility Stats")
@export var move_speed: float = 2.0
@export var attack_speed: float = 1.0
@export var detection_range: float = 10.0 #rango que detecta al jugador
@export var attack_range: float = 1.5
