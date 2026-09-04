class_name PixelCanvas
extends RefCounted

## Le rastériseur de la forge : on empile des capsules, on en déduit un volume
## éclairé, puis on cerne le tout d'un contour. C'est la seule couche qui touche
## réellement des pixels — tous les générateurs d'assets passent par elle.
##
## Pourquoi une capsule (segment + rayon) et rien d'autre : un personnage vu de
## dessus se résume à une dizaine de membres, et la capsule couvre le disque
## (tête), le cylindre (bras, jambe, arme) et l'ovale (buste) selon la longueur
## du segment. Une seule primitive à écrire, une seule à éclairer, et l'union de
## capsules donne naturellement des silhouettes rondes et lisibles en 32 px.
##
## On ne stocke pas des couleurs mais un couple (rampe, niveau d'éclairage).
## La couleur n'est décidée qu'à to_image() : le même dessin peut donc ressortir
## dans n'importe quelle palette, ce qui rend les variantes gratuites.

## Direction d'où vient la lumière, en coordonnées écran (y vers le bas) : en
## haut à gauche. Fixe pour tout le jeu, sinon les sprites ne s'accordent pas.
const LIGHT := Vector2(-0.5524, -0.8337)

const EMPTY := -1

var width: int
var height: int

var _ramp: PackedInt32Array
var _level: PackedFloat32Array
## [cx, cy, rx, ry, alpha] — peintes sous le sprite, elles ne participent ni à
## l'éclairage ni au contour.
var _shadows: Array = []

## Rectangle réellement peint. Un personnage n'occupe qu'une moitié de son
## image ; sans ce suivi, to_image balaierait les 1024 pixels du cadre pour en
## colorer 400.
var _x0 := 0
var _y0 := 0
var _x1 := -1
var _y1 := -1


func _init(p_width: int, p_height: int) -> void:
	width = p_width
	height = p_height
	_ramp.resize(width * height)
	_ramp.fill(EMPTY)
	_level.resize(width * height)


## bias décale l'éclairage de la forme entière : négatif pour un membre en
## arrière-plan, +1.0 pour forcer le blanc d'un point lumineux.
func capsule(a: Vector2, b: Vector2, radius: float, ramp: int, bias := 0.0) -> void:
	if radius <= 0.0:
		return

	var x0 := maxi(int(floor(minf(a.x, b.x) - radius)), 0)
	var x1 := mini(int(ceil(maxf(a.x, b.x) + radius)), width - 1)
	var y0 := maxi(int(floor(minf(a.y, b.y) - radius)), 0)
	var y1 := mini(int(ceil(maxf(a.y, b.y) + radius)), height - 1)
	if x1 < x0 or y1 < y0:
		return
	# Élargi une fois par capsule et non par pixel : un appel de fonction par
	# pixel coûtait plus cher que la boucle qu'il fait économiser. Le rectangle
	# est donc celui de la boîte englobante, légèrement plus large que la forme.
	_touch(x0, y0)
	_touch(x1, y1)

	# Boucle écrite en scalaires plutôt qu'en Vector2 : c'est le seul endroit du
	# projet où ça se justifie, mais il tourne quelques milliers de fois par
	# image et des centaines de milliers de fois par lancement.
	var ax := a.x
	var ay := a.y
	var abx := b.x - a.x
	var aby := b.y - a.y
	var len_sq := abx * abx + aby * aby
	var r2 := radius * radius
	var inv_r := 1.0 / radius

	for y in range(y0, y1 + 1):
		var dy0 := float(y) - ay
		for x in range(x0, x1 + 1):
			var dx0 := float(x) - ax

			# Projection du pixel sur le segment, bornée à ses extrémités.
			var t := 0.0
			if len_sq > 0.0001:
				t = clampf((dx0 * abx + dy0 * aby) / len_sq, 0.0, 1.0)

			# Vecteur du segment vers le pixel : c'est la normale de la surface,
			# non normalisée — sa longueur est la distance à l'axe.
			var nx := dx0 - abx * t
			var ny := dy0 - aby * t
			var d2 := nx * nx + ny * ny
			if d2 > r2:
				continue

			# Le centre du volume reste en demi-teinte et les bords partent vers
			# la lumière ou vers l'ombre : c'est ce qui donne le relief rond.
			# L'éclairage voulu est (n/|n|) · L, atténué par |n|/rayon vers le
			# centre — les deux |n| s'annulent, donc ni normalisation ni racine
			# carrée. Un bord franc, sans cette atténuation, se lirait comme un
			# aplat découpé au lieu d'un volume.
			var lvl := 0.55 + 0.45 * (nx * LIGHT.x + ny * LIGHT.y) * inv_r

			var i := y * width + x
			_ramp[i] = ramp
			_level[i] = clampf(lvl + bias, 0.0, 1.0)


func disc(center: Vector2, radius: float, ramp: int, bias := 0.0) -> void:
	capsule(center, center, radius, ramp, bias)


## Pixel posé à la main, pour les détails qu'aucune forme ne donne : un œil,
## une boucle de ceinture, une étincelle.
func dot_px(x: int, y: int, ramp: int, level: float) -> void:
	if x < 0 or y < 0 or x >= width or y >= height:
		return
	var i := y * width + x
	_ramp[i] = ramp
	_level[i] = clampf(level, 0.0, 1.0)
	_touch(x, y)


## Ombre portée au sol. Indispensable en vue de dessus : sans elle, on ne sait
## pas si un personnage est posé ou s'il flotte, et la profondeur disparaît.
func ground_shadow(cx: float, cy: float, rx: float, ry: float, alpha := 0.30) -> void:
	_shadows.append([cx, cy, rx, ry, alpha])


func _touch(x: int, y: int) -> void:
	if _x1 < _x0:
		_x0 = x
		_x1 = x
		_y0 = y
		_y1 = y
		return
	_x0 = mini(_x0, x)
	_x1 = maxi(_x1, x)
	_y0 = mini(_y0, y)
	_y1 = maxi(_y1, y)


func is_empty() -> bool:
	return _x1 < _x0


## Le rectangle réellement peint, contour compris. Sert à recadrer un dessin qui
## ne remplit pas son cadre — une icône d'objet, par exemple, dont la forme
## dépend de l'arme et ne tombe jamais au centre toute seule.
func painted_rect() -> Rect2i:
	if is_empty():
		return Rect2i()
	# +1 de marge : le contour se pose sur les pixels vides qui touchent la
	# silhouette, donc juste à l'extérieur du rectangle suivi.
	return Rect2i(_x0, _y0, _x1 - _x0 + 1, _y1 - _y0 + 1).grow(1).intersection(
		Rect2i(0, 0, width, height)
	)


## Une seule passe sur les pixels, et une seule écriture par pixel.
##
## Ce qui coûte en GDScript, ce n'est pas le calcul mais le nombre d'accès
## indexés. Mesuré sur une image de personnage : tampon d'octets écrit canal
## par canal 238 µs, couleur pré-empaquetée en entier 32 bits et passe de
## contour fondue dans la même boucle 176 µs, balayage borné au rectangle
## réellement peint 100 µs. Sur la forge entière, 0,65 ms par image au départ
## contre 0,265 ms — 56 ms au lancement d'une zone au lieu de 136.
##
## La passe de contour est fondue dans la même boucle : un pixel vide qui touche
## de la matière prend la couleur de contour de sa voisine.
func to_image(palettes: Array) -> Image:
	var data := PackedByteArray()
	data.resize(width * height * 4)

	var lut := _build_lut(palettes)
	var levels: int = ArtPalette.LEVELS
	var last := levels - 1

	# Avant la boucle : les pixels vides ne sont jamais réécrits, donc l'ombre
	# qu'ils portent survit.
	for s in _shadows:
		_paint_shadow(data, s)

	# +1 de marge : le contour se pose sur les pixels vides qui touchent le bord
	# de la silhouette, donc juste à l'extérieur du rectangle peint.
	for y in range(maxi(_y0 - 1, 0), mini(_y1 + 2, height)):
		for x in range(maxi(_x0 - 1, 0), mini(_x1 + 2, width)):
			var i := y * width + x
			var r: int = _ramp[i]

			if r != EMPTY:
				var step := clampi(int(round(_level[i] * last)), 0, last)
				data.encode_u32(i * 4, lut[r * (levels + 1) + step])
				continue

			# Contour a posteriori plutôt que dessiné : on cerne la silhouette
			# finale, pas chaque membre. Un contour par membre transformerait le
			# personnage en tas de saucisses cernées — l'erreur classique du
			# sprite généré.
			var n := EMPTY
			if x + 1 < width and _ramp[i + 1] != EMPTY:
				n = _ramp[i + 1]
			elif x > 0 and _ramp[i - 1] != EMPTY:
				n = _ramp[i - 1]
			elif y + 1 < height and _ramp[i + width] != EMPTY:
				n = _ramp[i + width]
			elif y > 0 and _ramp[i - width] != EMPTY:
				n = _ramp[i - width]

			if n != EMPTY:
				data.encode_u32(i * 4, lut[n * (levels + 1) + levels])

	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)


## Chaque rampe occupe LEVELS + 1 entrées : ses niveaux, puis sa couleur de
## contour en dernière position. Les couleurs sont empaquetées en RGBA petit
## boutiste, l'ordre attendu par Image.FORMAT_RGBA8.
func _build_lut(palettes: Array) -> PackedInt32Array:
	var levels: int = ArtPalette.LEVELS
	var lut := PackedInt32Array()

	for p in palettes:
		var ramp: PackedColorArray = p
		for step in levels:
			lut.append(_pack(ramp[mini(step, ramp.size() - 1)]))
		lut.append(_pack(ArtPalette.outline_of(ramp)))
	return lut


static func _pack(c: Color) -> int:
	return (
		int(clampf(c.r, 0.0, 1.0) * 255.0)
		| (int(clampf(c.g, 0.0, 1.0) * 255.0) << 8)
		| (int(clampf(c.b, 0.0, 1.0) * 255.0) << 16)
		| (int(clampf(c.a, 0.0, 1.0) * 255.0) << 24)
	)


func _paint_shadow(data: PackedByteArray, s: Array) -> void:
	var cx: float = s[0]
	var cy: float = s[1]
	var rx: float = s[2]
	var ry: float = s[3]
	var alpha := int(clampf(s[4], 0.0, 1.0) * 255.0)

	for y in range(maxi(int(cy - ry), 0), mini(int(cy + ry) + 1, height)):
		for x in range(maxi(int(cx - rx), 0), mini(int(cx + rx) + 1, width)):
			var dx := (float(x) - cx) / rx
			var dy := (float(y) - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				data[(y * width + x) * 4 + 3] = alpha
