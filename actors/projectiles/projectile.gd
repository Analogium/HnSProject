class_name Projectile
extends Area2D

## Tir générique, partagé par le caster et par le joueur : avancer, s'arrêter au
## mur, blesser la première Hurtbox rencontrée. Ce sont les layers de collision de
## la scène qui décident de qui il peut toucher, pas le script — d'où
## enemy_bolt.tscn et player_bolt.tscn.
##
## Contrairement aux ennemis, il garde son propre _physics_process. Le jour où les
## projectiles se compteront par centaines, c'est le même chemin de migration
## qu'eux : une boucle unique.

@export var speed: float = 140.0
## Zéro par défaut, comme CharacterStats.knockback_force : ce jeu n'a pas de
## recul. Un nouveau projectile ne doit pas en réintroduire sans qu'on le veuille.
@export var knockback: float = 0.0
@export var lifetime: float = 3.0
## Les tirs du joueur figent brièvement le jeu à l'impact, comme le corps à
## corps ; ceux des ennemis non, sinon se faire tirer dessus hacherait le jeu.
@export var hit_stop_on_impact: bool = false
## La nature de la scène : celle que portent les tirs ennemis, qui n'ont qu'un
## nombre, et **la couleur du tir, quoi qu'il porte**. Un éclair reste un éclair :
## le froid qu'un objet y ajoute change ses dégâts, pas son dessin.
@export var damage_type: DamageType.Kind = DamageType.Kind.PHYSICAL

## Distance à laquelle le tir naît devant son lanceur. Trop court, il apparaît
## dans le corps et touche le tireur lui-même ; trop loin, il saute une case.
const MUZZLE := 12.0

# --------------------------------------------------------------------------
# Le dessin
# --------------------------------------------------------------------------

## Le glyphe de l'éclair, sept sommets dans une boîte de 24, **pointe vers +x**.
## Le nœud tourne déjà sur sa trajectoire — `setup()` pose sa `rotation` — donc
## le dessin n'a rien à orienter : il travaille en repère local.
##
## Sept sommets et non une image : à cette taille une texture serait figée, et un
## éclair figé a l'air mort. Ici les sommets bougent d'une image à l'autre.
const GLYPHE := [
	Vector2(-10, 5), Vector2(1, 5), Vector2(1, 2), Vector2(10, 2),
	Vector2(-2, -5), Vector2(-2, -1), Vector2(-10, -5),
]

## La boîte du glyphe, puis son étirement : long dans le sens de la marche,
## mince en travers. Dix-huit pixels sur trois — un dard, pas un pictogramme.
##
## **C'est un choix de lecture, pas un réglage de goût** : à cette finesse le cran
## de l'éclair se referme presque, et la forme se lit comme un trait effilé. C'est
## celle qui a été retenue en la regardant en jeu, contre la variante large qui
## gardait mieux son cran mais faisait la taille du torse du joueur.
const TAILLE := 12.0
const ALLONGE := 1.8
const FINESSE := 0.62

## Le halo est le glyphe lui-même, réempilé plus large et plus pâle. Un contour
## épais aurait été plus court à écrire, mais les jointures d'une polyligne large
## sont anguleuses : le halo sortait carré autour d'une forme qui ne l'est pas.
const AUREOLES := [[1.34, 0.10], [1.18, 0.15], [1.07, 0.20]]

## Le corps est sous-alimenté exprès. En mélange additif, la teinte pleine fait
## déborder le canal le plus clair et le tir sort **blanc**, quelle que soit sa
## nature — le froid et la foudre deviendraient le même trait. À cette valeur, il
## se cumule avec ses auréoles jusqu'à sa couleur sans jamais saturer, sauf au
## croisement des passes, qui devient le cœur brûlant.
const CORPS := 0.78

## Écart des sommets d'une image à l'autre, en unités du glyphe. C'est tout le
## grésillement : sans lui le tir est un autocollant qui glisse.
const GIGUE := 0.4

var _dir := Vector2.RIGHT
## Les parts du coup, par nature, tirées au lancer.
var _parts: Array[float] = []
var _source: Node2D
var _life := 0.0

## Tirage **local**, et surtout pas `Game.rng` : celui-là est le fil des tirages
## de la partie, et un scintillement qui y puiserait décalerait toutes les graines
## de zone tirées ensuite (invariant 3). Semé sur l'identité du nœud, pour que
## deux tirs d'une même salve ne grésillent pas à l'unisson.
var _scintille := RandomNumberGenerator.new()


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_scintille.seed = int(get_instance_id())
	# Additif : la lumière s'ajoute au sol au lieu de le couvrir. C'est ce qui
	# sépare un trait coloré posé sur l'image de quelque chose qui éclaire.
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m


## Le glyphe à cette échelle, sommets regigotés. Reconstruit à chaque appel et
## non mis en cache : c'est le fait qu'il change qui fait l'effet.
func _forme(echelle: float) -> PackedVector2Array:
	var k := TAILLE * echelle / 24.0
	var pts := PackedVector2Array()
	for v: Vector2 in GLYPHE:
		var d := Vector2(v.x * ALLONGE, v.y * FINESSE)
		d += Vector2(
			_scintille.randf_range(-GIGUE, GIGUE),
			_scintille.randf_range(-GIGUE, GIGUE)
		)
		pts.append(d * k)
	return pts


## La couleur vient de la nature du tir, jamais réécrite ici : `DamageType.COLORS`
## est la seule définition, celle que la gerbe d'éclats et la fiche montrent aussi.
func _draw() -> void:
	# Type explicite : COLORS est un tableau non typé, donc l'indexer rend un
	# Variant et l'inférence échoue — le même piège que `generator.grid` dans la
	# zone.
	var teinte: Color = DamageType.COLORS[damage_type]
	for a: Array in AUREOLES:
		var halo := teinte
		halo.a = float(a[1])
		draw_colored_polygon(_forme(float(a[0])), halo)
	var corps := teinte
	corps.a = CORPS
	draw_colored_polygon(_forme(1.0), corps)


## Fait partir un tir, avec le piège de l'ordre : add_child d'abord, sinon
## global_position ne veut rien dire.
##
## Ajout immédiat et non différé, contrairement à GroundItem : un tir part toujours
## depuis _physics_process, jamais depuis un callback de collision.
static func spawn(
	parent: Node, scene: PackedScene, from: Vector2, dir: Vector2,
	parts: Array[float], source: Node2D, vitesse := 0.0
) -> Projectile:
	var bolt := _naitre(parent, scene, from, dir)
	if bolt != null:
		bolt.setup(dir, parts, source, vitesse)
	return bolt


## Un tir d'une seule nature, celle de sa scène : le chemin des ennemis, qui ne
## portent qu'un nombre. La nature reste ainsi écrite à un seul endroit, dans
## l'inspecteur de `enemy_bolt.tscn`.
static func spawn_d_une_nature(
	parent: Node, scene: PackedScene, from: Vector2, dir: Vector2,
	montant: float, source: Node2D
) -> Projectile:
	var bolt := _naitre(parent, scene, from, dir)
	if bolt != null:
		var parts := DamageType.parts_vides()
		parts[bolt.damage_type] = montant
		bolt.setup(dir, parts, source)
	return bolt


static func _naitre(parent: Node, scene: PackedScene, from: Vector2, dir: Vector2) -> Projectile:
	if scene == null or parent == null:
		return null
	var bolt: Projectile = scene.instantiate()
	parent.add_child(bolt)
	bolt.global_position = from + dir * MUZZLE
	return bolt


## À appeler après add_child, sinon global_position ne veut rien dire.
##
## `vitesse` à zéro garde celle de la scène : c'est le cas des tirs ennemis, qui
## n'ont pas de compétence. Le joueur passe toujours celle de la sienne, et
## `player_bolt.tscn` n'en déclare donc plus — une valeur toujours écrasée
## laisserait croire qu'on règle la vitesse du tir en l'y changeant.
##
## La durée de vie, elle, reste sur la scène : un tir plus rapide porte donc plus
## loin, ce qui est ce qu'on attend d'un bonus de vitesse de projectile.
##
## Les parts sont recopiées : le lanceur tire les suivantes dans son propre tableau.
func setup(dir: Vector2, parts: Array[float], source: Node2D, vitesse := 0.0) -> void:
	_dir = dir.normalized()
	_parts = parts.duplicate()
	_source = source
	if vitesse > 0.0:
		speed = vitesse
	rotation = _dir.angle()


func _physics_process(delta: float) -> void:
	global_position += _dir * speed * delta
	_life += delta
	# Redessiné à chaque pas : c'est le seul endroit du jeu où repeindre en
	# permanence se justifie, parce que c'est le changement lui-même qu'on
	# regarde. Sept sommets et quatre polygones, sur une poignée de tirs.
	queue_redraw()
	if _life >= lifetime:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area is Hurtbox:
		return
	var info := DamageInfo.en_parts(_parts, global_position, knockback)
	(area as Hurtbox).take_damage(info)
	# Le tir n'est qu'un messager : c'est le lanceur qui porte l'affixe, donc
	# c'est lui qu'on soigne, s'il est encore en vie.
	#
	# La validité se teste **avant** la conversion : convertir un objet déjà libéré
	# est en soi une erreur, et elle interrompt la fonction avant son queue_free().
	# Le tir d'un caster tué pendant que sa bille vole traverse alors le joueur en
	# le blessant à chaque image, jusqu'à expiration.
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
