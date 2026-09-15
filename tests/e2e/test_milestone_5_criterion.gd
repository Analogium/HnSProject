extends GutTest

## Le critère de réussite du jalon 5, joué en entier : régler la zone sur le
## niveau 40, y entrer avec un personnage de niveau 12 et se faire tuer ; y
## revenir plus fort, en ressortir avec un torse qui n'existait pas au niveau 1 ;
## maintenir Alt dessus et lire son palier ; et vérifier qu'aucune baguette
## tombée ne porte de dégâts d'attaque.
##
## Chaque règle est déjà vérifiée pièce par pièce ailleurs — la mise à l'échelle
## et le niveau du butin dans test_zone, les fenêtres de paliers et le filtre par
## étiquettes dans test_affixes. Ce qui manquait est la **chaîne** : le niveau
## part de l'autoload, traverse les ennemis, le butin, le sac, et ressort à
## l'écran sous une touche. Un maillon rompu au milieu laisserait vertes toutes
## les suites unitaires.

const SEED := 4242
## Le niveau du critère. Pas rond par hasard : c'est là que le plastron de départ
## ne tombe plus et que le T3 de `vigorous` est ouvert.
const LEVEL := 40
## Celui du personnage qu'on envoie mourir. Douze niveaux ne donnent que des
## points à répartir : sans les placer, c'est bien la fiche de départ — cent PV —
## qui entre dans la zone, et c'est le propos du critère.
const PLAYER_LEVEL := 12

## Trois secondes de contact avec un grunt. L'arithmétique, à cent PV : en zone
## 40 il frappe à 45 dégâts toutes les 0,9 s et tue au troisième coup — relevé à
## la 108e image ; en zone 1 il frappe à 8 et n'en aura pris que 24. La fenêtre
## est assez large des deux côtés pour qu'aucune des deux assertions ne tienne à
## un coup près.
const EXPOSURE_FRAMES := 180

## Combien de zones on accepte de jouer avant de voir tomber le torse du critère.
## Généreux : la recherche s'arrête au premier trouvé, et une borne serrée
## transformerait une malchance en régression.
const FARM_ROUNDS := 20

var _zone: Node2D
var _death := false
var _rng_state := 0


func before_each() -> void:
	# La zone n'écrit sur le disque que si un personnage y est chargé. Ce test
	# n'a rien à sauvegarder — la persistance a sa propre suite — et n'a donc pas
	# à laisser de fichier derrière lui.
	Game.character = null

	# Le butin tire sur Game.rng. Sans graine fixe, le nombre de zones à jouer
	# avant qu'un torse tombe change à chaque campagne et un échec ne se
	# reproduit pas. L'état est rendu ensuite : les autres suites n'ont pas
	# demandé à devenir déterministes.
	_rng_state = Game.rng.state
	Game.rng.seed = SEED

	_zone = await _enter(LEVEL)
	_raise_to(_zone.player, PLAYER_LEVEL)


func after_each() -> void:
	# Alt est un état **global** du clavier : laissée enfoncée, elle suivrait le
	# test suivant, et rien dans son rapport ne dirait pourquoi.
	_alt_key(false)
	# Un niveau laissé derrière soi donnerait des ennemis mis à l'échelle aux
	# suites d'après, et une mesure de combat qui ne mesure plus rien.
	Game.zone_level = 1
	Game.rng.state = _rng_state


## Le critère, dans son ordre.
func test_the_milestone_5_criterion() -> void:
	# --- « y entrer au niveau 12 et se faire tuer » ---
	var frames := await _expose(_zone, EXPOSURE_FRAMES)
	assert_ne(frames, -1, "le personnage de niveau %d est tombé en zone %d" % [
		PLAYER_LEVEL, LEVEL
	])
	gut.p("  tombé en %d images de physique" % frames)

	# Le témoin : le même personnage, le même grunt, la même durée, mais une zone
	# de niveau 1. Sans lui, un joueur devenu mortel partout passerait ce test.
	# La zone profonde est vidée avant : la mort l'a repeuplée, et soixante-neuf
	# ennemis de niveau 40 qui continuent de tourner fausseraient la suite.
	_zone.kill_all()
	var easy := await _enter(1)
	_raise_to(easy.player, PLAYER_LEVEL)
	assert_eq(
		await _expose(easy, EXPOSURE_FRAMES), -1,
		"le même personnage tient les mêmes %d images en zone 1" % EXPOSURE_FRAMES
	)
	assert_gt(easy.player.health, 0.0, "et il lui reste des PV")
	easy.kill_all()

	# --- « y revenir plus fort, en ressortir avec un plastron » ---
	# Y revenir, littéralement : le niveau est relu **à chaque génération**, et le
	# témoin vient de le poser à 1. Sans cette ligne, le farm qui suit tire du
	# butin de zone 1, et cherche donc indéfiniment ce qu'une zone 1 ne donne pas.
	Game.zone_level = LEVEL
	# Revenir plus fort, c'est ce que les zones vidées font : chaque ennemi tué
	# rapporte, et c'est le même joueur qui ramasse.
	var on_ground := await _farm_the_chest(_zone, FARM_ROUNDS)
	assert_not_null(on_ground, "un torse hors de portée d'une zone 1 est tombé")
	if on_ground == null:
		return
	var torso: Item = on_ground.data

	# Ramassé en marchant dessus, jamais posé dans le sac à la main : c'est la
	# moitié du trajet, et elle passe par un corps, une aire et le rangement en
	# rectangles.
	var player: Player = _zone.player
	player.global_position = on_ground.global_position
	await wait_physics_frames(4)
	var cell := _cell_of(player.inventory, torso)
	assert_ne(cell, Vector2i(-1, -1), "« %s » est dans le sac" % torso.display_name())
	if cell == Vector2i(-1, -1):
		return

	assert_eq(torso.item_level, LEVEL, "il porte le niveau de sa zone")
	assert_false(
		ItemCatalog.available(1).has(torso.base),
		"« %s » ne tombe pas en zone 1" % torso.base.display_name
	)

	# --- « maintenir Alt dessus et lire T3 (59–74) » ---
	# Non nul : c'est le filtre par lequel le torse a été retenu.
	var affix := _first_locked_tier(torso)
	var panel: InventoryPanel = _zone.inventory
	panel.toggle()
	# La case survolée : c'est elle que le dessin interroge pour savoir quelle
	# infobulle sortir.
	panel._hover = cell
	await wait_process_frames(1)

	# La touche **réellement enfoncée**, et non le drapeau posé à la main : le
	# panneau sonde l'état du clavier à chaque image et effacerait le drapeau à
	# l'image suivante. C'est ce sondage qu'on vient vérifier.
	_alt_key(true)
	await wait_process_frames(2)
	assert_true(panel._alt, "le panneau a vu la touche")

	# Le dessin est relancé sous Alt : c'est le seul chemin qui construit les deux
	# colonnes et écrit la plage du palier. Ce que ça donne à l'œil est du ressort
	# de la capture ; ce qu'on peut affirmer ici, c'est que la valeur portée par
	# l'objet tombe dans la fourchette que sa propre ligne annonce — le défaut que
	# deux formatages séparés créeraient.
	panel.queue_redraw()
	await wait_process_frames(1)
	var line := affix.tier_and_span()
	assert_string_contains(line, "T%d" % affix.tier)
	var tier: ItemAffixTier = ItemAffixPool.by_id(affix.affix_id).tiers[affix.tier - 1]
	assert_between(
		affix.mod.value, tier.min_value, tier.max_value,
		"« %s » : la valeur portée tombe dans la plage annoncée" % line
	)
	gut.p("  %s — %s  %s" % [torso.display_name(), affix.mod.label(), line])

	_alt_key(false)
	await wait_process_frames(2)
	assert_false(panel._alt, "et le relâchement aussi")


## « Après cent baguettes ramassées, aucune ne porte de dégâts d'attaque. »
##
## La règle est prouvée sur mille tirages dans test_affixes, directement sur la
## réserve. Ce qui est joué ici est le **chemin de la chute** : la base tirée
## dans le catalogue de la zone, le niveau qu'elle pose, les affixes tirés
## derrière. Une étiquette perdue entre les deux ne se verrait pas là-bas.
func test_a_hundred_dropped_wands_without_attack_damage() -> void:
	var views := 0
	var attempts := 0
	# La chute rend null quatre fois sur cinq : la borne compte les tirages, pas
	# les objets, sinon elle s'arrêterait avant la première baguette.
	while views < 100 and attempts < 20000:
		attempts += 1
		var item := LootTable.roll(0, LEVEL)
		if item == null or item.base.family != "weapon" or not item.base.tags.has("caster"):
			continue
		views += 1
		for r in item.explicits:
			assert_ne(
				r.mod.scope, Keywords.ATTACK,
				"« %s » : %s" % [item.display_name(), r.mod.label()]
			)
	assert_eq(views, 100, "cent baguettes sont tombées en %d tirages" % attempts)


# --------------------------------------------------------------------------


## Entrer dans une zone, c'est régler le niveau **puis** naître dedans : le
## manager le lit à la construction, et le poser après donnerait une zone de
## niveau 40 peuplée d'ennemis de niveau 1.
func _enter(level: int) -> Node2D:
	Game.zone_level = level
	var zone: Node2D = load("res://world/zone.tscn").instantiate()
	add_child_autofree(zone)
	await wait_physics_frames(1)
	zone.generate_zone(SEED)
	return zone


## Le niveau se gagne, il ne se pose pas : c'est la montée qui distribue les
## points, et un `level` écrit à la main donnerait un personnage que le jeu ne
## sait pas produire.
func _raise_to(player: Player, level: int) -> void:
	while player.level < level:
		player.gain_xp(player.xp_to_next - player.xp)


## Un grunt au contact, et **un seul** : le paquet complet tue aussi au niveau 1
## en trois secondes, et le test ne dirait plus rien du niveau de la zone.
##
## Rend l'image à laquelle le joueur est tombé, ou -1 s'il a tenu. Par signal et
## non en relevant `is_dead` à la fin : la mort fait repeupler la zone, qui
## ressuscite le joueur au passage — le drapeau serait déjà retombé.
func _expose(zone: Node2D, frames: int) -> int:
	zone.kill_all()
	var player: Player = zone.player
	_death = false
	player.died.connect(func() -> void: _death = true)

	var grunt: Enemy = zone.enemy_manager.spawn(
		load("res://actors/enemies/grunt.tscn"), player.global_position + Vector2(14.0, 0.0)
	)
	grunt.is_aggro = true
	for i in frames:
		await wait_physics_frames(1)
		if _death:
			return i
	return -1


## Joue des zones jusqu'à ce que tombe le torse du critère, et le laisse au sol :
## c'est le ramassage qui suit. Null si aucun n'est venu.
##
## Deux conditions, et la seconde est le jalon lui-même : une base que la zone 1
## ne lâche pas, **et** un palier qu'elle n'ouvre pas. La seconde n'est pas
## acquise sur chaque chute — un torse de niveau 40 peut n'avoir qu'un T6, que la
## zone 1 donne aussi. Ce qui est promis, c'est qu'en jouant on finit par en voir
## un ; c'est donc une recherche bornée, et son échec est la régression.
func _farm_the_chest(zone: Node2D, rounds: int) -> GroundItem:
	for r in rounds:
		# Une graine par ronde : le butin tire sur Game.rng et changerait de toute
		# façon, mais vingt fois la même carte ne ferait mourir que la même
		# population, aux mêmes endroits.
		zone.generate_zone(SEED + r)
		# Sur une copie : mourir retire l'ennemi de la liste qu'on parcourt.
		for e in zone.enemy_manager.enemies.duplicate():
			if is_instance_valid(e):
				e.die()
		await wait_physics_frames(2)

		for child in zone.loot.get_children():
			var on_ground := child as GroundItem
			if on_ground == null or on_ground.data.base.family != "chest":
				continue
			if _first_locked_tier(on_ground.data) != null:
				return on_ground
	return null


## Le premier affixe de cet objet dont le palier est hors de portée d'une zone de
## niveau 1, ou null. C'est la définition tenable de « il n'existait pas au
## niveau 1 » : la valeur, elle, ne dit rien — deux paliers voisins se
## chevauchent.
func _first_locked_tier(item: Item) -> RolledAffix:
	for a in item.explicits:
		if not a.known():
			continue
		var definition := ItemAffixPool.by_id(a.affix_id)
		if definition != null and not definition.unlocked_tiers(1).has(a.tier - 1):
			return a
	return null


func _cell_of(bag: Inventory, item: Item) -> Vector2i:
	for p in bag.placed:
		if p.data == item:
			return p.cell
	return Vector2i(-1, -1)


## Alt enfoncée ou relâchée pour de bon : `Input.parse_input_event` passe par le
## même chemin qu'une frappe réelle, donc `is_key_pressed` la voit — c'est ce que
## le panneau sonde.
func _alt_key(pressed_down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = KEY_ALT
	e.physical_keycode = KEY_ALT
	e.pressed = pressed_down
	Input.parse_input_event(e)
