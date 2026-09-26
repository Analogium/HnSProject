class_name Comet
extends RefCounted

## Le tir du Projectile élémentaire, choisi sur planche (jalon 28) : une tête ronde à
## cœur blanc et une queue effilée, **la même pour les trois éléments** — seule la
## teinte change. Il part dans n'importe quelle direction : fabriqué au cap le plus
## proche (`Slash.TURNS`), une fois par teinte, cap et forme, et gardé.

const HEAD := 2.6
const CORE := 1.3
const LENGTH := 13.0
## Le cœur, poussé vers le blanc : au-dessus du seuil de glow dans les trois teintes.
const CORE_MIX := 0.7
## Deux formes, qui ne diffèrent que par le grain détaché au bout de la queue : sans
## lui le tir glisse comme un autocollant.
const FORMS := 2
const HZ := 14.0

static var _pieces := {}


static func piece(tint: Color, turn: int, form: int) -> EffectForge.Piece:
	var key := "%s|%d|%d" % [tint.to_html(false), turn, posmod(form, FORMS)]
	if _pieces.has(key):
		return _pieces[key]
	var dir := Vector2.from_angle(Slash.angle_of(turn))
	var span := int(LENGTH) + 6
	var canvas := PixelCanvas.new(span * 2 + 1, span * 2 + 1)
	var mid := Vector2(span, span)
	for y in span * 2 + 1:
		for x in span * 2 + 1:
			var p := Vector2(x, y) - mid
			var from_head := p.length()
			if from_head <= HEAD:
				if from_head < CORE:
					canvas.dot_px(x, y, 1, 1.0)
				else:
					canvas.dot_px(x, y, 0, 0.85)
				continue
			var along := -p.dot(dir)
			if along < 0.0 or along > LENGTH:
				continue
			var k := along / LENGTH
			if absf(p.cross(dir)) <= HEAD * pow(1.0 - k, 0.8):
				canvas.dot_px(x, y, 0, 0.85 - 0.55 * k)
	var grain := (mid - dir * (LENGTH + 3.0 + 2.0 * float(posmod(form, FORMS)))).round()
	canvas.dot_px(int(grain.x), int(grain.y), 0, 0.6)
	var img := canvas.to_image([ArtPalette.ramp(tint), ArtPalette.ramp(tint.lerp(Color.WHITE, CORE_MIX))])
	var made := EffectForge.Piece.new(ImageTexture.create_from_image(img), -mid)
	_pieces[key] = made
	return made
