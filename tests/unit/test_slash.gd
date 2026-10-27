extends GutTest

## Le coup d'arme fabriqué au cap. Sa promesse : **une forme par cap et par temps,
## jamais deux** — un coup qui fabriquerait à chaque image paierait une
## rastérisation par image, et rien dans le dessin ne le dirait.

const STEEL := Color(1.0, 0.98, 0.85)


func test_a_heading_finds_the_nearest_of_the_turns() -> void:
	var step := TAU / float(Slash.TURNS)
	assert_eq(Slash.turn_of(0.0), 0, "droite")
	assert_eq(Slash.turn_of(step), 1, "le cap suivant")
	assert_eq(Slash.turn_of(-step), Slash.TURNS - 1, "et le précédent, par l'autre bout")
	assert_eq(Slash.turn_of(TAU), 0, "un tour entier revient au départ")


## Un quart de tour ne perd ni n'invente d'encre : le vote tombe juste quand les
## pixels tombent juste — sur une grille de côtés impairs, dont le centre est un pixel
## (l'épée de l'Épée spirale, partie au jalon 54 ; le couteau, 13 × 4, n'en est pas une).
const ODD := ["....g....", "hhhhGdddd", "....g...."]


func test_a_quarter_turn_keeps_every_pixel() -> void:
	assert_eq(_ink(EffectForge.rotated(ODD, PI * 0.5)), _ink(ODD), "autant d'encre avant et après")


## En biais, le vote arrondit : un peu d'encre en plus ou en moins, jamais la
## moitié. Au plus proche voisin, une lame d'un pixel se cassait en pointillés.
func test_a_slanted_turn_keeps_the_blade_whole() -> void:
	var before := float(_ink(EffectForge.KNIFE))
	var after := float(_ink(EffectForge.rotated(EffectForge.KNIFE, PI * 0.25)))
	assert_almost_eq(after / before, 1.0, 0.2, "la lame garde sa matière en biais")


## La dissolution efface la part qu'on lui demande, en damier.
func test_dissolving_half_clears_half() -> void:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	EffectForge.dissolve(img, 0.5)
	var left := 0
	for y in 8:
		for x in 8:
			if img.get_pixel(x, y).a > 0.5:
				left += 1
	assert_eq(left, 32, "la moitié des pixels")


func _ink(grid: Array) -> int:
	var count := 0
	for row: String in grid:
		for ch in row:
			if ch != ".":
				count += 1
	return count
