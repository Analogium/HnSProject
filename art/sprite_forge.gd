class_name SpriteForge

## La forge de personnages : (archétype, variante) -> SpriteFrames animées.
##
## Aucun fichier image n'existe sur le disque. Les pixels sont calculés au premier
## appel puis gardés en cache pour la session ; la graine étant dérivée du nom et
## du numéro de variante, le même personnage ressort identique à chaque lancement.
##
## Un personnage n'est pas un dessin mais un **squelette** : une dizaine de points
## d'ancrage reliés par des capsules. Animer revient à déplacer ces points, pas à
## redessiner — d'où une marche à 4 images aussi bon marché qu'une pose fixe, et
## un archétype qui s'ajoute en une entrée de configuration.
##
## La galerie (F4) exporte toutes les planches en PNG pour les retoucher à la
## main.

const FRAME := 32
## Axe vertical du corps et ligne de sol, dans le repère de l'image.
## 15.5 et non 16 : les coordonnées de pixel sont entières, donc seul un axe à
## la demie donne une silhouette symétrique — sinon le flip_h décale d'un pixel.
const CX := 15.5
const FEET := 27.0

## Identifiants de rampe. Le dessin ne connaît que ces cinq rôles ; les couleurs
## sont décidées par la palette, ce qui rend les variantes gratuites.
const R_CLOTH := 0
const R_SKIN := 1
const R_ACCENT := 2
const R_METAL := 3
const R_LEATHER := 4

const DIRS := ["down", "side", "up"]
const ARCHETYPES := ["player", "swiftblade", "witch", "grunt", "caster", "dummy", "undead"]

## Les archétypes dessinés hors du jeu (`tools/character_forge.py`) : trois poses
## fixes et les gestes générés dans `<archétype>.png`, leurs repères dans
## `<archétype>.json`. La forge y pose l'ombre et l'arme.
const SHEET_DIR := "res://art/characters/"

## Nombre de silhouettes différentes par archétype. Chaque ennemi en tire une au
## hasard : c'est ce qui empêche un paquet de sept grunts de ressembler à sept
## copies du même pochoir.
const VARIANTS := 4

## Les quatre tenues du joueur, dans l'ordre des variantes.
##
## Choisies et non tirées : quatre héros qui ne diffèrent que d'un demi-ton de
## bleu — ce que donne un tirage de nuance — ne sont pas un choix.
##
## Seule l'étoffe change. Le fil doré, l'acier et le cuir restent communs : ce sont
## eux qui font qu'on se reconnaît dans une mêlée de soixante-dix ennemis.
const PLAYER_CLOTHS := [
	Color(0.24, 0.45, 0.86),   # bleu, la tenue d'origine
	Color(0.76, 0.26, 0.28),   # cramoisi
	Color(0.24, 0.60, 0.38),   # vert
	Color(0.58, 0.34, 0.80),   # violet
]

## Cycle de marche en 4 temps : contact, passage, contact opposé, passage.
## Le rebond d'une image sur deux (le corps monte au passage) fait davantage
## pour la lisibilité de la marche que le balancement des jambes.
const WALK_SWING := [1.0, 0.0, -1.0, 0.0]
const WALK_BOB := [0.0, -1.0, 0.0, -1.0]
const IDLE_BOB := [0.0, -1.0]

## Armé, puis frappé. Deux images suffisent — c'est le contraste entre les deux
## qui se lit, pas leur nombre. La galerie compose ses planches d'export à partir
## de la même constante.
const ATTACK_FRAMES := 2

## Le souffle du repos d'une planche. Sa marche et son attaque, elles, sont des
## images générées (`tools/character_forge.py`), jouées telles quelles : un pas
## fait de décalages restait raide et tremblait (jalon 25, §4).
const SHEET_BREATH := [0, 0, -1, -1]

static var _cache: Dictionary = {}
static var _sheets: Dictionary = {}


## Une planche et ses repères : taille de case, ligne des pieds, par vue la main
## armée et le haut des pieds, et par geste généré ses rangées et ses mains.
class Sheet:
	var image: Image
	var meta: Dictionary

	## Les images d'un geste généré ; une seule, la pose, s'il ne l'est pas.
	func count(anim: String) -> int:
		var anims: Dictionary = meta.get("anims", {})
		return int(anims[anim]["count"]) if anims.has(anim) else 1


## Null pour un archétype en grilles ou en capsules.
static func sheet_of(archetype: String) -> Sheet:
	if not _sheets.has(archetype):
		var path := SHEET_DIR + archetype + ".png"
		var sheet: Sheet = null
		if ResourceLoader.exists(path):
			sheet = Sheet.new()
			sheet.image = (load(path) as Texture2D).get_image()
			sheet.image.convert(Image.FORMAT_RGBA8)
			sheet.meta = (load(SHEET_DIR + archetype + ".json") as JSON).data
		_sheets[archetype] = sheet
	return _sheets[archetype]


## Ce qu'un corps dépasse le guerrier par le haut, en pixels : barre de vie et
## textes du joueur, calés sur la tête du guerrier, montent d'autant. Lu sur l'image
## de repos elle-même, pour suivre un chapeau qu'aucun repère ne décrit.
static func head_room(archetype: String) -> float:
	return maxf(_top("player") - _top(archetype), 0.0)


static var _tops: Dictionary = {}


## La première rangée opaque de l'image de repos, repère du nœud (offset compris).
static func _top(archetype: String) -> float:
	if not _tops.has(archetype):
		var img := frame_image(config(archetype, 0), "down", "idle", 0)
		var row := 0
		while row < img.get_height() and not _row_is_opaque(img, row):
			row += 1
		_tops[archetype] = row - img.get_height() * 0.5 + offset_of(archetype).y
	return _tops[archetype]


static func _row_is_opaque(img: Image, row: int) -> bool:
	for x in img.get_width():
		# Au-dessus de l'ombre au sol, à 30 % d'opacité.
		if img.get_pixel(x, row).a > 0.5:
			return true
	return false


## Pose les pieds d'une case plus grande sur ceux des grilles : collision, barre de
## vie et ombre des acteurs sont calées sur `FEET` dans une case de `FRAME`.
static func offset_of(archetype: String) -> Vector2:
	var sheet := sheet_of(archetype)
	if sheet == null:
		return Vector2.ZERO
	var f: float = sheet.meta["frame"]
	return Vector2(0.0, (FEET - FRAME * 0.5) - (float(sheet.meta["feet"]) - f * 0.5))


## Le point d'entrée du jeu. Les SpriteFrames sont partagées entre toutes les
## instances d'une même variante : seul l'état de lecture est propre à chaque
## AnimatedSprite2D.
##
## `weapon` force l'arme tenue, vide pour celle de l'archétype — c'est ce qui rend
## l'équipement visible. Elle entre dans la clé du cache, sinon équiper une
## baguette changerait l'arme de tous les personnages de cette variante.
static func frames(archetype: String, variant := 0, weapon := "") -> SpriteFrames:
	var key := "%s:%d:%s" % [archetype, variant, weapon]
	if _cache.has(key):
		return _cache[key]

	var cfg := config(archetype, variant)
	if not weapon.is_empty():
		cfg["weapon"] = weapon
	var sf := SpriteFrames.new()
	sf.remove_animation("default")

	var sheet := sheet_of(archetype)
	for dir in DIRS:
		if sheet != null:
			_add_anim(sf, cfg, "idle_" + dir, dir, "idle", SHEET_BREATH.size(), 4.0, true)
			_add_anim(sf, cfg, "walk_" + dir, dir, "walk", sheet.count("walk"), 8.0, true)
			_add_anim(sf, cfg, "attack_" + dir, dir, "attack", sheet.count("attack"), 11.0, false)
			_add_anim(sf, cfg, "cast_" + dir, dir, "cast", sheet.count("cast"), 11.0, false)
			continue
		_add_anim(sf, cfg, "idle_" + dir, dir, "idle", IDLE_BOB.size(), 3.0, true)
		_add_anim(sf, cfg, "walk_" + dir, dir, "walk", WALK_SWING.size(), 10.0, true)
		_add_anim(sf, cfg, "attack_" + dir, dir, "attack", ATTACK_FRAMES, 11.0, false)

	_cache[key] = sf
	return sf


static func _add_anim(
	sf: SpriteFrames, cfg: Dictionary, name: String,
	dir: String, anim: String, count: int, fps: float, loops: bool
) -> void:
	sf.add_animation(name)
	sf.set_animation_speed(name, fps)
	sf.set_animation_loop(name, loops)
	for i in count:
		sf.add_frame(name, ImageTexture.create_from_image(frame_image(cfg, dir, anim, i)))


## Une image isolée. Publique parce que la galerie s'en sert pour composer ses
## planches d'export sans repasser par des textures.
static func frame_image(cfg: Dictionary, dir: String, anim: String, index: int) -> Image:
	var placed := _pose(cfg, dir, anim, index)
	var sheet := sheet_of(cfg["archetype"])
	if sheet != null:
		return _draw_sheet(sheet, cfg, dir, placed, anim, index)

	var canvas := PixelCanvas.new(FRAME, FRAME)

	if cfg["archetype"] == "dummy":
		_draw_dummy(canvas, cfg, placed)
	elif ART.has(cfg["archetype"]):
		_draw_authored(canvas, cfg, dir, placed, anim, index)
	elif dir == "side":
		_draw_side(canvas, cfg, placed)
	else:
		_draw_front(canvas, cfg, placed, dir == "down")

	return canvas.to_image(cfg["palettes"])


## Cadre de travail d'une icône d'objet. Plus petit que celui d'un personnage :
## une arme seule n'a pas besoin de la place d'un corps.
const ICON := 24

static var _icons: Dictionary = {}


## La place d'un objet au sol, en pixels. Sous le cadre de travail : à 24 px une
## épée au sol pesait autant qu'un personnage (32), et six chutes faisaient un tas
## illisible. C'est le nom, au-dessus, qui dit ce que c'est.
const GROUND := Vector2i(14, 14)


## L'icône d'un objet posé au sol. Le dessin de la forge y part en diagonale : une
## arme verticale dans un cadre carré laisse deux grandes marges vides et se lit
## plus petite qu'elle n'est. Une image, elle, garde l'orientation sous laquelle
## elle a été produite.
static func ground_icon(base: ItemBase) -> Texture2D:
	return _base_icon(base, false, GROUND)


## L'icône d'un objet dans le sac. Le dessin de la forge s'y dresse à la
## verticale : il épouse la forme des emplacements, presque tous plus hauts que
## larges.
##
## `target` est la place disponible en pixels d'écran : l'icône y est agrandie
## d'un facteur **entier**, un facteur fractionnaire doublant certaines lignes de
## pixels et pas d'autres.
static func inventory_icon(base: ItemBase, target: Vector2i) -> Texture2D:
	return _base_icon(base, true, target)


## La silhouette qui remplace le nom d'un emplacement vide : il n'y a pas d'objet,
## donc pas d'image possible — seulement le dessin de la forge, à partir du `kind`
## que la famille suggère.
static func ghost_icon(kind: String, target: Vector2i) -> Texture2D:
	return _icon(kind, true, target)


## Son image si la base en a une, le dessin de la forge sinon. Le champ vide est
## un état normal, comme pour une compétence : une base sans image reste jouable.
static func _base_icon(base: ItemBase, upright: bool, target: Vector2i) -> Texture2D:
	if base.icon == null:
		return _icon(base.kind, upright, target, base.tier)

	# Le même cache que les dessins : une icône se recadre une fois, pas à chaque
	# image. L'identifiant est unique par construction (invariant 1), et sa clé à
	# deux champs ne peut pas rencontrer celle d'un dessin, qui en a quatre.
	var key := "%s:%dx%d" % [base.id, target.x, target.y]
	if _icons.has(key):
		return _icons[key]
	var img := base.icon.get_image()
	_fit(img, target)
	var tex := ImageTexture.create_from_image(img)
	_icons[key] = tex
	return tex


## Le dessin d'un objet, recadré sur ce qui est réellement peint : une épée, une
## baguette et un plastron ne tombent pas au centre du cadre tout seuls, et un
## sprite recadré est centré par construction.
static func _icon(kind: String, upright: bool, target: Vector2i, tier := 1) -> Texture2D:
	var key := "%s:%d:%dx%d:%d" % [kind, int(upright), target.x, target.y, tier]
	if _icons.has(key):
		return _icons[key]

	var canvas := PixelCanvas.new(ICON, ICON)
	# La palette du joueur : c'est elle qui donne l'acier clair et l'or de la
	# garde, les deux teintes qui font lire « arme » plutôt que « bâton ».
	var cfg := config("player", 0)
	cfg["weapon"] = kind

	# Trois des cinq rampes sont remplacées par celles du palier. L'or de
	# l'accent, lui, ne bouge pas : c'est la couleur qui dit « ça compte » dans
	# tout le jeu, et la faire varier ferait passer un palier pour une rareté.
	var p := clampi(tier, 1, TIER_METAL.size()) - 1
	var palettes: Array = cfg["palettes"]
	palettes[R_METAL] = ArtPalette.ramp(TIER_METAL[p])
	palettes[R_LEATHER] = ArtPalette.ramp(TIER_LEATHER[p])
	palettes[R_CLOTH] = ArtPalette.ramp(TIER_CLOTH[p])

	if GEAR.has(kind):
		_gear(canvas, kind, ICON * 0.5, 2.0)
	elif upright:
		_weapon(canvas, cfg, Vector2(ICON * 0.5, 20.0), Vector2(0.0, -1.0), 0.0)
	else:
		_weapon(canvas, cfg, Vector2(6.0, 17.5), Vector2(0.72, -0.69), 0.0)

	var img := canvas.to_image(cfg["palettes"]).get_region(canvas.painted_rect())
	_fit(img, target)

	var tex := ImageTexture.create_from_image(img)
	_icons[key] = tex
	return tex


## Met une icône à la place disponible, en pixels d'écran. Agrandir : facteur
## entier. Réduire : facteur exact — c'est moins beau, mais une icône qui dépasse
## déborde sur les cases voisines et on ne sait plus lire la grille.
static func _fit(img: Image, target: Vector2i) -> void:
	if target.x <= 0 or target.y <= 0:
		return
	var ratio := minf(
		float(target.x) / float(img.get_width()), float(target.y) / float(img.get_height())
	)
	var factor := floorf(ratio) if ratio >= 1.0 else ratio
	if is_equal_approx(factor, 1.0):
		return
	img.resize(
		maxi(int(img.get_width() * factor), 1),
		maxi(int(img.get_height() * factor), 1),
		Image.INTERPOLATE_NEAREST
	)


## Les pièces d'équipement qui ne sont pas des armes : des objets posés à plat,
## qui n'existent que pour l'icône — d'où leur dessin ici plutôt que dans le
## squelette d'un personnage.
##
## La liste sert aussi d'aiguillage : un `kind` qui n'y est pas est une arme et
## part dans _weapon. Le test du catalogue vérifie que chaque base tombe dans l'un
## des deux, sinon son icône serait vide et personne ne le verrait avant de
## l'avoir ramassée.
const GEAR := [
	"torso", "shield", "helmet", "gloves", "boots", "belt", "amulet", "ring",
	# Étape 5 du jalon 5 : la main gauche d'incantation et les deux pièces
	# d'armure légère, qui ne pouvaient pas réemployer le casque et le plastron
	# sans se lire comme eux.
	"tome", "hood", "tunic",
	# Jalon 6 : le manuel, qui ne pouvait pas réemployer le tome — celui-ci est
	# le livre qu'on tient en main gauche, celui-là est le livre qu'on lit.
	"manual",
	# Jalon 10 : deux manuels de plus. Tous trois ont le même palier, donc les
	# mêmes rampes de couleur — c'est la **silhouette** qui doit les séparer dans
	# un sac, et ils n'en partagent aucune.
	"manual_fire", "manual_weapons",
	# Jalon 21 : le manuel du froid, le seul livre **debout**.
	"manual_cold",
	# Le manuel sacré : un livre couché dans son halo, la seule silhouette du
	# râtelier qui déborde du livre lui-même.
	"manual_holy",
	# Jalon 26 : le manuel nécrotique, un livre couché **sous un crâne** — la seule
	# silhouette du râtelier qui a un œil.
	"manual_necrotic",
]

## Ce qui distingue trois paliers d'une même lignée **sans image** : depuis que
## chaque base a la sienne, la silhouette s'en charge, et ces rampes ne servent
## plus qu'au repli.
##
## Le nom ne suffit pas — on ne lit pas le nom d'un objet au sol — et redessiner
## trois silhouettes par lignée à la main serait un jalon à soi seul. Restent les
## couleurs :
## un métal plus clair, un cuir plus riche et une étoffe plus franche à chaque
## palier, ce qui se lit à la taille d'une case là où un détail de deux pixels se
## perd.
const TIER_METAL := [
	Color(0.50, 0.51, 0.56), Color(0.72, 0.78, 0.86), Color(0.88, 0.93, 1.00)
]
const TIER_LEATHER := [
	Color(0.31, 0.21, 0.14), Color(0.40, 0.26, 0.18), Color(0.58, 0.41, 0.23)
]
const TIER_CLOTH := [
	Color(0.34, 0.36, 0.44), Color(0.30, 0.45, 0.68), Color(0.48, 0.34, 0.72)
]


## Chaque pièce en trois ou quatre traits. La contrainte n'est pas le détail mais
## la **silhouette** : à la taille d'une case on reconnaît une forme, pas un
## dessin, et un anneau et une amulette qui se ressemblent en petit sont deux
## objets qu'on confondra dans un sac plein.
static func _gear(c: PixelCanvas, kind: String, cx: float, top: float) -> void:
	match kind:
		"torso":
			c.capsule(Vector2(cx - 5.8, top + 2.8), Vector2(cx + 5.8, top + 2.8), 2.6, R_METAL)
			c.capsule(Vector2(cx, top + 5.0), Vector2(cx, top + 11.0), 5.2, R_METAL)
			c.capsule(Vector2(cx - 4.0, top + 14.0), Vector2(cx + 4.0, top + 14.0), 1.7, R_LEATHER)
			# Encolure creusée : sans elle, la plaque se lit comme un bouclier.
			c.disc(Vector2(cx, top + 1.6), 2.1, R_LEATHER, -0.30)

		"shield":
			# Large en haut, pointu en bas : c'est ce profil-là qui le distingue
			# du plastron, dont les épaules sont plus étroites que le ventre.
			c.capsule(Vector2(cx, top + 5.0), Vector2(cx, top + 10.0), 6.0, R_METAL)
			c.capsule(Vector2(cx, top + 10.0), Vector2(cx, top + 16.5), 2.4, R_METAL)
			c.disc(Vector2(cx, top + 7.5), 2.2, R_ACCENT, 0.30)

		"helmet":
			c.disc(Vector2(cx, top + 8.0), 4.8, R_METAL)
			c.capsule(Vector2(cx - 4.4, top + 10.8), Vector2(cx + 4.4, top + 10.8), 1.5, R_METAL)
			# La fente, peinte sombre par-dessus le dôme : sans elle le casque
			# n'est qu'une bosse grise. **Au-dessus** du nasal et non traversée
			# par lui — coupée en deux, elle se lisait comme des lunettes.
			c.capsule(Vector2(cx - 3.4, top + 9.8), Vector2(cx + 3.4, top + 9.8), 0.9, R_LEATHER, -0.40)
			c.capsule(Vector2(cx, top + 11.0), Vector2(cx, top + 12.6), 0.9, R_METAL, 0.25)

		"gloves":
			# Une moufle : la masse de la main, le pouce, la manchette. Le pouce
			# **part du bord de la main** — détaché, il flottait à côté comme un
			# second objet.
			c.capsule(Vector2(cx + 0.4, top + 6.8), Vector2(cx + 0.4, top + 11.2), 3.0, R_METAL)
			c.capsule(Vector2(cx - 2.4, top + 9.4), Vector2(cx - 4.2, top + 11.6), 1.4, R_METAL)
			c.capsule(Vector2(cx - 3.6, top + 14.2), Vector2(cx + 3.6, top + 14.2), 2.2, R_LEATHER)

		"boots":
			# La tige et le pied à angle droit : c'est l'angle qui fait la botte.
			# Tige fine et pied long — à l'inverse, la première version se lisait
			# comme un marteau, le pied ne dépassant presque pas.
			c.capsule(Vector2(cx - 1.0, top + 4.5), Vector2(cx - 1.0, top + 11.0), 2.4, R_LEATHER)
			c.capsule(Vector2(cx - 2.0, top + 13.5), Vector2(cx + 5.5, top + 13.5), 2.4, R_LEATHER)
			c.capsule(Vector2(cx - 3.6, top + 16.2), Vector2(cx + 6.2, top + 16.2), 1.0, R_METAL)

		"belt":
			c.capsule(Vector2(cx - 8.5, top + 9.0), Vector2(cx + 8.5, top + 9.0), 2.0, R_LEATHER)
			c.capsule(Vector2(cx - 2.0, top + 9.0), Vector2(cx + 2.0, top + 9.0), 3.2, R_ACCENT)
			# L'ardillon, creusé : une boucle pleine se lit comme une gemme.
			c.disc(Vector2(cx, top + 9.0), 1.5, R_LEATHER, -0.40)

		"amulet":
			# Chaîne resserrée : ouverte en grand, le V se lisait comme une paire
			# de ciseaux plutôt que comme un pendentif.
			c.capsule(Vector2(cx - 3.4, top + 3.5), Vector2(cx - 0.6, top + 9.5), 0.8, R_METAL)
			c.capsule(Vector2(cx + 3.4, top + 3.5), Vector2(cx + 0.6, top + 9.5), 0.8, R_METAL)
			# Monture large et gemme réduite : à l'inverse, la gemme mangeait sa
			# monture et le pendentif se lisait comme une étoile à quatre branches.
			c.disc(Vector2(cx, top + 13.2), 4.0, R_METAL)
			c.disc(Vector2(cx, top + 13.2), 1.8, R_ACCENT, 0.55)

		"tome":
			# Un livre fermé, vu de trois quarts : le corps, le dos plus sombre
			# sur un seul bord, le fermoir en travers. C'est le dos qui le
			# distingue d'un plastron — sans lui, deux rectangles arrondis.
			c.capsule(Vector2(cx + 0.6, top + 5.4), Vector2(cx + 0.6, top + 13.0), 4.6, R_LEATHER)
			c.capsule(Vector2(cx - 4.2, top + 4.6), Vector2(cx - 4.2, top + 13.8), 1.3, R_METAL)
			c.capsule(Vector2(cx + 0.4, top + 9.2), Vector2(cx + 5.0, top + 9.2), 1.0, R_ACCENT)
			# Les pages, en creux le long du bord libre.
			c.capsule(Vector2(cx + 4.4, top + 6.4), Vector2(cx + 4.4, top + 12.0), 0.7, R_CLOTH, 0.35)

		"manual":
			# **Deux livres empilés**, vus de trois quarts. Le tome de la main
			# gauche est un livre unique et debout ; une pile couchée s'en
			# distingue par sa silhouette seule, ce qui est la seule chose qui se
			# lise à la taille d'une case — un détail de deux pixels s'y perd.
			#
			# Chaque volume est une reliure sombre surmontée d'une tranche claire :
			# c'est ce liseré qui dit « pages » et empêche la pile de se lire comme
			# deux briques. Les tranches prennent la rampe du **métal**, la plus
			# claire des trois au premier palier ; en étoffe ou en cuir, tous deux
			# sombres, la pile sortait comme un monticule.
			c.capsule(Vector2(cx - 5.4, top + 12.6), Vector2(cx + 5.4, top + 12.6), 1.9, R_LEATHER)
			c.capsule(Vector2(cx - 4.6, top + 11.2), Vector2(cx + 4.6, top + 11.2), 0.8, R_METAL, 0.40)
			c.capsule(Vector2(cx - 4.4, top + 8.4), Vector2(cx + 4.4, top + 8.4), 1.9, R_LEATHER)
			c.capsule(Vector2(cx - 3.6, top + 7.0), Vector2(cx + 3.6, top + 7.0), 0.8, R_METAL, 0.40)
			# Le fermoir du volume du dessus, seul accent : posé au bord gauche,
			# là où le dos se lit, et jamais au centre où il passerait pour un titre.
			c.capsule(Vector2(cx - 4.4, top + 8.4), Vector2(cx - 2.4, top + 8.4), 1.0, R_ACCENT)

		"manual_fire":
			# **Un livre ouvert**, deux pages en V posées à plat. La pile est
			# fermée et horizontale, celui-ci s'ouvre vers le haut : c'est la
			# seule des deux formes qui laisse voir un creux au milieu, et le
			# creux se lit à la taille d'une case.
			# Les pages prennent la rampe du **métal**, la plus claire des trois :
			# en étoffe, le V sortait gris sur gris et se lisait comme un oiseau.
			c.capsule(Vector2(cx - 6.4, top + 10.8), Vector2(cx - 0.9, top + 7.2), 2.1, R_METAL, 0.20)
			c.capsule(Vector2(cx + 6.4, top + 10.8), Vector2(cx + 0.9, top + 7.2), 2.1, R_METAL, 0.20)
			# La reliure, sombre, tient les deux pages : sans elle, le V se lit
			# comme deux traits séparés.
			c.capsule(Vector2(cx, top + 8.0), Vector2(cx, top + 12.8), 1.7, R_LEATHER)
			# Le signet, seul accent, pendu sous la reliure et décalé : au centre,
			# il bouchait le creux qui fait tout le dessin.
			c.capsule(Vector2(cx + 1.6, top + 11.4), Vector2(cx + 1.6, top + 14.6), 0.8, R_ACCENT)

		"manual_weapons":
			# **Un rouleau**, couché et roulé sur ses deux bâtons. Ni une pile ni
			# un livre ouvert : un cylindre franc, qu'on reconnaît à ses deux
			# bouts plus clairs.
			c.capsule(Vector2(cx - 5.0, top + 10.0), Vector2(cx + 5.0, top + 10.0), 2.9, R_LEATHER)
			c.capsule(Vector2(cx - 6.2, top + 10.0), Vector2(cx - 6.2, top + 10.0), 1.5, R_METAL)
			c.capsule(Vector2(cx + 6.2, top + 10.0), Vector2(cx + 6.2, top + 10.0), 1.5, R_METAL)
			# La tranche du parchemin en creux le long du haut : c'est elle qui dit
			# « enroulé » plutôt que « bâton ».
			c.capsule(Vector2(cx - 4.4, top + 8.2), Vector2(cx + 4.4, top + 8.2), 0.8, R_CLOTH, 0.35)
			# Le lien qui le ferme, en travers et non au bout : au bout, il se
			# confondrait avec un embout.
			c.capsule(Vector2(cx - 0.6, top + 7.4), Vector2(cx - 0.6, top + 12.6), 0.9, R_ACCENT)

		"manual_cold":
			# **Un livre debout**, vu de face. Les trois autres sont couchés — pile,
			# livre ouvert, rouleau — et c'est la verticale seule qui le distingue à la
			# taille d'une case ; le dos sombre sur un bord dit de quel côté il s'ouvre.
			c.capsule(Vector2(cx + 0.4, top + 5.2), Vector2(cx + 0.4, top + 14.4), 3.6, R_METAL, 0.20)
			c.capsule(Vector2(cx - 3.4, top + 4.4), Vector2(cx - 3.4, top + 15.2), 1.5, R_LEATHER)
			# Le cristal au plat de la couverture, seul accent : c'est lui qui dit « livre »
			# plutôt que « stèle ».
			c.disc(Vector2(cx + 0.8, top + 9.6), 1.8, R_ACCENT)

		"manual_holy":
			# **Un livre couché devant son halo.** Les quatre autres se distinguent par
			# l'orientation du livre seul ; une cinquième s'y serait confondue, alors
			# que la rondeur se lit à la taille d'une case. Le halo **dépasse par le
			# haut** : centré sur la reliure, il donnait une pièce barrée d'un trait.
			c.disc(Vector2(cx, top + 8.2), 6.4, R_METAL, 0.30)
			c.capsule(Vector2(cx - 5.8, top + 12.6), Vector2(cx + 5.8, top + 12.6), 2.8, R_LEATHER)
			# La tranche claire le long du bord libre : c'est elle qui dit « pages »
			# plutôt que « socle ».
			c.capsule(Vector2(cx - 5.0, top + 11.0), Vector2(cx + 5.0, top + 11.0), 0.9, R_METAL, 0.40)
			c.capsule(Vector2(cx - 5.4, top + 12.6), Vector2(cx - 3.0, top + 12.6), 1.1, R_ACCENT)

		"manual_necrotic":
			# **Un crâne posé sur un livre couché.** Le halo du sacré déborde du livre par
			# une rondeur claire ; le crâne en déborde aussi, mais ses deux orbites
			# creusées le distinguent à la taille d'une case.
			c.capsule(Vector2(cx - 5.8, top + 13.0), Vector2(cx + 5.8, top + 13.0), 2.6, R_LEATHER)
			c.capsule(Vector2(cx - 5.0, top + 11.4), Vector2(cx + 5.0, top + 11.4), 0.9, R_METAL, 0.40)
			c.disc(Vector2(cx, top + 6.6), 3.8, R_METAL, 0.20)
			c.capsule(Vector2(cx - 1.4, top + 9.6), Vector2(cx + 1.4, top + 9.6), 1.6, R_METAL, 0.20)
			c.disc(Vector2(cx - 1.5, top + 6.8), 1.0, R_LEATHER, -0.40)
			c.disc(Vector2(cx + 1.5, top + 6.8), 1.0, R_LEATHER, -0.40)

		"hood":
			# Une pointe et une ouverture : c'est le sommet effilé qui la sépare
			# du dôme d'un casque, et l'ouverture creusée qui dit qu'on y entre
			# la tête.
			c.capsule(Vector2(cx, top + 3.2), Vector2(cx, top + 10.4), 4.4, R_CLOTH)
			c.capsule(Vector2(cx, top + 1.6), Vector2(cx, top + 4.6), 1.6, R_CLOTH)
			c.disc(Vector2(cx, top + 11.4), 3.0, R_LEATHER, -0.38)
			c.capsule(Vector2(cx - 4.2, top + 13.6), Vector2(cx + 4.2, top + 13.6), 1.4, R_LEATHER)

		"tunic":
			# Le plastron en étoffe : épaules tombantes au lieu de spallières,
			# taille resserrée par une ceinture, encolure en V. Aucune plaque —
			# c'est l'absence de métal qui dit « légère » avant la couleur.
			c.capsule(Vector2(cx - 5.2, top + 3.6), Vector2(cx + 5.2, top + 3.6), 2.0, R_CLOTH)
			c.capsule(Vector2(cx, top + 5.2), Vector2(cx, top + 11.4), 4.6, R_CLOTH)
			c.capsule(Vector2(cx - 3.4, top + 13.4), Vector2(cx + 3.4, top + 13.4), 1.8, R_LEATHER)
			c.capsule(Vector2(cx, top + 1.4), Vector2(cx, top + 4.6), 1.4, R_LEATHER, -0.32)

		"ring":
			c.disc(Vector2(cx, top + 11.0), 4.8, R_METAL)
			# Le trou, peint sombre : le canevas n'efface pas, il repeint. C'est
			# le même procédé que l'encolure du plastron.
			c.disc(Vector2(cx, top + 11.0), 2.5, R_LEATHER, -0.55)
			c.disc(Vector2(cx, top + 5.6), 2.3, R_ACCENT, 0.55)


# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------

## Toute la direction artistique des personnages tient dans cette fonction : cinq
## couleurs, une dizaine de mesures, trois options. Ajouter un archétype, c'est
## ajouter un cas ici — le reste du fichier n'en sait rien.
static func config(archetype: String, variant := 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	# Graine figée : la variante 2 du grunt sera toujours le même grunt.
	rng.seed = hash(archetype) * 7919 + variant * 104729

	# Proportions caricaturales et non anatomiques : grosse tête, épaules larges,
	# jambes courtes. En 32 px, c'est la tête qui porte la lisibilité d'un
	# personnage — elle occupe un tiers de la hauteur du corps, pas un sixième.
	var cfg := {
		"archetype": archetype,
		"head_r": 4.6, "head_y": 8.8,
		"shoulder_y": 13.6, "hip_y": 20.5,
		"torso_r": 4.5, "sh_w": 4.4, "hip_w": 2.5,
		"limb_r": 1.7, "arm_r": 1.5,
		"hood": false, "robe": false, "pauldrons": false, "mantle": false,
		"weapon": "none",
		"eye_ramp": R_LEATHER, "eye_level": 0.0,
	}

	var base := {}
	# Le joueur est exclu de la variation : sa tenue est choisie à la création, et
	# un tirage par-dessus ce choix ferait deux personnages du même numéro.
	var amount := 1.0
	match archetype:
		"player":
			base = {
				"cloth": PLAYER_CLOTHS[variant % PLAYER_CLOTHS.size()],
				"skin": Color(0.92, 0.73, 0.56),
				"accent": Color(0.98, 0.80, 0.30), "metal": Color(0.72, 0.78, 0.86),
				"leather": Color(0.40, 0.26, 0.18),
			}
			cfg["weapon"] = "sword"
			cfg["pauldrons"] = true
			amount = 0.0

		"grunt":
			base = {
				"cloth": Color(0.42, 0.55, 0.24), "skin": Color(0.58, 0.66, 0.42),
				"accent": Color(0.85, 0.35, 0.20), "metal": Color(0.58, 0.52, 0.44),
				"leather": Color(0.30, 0.24, 0.16),
			}
			# Plus trapu et plus bas que le joueur : la silhouette doit dire
			# « masse qui fonce » avant même qu'il bouge.
			cfg.merge({
				"head_r": 5.0, "head_y": 10.2,
				"shoulder_y": 15.0, "hip_y": 21.0,
				"torso_r": 5.0, "sh_w": 5.0, "hip_w": 2.8,
				"limb_r": 1.8,
			}, true)
			cfg["weapon"] = "cleaver" if rng.randf() < 0.5 else "club"
			cfg["eye_ramp"] = R_ACCENT
			cfg["eye_level"] = 1.0

		"caster":
			base = {
				"cloth": Color(0.52, 0.28, 0.72), "skin": Color(0.80, 0.68, 0.62),
				"accent": Color(0.45, 0.92, 0.95), "metal": Color(0.60, 0.62, 0.72),
				"leather": Color(0.28, 0.20, 0.34),
			}
			# Pas de jambes : une robe évasée. Le caster doit se repérer dans une
			# mêlée à sa silhouette seule, avant sa couleur.
			# La capuche suit la tête de près : trop grosse, elle repasse devant le
			# buste et le caster redevient une quille. D'où +0,4 seulement, et un
			# buste élargi d'autant.
			cfg.merge({
				"head_r": 4.0, "head_y": 8.0,
				"shoulder_y": 13.2, "hip_y": 19.5,
				"torso_r": 3.9, "sh_w": 3.6, "hip_w": 2.3,
				"hood": true, "robe": true, "mantle": true,
			}, true)
			cfg["weapon"] = "staff"

		"undead":
			# Des os et rien d'autre : un allié ne doit jamais se confondre avec le grunt
			# vert, et c'est le blanc de l'os, plus que les orbites, qui le sépare.
			base = {
				"cloth": Color(0.40, 0.36, 0.30), "skin": Color(0.86, 0.84, 0.74),
				"accent": Color(0.62, 0.95, 0.35), "metal": Color(0.55, 0.52, 0.46),
				"leather": Color(0.30, 0.24, 0.20),
			}
			amount = 0.3

		_:
			base = {
				"cloth": Color(0.78, 0.62, 0.36), "skin": Color(0.80, 0.68, 0.56),
				"accent": Color(0.82, 0.30, 0.24), "metal": Color(0.62, 0.62, 0.66),
				"leather": Color(0.40, 0.28, 0.18),
			}

	# Un archétype en planche porte sa palette et son arme par défaut, et l'ombre au
	# sol se règle sur le buste d'une case de 48.
	var sheet := sheet_of(archetype)
	if sheet != null:
		var palette: Dictionary = sheet.meta["palette"]
		for role in palette:
			base[role] = Color(palette[role])
		cfg["weapon"] = sheet.meta["weapon"]
		cfg["torso_r"] = 6.8
		amount = 0.0

	# Variation par instance : nuance des étoffes et de la peau, corpulence.
	cfg["palettes"] = [
		ArtPalette.ramp(ArtPalette.jitter(base["cloth"], rng, amount)),
		ArtPalette.ramp(ArtPalette.jitter(base["skin"], rng, amount * 0.7)),
		ArtPalette.ramp(base["accent"]),
		ArtPalette.ramp(base["metal"]),
		ArtPalette.ramp(ArtPalette.jitter(base["leather"], rng, amount * 0.5)),
	]

	if amount > 0.0:
		cfg["torso_r"] = float(cfg["torso_r"]) + rng.randf_range(-0.35, 0.45)
		cfg["head_r"] = float(cfg["head_r"]) + rng.randf_range(-0.25, 0.25)
		cfg["hip_y"] = float(cfg["hip_y"]) + rng.randf_range(-0.5, 0.5)

	return cfg


# --------------------------------------------------------------------------
# Pixels dessinés à la main
# --------------------------------------------------------------------------

## La légende des grilles : minuscule = ombre, majuscule = teinte de base, une
## troisième lettre pour la lumière, et `j`/`k` pour les traits sombres qui
## séparent un bras d'un buste. Les cinq rampes sont celles de `config()`.
##
## Le contour extérieur n'est **pas** dessiné dans les grilles : `to_image()` le
## pose sur la silhouette entière, ce qui évite un contour par pièce.
const INK := {
	"c": [R_CLOTH, 1], "C": [R_CLOTH, 2], "L": [R_CLOTH, 3], "k": [R_CLOTH, 0],
	"s": [R_SKIN, 1], "S": [R_SKIN, 2], "P": [R_SKIN, 3],
	"a": [R_ACCENT, 1], "A": [R_ACCENT, 2], "E": [R_ACCENT, 3],
	"m": [R_METAL, 1], "M": [R_METAL, 2], "H": [R_METAL, 3],
	"t": [R_LEATHER, 1], "T": [R_LEATHER, 2], "U": [R_LEATHER, 3], "j": [R_LEATHER, 0],
}

## Rangée où commencent les jambes. Elles sont une grille à part : c'est elle
## qui change au pas de marche, et le buste respire au-dessus sans emmener les
## pieds. Sa première rangée est de la tunique, qui bouche le trou laissé par un
## buste monté d'un pixel.
const LEGS_TOP := 21

## Quelle grille de jambes pour chaque temps de `WALK_SWING` : contact, passage,
## contact opposé, passage.
const WALK_LEGS := [1, 0, 2, 0]

const BODY_DOWN := [
	"....TTTTTT....",
	"..UTTTTTTTTt..",
	"..UTTTTTTTTt..",
	"..UTSSSSSSTt..",
	"..TPSSSSSSst..",
	"..TPSjSSjSst..",
	"..TPSSSSSSst..",
	"...sSSSSSSs...",
	"....sSSSSs....",
	".....sSSs.....",
	".HMMCCCCCCMMm.",
	".HMMkLCCCckMm.",
	"..LCkLCCCckCc.",
	"..LCkLCCCckCc.",
	"..LCkLCCCckCc.",
	"..PSkLCCCckSs.",
	"...jCCCCCCj...",
	"..jTTTTTTTTj..",
	"..jTTAAEATTj..",
]

const BODY_SIDE := [
	"..TTTTTT....",
	".TTTTTTTT...",
	".TTTTTTTTT..",
	".TTTSSSSSS..",
	".TTTSSSSSSP.",
	".TTTSjSSSSP.",
	".TTTSSSSSSs.",
	"..tsSSSSSs..",
	"...sSSSSs...",
	"....sSSs....",
	"..mMMMMCCc..",
	"..mMMMkLCc..",
	"..cCCCkLCc..",
	"..cCCCkLCc..",
	"..cCCCkLCc..",
	"..cCCCkPSc..",
	"..jCCCCCCj..",
	"..jTTTTTTj..",
	"..jTTAETTj..",
]

const BODY_UP := [
	"....TTTTTT....",
	"..UTTTTTTTTt..",
	"..UTTTTTTTTt..",
	"..UTTTTTTTTt..",
	"..UTTTTTTTTt..",
	"..UTTTTTTTTt..",
	"..UTTTTTTTTt..",
	"...tTTTTTTt...",
	"....ttTTtt....",
	".....cCCc.....",
	".HMMCCCCCCMMm.",
	".HMMkLCCCckMm.",
	"..LCkLCCCckCc.",
	"..LCkLCCCckCc.",
	"..LCkLCCCckCc.",
	"..PSkLCCCckSs.",
	"...jCCCCCCj...",
	"..jTTTTTTTTj..",
	"..jTTTTTTTTj..",
]

const LEGS_IDLE := [
	"...CCCCCCCC...",
	"...CCCCCCCC...",
	"...CCCjjCCC...",
	"...cCCjjCCc...",
	"...TTUjjUTt...",
	"...TTUjjUTt...",
	"...jTTjjTTj...",
]

const LEGS_A := [
	"...CCCCCCCC...",
	"...CCCCCCCC...",
	"...CCCjjCCC...",
	"...TTUjjCCc...",
	"...TTUjjUTt...",
	"...jTTjjUTt...",
	"......jjTTj...",
]

const LEGS_B := [
	"...CCCCCCCC...",
	"...CCCCCCCC...",
	"...CCCjjCCC...",
	"...cCCjjUTT...",
	"...TTUjjUTT...",
	"...TTUjjTTj...",
	"...jTTjj......",
]

const SIDE_IDLE := [
	"...CCCCCC...",
	"...CCCCCC...",
	"...CCCCCC...",
	"...cCCCCc...",
	"...TTUUTt...",
	"...TTUUTt...",
	"..jTTUUTTj..",
]

const SIDE_A := [
	"...CCCCCC...",
	"...CCCCCC...",
	"...CCCCCC...",
	"..cCCCCCc...",
	"..TTUUCCc...",
	"..TTUjUTt...",
	".jTTj.jTTj..",
]

const SIDE_B := [
	"...CCCCCC...",
	"...CCCCCC...",
	"...CCCCCC...",
	"...cCCCCc...",
	"...cCCUUTt..",
	"...TTUjUTt..",
	"..jTTj.jTTj.",
]

## Le grunt : trapu, épaules larges, tête basse. La silhouette doit dire « masse
## qui fonce » avant que la couleur n'arrive.
const GRUNT_DOWN := [
	"......tttt......",
	".....tttttt.....",
	"....SSSSSSSS....",
	"....SSSSSSSS....",
	"....SsaSSasS....",
	"....SSSSSSSS....",
	"....SSjjjjSS....",
	".....SjEEjS.....",
	"......ssss......",
	"..TTCCCCCCCCTT..",
	".TTTCCLLCCCCTTT.",
	".TTcCCLLCCCCcTT.",
	"..ScCCLLCCCCcS..",
	"..SSjCCCCCCjSS..",
	"...jTTTTTTTTj...",
	"...jCCCCCCCCj...",
]

const GRUNT_SIDE := [
	"....tttt........",
	"...tttttt.......",
	"...tSSSSSS......",
	"...tSSSSSSs.....",
	"...tSSaSSSP.....",
	"...tSSSSSSs.....",
	"...tSSjjjSs.....",
	"....sSjEjs......",
	".....ssss.......",
	"..TTTCCCCCc.....",
	"..TTCCCCkLCc....",
	"..TcCCCCkLCc....",
	"..ScCCCCkLCc....",
	"..SSjCCCkPSc....",
	"...jTTTTTTj.....",
	"...jCCCCCCj.....",
]

const GRUNT_UP := [
	"......tttt......",
	".....tttttt.....",
	"....tttttttt....",
	"....tttttttt....",
	"....tttttttt....",
	"....tttttttt....",
	"....SSSSSSSS....",
	".....ssssss.....",
	"......ssss......",
	"..TTCCCCCCCCTT..",
	".TTTCCCCCCCCTTT.",
	".TTcCCCCCCCCcTT.",
	"..ScCCCCCCCCcS..",
	"..SSjCCCCCCjSS..",
	"...jTTTTTTTTj...",
	"...jCCCCCCCCj...",
]

const GRUNT_LEGS := [
	"...CCCCCCCCCC...",
	"...CCCCccCCCC...",
	"...cCCCccCCCc...",
	"...TTCCccCCTt...",
	"...TTUCccCUTt...",
	"...TTUCccCUTt...",
	"...jTTjccjTTj...",
]

const GRUNT_LEGS_A := [
	"...CCCCCCCCCC...",
	"...CCCCccCCCC...",
	"...cCCCccCCCc...",
	"...TTCCccCCTt...",
	"...TTUCccCUTt...",
	"...jTTjccjUTt...",
	".........jTTj...",
]

const GRUNT_LEGS_B := [
	"...CCCCCCCCCC...",
	"...CCCCccCCCC...",
	"...cCCCccCCCc...",
	"...TTCCccCCTt...",
	"...TTUCccCUTt...",
	"...TTUjccjTTj...",
	"...jTTjj........",
]

const GRUNT_SIDE_LEGS := [
	"...CCCCCCCC.....",
	"...CCCCCCCC.....",
	"...cCCCCCCc.....",
	"...cCCCCCCc.....",
	"...TTUUUUTt.....",
	"...TTUUUUTt.....",
	"..jTTUUUUTTj....",
]

const GRUNT_SIDE_LEGS_A := [
	"...CCCCCCCC.....",
	"...CCCCCCCC.....",
	"...cCCCCCCc.....",
	"..cCCCCCCc......",
	"..TTUUCCc.......",
	"..TTUjUUTt......",
	".jTTj.jTTj......",
]

const GRUNT_SIDE_LEGS_B := [
	"...CCCCCCCC.....",
	"...CCCCCCCC.....",
	"...cCCCCCCc.....",
	"....cCCCCCCc....",
	".....cCUUUUTt...",
	"....TTUjUUTt....",
	"...jTTj.jTTj....",
]

## Le caster : une robe et une capuche pointue, aucun visage — un creux noir et
## deux braises. C'est la silhouette qui le fait repérer dans une mêlée, et une
## capuche plus large que le buste le rendrait à l'état de quille.
const CASTER_DOWN := [
	"......LL......",
	".....LCCL.....",
	"....LCCCCc....",
	"....LCCCCCc...",
	"...LCCCCCCcc..",
	"...LCCCCCCCc..",
	"...LCkkkkkCc..",
	"...LCkEkkEkc..",
	"...LCkkkkkkc..",
	"...LCCCCCCCc..",
	"..LCCCCCCCCcc.",
	"..kkkkkkkkkkk.",
	"..LCCCCCCCCcc.",
	"..LCCCCCCCCcc.",
	".SsLCCCCCCcsS.",
	"..jLCCCCCCcj..",
	"..jLCCCCCCcj..",
	"..jLCCCCCCcj..",
]

const CASTER_SIDE := [
	"....LL........",
	"...LCCL.......",
	"..LCCCCc......",
	"..LCCCCCc.....",
	"..LCCCCCCc....",
	"..LCCCCCCCc...",
	"..LCkkkkCCc...",
	"..LCkEkkCCc...",
	"..LCkkkkCCc...",
	"..LCCCCCCCc...",
	"..LCCCCCCCCc..",
	"..kkkkkkkkkk..",
	"..LCCCCCCCCc..",
	"..LCCCCCCCCc..",
	"..LCCCCCCsSc..",
	"..jLCCCCCCcj..",
	"..jLCCCCCCcj..",
	"..jLCCCCCCcj..",
]

const CASTER_UP := [
	"......LL......",
	".....LCCL.....",
	"....LCCCCc....",
	"....LCCCCCc...",
	"...LCCCCCCcc..",
	"...LCCCCCCCc..",
	"...LCCCCCCCc..",
	"...LCCCCCCCc..",
	"...LCCCCCCCc..",
	"...LCCCCCCCc..",
	"..LCCCCCCCCcc.",
	"..kkkkkkkkkkk.",
	"..LCCCCCCCCcc.",
	"..LCCCCCCCCcc.",
	".SsLCCCCCCcsS.",
	"..jLCCCCCCcj..",
	"..jLCCCCCCcj..",
	"..jLCCCCCCcj..",
]

const CASTER_ROBE := [
	"..LCCCCCCCCc..",
	"..LCCCCCCCCc..",
	".LCCCCCCCCCCc.",
	".LCCCCCCCCCCc.",
	"LCCCCCCCCCCCCc",
	"LCCkCCCCCCkCCc",
	"jTTTTTTTTTTTTj",
]

const CASTER_ROBE_A := [
	"..LCCCCCCCCc..",
	"..LCCCCCCCCc..",
	".LCCCCCCCCCCc.",
	".LCCCCCCCCCCc.",
	"LCCCCCCCCCCCc.",
	"LCCkCCCCCCkCc.",
	"jTTTTTTTTTTj..",
]

const CASTER_ROBE_B := [
	"..LCCCCCCCCc..",
	"..LCCCCCCCCc..",
	".LCCCCCCCCCCc.",
	".LCCCCCCCCCCc.",
	".LCCCCCCCCCCCc",
	".LCCkCCCCCCkCc",
	"..jTTTTTTTTTTj",
]

## Les archétypes dessinés pixel par pixel. Les autres restent assemblés en
## capsules par `_draw_front` / `_draw_side` — les deux chemins cohabitent, et un
## archétype absent de cette table n'a rien à déclarer.
##
## `hand` est le poignet armé, d'où part `_weapon()` : le dessin donne la
## silhouette, l'arme reste procédurale parce qu'elle suit l'équipement.
## Le mort-vivant de la Relève (jalon 26) : un squelette nu, des os séparés par le vide,
## les orbites vertes. Choisi sur planche contre un soldat en armure, un revenant
## encapuchonné et un zombie — le seul qu'on ne confonde avec aucun ennemi.
const UNDEAD_DOWN := [
	"......PPPP......",
	".....PSSSSP.....",
	"....PSSSSSSP....",
	"....SSSSSSSS....",
	"....SEaSSaES....",
	"....SSSjjSSS....",
	".....SSSSSS.....",
	".....sjsjsjs....",
	"......ssss......",
	"...SS.SSSS.SS...",
	"..S.sSjSSjSs.S..",
	"..S..SjSSjS..S..",
	"..s..sSjjSs..s..",
	"..S...SSSS...S..",
	"..P...jSSj...P..",
	"......SSSS......",
]

const UNDEAD_SIDE := [
	"....PPPP........",
	"...PSSSSP.......",
	"...SSSSSSP......",
	"...SSSSSSS......",
	"...SSSSaES......",
	"...SSSSSjS......",
	"...sSSSSSS......",
	"....sSjsjs......",
	".....sss........",
	".....SSS........",
	"....SsSjS.......",
	"....SSjS.S......",
	"....sSjS.S......",
	".....SS..P......",
	".....jS.........",
	".....SS.........",
]

const UNDEAD_UP := [
	"......PPPP......",
	".....PSSSSP.....",
	"....PSSSSSSP....",
	"....SSSSSSSS....",
	"....SSSSSSSS....",
	"....sSSSSSSs....",
	".....sSSSSs.....",
	"......ssss......",
	"......ssss......",
	"...SS.SjjS.SS...",
	"..S.sSjSSjSs.S..",
	"..S..SjSSjS..S..",
	"..s..sSjjSs..s..",
	"..S...SSSS...S..",
	"..P...jSSj...P..",
	"......SSSS......",
]

const UNDEAD_LEGS := [
	"......SSSS......",
	".....SS..SS.....",
	".....S....S.....",
	".....S....S.....",
	".....s....s.....",
	".....S....S.....",
	"....SS....SS....",
]

const UNDEAD_LEGS_A := [
	"......SSSS......",
	".....SS..SS.....",
	".....S....S.....",
	".....S....S.....",
	".....s...SS.....",
	".....S..........",
	"....SS..........",
]

const UNDEAD_LEGS_B := [
	"......SSSS......",
	".....SS..SS.....",
	".....S....S.....",
	".....S....S.....",
	".....SS...s.....",
	"..........S.....",
	"..........SS....",
]

const UNDEAD_SIDE_LEGS := [
	".....SS.........",
	".....SS.........",
	".....S.S........",
	".....S.S........",
	".....s.s........",
	".....S.S........",
	"....SS.SS.......",
]

const UNDEAD_SIDE_LEGS_A := [
	".....SS.........",
	".....SS.........",
	"....S..S........",
	"...S....S.......",
	"...s....s.......",
	"..S......S......",
	"..SS.....SS.....",
]

const UNDEAD_SIDE_LEGS_B := [
	".....SS.........",
	".....SS.........",
	".....SS.........",
	".....SS.........",
	"....s.s.........",
	"....S..S........",
	"...SS..SS.......",
]

const ART := {
	"player": {
		"down": {
			"origin": Vector2i(9, 3),
			"hand": Vector2(20.0, 18.5),
			"body": BODY_DOWN,
			"legs": [LEGS_IDLE, LEGS_A, LEGS_B],
		},
		"side": {
			"origin": Vector2i(10, 3),
			# Plus en avant et plus bas que de face : de profil, une épée tenue à
			# hauteur de ceinture traverse le visage.
			"hand": Vector2(19.0, 19.5),
			"body": BODY_SIDE,
			"legs": [SIDE_IDLE, SIDE_A, SIDE_B],
		},
		"up": {
			"origin": Vector2i(9, 3),
			"hand": Vector2(11.0, 18.5),
			"body": BODY_UP,
			"legs": [LEGS_IDLE, LEGS_A, LEGS_B],
		},
	},
	"grunt": {
		"down": {
			"origin": Vector2i(8, 5),
			"hand": Vector2(21.0, 18.5),
			"body": GRUNT_DOWN,
			"legs": [GRUNT_LEGS, GRUNT_LEGS_A, GRUNT_LEGS_B],
		},
		"side": {
			"origin": Vector2i(8, 5),
			# Bas et en avant : le couperet est large, et tenu à hauteur d'épaule
			# il recouvre la tête du grunt.
			"hand": Vector2(19.5, 21.0),
			"body": GRUNT_SIDE,
			"legs": [GRUNT_SIDE_LEGS, GRUNT_SIDE_LEGS_A, GRUNT_SIDE_LEGS_B],
		},
		"up": {
			"origin": Vector2i(8, 5),
			"hand": Vector2(10.0, 18.5),
			"body": GRUNT_UP,
			"legs": [GRUNT_LEGS, GRUNT_LEGS_A, GRUNT_LEGS_B],
		},
	},
	"undead": {
		"down": {
			"origin": Vector2i(8, 5),
			"hand": Vector2(21.0, 19.5),
			"body": UNDEAD_DOWN,
			"legs": [UNDEAD_LEGS, UNDEAD_LEGS_A, UNDEAD_LEGS_B],
		},
		"side": {
			"origin": Vector2i(8, 5),
			"hand": Vector2(17.5, 18.5),
			"body": UNDEAD_SIDE,
			"legs": [UNDEAD_SIDE_LEGS, UNDEAD_SIDE_LEGS_A, UNDEAD_SIDE_LEGS_B],
		},
		"up": {
			"origin": Vector2i(8, 5),
			"hand": Vector2(10.0, 19.5),
			"body": UNDEAD_UP,
			"legs": [UNDEAD_LEGS, UNDEAD_LEGS_A, UNDEAD_LEGS_B],
		},
	},
	"caster": {
		"down": {
			"origin": Vector2i(9, 3),
			"hand": Vector2(20.5, 17.5),
			"body": CASTER_DOWN,
			"legs": [CASTER_ROBE, CASTER_ROBE_A, CASTER_ROBE_B],
		},
		"side": {
			"origin": Vector2i(9, 3),
			"hand": Vector2(18.5, 17.5),
			"body": CASTER_SIDE,
			"legs": [CASTER_ROBE, CASTER_ROBE_A, CASTER_ROBE_B],
		},
		"up": {
			"origin": Vector2i(9, 3),
			"hand": Vector2(10.5, 17.5),
			"body": CASTER_UP,
			"legs": [CASTER_ROBE, CASTER_ROBE_A, CASTER_ROBE_B],
		},
	},
}

# --------------------------------------------------------------------------
# Poses
# --------------------------------------------------------------------------

## Une pose = les quelques scalaires qui suffisent à décaler le squelette.
## swing : phase de marche (-1..1). lean : buste projeté en avant.
## arm : bras armé (négatif = armé en arrière, positif = tendu).
static func _pose(cfg: Dictionary, dir: String, anim: String, index: int) -> Dictionary:
	var placed := {"bob": 0.0, "swing": 0.0, "lean": 0.0, "arm": 0.0}

	match anim:
		"idle":
			placed["bob"] = IDLE_BOB[index % IDLE_BOB.size()]
		"walk":
			placed["swing"] = WALK_SWING[index % WALK_SWING.size()]
			placed["bob"] = WALK_BOB[index % WALK_BOB.size()]
		"attack":
			if index == 0:
				# Armé : on recule pour donner de l'élan à l'image suivante.
				placed["lean"] = -0.7
				placed["arm"] = -1.0
			else:
				placed["lean"] = 1.3
				placed["arm"] = 1.0
				placed["bob"] = -1.0

	placed["weapon_dir"] = _weapon_dir(cfg, dir, anim, index)
	return placed


## Un bâton ne se porte pas comme une épée : tenu en biais il traverse le
## sprite en diagonale et son cristal finit à flotter dans le vide, à côté du
## personnage. Au repos il reste donc quasi vertical, contre le corps, et ne
## bascule vers l'avant qu'au moment du sort.
static func _weapon_dir(cfg: Dictionary, dir: String, anim: String, index: int) -> Vector2:
	var staff: bool = cfg["weapon"] == "staff"

	# Le lancer tient l'arme comme le coup : armée, puis portée en avant.
	if anim == "attack" or anim == "cast":
		if index == 0:
			if staff:
				return Vector2(-0.05, -1.0)
			return Vector2(0.62, -0.78) if dir != "side" else Vector2(-0.20, -0.98)
		if staff:
			return Vector2(0.78, 0.63) if dir != "side" else Vector2(0.98, 0.20)
		return Vector2(0.30, 0.95) if dir != "side" else Vector2(0.97, 0.24)

	return Vector2(0.14, -0.99) if staff else Vector2(0.42, -0.91)


# --------------------------------------------------------------------------
# Dessin
# --------------------------------------------------------------------------

## Un archétype dessiné à la main : on pose les jambes, le buste par-dessus, puis
## l'arme à la main armée. Le squelette ne sert plus qu'à trois nombres — le
## souffle, le déport du buste et la pose de l'arme.
static func _draw_authored(
	c: PixelCanvas, cfg: Dictionary, dir: String, placed: Dictionary, anim: String, index: int
) -> void:
	var art: Dictionary = (ART[cfg["archetype"]] as Dictionary)[dir]
	var origin: Vector2i = art["origin"]
	var bob := roundi(placed["bob"])
	# Le déport du buste est en pixels entiers : un demi-pixel de biais rendrait
	# flou tout ce que la grille a de net.
	var lean := roundi(float(placed["lean"]) * 0.8)

	c.ground_shadow(CX, FEET + 1.5, float(cfg["torso_r"]) + 1.2, 2.2)

	var legs: Array = art["legs"]
	var step: int = WALK_LEGS[index % WALK_LEGS.size()] if anim == "walk" else 0
	c.stamp(legs[step], Vector2i(origin.x, LEGS_TOP), INK)
	c.stamp(art["body"], Vector2i(origin.x + lean, origin.y + bob), INK)

	# De dos, le bras armé passe de l'autre côté de l'écran ; la grille le sait
	# déjà pour la main, `_weapon` a besoin qu'on retourne sa direction.
	var s := -1.0 if dir == "up" else 1.0
	var hand: Vector2 = Vector2(art["hand"]) + Vector2(lean, bob)
	var arm: float = placed["arm"]
	if arm != 0.0:
		var goal := Vector2(hand.x + s * 2.0, 13.5)
		if arm < 0.0:
			goal = Vector2(hand.x - s * 1.5, 21.0)
		hand = hand.lerp(goal, absf(arm))
		# La main suit l'arme, sinon elle reste plantée à la ceinture pendant que
		# l'épée part en l'air.
		c.disc(hand, 1.7, R_SKIN)

	_weapon(c, cfg, hand, Vector2(placed["weapon_dir"]) * Vector2(s, 1.0), 0.0)


## Un archétype en planche (`tools/character_forge.py`) : la marche et l'attaque
## sont des images générées, posées telles quelles, chacune avec sa main armée ; le
## repos est la pose validée, qui respire. Ombre dessous, arme dessus, chacune sur
## son canevas — `to_image()` pose l'ombre sous tout ce qu'il a peint.
static func _draw_sheet(
	sheet: Sheet, cfg: Dictionary, dir: String, placed: Dictionary, anim: String, index: int
) -> Image:
	var f: int = sheet.meta["frame"]
	var view: Dictionary = sheet.meta["views"][dir]
	var anims: Dictionary = sheet.meta.get("anims", {})

	var under := PixelCanvas.new(f, f)
	under.ground_shadow(f * 0.5 - 0.5, float(sheet.meta["feet"]) + 1.5, float(cfg["torso_r"]) + 1.2, 2.2)
	var out := under.to_image(cfg["palettes"])

	var hand := Vector2(view["hand"][0], view["hand"][1])
	if anims.has(anim):
		var cycle: Dictionary = anims[anim]
		var i := index % int(cycle["count"])
		var cell := Rect2i(i * f, int(cycle["rows"][dir]) * f, f, f)
		out.blend_rect(sheet.image, cell, Vector2i.ZERO)
		var at: Array = cycle["hands"][dir][i]
		hand = Vector2(at[0], at[1])
	else:
		# Le repos : la pose validée, qui respire au-dessus des pieds. Le jour laissé
		# sous le buste monté est bouché par sa dernière rangée.
		var legs: int = view["legs"]
		var bob: int = SHEET_BREATH[index % SHEET_BREATH.size()]
		var pose := Rect2i(DIRS.find(dir) * f, 0, f, f)
		out.blend_rect(sheet.image, Rect2i(pose.position.x, legs, f, f - legs), Vector2i(0, legs))
		out.blend_rect(sheet.image, Rect2i(pose.position.x, 0, f, legs), Vector2i(0, bob))
		if bob < 0:
			out.blend_rect(sheet.image, Rect2i(pose.position.x, legs - 1, f, 1), Vector2i(0, legs - 1 + bob + 1))
		hand.y += bob

	# La main de chaque image générée est celle de son squelette : l'arme la suit sans
	# qu'on dessine une main par-dessus.
	var top := PixelCanvas.new(f, f)
	var s := -1.0 if dir == "up" else 1.0
	_weapon(top, cfg, hand, Vector2(placed["weapon_dir"]) * Vector2(s, 1.0), 0.0)
	out.blend_rect(top.to_image(cfg["palettes"]), Rect2i(0, 0, f, f), Vector2i.ZERO)
	return out


## Vue de face ou de dos. `faces_camera` ne change que trois choses : le côté du
## bras armé, la présence du visage et la quantité de cheveux.
static func _draw_front(c: PixelCanvas, cfg: Dictionary, placed: Dictionary, faces_camera: bool) -> void:
	var torso_r: float = cfg["torso_r"]
	var sh_w: float = cfg["sh_w"]
	var hip_w: float = cfg["hip_w"]
	var limb_r: float = cfg["limb_r"]
	var arm_r: float = cfg["arm_r"]

	var bob: float = placed["bob"]
	var sw: float = placed["swing"]
	var lean: float = placed["lean"]
	var arm: float = placed["arm"]

	var hip_y: float = float(cfg["hip_y"]) + bob
	var sh_y: float = float(cfg["shoulder_y"]) + bob - lean * 0.5
	var head_y: float = float(cfg["head_y"]) + bob - lean * 1.1

	# De dos, le bras armé passe de l'autre côté de l'écran.
	var s := 1.0 if faces_camera else -1.0

	c.ground_shadow(CX, FEET + 1.5, torso_r + 1.2, 2.2)

	# --- jambes ou robe
	if cfg["robe"]:
		_draw_robe(c, cfg, hip_y, sw)
	else:
		var lift_l := maxf(sw, 0.0) * 1.6
		var lift_r := maxf(-sw, 0.0) * 1.6
		var hip_l := Vector2(CX - hip_w, hip_y)
		var hip_r := Vector2(CX + hip_w, hip_y)
		var foot_l := Vector2(CX - hip_w + sw * 0.9, FEET - lift_l)
		var foot_r := Vector2(CX + hip_w + sw * 0.9, FEET - lift_r)
		c.capsule(hip_l, foot_l, limb_r, R_CLOTH, -0.10)
		c.capsule(hip_r, foot_r, limb_r, R_CLOTH, -0.10)
		c.disc(foot_l, limb_r + 0.2, R_LEATHER)
		c.disc(foot_r, limb_r + 0.2, R_LEATHER)

	# --- bras, posés avant le buste pour qu'il recouvre l'attache de l'épaule
	var arm_swing := -sw * 1.4
	var free_hand := Vector2(CX - s * (sh_w + 0.8), hip_y + 1.0 - arm_swing)
	var weapon_hand := Vector2(CX + s * (sh_w + 0.8), hip_y + 1.0 + arm_swing)
	if arm != 0.0:
		var goal := Vector2(CX + s * (sh_w + 2.2), sh_y - 2.0)
		if arm < 0.0:
			goal = Vector2(CX + s * (sh_w - 0.4), sh_y + 5.0)
		weapon_hand = weapon_hand.lerp(goal, absf(arm))

	c.capsule(Vector2(CX - s * sh_w, sh_y + 0.5), free_hand, arm_r, R_CLOTH, -0.06)
	c.capsule(Vector2(CX + s * sh_w, sh_y + 0.5), weapon_hand, arm_r, R_CLOTH, -0.06)

	# De dos, l'arme est derrière le corps : elle passe avant le buste.
	if not faces_camera:
		_weapon(c, cfg, weapon_hand, Vector2(placed["weapon_dir"]) * Vector2(s, 1.0), -0.18)

	# --- buste
	c.capsule(Vector2(CX, sh_y), Vector2(CX, hip_y), torso_r, R_CLOTH)
	c.capsule(Vector2(CX - torso_r * 0.8, hip_y - 0.5), Vector2(CX + torso_r * 0.8, hip_y - 0.5), 0.9, R_LEATHER)
	if cfg["pauldrons"]:
		c.disc(Vector2(CX - sh_w - 0.3, sh_y - 0.3), 2.1, R_METAL)
		c.disc(Vector2(CX + sh_w + 0.3, sh_y - 0.3), 2.1, R_METAL)
	if cfg["mantle"]:
		# Barre d'épaules assombrie. Sans elle, une robe et une capuche du même
		# tissu fondent en une seule masse : il faut une ligne horizontale pour
		# que l'œil sépare la tête du corps.
		c.capsule(
			Vector2(CX - sh_w - 0.9, sh_y + 1.4), Vector2(CX + sh_w + 0.9, sh_y + 1.4),
			1.9, R_CLOTH, -0.24
		)

	# --- mains, redessinées par dessus le buste sinon elles disparaissent.
	# Plus petites sous une robe : à taille égale, deux taches de peau nue à
	# hauteur de ceinture se lisent comme des objets tenus, pas comme des mains.
	var hand_r := arm_r + (-0.25 if cfg["robe"] else 0.2)
	c.disc(free_hand, hand_r, R_SKIN)
	c.disc(weapon_hand, hand_r, R_SKIN)

	# --- tête
	_draw_head(c, cfg, Vector2(CX, head_y), faces_camera, 0.0)

	if faces_camera:
		_weapon(c, cfg, weapon_hand, Vector2(placed["weapon_dir"]) * Vector2(s, 1.0), 0.0)


## Vue de profil, tournée vers la droite (le flip_h de l'ActorSprite fournit la
## gauche). Les membres arrière sont assombris : c'est le seul indice de
## profondeur dont on dispose sans redessiner.
static func _draw_side(c: PixelCanvas, cfg: Dictionary, placed: Dictionary) -> void:
	var torso_r: float = cfg["torso_r"]
	var limb_r: float = cfg["limb_r"]
	var arm_r: float = cfg["arm_r"]

	var bob: float = placed["bob"]
	var sw: float = placed["swing"]
	var lean: float = placed["lean"]
	var arm: float = placed["arm"]

	var hip_y: float = float(cfg["hip_y"]) + bob
	var sh_y: float = float(cfg["shoulder_y"]) + bob - lean * 0.5
	var head_y: float = float(cfg["head_y"]) + bob - lean * 1.1

	c.ground_shadow(CX, FEET + 1.5, torso_r + 1.0, 2.2)

	# --- membres arrière
	if cfg["robe"]:
		_draw_robe(c, cfg, hip_y, sw)
	else:
		var back_foot := Vector2(CX - 1.2 - sw * 2.6, FEET - maxf(-sw, 0.0) * 1.2)
		c.capsule(Vector2(CX - 0.6, hip_y), back_foot, limb_r, R_CLOTH, -0.22)
		c.disc(back_foot, limb_r + 0.2, R_LEATHER, -0.22)

	var back_hand := Vector2(CX - 1.0 + sw * 2.2, hip_y + 0.8)
	c.capsule(Vector2(CX - 0.4, sh_y + 0.5), back_hand, arm_r, R_CLOTH, -0.24)

	# --- buste, penché vers l'avant pendant le coup
	c.capsule(Vector2(CX + lean * 0.9, sh_y), Vector2(CX, hip_y), torso_r * 0.84, R_CLOTH)
	c.capsule(
		Vector2(CX - torso_r * 0.6, hip_y - 0.5), Vector2(CX + torso_r * 0.6, hip_y - 0.5),
		0.9, R_LEATHER
	)

	# --- jambe avant, après le buste pour qu'elle recouvre la hanche
	if not cfg["robe"]:
		var front_foot := Vector2(CX + 1.2 + sw * 2.6, FEET - maxf(sw, 0.0) * 1.2)
		c.capsule(Vector2(CX + 0.6, hip_y), front_foot, limb_r, R_CLOTH)
		c.disc(front_foot, limb_r + 0.2, R_LEATHER)

	if cfg["pauldrons"]:
		c.disc(Vector2(CX - 0.4, sh_y - 0.4), 2.2, R_METAL, -0.08)
	if cfg["mantle"]:
		c.capsule(
			Vector2(CX - 2.0, sh_y + 1.4), Vector2(CX + 2.2, sh_y + 1.4),
			2.0, R_CLOTH, -0.24
		)

	# --- tête, avancée : de profil, un menton en retrait fait bossu
	_draw_head(c, cfg, Vector2(CX + 0.9 + lean * 1.3, head_y), false, 1.0)

	# --- bras avant et arme
	var front_hand := Vector2(CX + 1.4 - sw * 2.2, hip_y + 0.8)
	if arm != 0.0:
		var goal := Vector2(CX + torso_r + 2.6, sh_y + 0.5)
		if arm < 0.0:
			goal = Vector2(CX - 0.5, sh_y + 4.5)
		front_hand = front_hand.lerp(goal, absf(arm))

	c.capsule(Vector2(CX + 0.4, sh_y + 0.5), front_hand, arm_r, R_CLOTH)
	c.disc(front_hand, arm_r + (-0.25 if cfg["robe"] else 0.2), R_SKIN)
	_weapon(c, cfg, front_hand, placed["weapon_dir"], 0.0)


## profile > 0 ajoute un nez et un œil de côté. Sans le nez, un profil en 32 px
## se lit comme une tête vue de dos et le personnage semble marcher à reculons.
static func _draw_head(c: PixelCanvas, cfg: Dictionary, center: Vector2, face: bool, profile: float) -> void:
	var head_r: float = cfg["head_r"]

	if cfg["hood"]:
		# Capuche pointue, en trois disques qui se resserrent vers le haut. Avec
		# un seul disque la tête finissait plus large que le buste, et toute la
		# silhouette se lisait comme une quille au lieu d'un personnage.
		for i in 3:
			var t := float(i) / 2.0
			c.disc(
				center + Vector2(profile * (-0.4 - t * 1.0), -0.4 - t * 2.6),
				(head_r + 0.7) * (1.0 - t * 0.58),
				R_CLOTH,
				0.06 * t
			)
		if face or profile > 0.0:
			# Creux d'ombre : c'est le vide de la capuche, pas un visage.
			c.disc(center + Vector2(profile * 1.1, 0.9), head_r * 0.70, R_CLOTH, -0.55)
		if face:
			c.dot_px(roundi(center.x) - 2, roundi(center.y) + 1, R_ACCENT, 1.0)
			c.dot_px(roundi(center.x) + 1, roundi(center.y) + 1, R_ACCENT, 1.0)
		elif profile > 0.0:
			c.dot_px(roundi(center.x) + 1, roundi(center.y) + 1, R_ACCENT, 1.0)
		return

	c.disc(center, head_r, R_SKIN)
	# Calotte de cheveux : un disque décalé vers le haut suffit, la partie qui
	# dépasse fait la frange.
	c.disc(center + Vector2(profile * -0.5, -1.2), head_r * 0.95, R_LEATHER)
	c.disc(center + Vector2(profile * 0.6, 0.7), head_r * 0.85, R_SKIN)

	# Un œil d'un pixel, à mi-hauteur de la tête. Deux pixels par œil ont été
	# essayés pour la tête grossie du jalon 24 : ça donne un bandeau sombre, le
	# visage se lit renfrogné et non caricatural. Rejeté sur planche.
	if profile > 0.0:
		c.disc(center + Vector2(head_r * 0.80, 0.6), 0.9, R_SKIN)   # nez
		c.dot_px(roundi(center.x) + 1, roundi(center.y), int(cfg["eye_ramp"]), cfg["eye_level"])
	elif face:
		c.dot_px(roundi(center.x) - 2, roundi(center.y), int(cfg["eye_ramp"]), cfg["eye_level"])
		c.dot_px(roundi(center.x) + 1, roundi(center.y), int(cfg["eye_ramp"]), cfg["eye_level"])


## Trois disques d'un rayon croissant : une capsule ne sait pas s'évaser, et une
## robe qui ne s'évase pas ressemble à un sac de couchage.
static func _draw_robe(c: PixelCanvas, cfg: Dictionary, hip_y: float, sw: float) -> void:
	var hip_w: float = cfg["hip_w"]
	var torso_r: float = cfg["torso_r"]
	for i in 3:
		var t := float(i) / 2.0
		c.disc(
			Vector2(CX + sw * 0.7 * t, lerpf(hip_y, FEET - 0.5, t)),
			lerpf(hip_w + 0.4, torso_r + 1.5, t),
			R_CLOTH,
			-0.10 * t
		)


static func _weapon(c: PixelCanvas, cfg: Dictionary, hand: Vector2, dir: Vector2, bias: float) -> void:
	var d := dir.normalized()
	var perp := d.orthogonal()

	match cfg["weapon"]:
		"sword":
			c.capsule(hand + d * 1.6, hand + d * 11.0, 1.1, R_METAL, bias)
			var guard := hand + d * 2.6
			c.capsule(guard - perp * 2.2, guard + perp * 2.2, 0.9, R_ACCENT, bias)
			c.capsule(hand - d * 1.6, hand + d * 2.0, 1.2, R_LEATHER, bias)

		"cleaver":
			var base := hand + d * 3.0
			c.capsule(hand - d * 1.4, base, 1.2, R_LEATHER, bias)
			c.capsule(base + perp * 0.4, base + d * 5.5 + perp * 2.2, 2.0, R_METAL, bias)

		"club":
			var head := hand + d * 4.0
			c.capsule(hand - d * 1.4, head, 1.3, R_LEATHER, bias)
			c.capsule(head, head + d * 4.5, 2.7, R_LEATHER, bias + 0.08)

		"dagger":
			# Une épée en plus court et plus fin, garde comprise : c'est le
			# rapport lame / poignée qui la distingue, pas un détail.
			c.capsule(hand + d * 1.4, hand + d * 6.4, 0.9, R_METAL, bias)
			var cruising := hand + d * 2.0
			c.capsule(cruising - perp * 1.5, cruising + perp * 1.5, 0.8, R_ACCENT, bias)
			c.capsule(hand - d * 1.4, hand + d * 1.6, 1.0, R_LEATHER, bias)

		"mace":
			# Manche long, tête courte et large, et deux ailettes en travers :
			# sans elles la tête se lit comme le cristal d'un bâton.
			var head := hand + d * 6.0
			c.capsule(hand - d * 1.6, head, 1.0, R_LEATHER, bias)
			c.capsule(head, head + d * 3.4, 2.5, R_METAL, bias)
			c.capsule(
				head + d * 1.7 - perp * 3.0, head + d * 1.7 + perp * 3.0, 0.9, R_METAL, bias + 0.12
			)

		"wand":
			# Un bâton court. Le cristal reste au niveau maximal, comme celui du
			# staff : c'est une source de lumière, elle ne s'assombrit pas avec
			# le manche.
			c.capsule(hand - d * 1.8, hand + d * 5.2, 1.0, R_LEATHER, bias)
			# La poignée d'étoffe. Elle a été ajoutée pour l'icône : le manche
			# est mince et le cristal, qui occupe presque toute la silhouette,
			# garde l'or constant d'un palier à l'autre — les trois baguettes de
			# la lignée se ressemblaient donc trait pour trait. L'étoffe, elle,
			# change avec le palier, et elle éloigne au passage la baguette de
			# la dague, qui a la même longueur.
			c.capsule(hand - d * 1.4, hand + d * 1.4, 1.4, R_CLOTH, bias)
			c.disc(hand + d * 5.8, 1.5, R_ACCENT, 1.0)

		"staff":
			c.capsule(hand - d * 3.0, hand + d * 9.0, 1.2, R_LEATHER, bias)
			# Cristal forcé au niveau maximal : c'est une source de lumière. Collé
			# au bout du bâton — un pixel de trop et il flotte dans le vide.
			c.disc(hand + d * 9.6, 2.0, R_ACCENT, 1.0)


## Le mannequin n'a pas de squelette : un poteau, un sac, une cible peinte.
## Il ne marche pas — son unique animation est un léger balancement.
static func _draw_dummy(c: PixelCanvas, _cfg: Dictionary, placed: Dictionary) -> void:
	var sway: float = float(placed["bob"]) * 0.6

	c.ground_shadow(CX, FEET + 1.5, 5.5, 2.4)

	c.capsule(Vector2(CX, FEET), Vector2(CX + sway, 15.0), 1.7, R_LEATHER)
	c.capsule(Vector2(CX - 6.5 + sway, 13.0), Vector2(CX + 6.5 + sway, 13.0), 1.5, R_LEATHER)
	c.capsule(Vector2(CX + sway, 11.0), Vector2(CX + sway, 17.0), 5.4, R_CLOTH)
	c.capsule(
		Vector2(CX - 4.6 + sway, 15.5), Vector2(CX + 4.6 + sway, 15.5), 1.0, R_LEATHER, -0.10
	)
	c.disc(Vector2(CX + sway, 6.5), 3.4, R_CLOTH)
	c.capsule(Vector2(CX - 3.4 + sway, 9.6), Vector2(CX + 3.4 + sway, 9.6), 0.9, R_LEATHER)

	# Cible peinte : c'est elle qui dit « frappe ici », pas la forme du sac.
	c.disc(Vector2(CX + sway, 13.5), 2.6, R_ACCENT, 0.15)
	c.disc(Vector2(CX + sway, 13.5), 1.2, R_ACCENT, -0.35)
