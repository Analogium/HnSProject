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
## Attente avant le prochain coup. Sur Enemy et non sur chaque archétype : le
## grunt et le caster tenaient la même variable, la décomptaient de la même
## façon et la rechargeaient avec la même statistique.
var _attack_cd := 0.0
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
	# Après _apply_affixes, qui duplique la fiche : donnée avant, la hurtbox
	# défendrait avec la fiche partagée et ignorerait l'armure de l'affixe.
	hurtbox.stats = stats
	_set_health(stats.max_health)
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
		stats.armor += a.armor
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
	_set_health(health + amount * lifesteal)


## Le seul chemin pour changer la vie : la barre suivait chaque écriture de
## `health` à la main, et une seule oubliée la faisait mentir.
func _set_health(value: float) -> void:
	health = clampf(value, 0.0, stats.max_health)
	health_bar.set_health(health, stats.max_health)


func setup(p_target: Node2D) -> void:
	target = p_target


## Appelée par l'EnemyManager avant tick(). Chez le manager et non dans tick()
## de chaque archétype : c'est lui le pilote, et un archétype qui oublierait de
## l'appeler aurait silencieusement une statistique morte.
##
## Les ennemis culés (au-delà de CULL_DISTANCE) ne régénèrent pas. Voulu : à
## 700 px ils sont hors combat depuis longtemps, et les faire remonter coûterait
## une boucle sur toute la liste pour une différence invisible.
func regen(delta: float) -> void:
	if stats.health_regen <= 0.0 or is_dead or health >= stats.max_health:
		return
	_set_health(health + stats.health_regen * delta)


## Surchargée par chaque archétype. Appelée par l'EnemyManager.
func tick(_delta: float) -> void:
	pass


## Par où partir pour rejoindre la cible.
##
## Le champ de flux quand la zone en a un — il contourne les murs, ce que la
## ligne droite ne fait pas : un ennemi séparé du joueur par une concavité
## poussait contre la pierre jusqu'à ce qu'on vienne le chercher.
##
## La ligne droite sinon, et c'est un vrai repli, pas un pis-aller : l'arène de
## réglage et le banc de stress n'ont pas de murs, et le champ y serait du
## calcul pour rien. Elle sert aussi quand la case courante n'a pas de direction
## — l'ennemi repoussé dans la pierre, ou hors du rayon du champ.
func heading() -> Vector2:
	if target == null:
		return Vector2.ZERO
	if manager != null and manager.field != null:
		var d := manager.field.direction_at(MapGenerator.cell_at(global_position))
		if d != Vector2.ZERO:
			return d
	return (target.global_position - global_position).normalized()


## À appeler en fin de tick(). Le sprite se pilote depuis la vitesse réelle et
## non depuis l'intention de déplacement : un ennemi qui pousse contre un mur ne
## doit pas continuer à marcher sur place.
func _animate() -> void:
	sprite.set_state(velocity.length() > 8.0, velocity)


## À appeler une fois par tick, avant de tester `_attack_cd`. Séparé du test
## pour qu'un ennemi hors de portée continue de recharger : glissé dans la
## condition, l'évaluation paresseuse aurait figé son attente.
func _cool_down(delta: float) -> void:
	_attack_cd = maxf(_attack_cd - delta, 0.0)


## Déclenche le coup : recharge, et l'animation face à la cible. Face à elle et
## non dans le sens de la vitesse — au contact l'ennemi ne bouge presque plus,
## et le coup partirait dans une direction arbitraire.
func _strike(facing: Vector2) -> void:
	_attack_cd = stats.attack_interval()
	sprite.set_state(false, facing)
	sprite.attack()


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
	_set_health(health - info.amount)
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
