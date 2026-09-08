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
const ARCHETYPES := ["player", "grunt", "caster", "dummy"]

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

static var _cache: Dictionary = {}


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

	for dir in DIRS:
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
	var canvas := PixelCanvas.new(FRAME, FRAME)
	var pose := _pose(cfg, dir, anim, index)

	if cfg["archetype"] == "dummy":
		_draw_dummy(canvas, cfg, pose)
	elif dir == "side":
		_draw_side(canvas, cfg, pose)
	else:
		_draw_front(canvas, cfg, pose, dir == "down")

	return canvas.to_image(cfg["palettes"])


## Cadre de travail d'une icône d'objet. Plus petit que celui d'un personnage :
## une arme seule n'a pas besoin de la place d'un corps.
const ICON := 24

static var _icons: Dictionary = {}


## L'icône d'un objet posé au sol : dessinée en diagonale, à sa taille native.
## En diagonale parce qu'une arme verticale dans un cadre carré laisse deux
## grandes marges vides et se lit plus petite qu'elle n'est.
static func ground_icon(kind: String, palier := 1) -> Texture2D:
	return _icon(kind, false, Vector2i.ZERO, palier)


## L'icône d'un objet dans le sac. Dressée à la verticale : elle épouse la forme
## des emplacements, presque tous plus hauts que larges.
##
## `target` est la place disponible en pixels d'écran : le dessin y est agrandi
## d'un facteur **entier**, un facteur fractionnaire doublant certaines lignes de
## pixels et pas d'autres.
static func inventory_icon(kind: String, target: Vector2i, palier := 1) -> Texture2D:
	return _icon(kind, true, target, palier)


## Le dessin d'un objet, recadré sur ce qui est réellement peint : une épée, une
## baguette et un plastron ne tombent pas au centre du cadre tout seuls, et un
## sprite recadré est centré par construction.
static func _icon(kind: String, upright: bool, target: Vector2i, palier := 1) -> Texture2D:
	var key := "%s:%d:%dx%d:%d" % [kind, int(upright), target.x, target.y, palier]
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
	var p := clampi(palier, 1, PALIER_METAL.size()) - 1
	var palettes: Array = cfg["palettes"]
	palettes[R_METAL] = ArtPalette.ramp(PALIER_METAL[p])
	palettes[R_LEATHER] = ArtPalette.ramp(PALIER_LEATHER[p])
	palettes[R_CLOTH] = ArtPalette.ramp(PALIER_CLOTH[p])

	if GEAR.has(kind):
		_gear(canvas, kind, ICON * 0.5, 2.0)
	elif upright:
		_weapon(canvas, cfg, Vector2(ICON * 0.5, 20.0), Vector2(0.0, -1.0), 0.0)
	else:
		_weapon(canvas, cfg, Vector2(6.0, 17.5), Vector2(0.72, -0.69), 0.0)

	var img := canvas.to_image(cfg["palettes"]).get_region(canvas.painted_rect())
	if target.x > 0 and target.y > 0:
		var fit := minf(
			float(target.x) / float(img.get_width()), float(target.y) / float(img.get_height())
		)
		# Agrandir : facteur entier. Réduire : facteur exact — c'est moins beau,
		# mais une icône qui dépasse déborde sur les cases voisines et on ne sait
		# plus lire la grille. Le cas ne se présente que si l'encombrement déclaré
		# dans le .tres est plus petit que le dessin.
		var factor := floorf(fit) if fit >= 1.0 else fit
		if not is_equal_approx(factor, 1.0):
			img.resize(
				maxi(int(img.get_width() * factor), 1),
				maxi(int(img.get_height() * factor), 1),
				Image.INTERPOLATE_NEAREST
			)

	var tex := ImageTexture.create_from_image(img)
	_icons[key] = tex
	return tex


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
]

## Ce qui distingue trois paliers d'une même lignée dans le sac.
##
## Le nom ne suffit pas — on ne lit pas le nom d'un objet au sol — et redessiner
## trois silhouettes par lignée serait un jalon à soi seul. Restent les couleurs :
## un métal plus clair, un cuir plus riche et une étoffe plus franche à chaque
## palier, ce qui se lit à la taille d'une case là où un détail de deux pixels se
## perd.
const PALIER_METAL := [
	Color(0.50, 0.51, 0.56), Color(0.72, 0.78, 0.86), Color(0.88, 0.93, 1.00)
]
const PALIER_LEATHER := [
	Color(0.31, 0.21, 0.14), Color(0.40, 0.26, 0.18), Color(0.58, 0.41, 0.23)
]
const PALIER_CLOTH := [
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

	var cfg := {
		"archetype": archetype,
		"head_r": 3.8, "head_y": 8.0,
		"shoulder_y": 13.0, "hip_y": 19.5,
		"torso_r": 4.2, "sh_w": 3.8, "hip_w": 2.3,
		"limb_r": 1.7, "arm_r": 1.5,
		"hood": false, "robe": false, "pauldrons": false, "mantle": false,
		"weapon": "none",
		"eye_ramp": R_LEATHER, "eye_level": 0.0,
	}

	var base := {}
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

		"grunt":
			base = {
				"cloth": Color(0.42, 0.55, 0.24), "skin": Color(0.58, 0.66, 0.42),
				"accent": Color(0.85, 0.35, 0.20), "metal": Color(0.58, 0.52, 0.44),
				"leather": Color(0.30, 0.24, 0.16),
			}
			# Plus trapu et plus bas que le joueur : la silhouette doit dire
			# « masse qui fonce » avant même qu'il bouge.
			cfg.merge({
				"head_r": 4.0, "head_y": 9.5,
				"shoulder_y": 14.5, "hip_y": 20.5,
				"torso_r": 4.7, "sh_w": 4.2, "hip_w": 2.6,
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
			cfg.merge({
				"head_r": 3.6, "head_y": 7.5,
				"shoulder_y": 13.0, "hip_y": 19.0,
				"torso_r": 3.6, "sh_w": 3.4, "hip_w": 2.2,
				"hood": true, "robe": true, "mantle": true,
			}, true)
			cfg["weapon"] = "staff"

		_:
			base = {
				"cloth": Color(0.78, 0.62, 0.36), "skin": Color(0.80, 0.68, 0.56),
				"accent": Color(0.82, 0.30, 0.24), "metal": Color(0.62, 0.62, 0.66),
				"leather": Color(0.40, 0.28, 0.18),
			}

	# Variation par instance : nuance des étoffes et de la peau, corpulence. Le
	# joueur en est exclu — sa tenue est choisie à la création, et un tirage
	# par-dessus ce choix ferait deux personnages du même numéro de silhouette.
	var amount := 0.0 if archetype == "player" else 1.0
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
# Poses
# --------------------------------------------------------------------------

## Une pose = les quelques scalaires qui suffisent à décaler le squelette.
## swing : phase de marche (-1..1). lean : buste projeté en avant.
## arm : bras armé (négatif = armé en arrière, positif = tendu).
static func _pose(cfg: Dictionary, dir: String, anim: String, index: int) -> Dictionary:
	var pose := {"bob": 0.0, "swing": 0.0, "lean": 0.0, "arm": 0.0}

	match anim:
		"idle":
			pose["bob"] = IDLE_BOB[index % IDLE_BOB.size()]
		"walk":
			pose["swing"] = WALK_SWING[index % WALK_SWING.size()]
			pose["bob"] = WALK_BOB[index % WALK_BOB.size()]
		"attack":
			if index == 0:
				# Armé : on recule pour donner de l'élan à l'image suivante.
				pose["lean"] = -0.7
				pose["arm"] = -1.0
			else:
				pose["lean"] = 1.3
				pose["arm"] = 1.0
				pose["bob"] = -1.0

	pose["weapon_dir"] = _weapon_dir(cfg, dir, anim, index)
	return pose


## Un bâton ne se porte pas comme une épée : tenu en biais il traverse le
## sprite en diagonale et son cristal finit à flotter dans le vide, à côté du
## personnage. Au repos il reste donc quasi vertical, contre le corps, et ne
## bascule vers l'avant qu'au moment du sort.
static func _weapon_dir(cfg: Dictionary, dir: String, anim: String, index: int) -> Vector2:
	var staff: bool = cfg["weapon"] == "staff"

	if anim == "attack":
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

## Vue de face ou de dos. `faces_camera` ne change que trois choses : le côté du
## bras armé, la présence du visage et la quantité de cheveux.
static func _draw_front(c: PixelCanvas, cfg: Dictionary, pose: Dictionary, faces_camera: bool) -> void:
	var torso_r: float = cfg["torso_r"]
	var sh_w: float = cfg["sh_w"]
	var hip_w: float = cfg["hip_w"]
	var limb_r: float = cfg["limb_r"]
	var arm_r: float = cfg["arm_r"]

	var bob: float = pose["bob"]
	var sw: float = pose["swing"]
	var lean: float = pose["lean"]
	var arm: float = pose["arm"]

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
		_weapon(c, cfg, weapon_hand, Vector2(pose["weapon_dir"]) * Vector2(s, 1.0), -0.18)

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
		_weapon(c, cfg, weapon_hand, Vector2(pose["weapon_dir"]) * Vector2(s, 1.0), 0.0)


## Vue de profil, tournée vers la droite (le flip_h de l'ActorSprite fournit la
## gauche). Les membres arrière sont assombris : c'est le seul indice de
## profondeur dont on dispose sans redessiner.
static func _draw_side(c: PixelCanvas, cfg: Dictionary, pose: Dictionary) -> void:
	var torso_r: float = cfg["torso_r"]
	var limb_r: float = cfg["limb_r"]
	var arm_r: float = cfg["arm_r"]

	var bob: float = pose["bob"]
	var sw: float = pose["swing"]
	var lean: float = pose["lean"]
	var arm: float = pose["arm"]

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
	_weapon(c, cfg, front_hand, pose["weapon_dir"], 0.0)


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
			var croisiere := hand + d * 2.0
			c.capsule(croisiere - perp * 1.5, croisiere + perp * 1.5, 0.8, R_ACCENT, bias)
			c.capsule(hand - d * 1.4, hand + d * 1.6, 1.0, R_LEATHER, bias)

		"mace":
			# Manche long, tête courte et large, et deux ailettes en travers :
			# sans elles la tête se lit comme le cristal d'un bâton.
			var tete := hand + d * 6.0
			c.capsule(hand - d * 1.6, tete, 1.0, R_LEATHER, bias)
			c.capsule(tete, tete + d * 3.4, 2.5, R_METAL, bias)
			c.capsule(
				tete + d * 1.7 - perp * 3.0, tete + d * 1.7 + perp * 3.0, 0.9, R_METAL, bias + 0.12
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
static func _draw_dummy(c: PixelCanvas, _cfg: Dictionary, pose: Dictionary) -> void:
	var sway: float = float(pose["bob"]) * 0.6

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
