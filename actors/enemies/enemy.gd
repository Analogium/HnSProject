class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy)

@export var stats: CharacterStats

## Rayon de repérage, le bord de l'écran. À ne pas confondre avec CULL_DISTANCE
## (700 px), le garde-fou de performance.
@export var detection_radius: float = 350.0

@onready var sprite: ActorSprite = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_bar: HealthBar = $HealthBar
@onready var affix_tag: AffixTag = $AffixTag

## Les affixes de cet ennemi, tirés à l'apparition et jamais changés ensuite.
var affixes: Array[Affix] = []
## Fraction des dégâts infligés reconvertie en soin, cumulée depuis les affixes.
var lifesteal := 0.0

## Le niveau de la zone, posé par l'EnemyManager **avant** l'entrée dans l'arbre :
## `_ready` met la fiche à l'échelle.
var niveau := 1

var health: float
## Sur Enemy : le grunt et le caster la décomptent pareil.
var _attack_cd := 0.0
var target: Node2D
var is_dead := false
var is_aggro := false
## Posé par EnemyManager.register() ; le caster y fait naître ses tirs.
var manager: EnemyManager
## Ses états, neufs pour chaque ennemi.
var etats := Etats.new()


func _ready() -> void:
	if stats == null:
		stats = CharacterStats.new()

	# Le tirage d'abord, l'écriture ensuite : c'est lui qui dit s'il y aura
	# quelque chose à écrire.
	_tirer_affixes()

	# **Une copie, et seulement si quelqu'un écrit** : la fiche est un `.tres` partagé
	# (invariant 2), mais sept cents copies inutiles coûtaient 5,4 ms de physique contre
	# 4,4 à sept cents ennemis.
	if niveau > 1 or not affixes.is_empty():
		stats = fiche_de(stats, niveau, affixes)
		_appliquer_affixes()
	# Après échelle et affixes : sinon la hurtbox défendrait avec la fiche d'origine.
	hurtbox.stats = stats
	hurtbox.etats = etats
	etats.change.connect(_montrer_les_etats)
	etats.soin.connect(_soigner)
	_set_health(stats.max_health)
	hurtbox.damaged.connect(_on_damaged)
	# Volontairement désactivé : c'est l'EnemyManager qui pilote.
	set_physics_process(false)


## Déduit de la case d'apparition, jamais de Game.rng : une graine redonne les mêmes
## ennemis. Séparé de l'application, qui dépend de son résultat.
func _tirer_affixes() -> void:
	var rng := RandomNumberGenerator.new()
	# Décalé par rapport à la graine de silhouette, sinon la variante et
	# l'affixe seraient corrélés et un Colossal aurait toujours le même corps.
	rng.seed = absi(hash(Vector2i(position.round()))) ^ 0xA771
	affixes = AffixPool.roll(rng)
	# Posée dans tous les cas : sans affixe, l'étiquette se vide et se cache.
	affix_tag.set_affixes(affixes)


## La fiche d'un ennemi de ce niveau et de ces affixes, **sur une copie**. Statique : le
## banc d'équilibrage la calcule sans corps.
static func fiche_de(base: CharacterStats, p_niveau: int, p_affixes: Array[Affix]) -> CharacterStats:
	var fiche: CharacterStats = base.duplicate()
	CharacterStats.mettre_a_l_echelle(fiche, p_niveau)
	for a in p_affixes:
		fiche.max_health *= a.health_mult
		fiche.move_speed *= a.speed_mult
		fiche.attack_damage *= a.damage_mult
		fiche.attack_cooldown *= a.cooldown_mult
		fiche.armor += a.armor
	return fiche


## Ce que les affixes font hors de la fiche.
func _appliquer_affixes() -> void:
	if affixes.is_empty():
		return

	for a in affixes:
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


## **Le seul chemin pour changer la vie** : la barre suit.
func _set_health(value: float) -> void:
	health = clampf(value, 0.0, stats.max_health)
	health_bar.set_health(health, stats.max_health)


func setup(p_target: Node2D) -> void:
	target = p_target


## Appelée par l'EnemyManager avant tick() : un archétype ne peut pas l'oublier. Pas
## pour les ennemis culés.
func regen(delta: float) -> void:
	if stats.health_regen <= 0.0 or is_dead or health >= stats.max_health:
		return
	_set_health(health + stats.health_regen * delta)


## Ce que ses états brûlent, appelée par l'EnemyManager avec la régénération. Une mort
## par brûlure est une victoire.
func subir_les_etats(delta: float) -> void:
	if is_dead:
		return
	var perte := etats.avancer(delta)
	if perte <= 0.0:
		return
	_set_health(health - perte)
	var chiffre := etats.chiffre()
	if chiffre > 0.0 and HitFeedback.current != null:
		HitFeedback.current.degats_sans_coup(hurtbox.global_position, chiffre, false)
	if health <= 0.0:
		die()


## Pas à un corps tombé : sa pourriture lui survit, le soin non.
func _soigner(montant: float) -> void:
	if not is_dead:
		_set_health(health + montant)


func _montrer_les_etats() -> void:
	sprite.montrer_les_etats(etats)
	health_bar.montrer_les_etats(etats)


## Gel compris : les archétypes la lisent ici, jamais sur la fiche.
func vitesse_de_deplacement() -> float:
	return stats.move_speed * etats.facteur_de_vitesse


## Surchargée par chaque archétype. Appelée par l'EnemyManager.
func tick(_delta: float) -> void:
	pass


## Le champ de flux quand la zone en a un, qui contourne les murs ; la ligne droite
## sinon (arène, banc, case sans direction).
func heading() -> Vector2:
	if target == null:
		return Vector2.ZERO
	if manager != null and manager.field != null:
		var d := manager.field.direction_at(MapGenerator.cell_at(global_position))
		if d != Vector2.ZERO:
			return d
	return (target.global_position - global_position).normalized()


## En fin de tick() : le sprite suit la vitesse réelle, pas l'intention.
func _animate() -> void:
	sprite.set_state(velocity.length() > 8.0, velocity)


## Une fois par tick, **hors** du test de portée, sinon l'attente se fige. Le gel
## l'étire.
func _cool_down(delta: float) -> void:
	_attack_cd = maxf(_attack_cd - delta * etats.facteur_de_vitesse, 0.0)


## Face à la cible et non dans le sens de la vitesse, quasi nulle au contact.
func _strike(facing: Vector2) -> void:
	_attack_cd = stats.attack_interval()
	sprite.set_state(false, facing)
	sprite.attack()


## En tête de tick(). Une fois alerté, l'ennemi le reste.
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


## Ce qu'on garde de l'expérience d'une zone laissée **derrière** soi : cinq niveaux
## sans pénalité, puis elle fond. Sans borne haute (jalon 6) : descendre plus bas
## rapporte mieux, moudre une zone facile ne doit pas rester payant.
const XP_MARGE := 5
const XP_PERTE_PAR_NIVEAU := 0.10
const XP_PLANCHER := 0.05


static func facteur_d_experience(niveau_zone: int, niveau_joueur: int) -> float:
	var ecart := niveau_joueur - niveau_zone
	return clampf(1.0 - XP_PERTE_PAR_NIVEAU * float(maxi(0, ecart - XP_MARGE)), XP_PLANCHER, 1.0)


## L'expérience que valent ces PV, avant affixes. Partagée avec la boule
## d'expérience de l'établi, qui vaut ce que rapportent des grunts de la zone.
static func xp_de_la_sante(max_health: float) -> float:
	return max_health * XP_PER_HEALTH


func xp_value() -> int:
	return experience_de(stats, affixes)


## Statique pour le banc d'équilibrage. `fiche.max_health` porte déjà les multiplicateurs
## d'affixes ; `xp_mult` est le supplément de récompense, distinct de la robustesse.
static func experience_de(fiche: CharacterStats, p_affixes: Array[Affix]) -> int:
	var v := xp_de_la_sante(fiche.max_health)
	for a in p_affixes:
		v *= a.xp_mult
	return maxi(roundi(v), 1)


## `award` faux pour les morts sans victoire : touche K, rechargement, banc.
func die(award := true) -> void:
	if is_dead:
		return
	is_dead = true
	if award and manager != null:
		manager.report_kill(self)
	died.emit(self)
	queue_free()
