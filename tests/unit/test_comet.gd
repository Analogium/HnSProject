extends GutTest

## Le tir du Projectile élémentaire, fabriqué au cap (jalon 28) : une forme par teinte,
## cap et forme, jamais deux ; un cœur qui passe le seuil de glow dans les trois
## éléments ; et une tête qui reste à l'ancre quel que soit le cap.

const ELEMENTS := [DamageType.Kind.FIRE, DamageType.Kind.COLD, DamageType.Kind.LIGHTNING]


func test_the_same_comet_is_made_once() -> void:
	var tint: Color = DamageType.COLORS[DamageType.Kind.FIRE]
	assert_same(Comet.piece(tint, 5, 0), Comet.piece(tint, 5, 0), "deux demandes, une fabrication")
	assert_same(Comet.piece(tint, 5, 0), Comet.piece(tint, 5, Comet.FORMS), "les formes bouclent")
	assert_ne(Comet.piece(tint, 5, 0), Comet.piece(tint, 6, 0), "un autre cap, une autre forme")


## Le seuil de glow est à 0,9 de luminance : sans un cœur au-dessus, la comète ne
## brille pas, et le froid, déjà clair, se lirait comme le seul élément lumineux.
func test_the_core_glows_in_each_element() -> void:
	for kind: int in ELEMENTS:
		var piece := Comet.piece(DamageType.COLORS[kind], 0, 0)
		var img := piece.texture.get_image()
		var head := Vector2i(-piece.offset)
		assert_gt(img.get_pixelv(head).get_luminance(), 0.9, "le cœur de « %s »" % DamageType.NAMES[kind])


## La tête reste sur l'ancre : c'est elle que la collision porte, la queue suit.
func test_the_head_stays_on_the_anchor_whatever_the_heading() -> void:
	for turn in Slash.TURNS:
		var piece := Comet.piece(DamageType.COLORS[DamageType.Kind.COLD], turn, 0)
		var img := piece.texture.get_image()
		assert_gt(img.get_pixelv(Vector2i(-piece.offset)).a, 0.0, "cap %d" % turn)
