extends GutTest

## La forge, du côté qui a maintenant une règle de jeu à tenir : le joueur
## choisit sa silhouette à la création, donc les quatre doivent se distinguer.
##
## Ce test existe parce qu'une capture d'écran a montré quatre héros identiques
## là où l'écran en promettait quatre différents. Une assertion aurait été moins
## chère à découvrir que l'image.


func _image(variant_index: int) -> PackedByteArray:
	return SpriteForge.frame_image(
		SpriteForge.config("player", variant_index), "down", "idle", 0
	).get_data()


func test_the_four_player_silhouettes_are_distinguishable() -> void:
	var views := {}
	for v in SpriteForge.VARIANTS:
		var pixels := _image(v)
		for other in views:
			assert_ne(
				pixels, views[other],
				"les silhouettes %d et %d sont le même dessin" % [other, v]
			)
		views[v] = pixels


## Une silhouette choisie doit rester la même d'une partie à l'autre : c'est ce
## qui fait qu'on reconnaît son personnage dans la liste.
func test_a_silhouette_always_gives_the_same_drawing() -> void:
	assert_eq(_image(2), _image(2), "deux appels, un seul personnage")


## La tenue change, l'archétype non : un joueur ne doit jamais pouvoir se
## confondre avec un ennemi au milieu d'une mêlée.
func test_outfits_cover_the_variants() -> void:
	assert_eq(
		SpriteForge.PLAYER_CLOTHS.size(), SpriteForge.VARIANTS,
		"une tenue par variante, sinon deux silhouettes partagent la même"
	)
	var tints := {}
	for c in SpriteForge.PLAYER_CLOTHS:
		tints[c] = true
	assert_eq(tints.size(), SpriteForge.VARIANTS, "et quatre couleurs distinctes")


## L'ombre au sol vit dans le canal alpha du sprite, à 30 % : c'est l'hypothèse
## sur laquelle repose le `step(0.5, tex.a)` de `core/flash.gdshader`, et donc le
## flash, le liseré d'affixe et la teinte d'état. Un changement de cadre ou de
## ligne de pieds peut la casser sans qu'aucun autre test bronche.
func test_a_sprite_carries_its_ground_shadow_in_its_alpha() -> void:
	var img := SpriteForge.frame_image(SpriteForge.config("player", 0), "down", "idle", 0)
	var half_transparent := 0
	var solid := 0
	for y in img.get_height():
		for x in img.get_width():
			var a := img.get_pixel(x, y).a
			if a > 0.0 and a < 0.5:
				half_transparent += 1
			elif a >= 0.5:
				solid += 1
	# Seize pixels sur une image de repos : l'ombre n'affleure qu'autour des pieds,
	# le reste passe sous un corps opaque qui gagne. Les 428 pixels du jalon des
	# assets se comptent sur la **planche** entière, pas sur une image.
	assert_gt(half_transparent, 8, "l'ombre au sol a disparu du canal alpha")
	assert_gt(solid, half_transparent, "le corps doit rester majoritaire sur son ombre")
