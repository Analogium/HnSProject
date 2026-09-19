extends GutTest

## Les trois textures de lumière. Elles n'ont qu'une promesse, mais tout le jalon
## 24 en dépend : un **cœur au-dessus du seuil de glow** (0,9) et un bord éteint.
## Un dégradé qui plafonnerait à 0,8 rendrait tous les effets ternes d'un coup,
## sans qu'aucune assertion de forme ne s'en aperçoive.


func _alpha(tex: Texture2D, u: float, v: float) -> float:
	var img := tex.get_image()
	var x := clampi(roundi(u * float(img.get_width() - 1)), 0, img.get_width() - 1)
	var y := clampi(roundi(v * float(img.get_height() - 1)), 0, img.get_height() - 1)
	return img.get_pixel(x, y).a


func test_the_heart_of_a_blob_passes_the_glow_threshold() -> void:
	assert_gt(_alpha(Glow.blob(), 0.5, 0.5), 0.95, "le centre du cœur doit être plein")
	assert_almost_eq(_alpha(Glow.blob(), 0.0, 0.0), 0.0, 0.01, "et son coin éteint")


## `draw_ring` divise le rayon demandé par `RING_CREST` pour que la crête tombe
## dessus. Deux promesses dans le même test : la crête est bien là, et **rien
## n'est peint au-delà** — un halo qui dépasse annoncerait une portée que le coup
## n'a pas.
func test_the_ring_peaks_where_draw_ring_places_the_bite() -> void:
	var crest := _alpha(Glow.ring(), 0.5 + Glow.RING_CREST * 0.5, 0.5)
	assert_gt(crest, 0.95, "la crête de l'anneau")
	assert_lt(_alpha(Glow.ring(), 0.5, 0.5), 0.05, "et son centre creux")
	assert_almost_eq(_alpha(Glow.ring(), 1.0, 0.5), 0.0, 0.01, "rien au-delà du rayon")


## La tête est sur `from` : c'est ce que `draw_streak` promet à ses appelants, qui
## passent tous le point d'où l'éclat part en premier.
func test_a_streak_is_brightest_at_its_head() -> void:
	assert_gt(_alpha(Glow.streak(), 0.02, 0.5), 0.95, "la tête de la comète")
	assert_lt(_alpha(Glow.streak(), 0.98, 0.5), 0.05, "sa queue")


## Une seule image par forme pour toute la session : les effets la demandent à
## chaque `_draw`, soixante fois par seconde.
func test_a_texture_is_built_once() -> void:
	assert_eq(Glow.blob(), Glow.blob(), "deux appels, une seule texture")
