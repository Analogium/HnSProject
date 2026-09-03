class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy)

@export var stats: CharacterStats

## Rayon auquel l'ennemi remarque sa cible.
##
## Avant, rien ne les freinait : le seul seuil était le culling de
## l'EnemyManager (700 px), donc ils fonçaient depuis bien au-delà de l'écran.
## 350 px, c'est la moitié — soit à peu près le bord de l'écran en 640 × 360.
##
## À ne pas confondre avec CULL_DISTANCE, qui reste un garde-fou de performance :
## entre 350 et 700 px l'ennemi est bien mis à jour, il ne t'a simplement pas
## encore repéré. Les deux valeurs confondues feraient geler à l'écran des
## ennemis parfaitement visibles.
@export var detection_radius: float = 350.0

@onready var sprite: ActorSprite = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_bar: HealthBar = $HealthBar
@onready var affix_tag: AffixTag = $AffixTag

## Les affixes de cet ennemi, tirés à l'apparition et jamais changés ensuite.
var affixes: Array[Affix] = []
## Fraction des dégâts infligés reconvertie en soin, cumulée depuis les affixes.
var lifesteal := 0.0

var health: float
var target: Node2D
var is_dead := false
var is_aggro := false
## Posé par EnemyManager.register(). Sert aux archétypes qui doivent faire
## naître quelque chose dans la scène (le caster et ses projectiles).
var manager: EnemyManager


func _ready() -> void:
	if stats == null:
		stats = CharacterStats.new()
	_apply_affixes()
	health = stats.max_health
	health_bar.set_health(health, stats.max_health)
	hurtbox.damaged.connect(_on_damaged)
	# Volontairement désactivé : c'est l'EnemyManager qui pilote.
	set_physics_process(false)


## Le tirage se déduit de la case d'apparition, comme la silhouette et le sens
## de rotation du caster. Surtout pas Game.rng : une même graine de zone doit
## redonner exactement les mêmes ennemis affixés, sinon la zone cesse d'être
## reproductible.
func _apply_affixes() -> void:
	var rng := RandomNumberGenerator.new()
	# Décalé par rapport à la graine de silhouette, sinon la variante et
	# l'affixe seraient corrélés et un Colossal aurait toujours le même corps.
	rng.seed = absi(hash(Vector2i(position.round()))) ^ 0xA771
	affixes = AffixPool.roll(rng)
	# Posée dans tous les cas : sans affixe, l'étiquette se vide et se cache.
	affix_tag.set_affixes(affixes)
	if affixes.is_empty():
		return

	# La copie est obligatoire. Aucun `.tres` du projet n'est
	# resource_local_to_scene : multiplier en place multiplierait les
	# statistiques de *tous* les ennemis du même type pour la session, et
	# l'éditeur peut graver le résultat dans le fichier.
	stats = stats.duplicate()
	for a in affixes:
		stats.max_health *= a.health_mult
		stats.move_speed *= a.speed_mult
		stats.attack_damage *= a.damage_mult
		stats.attack_cooldown *= a.cooldown_mult
		hurtbox.damage_reduction += a.damage_reduction
		lifesteal += a.lifesteal

	sprite.set_rim(
		AffixPool.tint_of(affixes),
		AffixPool.rim_amount_of(affixes),
		AffixPool.rim_width_of(affixes)
	)


## Appelée par l'archétype quand il a réellement blessé quelqu'un — au contact
## pour le grunt, à l'impact du projectile pour le caster.
func on_damage_dealt(amount: float) -> void:
	if lifesteal <= 0.0 or is_dead or amount <= 0.0:
		return
	health = minf(health + amount * lifesteal, stats.max_health)
	health_bar.set_health(health, stats.max_health)


func setup(p_target: Node2D) -> void:
	target = p_target


## Surchargée par chaque archétype. Appelée par l'EnemyManager.
func tick(_delta: float) -> void:
	pass


## À appeler en fin de tick(). Le sprite se pilote depuis la vitesse réelle et
## non depuis l'intention de déplacement : un ennemi qui pousse contre un mur ne
## doit pas continuer à marcher sur place.
func _animate() -> void:
	sprite.set_state(velocity.length() > 8.0, velocity)


## À appeler en tête de tick() par chaque archétype. Une fois alerté, l'ennemi
## le reste : sinon il ferait le yo-yo dès qu'on repasse la limite du rayon.
func _should_act() -> bool:
	if target == null or is_dead:
		return false
	if not is_aggro:
		var r := detection_radius
		if global_position.distance_squared_to(target.global_position) <= r * r:
			is_aggro = true
	return is_aggro


func _on_damaged(info: DamageInfo) -> void:
	if is_dead:
		return
	# Se faire tirer dessus de loin alerte, même hors du rayon de détection.
	is_aggro = true
	health -= info.amount
	health_bar.set_health(health, stats.max_health)
	velocity += (global_position - info.source_position).normalized() * info.knockback
	sprite.flash()
	if health <= 0.0:
		die()


## Expérience dérivée des PV, jamais posée à la main : une constante par
## archétype divergerait le jour où les statistiques bougent.
const XP_PER_HEALTH := 0.35


func xp_value() -> int:
	# max_health porte déjà les multiplicateurs d'affixes ; xp_mult est le
	# supplément de récompense, distinct de la robustesse.
	var v := stats.max_health * XP_PER_HEALTH
	for a in affixes:
		v *= a.xp_mult
	return maxi(roundi(v), 1)


## award = false pour les morts qui ne sont pas des victoires : la touche K de
## débogage, le rechargement d'une zone, la scène de stress. Sans ce garde-fou,
## vider la zone ferait monter le joueur de plusieurs niveaux d'un coup.
func die(award := true) -> void:
	if is_dead:
		return
	is_dead = true
	if award and manager != null:
		manager.report_kill(self)
	died.emit(self)
	queue_free()
