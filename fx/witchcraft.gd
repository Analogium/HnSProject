class_name Witchcraft
extends RefCounted

## La matière de la sorcière (jalon 41). Le sceau de la Catalyse, « cercle d'alchimie »
## choisi sur planche : un anneau pâle, un triangle inscrit qui tourne, un grain de chaque
## élément à ses sommets, un cœur qui grossit. Son rayon est une statistique : fabriqué
## au rayon du lancer, quatre temps, et gardé.

const STEPS := 4
## Le rayon du cercle au premier temps, en part du rayon du lancer : il s'ouvre jusqu'au bord.
const OPENING := 0.75
## Ce que tourne le triangle d'un temps à l'autre, en radians.
const TURN := 0.35
## L'anneau et le cœur, pâles : au-dessus du seuil de glow sans être le blanc d'un élément.
const PALE := Color(0.95, 0.92, 1.0)
const R_PALE := 3

static var _sigils := {}


## Ce temps du sceau à ce rayon, centré. **Fabriqué à sa première demande**, un temps par
## image : 1,2 ms chacun au rayon 36, dont 0,8 de `to_image()` — d'un bloc, les quatre
## coûtaient 4,9 ms au premier lancer (mesuré au jalon 41).
static func sigil(radius: float, step: int) -> EffectForge.Piece:
	var key := "%d@%d" % [roundi(radius), step]
	if not _sigils.has(key):
		_sigils[key] = _sigil_at(float(roundi(radius)), float(step) / float(STEPS - 1))
	return _sigils[key]


static func _sigil_at(radius: float, t: float) -> EffectForge.Piece:
	var size := int(radius) * 2 + 7
	var canvas := PixelCanvas.new(size, size)
	var mid := Vector2(size, size) * 0.5
	var r := radius * (OPENING + (1.0 - OPENING) * t)
	var n := maxi(int(TAU * r), 12)
	for k in n:
		var p := (mid + Vector2.from_angle(TAU * float(k) / float(n)) * r).round()
		canvas.dot_px(int(p.x), int(p.y), R_PALE, 0.5)
	var corners: Array[Vector2] = []
	for i in 3:
		corners.append(mid + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 3.0 + TURN * t * float(STEPS)) * r)
	for i in 3:
		canvas.line(corners[i], corners[(i + 1) % 3], R_PALE, 0.6)
	for i in 3:
		canvas.disc(corners[i], 2.5, i, 1.0)
	canvas.disc(mid, 2.0 + 3.0 * t, R_PALE, 1.0)
	var img := canvas.to_image([
		ArtPalette.ramp(DamageType.COLORS[DamageType.Kind.FIRE]),
		ArtPalette.ramp(DamageType.COLORS[DamageType.Kind.COLD]),
		ArtPalette.ramp(DamageType.COLORS[DamageType.Kind.LIGHTNING]),
		ArtPalette.ramp(PALE),
	])
	return EffectForge.Piece.new(ImageTexture.create_from_image(img), -mid)
