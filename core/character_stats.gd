class_name CharacterStats
extends Resource

@export var max_health: float = 100.0
@export var move_speed: float = 90.0

@export_group("Combat")
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 0.45
@export var attack_range: float = 28.0
## Zéro par défaut : ce jeu n'a pas de recul. Le mécanisme est entier — il
## suffit de monter ce chiffre, ou d'utiliser les touches 3/4 de l'arène de
## test — mais un nouvel ennemi doit naître comme les autres, sans recul, et
## pas obliger à penser à le débrancher.
@export var knockback_force: float = 0.0
## Retranché à chaque coup reçu, en points. Fixe et non proportionnel, comme
## pour l'affixe Blindé des ennemis : c'est ce qui rend les petits coups répétés
## inefficaces, donc ce qui change la façon dont on se fait toucher plutôt que
## la durée du combat. Le plancher de dégâts est dans Hurtbox.
@export var damage_reduction: float = 0.0
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0
