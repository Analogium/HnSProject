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


# --------------------------------------------------------------------------
# Les archétypes en planche (jalon 25) : trois poses de `tools/character_forge.py`.
# --------------------------------------------------------------------------

func _witch(dir: String, anim: String, index: int, weapon := "") -> Image:
	var cfg := SpriteForge.config("witch", 0)
	if not weapon.is_empty():
		cfg["weapon"] = weapon
	return SpriteForge.frame_image(cfg, dir, anim, index)


## Pieds sur ceux des grilles : collision, ombre et barre de vie y sont calées.
func test_a_sheet_puts_its_feet_where_the_grids_have_theirs() -> void:
	var img := _witch("down", "idle", 0)
	assert_eq(img.get_size(), Vector2i(48, 48), "la case de la planche, pas celle des grilles")
	assert_eq(SpriteForge.offset_of("witch"), Vector2(0, -10))
	assert_eq(SpriteForge.offset_of("player"), Vector2.ZERO)


## Si deux images d'une animation sont identiques, rien ne bouge à l'écran.
func test_every_animation_of_a_sheet_moves() -> void:
	for body in ["witch", "swiftblade"]:
		var sheet := SpriteForge.sheet_of(body)
		var cfg := SpriteForge.config(body, 0)
		for dir in SpriteForge.DIRS:
			assert_ne(SpriteForge.frame_image(cfg, dir, "idle", 0).get_data(),
				SpriteForge.frame_image(cfg, dir, "idle", 2).get_data(), "souffle %s %s" % [body, dir])
			for anim in ["walk", "attack", "cast", "sweep", "overhead", "thrust"]:
				var seen := {}
				for i in sheet.count(anim):
					var pixels := SpriteForge.frame_image(cfg, dir, anim, i).get_data()
					assert_false(seen.has(pixels), "deux images identiques (%s %s %s, %d)" % [body, anim, dir, i])
					seen[pixels] = true


## L'arme suit l'équipement : chaque personnage en planche a la marche, le coup
## d'épée **et** le lancer générés, et chaque image sa main armée.
func test_a_sheet_plays_its_generated_cycles() -> void:
	for body in ["witch", "swiftblade"]:
		var sheet := SpriteForge.sheet_of(body)
		var frames := SpriteForge.frames(body, 0)
		for anim in ["walk", "attack", "cast"]:
			assert_gt(sheet.count(anim), 1, "%s : le geste %s est généré" % [body, anim])
			assert_eq(frames.get_frame_count(anim + "_down"), sheet.count(anim))
			for dir in SpriteForge.DIRS:
				assert_eq((sheet.meta["anims"][anim]["hands"][dir] as Array).size(), sheet.count(anim),
					"une main par image (%s %s %s)" % [body, anim, dir])


## Chaque geste d'attaque (`Skill.GESTURE`, jalon 47) est sur la planche de chaque classe :
## une lame par image, et une image d'impact qui n'est ni la première ni la dernière — sinon
## le coup partirait à l'appui, ou après le geste.
func test_each_attack_gesture_is_on_each_class_sheet() -> void:
	for body in ["witch", "swiftblade"]:
		var sheet := SpriteForge.sheet_of(body)
		var frames := SpriteForge.frames(body, 0)
		for family: String in Skill.GESTURE.values():
			var cycle: Dictionary = sheet.meta["anims"][family]
			assert_eq(frames.get_frame_count(family + "_side"), sheet.count(family))
			assert_between(int(cycle["impact"]), 1, sheet.count(family) - 2, "%s %s" % [body, family])
			for dir in SpriteForge.DIRS:
				assert_eq((cycle["blades"][dir] as Array).size(), sheet.count(family),
					"une lame par image (%s %s %s)" % [body, family, dir])


## Une attaque joue son geste quand la planche l'a, le coup sinon ; l'impact se lit sur la
## planche, et les grilles retombent sur `DEFAULT_IMPACT`.
func test_an_attack_plays_its_gesture_and_reads_its_impact() -> void:
	var sprite := ActorSprite.new()
	sprite.archetype = "swiftblade"
	sprite.variant = 0
	add_child_autofree(sprite)
	sprite.attack(false, 0.5, "overhead")
	assert_eq(sprite.animation, &"overhead_down")
	var cycle: Dictionary = SpriteForge.sheet_of("swiftblade").meta["anims"]["overhead"]
	assert_almost_eq(sprite.impact_of("overhead"), float(cycle["impact"]) / float(cycle["count"]), 1e-6)
	var grid := ActorSprite.new()
	grid.archetype = "player"
	add_child_autofree(grid)
	grid.attack(false, 0.5, "overhead")
	assert_eq(grid.animation, &"attack_down", "les grilles n'ont que le coup")
	assert_eq(grid.impact_of("overhead"), ActorSprite.DEFAULT_IMPACT)


## Un sort joue le lancer, un coup d'arme le coup ; un corps sans lancer (les
## grilles) joue le coup dans les deux cas.
func test_a_spell_plays_the_cast() -> void:
	var sprite := ActorSprite.new()
	sprite.archetype = "witch"
	sprite.variant = 0
	add_child_autofree(sprite)
	sprite.attack(true)
	assert_eq(sprite.animation, &"cast_down")
	sprite.attack(false)
	assert_eq(sprite.animation, &"attack_down")
	sprite.set_archetype("player")
	sprite.attack(true)
	assert_eq(sprite.animation, &"attack_down")


## L'arme suit l'équipement : elle est posée par la forge, pas peinte dans la planche.
func test_a_sheet_holds_the_equipped_weapon() -> void:
	assert_ne(_witch("down", "idle", 0, "wand").get_data(), _witch("down", "idle", 0, "sword").get_data())


func test_a_sheet_carries_its_ground_shadow_in_its_alpha() -> void:
	var img := _witch("down", "idle", 0)
	var half_transparent := 0
	for y in img.get_height():
		for x in img.get_width():
			var a := img.get_pixel(x, y).a
			if a > 0.0 and a < 0.5:
				half_transparent += 1
	assert_gt(half_transparent, 8, "l'ombre au sol a disparu du canal alpha")
