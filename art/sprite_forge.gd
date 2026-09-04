class_name SpriteForge

## La forge de personnages : (archétype, variante) -> SpriteFrames animées.
##
## Aucun fichier image n'existe sur le disque. Au premier appel, les pixels sont
## calculés puis gardés en cache pour toute la session ; la graine étant dérivée
## du nom et du numéro de variante, le même personnage ressort identique à
## chaque lancement du jeu. C'est le même principe que TilesetBuilder, étendu
## aux acteurs.
##
## Un personnage n'est pas un dessin mais un squelette : une dizaine de points
## d'ancrage (hanches, épaules, mains, pieds, tête) reliés par des capsules.
## Animer revient à déplacer ces points, pas à redessiner — c'est ce qui rend
## une marche 4 images aussi bon marché qu'une pose fixe, et ce qui permet
## d'ajouter un archétype en n'écrivant qu'une entrée de configuration.
##
## Pour figer un sprite et le retoucher à la main : la galerie (F4) exporte
## toutes les planches en PNG dans user://forge_export/.

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

## Cycle de marche en 4 temps : contact, passage, contact opposé, passage.
## Le rebond d'une image sur deux (le corps monte au passage) fait davantage
## pour la lisibilité de la marche que le balancement des jambes.
const WALK_SWING := [1.0, 0.0, -1.0, 0.0]
const WALK_BOB := [0.0, -1.0, 0.0, -1.0]
const IDLE_BOB := [0.0, -1.0]

## Armé, puis frappé. Deux images suffisent — c'est le contraste entre les deux
## qui se lit, pas leur nombre. Constante et non nombre écrit à la main : la
## galerie compose ses planches d'export à partir de la même valeur.
const ATTACK_FRAMES := 2

static var _cache: Dictionary = {}


## Le point d'entrée du jeu. Les SpriteFrames sont partagées entre toutes les
## instances d'une même variante : seul l'état de lecture est propre à chaque
## AnimatedSprite2D, donc rien n'est dupliqué.
static func frames(archetype: String, variant := 0) -> SpriteFrames:
	var key := "%s:%d" % [archetype, variant]
	if _cache.has(key):
		return _cache[key]

	var cfg := config(archetype, variant)
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


## Côté d'une icône d'objet. Plus petit que le cadre d'un personnage : une arme
## seule n'a pas besoin de la place d'un corps.
const ICON := 24

static var _icons: Dictionary = {}


## L'icône d'un objet, dessinée par _weapon — exactement la fonction qui pose
## l'arme dans la main d'un personnage. Une épée au sol et l'épée que tient le
## joueur ne peuvent donc pas se contredire.
static func weapon_icon(kind: String) -> Texture2D:
	if _icons.has(kind):
		return _icons[kind]

	var canvas := PixelCanvas.new(ICON, ICON)
	# La palette du joueur : c'est celle qui donne l'acier clair et l'or de la
	# garde, les deux teintes qui font lire « arme » plutôt que « bâton ».
	var cfg := config("player", 0)
	cfg["weapon"] = kind
	# En diagonale : une arme verticale dans un cadre carré laisse deux grandes
	# marges vides et se lit plus petite qu'elle n'est.
	_weapon(canvas, cfg, Vector2(6.0, 17.5), Vector2(0.72, -0.69), 0.0)

	# Recadrée sur ce qui est réellement peint : une épée et une baguette n'ont
	# ni la même longueur ni le même encombrement, et aucune ne tombe au centre
	# du cadre toute seule. Sans ça l'objet et son halo au sol ne coïncident pas.
	var drawn := canvas.to_image(cfg["palettes"])
	var r := canvas.painted_rect()
	var img := Image.create_empty(ICON, ICON, false, Image.FORMAT_RGBA8)
	if r.size.x > 0 and r.size.y > 0:
		img.blit_rect(drawn, r, Vector2i((ICON - r.size.x) / 2, (ICON - r.size.y) / 2))

	var tex := ImageTexture.create_from_image(img)
	_icons[kind] = tex
	return tex


# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------

## Toute la direction artistique des personnages tient dans cette fonction :
## cinq couleurs, une dizaine de mesures, trois options. Ajouter un archétype,
## c'est ajouter un cas ici — le reste du fichier n'en sait rien.
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
				"cloth": Color(0.24, 0.45, 0.86), "skin": Color(0.92, 0.73, 0.56),
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

	# Variation par instance : nuance des étoffes et de la peau, corpulence.
	# Le joueur reste hors du tirage — son apparence doit être stable.
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

## Vue de face ou de dos. Le paramètre faces_camera ne change que trois choses :
## le côté du bras armé, la présence du visage, et la quantité de cheveux —
## redessiner un sprite de dos entier ne servirait à rien.
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

		"wand":
			# Un bâton court. Le cristal reste au niveau maximal, comme celui du
			# staff : c'est une source de lumière, elle ne s'assombrit pas avec
			# le manche.
			c.capsule(hand - d * 1.8, hand + d * 5.2, 1.0, R_LEATHER, bias)
			c.disc(hand + d * 5.8, 1.5, R_ACCENT, 1.0)

		"staff":
			c.capsule(hand - d * 3.0, hand + d * 9.0, 1.2, R_LEATHER, bias)
			# Cristal forcé au niveau maximal : c'est une source de lumière, elle
			# ne doit pas s'assombrir avec le reste du membre. Collé au bout du
			# bâton — un pixel de trop et il flotte tout seul dans le vide.
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
