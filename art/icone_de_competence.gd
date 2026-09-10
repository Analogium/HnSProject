class_name IconeDeCompetence

## L'icône d'une compétence, ramenée à la grille du jeu.
##
## Elle ne **dessine** rien : elle prend l'image fournie avec la compétence — une
## illustration générée, une planche découpée, n'importe quoi — et la ramène à un
## cadre de vingt-quatre pixels, comme les icônes d'objets de la forge.
##
## Une classe à part et non une méthode de `Competence` : une compétence est une
## fiche, elle ne connaît ni les textures ni les tailles d'écran. C'est la même
## séparation qu'entre `ItemBase` et `SpriteForge`.

## Le même cadre que `SpriteForge.ICON`, et ce n'est pas une coïncidence : une
## icône de sort et une icône d'objet se croisent à l'écran, et deux grilles
## différentes se verraient tout de suite.
const COTE := 24

static var _cache := {}


## L'icône prête à dessiner, ou **null** quand la compétence n'en fournit pas.
##
## Le null n'est pas une erreur : c'est l'état de toutes les compétences tant
## qu'aucune image n'a été produite, et l'appelant retombe alors sur le disque de
## couleur. Une icône manquante ne doit pas laisser une case vide.
static func texture(competence: Competence) -> Texture2D:
	if competence == null or competence.icone == null:
		return null
	if _cache.has(competence.id):
		return _cache[competence.id]

	var img := competence.icone.get_image()
	if img == null or img.is_empty():
		return null
	img = img.duplicate()
	# La ressource du disque n'est jamais modifiée (invariant 2) : on redimensionne
	# une copie, sinon la première case dessinée écrirait dans le `.tres`.
	img.convert(Image.FORMAT_RGBA8)
	_ajuster(img)

	var tex := ImageTexture.create_from_image(img)
	_cache[competence.id] = tex
	return tex


## Ramène l'image dans le cadre. **Au plus proche voisin**, toujours : une
## interpolation lisse sur du pixel art rend une bouillie grise, et c'est
## exactement ce qui arrive quand on réduit une illustration sans y penser.
##
## Une image déjà plus petite que le cadre est **laissée telle quelle** plutôt
## qu'agrandie : c'est la case qui l'agrandira, d'un facteur entier, au moment du
## dessin. L'agrandir ici figerait un facteur qui ne vaut que pour une taille de
## case, et la barre et la page de manuel n'ont pas la même.
static func _ajuster(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	if w <= COTE and h <= COTE:
		return
	var reduction := minf(float(COTE) / float(w), float(COTE) / float(h))
	img.resize(
		maxi(int(round(float(w) * reduction)), 1),
		maxi(int(round(float(h) * reduction)), 1),
		Image.INTERPOLATE_NEAREST
	)


## Le facteur d'agrandissement pour tenir dans un carré de `cote`, **entier** :
## un facteur fractionnaire double certaines lignes de pixels et pas d'autres, et
## la trame de l'icône se met à onduler. C'est la règle de `inventory_icon`.
static func facteur(tex: Texture2D, cote: float) -> int:
	if tex == null:
		return 1
	var taille := tex.get_size()
	var plus_grand := maxf(taille.x, taille.y)
	if plus_grand <= 0.0:
		return 1
	return maxi(int(floor(cote / plus_grand)), 1)


## Vide le cache. Pour les tests, qui fabriquent des icônes de toutes pièces et
## réemploient les mêmes identifiants d'une méthode à l'autre.
static func oublier() -> void:
	_cache.clear()
