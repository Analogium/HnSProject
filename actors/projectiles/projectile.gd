class_name Projectile
extends Area2D

## Tir générique du caster et du joueur : avancer, s'arrêter au mur, blesser la
## première Hurtbox. Les layers de la scène décident de qui il touche.

@export var speed: float = 140.0
## Zéro : ce jeu n'a pas de recul.
@export var knockback: float = 0.0
@export var lifetime: float = 3.0
## Les tirs du joueur figent le jeu à l'impact ; ceux des ennemis non.
@export var hit_stop_on_impact: bool = false
## La nature de la scène : celle des tirs ennemis, et la couleur par défaut. Le joueur
## passe celle de son geste (`setup`), pour qu'un sort converti change de couleur.
@export var damage_type: DamageType.Kind = DamageType.Kind.PHYSICAL

## Distance à laquelle le tir naît devant son lanceur. Trop court, il apparaît
## dans le corps et touche le tireur lui-même ; trop loin, il saute une case.
const MUZZLE := 12.0

# --------------------------------------------------------------------------
# Le dessin
# --------------------------------------------------------------------------

## Le glyphe de l'éclair, sept sommets dans une boîte de 24, **pointe vers +x** — le
## nœud tourne déjà. Des sommets et non une image : c'est leur gigue qui vit.
const GLYPH := [
	Vector2(-10, 5), Vector2(1, 5), Vector2(1, 2), Vector2(10, 2),
	Vector2(-2, -5), Vector2(-2, -1), Vector2(-10, -5),
]

## Long et mince : un dard de dix-huit pixels sur trois. **Un choix de lecture**, fait
## en jeu contre une variante large de la taille du torse.
const SIZE := 12.0
const REACH := 1.8
const FINESSE := 0.62

## Le halo est le glyphe réempilé plus large : une polyligne épaisse sortait carrée.
const AUREOLES := [[1.34, 0.10], [1.18, 0.15], [1.07, 0.20]]

## Sous-alimenté exprès : en additif, la teinte pleine sature en blanc et le froid se
## confondrait avec la foudre.
const BODY := 0.78

## Écart des sommets d'une image à l'autre, en unités du glyphe. C'est tout le
## grésillement : sans lui le tir est un autocollant qui glisse.
const JITTER := 0.4

## Les natures **dessinées** : planches cernées, qui ne tournent pas et ne sont pas
## additives. Les autres restent des glyphes tracés.
const DRAWN := [DamageType.Kind.LIGHTNING, DamageType.Kind.NECROTIC]
## L'écart entre deux volutes de la traînée de la Peste, et leur tangage.
const FUME_STEP := 7.0
const FUME_SWAY := 1.5

var _dir := Vector2.RIGHT
## Les parts du coup, par nature, tirées au lancer.
var _parts: Array[float] = []
var _source: Node2D
## Les états du lanceur, lus à la naissance du tir et gardés jusqu'à l'impact : le
## tir d'un caster mort en vol frappe encore, et sa bénédiction avec.
var _author: StatusEffects
## Le lancer du joueur, null pour un tir ennemi.
var _cast: SkillStats
var _life := 0.0
## La nature montrée, ou -1 pour celle de la scène.
var _nature := -1
## Ce qu'il a déjà frappé, par identifiant : un tir qui traverse ne frappe pas deux fois
## la même cible, et ses éclats non plus.
var _struck := {}
var _pierced := 0

## Tirage **local**, semé sur le nœud : invariant 3, et deux tirs ne grésillent pas à
## l'unisson.
var _flicker := RandomNumberGenerator.new()


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_flicker.seed = int(get_instance_id())
	material = ArtPalette.ADDITIVE


## Reconstruit à chaque appel : c'est le changement qui fait l'effet.
func _shape(scale_factor: float) -> PackedVector2Array:
	var k := SIZE * scale_factor / 24.0
	var pts := PackedVector2Array()
	for v: Vector2 in GLYPH:
		var d := Vector2(v.x * REACH, v.y * FINESSE)
		d += Vector2(
			_flicker.randf_range(-JITTER, JITTER),
			_flicker.randf_range(-JITTER, JITTER)
		)
		pts.append(d * k)
	return pts


func tint() -> Color:
	return DamageType.COLORS[nature()]


## La nature effectivement dessinée : celle que le lanceur a passée, sinon celle
## de la scène.
func nature() -> DamageType.Kind:
	return _nature if _nature >= 0 else damage_type


func _draw() -> void:
	var color := tint()
	# **La foudre ne se dessine pas comme une bille.** Un éclair court et fourché,
	# couché sur la trajectoire au cap le plus proche. La nécrose, elle, est un crâne.
	# Ce sont les deux écarts par nature de ce nœud : les autres natures sont des
	# boules qui brillent.
	if nature() == DamageType.Kind.LIGHTNING:
		Lightning.put(self, Lightning.dart(
			color, Slash.turn_of(_dir.angle()), Lightning.hold(_life) + int(get_instance_id())
		))
		return
	if nature() == DamageType.Kind.NECROTIC:
		_plague(color)
		return
	for a: Array in AUREOLES:
		var halo := color
		halo.a = float(a[1])
		draw_colored_polygon(_shape(float(a[0])), halo)
	var body := color
	body.a = BODY
	draw_colored_polygon(_shape(1.0), body)


## Le crâne de la Peste et ses fumées, qui ondulent de part et d'autre de la course.
func _plague(color: Color) -> void:
	var fumes := EffectForge.fumes(color)
	var side := _dir.orthogonal()
	for i in fumes.size():
		var behind := -_dir * FUME_STEP * float(i + 1) + side * FUME_SWAY * (1.0 if i % 2 == 0 else -1.0)
		Necrotic.centered(self, fumes[i], behind)
	var skulls := EffectForge.plagues(color)
	Necrotic.centered(self, skulls[int(_life * EffectForge.PLAGUE_HZ) % skulls.size()], Vector2.ZERO)


## add_child d'abord, sinon global_position ne veut rien dire. Immédiat : un tir ne
## part jamais d'un rappel de collision.
static func spawn(
	parent: Node, scene: PackedScene, from: Vector2, dir: Vector2,
	parts: Array[float], source: Node2D, p_speed := 0.0, nature := -1, cast: SkillStats = null
) -> Projectile:
	var bolt := _spawn(parent, scene, from, dir)
	if bolt != null:
		bolt.setup(dir, parts, source, p_speed, nature)
		bolt._cast = cast
		Settings.veil(bolt, Settings.SPELLS)
	return bolt


## Le chemin des ennemis : la nature reste écrite dans `enemy_bolt.tscn`.
static func spawn_of_nature(
	parent: Node, scene: PackedScene, from: Vector2, dir: Vector2,
	amount: float, source: Node2D
) -> Projectile:
	var bolt := _spawn(parent, scene, from, dir)
	if bolt != null:
		var parts := DamageType.empty_parts()
		parts[bolt.damage_type] = amount
		bolt.setup(dir, parts, source)
		Settings.veil(bolt, Settings.ENEMY_ATTACKS)
	return bolt


static func _spawn(parent: Node, scene: PackedScene, from: Vector2, dir: Vector2) -> Projectile:
	if scene == null or parent == null:
		return null
	var bolt: Projectile = scene.instantiate()
	parent.add_child(bolt)
	bolt.global_position = from + dir * MUZZLE
	return bolt


## Après add_child. `speed` à zéro garde celle de la scène (tirs ennemis) ; la durée
## de vie reste sur la scène, donc un tir plus rapide porte plus loin. Parts recopiées.
func setup(
	dir: Vector2, parts: Array[float], source: Node2D, p_speed := 0.0, nature := -1
) -> void:
	_dir = dir.normalized()
	_parts = parts.duplicate()
	_source = source
	_author = StatusEffects.of(source)
	if p_speed > 0.0:
		speed = p_speed
	# Négative, on garde celle de la scène : c'est le cas des tirs ennemis, qui
	# n'ont pas de geste résolu derrière eux.
	if nature >= 0:
		_nature = nature
	rotation = _dir.angle()
	# Dessinées, la foudre et la nécrose ne tournent pas et ne sont pas additives : une
	# planche pivotée se rééchantillonne, et son contour sombre n'ajoute rien en lumière
	# ajoutée.
	if self.nature() in DRAWN:
		rotation = 0.0
		material = null


func _physics_process(delta: float) -> void:
	global_position += _dir * speed * delta
	_life += delta
	# Redessiné à chaque pas : c'est le changement qu'on regarde.
	queue_redraw()
	if _life >= lifetime:
		_finish()


## Hors de `_on_area_entered` : `Fireball` décide d'exploser avant l'appel parent.
func strikes(area: Area2D) -> bool:
	return area is Hurtbox and not _struck.has(area.get_instance_id())


func _on_area_entered(area: Area2D) -> void:
	if not strikes(area):
		return
	_struck[area.get_instance_id()] = true
	var info := DamageInfo.roll(_cast, global_position, _parts, knockback)
	info.author = _author
	(area as Hurtbox).take_damage(info)
	# Le lanceur porte l'affixe : c'est lui qu'on soigne. **Valide avant le `as`** : un
	# caster libéré ferait sinon traverser le joueur par son tir (invariant 4).
	if is_instance_valid(_source):
		var caster := _source as Enemy
		if caster != null:
			caster.on_damage_dealt(info.amount)
	if hit_stop_on_impact:
		Game.hit_stop()
	if _cast != null and _pierced < int(_cast.pierce):
		_pierced += 1
		_shatter(true)
		return
	_finish()


## Le masque ne retient que le décor pour les corps : le tir s'arrête au mur,
## et traverse les autres ennemis sans les toucher.
func _on_body_entered(_body: Node2D) -> void:
	_finish()


## La fin de course, quelle qu'elle soit — cible, mur, portée.
func _finish() -> void:
	if is_queued_for_deletion():
		return
	_shatter()
	queue_free()


## Les éclats partent de chaque ennemi traversé et de la fin de course. Ils emportent
## la liste de ce qui a été frappé **à cet instant** : une copie, que le tir qui continue
## ne rallonge pas sous eux. **Traversé, l'étoile tourne d'un demi-pas** : le tir garde
## l'axe, et un éclat qui l'y suivrait frapperait deux fois l'ennemi suivant.
func _shatter(pierced := false) -> void:
	if _cast == null or _cast.splits <= 0.0:
		return
	var count := int(_cast.splits)
	var dir := _dir.rotated(PI / float(count)) if pierced else _dir
	Projectile._split.call_deferred(
		get_parent(), load(scene_file_path), global_position, dir, speed, _nature,
		_source, _cast.shard(), count, _struck.duplicate()
	)


## En étoile, le premier dans `dir`. **Différé** : la fin de course arrive d'un
## rappel de collision, où un tir ne naît pas (invariant 4). Statique, parce que le tir
## est déjà libéré quand l'appel arrive ; `source` sans type pour la même raison.
static func _split(
	parent: Node, scene: PackedScene, at: Vector2, dir: Vector2, p_speed: float,
	nature: int, source, shard: SkillStats, count: int, struck: Dictionary
) -> void:
	if not is_instance_valid(parent):
		return
	var author: Node2D = source if is_instance_valid(source) else null
	for i in count:
		var toward := dir.rotated(TAU * float(i) / float(count))
		var bolt := spawn(
			parent, scene, at - toward * MUZZLE, toward, shard.roll(Game.rng), author,
			p_speed, nature, shard
		)
		if bolt != null:
			bolt._struck = struck.duplicate()
			if bolt is Fireball:
				(bolt as Fireball).explosion_radius = shard.radius
