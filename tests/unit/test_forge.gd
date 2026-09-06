extends GutTest

## La forge, du côté qui a maintenant une règle de jeu à tenir : le joueur
## choisit sa silhouette à la création, donc les quatre doivent se distinguer.
##
## Ce test existe parce qu'une capture d'écran a montré quatre héros identiques
## là où l'écran en promettait quatre différents. Une assertion aurait été moins
## chère à découvrir que l'image.


func _image(variante: int) -> PackedByteArray:
	return SpriteForge.frame_image(
		SpriteForge.config("player", variante), "down", "idle", 0
	).get_data()


func test_les_quatre_silhouettes_du_joueur_se_distinguent() -> void:
	var vues := {}
	for v in SpriteForge.VARIANTS:
		var pixels := _image(v)
		for autre in vues:
			assert_ne(
				pixels, vues[autre],
				"les silhouettes %d et %d sont le même dessin" % [autre, v]
			)
		vues[v] = pixels


## Une silhouette choisie doit rester la même d'une partie à l'autre : c'est ce
## qui fait qu'on reconnaît son personnage dans la liste.
func test_une_silhouette_redonne_toujours_le_meme_dessin() -> void:
	assert_eq(_image(2), _image(2), "deux appels, un seul personnage")


## La tenue change, l'archétype non : un joueur ne doit jamais pouvoir se
## confondre avec un ennemi au milieu d'une mêlée.
func test_les_tenues_couvrent_les_variantes() -> void:
	assert_eq(
		SpriteForge.PLAYER_CLOTHS.size(), SpriteForge.VARIANTS,
		"une tenue par variante, sinon deux silhouettes partagent la même"
	)
	var teintes := {}
	for c in SpriteForge.PLAYER_CLOTHS:
		teintes[c] = true
	assert_eq(teintes.size(), SpriteForge.VARIANTS, "et quatre couleurs distinctes")
