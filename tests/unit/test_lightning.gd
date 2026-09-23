extends GutTest

## La foudre dessinée. Ses promesses : **seul le filament brille** — le violet
## plafonne à 0,63 de luminance —, un saut n'a qu'une silhouette, et ce qui est de
## taille fixe (le projectile, la charge) ne se fabrique qu'une fois.

const VIOLET := Color(0.72, 0.56, 1.00)
const THRESHOLD := 0.9


func test_the_strike_grid_is_rectangular() -> void:
	assert_eq(EffectForge.STRIKE.size(), EffectForge.STRIKE_SIZE, "hauteur de l'éclat")
	for row: String in EffectForge.STRIKE:
		assert_eq(row.length(), EffectForge.STRIKE_SIZE, "largeur de « %s »" % row)


## Le filament d'un pixel ne saute aucun pixel en biais : une capsule de rayon 0,5
## le cassait en pointillés.
func test_a_line_has_no_gap() -> void:
	var canvas := PixelCanvas.new(12, 12)
	canvas.line(Vector2(1, 1), Vector2(10, 5), 0, 1.0)
	var image := canvas.to_image([ArtPalette.ramp(VIOLET)])
	var lit := 0
	for x in range(1, 11):
		var column := 0
		for y in 12:
			# L'encre est claire, le contour sombre.
			if image.get_pixel(x, y).get_luminance() > 0.4:
				column += 1
		assert_gt(column, 0, "la colonne %d porte le trait" % x)
		lit += column
	assert_eq(lit, 10, "un pixel par colonne quand le trait est plus large que haut")


## C'est le filament qui passe le seuil de glow, et lui seul : un éclair dont tout
## brille est une ampoule, un éclair dont rien ne brille n'est plus de la foudre.
func test_only_the_filament_glows() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var pieces := Lightning.chain(PackedVector2Array([Vector2.ZERO, Vector2(80, 30)]), rng, VIOLET, 0, false)
	var image: Image = pieces[0].texture.get_image()
	var lit := 0
	var matter := 0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a < 0.5:
				continue
			matter += 1
			if c.get_luminance() > THRESHOLD:
				lit += 1
	assert_gt(VIOLET.get_luminance(), 0.6, "le violet part assez clair")
	assert_lt(VIOLET.get_luminance(), THRESHOLD, "mais sous le seuil")
	assert_gt(lit, 0, "le filament déborde")
	assert_lt(float(lit) / float(matter), 0.5, "mais il reste un filament")


## Une planche par saut : d'une pièce, une chaîne en zigzag balayait le vide entre
## ses sauts.
func test_a_chain_is_one_piece_per_jump() -> void:
	var rng := RandomNumberGenerator.new()
	var points := PackedVector2Array([Vector2.ZERO, Vector2(60, -30), Vector2(120, 20), Vector2(180, -10)])
	assert_eq(Lightning.chain(points, rng, VIOLET).size(), 3, "trois sauts, trois planches")


func test_the_same_dart_is_made_once() -> void:
	var a := Lightning.dart(VIOLET, 5, 2)
	var b := Lightning.dart(VIOLET, 5, 2 + Lightning.DART_FORMS)
	assert_same(a, b, "deux demandes, une fabrication")


## Six formes d'un sixième d'écart chacune : la septième est la première, sinon la
## charge sauterait d'un cran à chaque tour.
func test_the_charge_loops_on_its_forms() -> void:
	var a := Lightning.charge(VIOLET, 7.0, 1, 0.0)
	assert_same(a, Lightning.charge(VIOLET, 7.0, 1 + Lightning.CHARGE_FORMS, 0.0), "la boucle retombe")
	assert_ne(a, Lightning.charge(VIOLET, 7.0, 2, 0.0), "deux formes voisines diffèrent")


## Entier, puis défait sur son dernier tiers : un éclair ne pâlit pas.
func test_a_bolt_comes_apart_on_its_last_third() -> void:
	assert_eq(Lightning.gone(0.5, 1.0), 0.0, "entier à mi-vie")
	assert_eq(Lightning.gone(0.7, 1.0), Lightning.GONE, "défait sur la fin")
