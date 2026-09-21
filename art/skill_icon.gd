class_name SkillIcon

## L'icône d'une compétence, ramenée à la grille du jeu.
##
## Elle prend l'image fournie avec la compétence — une illustration générée, une
## planche découpée, n'importe quoi — et la ramène à un cadre de vingt-quatre pixels,
## comme les icônes d'objets de la forge. Elle la **pose** aussi (`draw_into`), parce
## que trois panneaux montrent la même marque et que la règle du facteur entier et du
## disque de repli n'a qu'un endroit.
##
## Une classe à part et non une méthode de `Skill` : une compétence est une
## fiche, elle ne connaît ni les textures ni les tailles d'écran. C'est la même
## séparation qu'entre `ItemBase` et `SpriteForge`.

## Le cadre de `SpriteForge.ICON`, **et non un 24 recopié** : une icône de sort et
## une icône d'objet se croisent à l'écran, et deux grilles différentes se
## verraient tout de suite.
const SIDE := SpriteForge.ICON

static var _cache := {}


## L'icône prête à dessiner, ou **null** quand la compétence n'en fournit pas.
##
## Le null n'est pas une erreur : c'est l'état de toutes les compétences tant
## qu'aucune image n'a été produite, et l'appelant retombe alors sur le disque de
## couleur. Une icône manquante ne doit pas laisser une case vide.
static func texture(skill: Skill) -> Texture2D:
	if skill == null:
		return null
	return from_value(skill.id, skill.icon)


## La même, pour une fiche qui n'est pas une compétence — un passif de manuel.
## L'identifiant sert de clé de cache, et c'est pourquoi il est demandé plutôt
## que déduit : deux images rangées sous le même nom se marcheraient dessus.
static func from_value(identifier: String, image: Texture2D) -> Texture2D:
	if image == null:
		return null
	if _cache.has(identifier):
		return _cache[identifier]

	var img := image.get_image()
	if img == null or img.is_empty():
		return null
	img = img.duplicate()
	# La ressource du disque n'est jamais modifiée (invariant 2) : on redimensionne
	# une copie, sinon la première case dessinée écrirait dans le `.tres`.
	img.convert(Image.FORMAT_RGBA8)
	_adjust(img)

	var tex := ImageTexture.create_from_image(img)
	_cache[identifier] = tex
	return tex


## Ramène l'image dans le cadre. **Au plus proche voisin**, toujours : une
## interpolation lisse sur du pixel art rend une bouillie grise, et c'est
## exactement ce qui arrive quand on réduit une illustration sans y penser.
##
## Une image déjà plus petite que le cadre est **laissée telle quelle** plutôt
## qu'agrandie : c'est la case qui l'agrandira, d'un facteur entier, au moment du
## dessin. L'agrandir ici figerait un facteur qui ne vaut que pour une taille de
## case, et la barre et la page de manuel n'ont pas la même.
static func _adjust(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	if w <= SIDE and h <= SIDE:
		return
	var reduction := minf(float(SIDE) / float(w), float(SIDE) / float(h))
	img.resize(
		maxi(int(round(float(w) * reduction)), 1),
		maxi(int(round(float(h) * reduction)), 1),
		Image.INTERPOLATE_NEAREST
	)


## Le facteur d'agrandissement pour tenir dans un carré de `side`, **entier** :
## un facteur fractionnaire double certaines lignes de pixels et pas d'autres, et
## la trame de l'icône se met à onduler. C'est la règle de `inventory_icon`.
static func factor(tex: Texture2D, side: float) -> int:
	if tex == null:
		return 1
	var size_value := tex.get_size()
	var biggest := maxf(size_value.x, size_value.y)
	if biggest <= 0.0:
		return 1
	return maxi(int(floor(side / biggest)), 1)


## Pose l'icône au centre de ce cadre, agrandie d'un **facteur entier** — ou, dans un
## cadre plus petit qu'elle, réduite d'un **diviseur entier** (une ligne sur deux, pas
## une sur trois ici et deux là) ; à défaut d'image, le disque de la couleur de la nature.
static func draw_into(canvas: CanvasItem, r: Rect2, skill: Skill) -> void:
	var side := minf(r.size.x, r.size.y)
	var tex := texture(skill)
	if tex == null:
		canvas.draw_circle(r.get_center(), side * 0.30, DamageType.COLORS[skill.nature])
		return
	var biggest := maxf(tex.get_width(), tex.get_height())
	var scale := float(factor(tex, side)) if biggest <= side else 1.0 / ceilf(biggest / side)
	var span := tex.get_size() * scale
	canvas.draw_texture_rect(tex, Rect2(r.position + (r.size - span) * 0.5, span), false)


## Vide le cache. Pour les tests, qui fabriquent des icônes de toutes pièces et
## réemploient les mêmes identifiants d'une méthode à l'autre.
static func forget() -> void:
	_cache.clear()
