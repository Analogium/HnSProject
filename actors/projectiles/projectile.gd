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

## Tirage **local**, semé sur le nœud : invariant 3, et deux tirs ne grésillent pas à
## l'unisson.
var _flicker := RandomNumberGenerator.new()


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_flicker.seed = int(get_instance_id())
	# Additif : la lumière s'ajoute au sol.
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m


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


## La nature passée par le lanceur, sinon celle de la scène.
func tint() -> Color:
	return DamageType.COLORS[_nature if _nature >= 0 else damage_type]


func _draw() -> void:
	var color := tint()
	for a: Array in AUREOLES:
		var halo := color
		halo.a = float(a[1])
		draw_colored_polygon(_shape(float(a[0])), halo)
	var body := color
	body.a = BODY
	draw_colored_polygon(_shape(1.0), body)


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


func _physics_process(delta: float) -> void:
	global_position += _dir * speed * delta
	_life += delta
	# Redessiné à chaque pas : c'est le changement qu'on regarde.
	queue_redraw()
	if _life >= lifetime:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area is Hurtbox:
		return
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
	queue_free()


## Le masque ne retient que le décor pour les corps : le tir s'arrête au mur,
## et traverse les autres ennemis sans les toucher.
func _on_body_entered(_body: Node2D) -> void:
	queue_free()
