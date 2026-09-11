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

const GRAINE := 4242
## Le niveau du critère. Pas rond par hasard : c'est là que le plastron de départ
## ne tombe plus et que le T3 de `vigoureux` est ouvert.
const NIVEAU := 40
## Celui du personnage qu'on envoie mourir. Douze niveaux ne donnent que des
## points à répartir : sans les placer, c'est bien la fiche de départ — cent PV —
## qui entre dans la zone, et c'est le propos du critère.
const NIVEAU_JOUEUR := 12

## Trois secondes de contact avec un grunt. L'arithmétique, à cent PV : en zone
## 40 il frappe à 45 dégâts toutes les 0,9 s et tue au troisième coup — relevé à
## la 108e image ; en zone 1 il frappe à 8 et n'en aura pris que 24. La fenêtre
## est assez large des deux côtés pour qu'aucune des deux assertions ne tienne à
## un coup près.
const IMAGES_D_EXPOSITION := 180

## Combien de zones on accepte de jouer avant de voir tomber le torse du critère.
## Généreux : la recherche s'arrête au premier trouvé, et une borne serrée
## transformerait une malchance en régression.
const RONDES_DE_FARM := 20

var _zone: Node2D
var _mort := false
var _rng_state := 0


func before_each() -> void:
	# La zone n'écrit sur le disque que si un personnage y est chargé. Ce test
	# n'a rien à sauvegarder — la persistance a sa propre suite — et n'a donc pas
	# à laisser de fichier derrière lui.
	Game.personnage = null

	# Le butin tire sur Game.rng. Sans graine fixe, le nombre de zones à jouer
	# avant qu'un torse tombe change à chaque campagne et un échec ne se
	# reproduit pas. L'état est rendu ensuite : les autres suites n'ont pas
	# demandé à devenir déterministes.
	_rng_state = Game.rng.state
	Game.rng.seed = GRAINE

	_zone = await _entrer(NIVEAU)
	_monter_a(_zone.player, NIVEAU_JOUEUR)


func after_each() -> void:
	# Alt est un état **global** du clavier : laissée enfoncée, elle suivrait le
	# test suivant, et rien dans son rapport ne dirait pourquoi.
	_touche_alt(false)
	# Un niveau laissé derrière soi donnerait des ennemis mis à l'échelle aux
	# suites d'après, et une mesure de combat qui ne mesure plus rien.
	Game.niveau_de_zone = 1
	Game.rng.state = _rng_state


## Le critère, dans son ordre.
func test_le_critere_du_jalon_5() -> void:
	# --- « y entrer au niveau 12 et se faire tuer » ---
	var images := await _exposer(_zone, IMAGES_D_EXPOSITION)
	assert_ne(images, -1, "le personnage de niveau %d est tombé en zone %d" % [
		NIVEAU_JOUEUR, NIVEAU
	])
	gut.p("  tombé en %d images de physique" % images)

	# Le témoin : le même personnage, le même grunt, la même durée, mais une zone
	# de niveau 1. Sans lui, un joueur devenu mortel partout passerait ce test.
	# La zone profonde est vidée avant : la mort l'a repeuplée, et soixante-neuf
	# ennemis de niveau 40 qui continuent de tourner fausseraient la suite.
	_zone.kill_all()
	var facile := await _entrer(1)
	_monter_a(facile.player, NIVEAU_JOUEUR)
	assert_eq(
		await _exposer(facile, IMAGES_D_EXPOSITION), -1,
		"le même personnage tient les mêmes %d images en zone 1" % IMAGES_D_EXPOSITION
	)
	assert_gt(facile.player.health, 0.0, "et il lui reste des PV")
	facile.kill_all()

	# --- « y revenir plus fort, en ressortir avec un plastron » ---
	# Y revenir, littéralement : le niveau est relu **à chaque génération**, et le
	# témoin vient de le poser à 1. Sans cette ligne, le farm qui suit tire du
	# butin de zone 1, et cherche donc indéfiniment ce qu'une zone 1 ne donne pas.
	Game.niveau_de_zone = NIVEAU
	# Revenir plus fort, c'est ce que les zones vidées font : chaque ennemi tué
	# rapporte, et c'est le même joueur qui ramasse.
	var au_sol := await _farmer_le_torse(_zone, RONDES_DE_FARM)
	assert_not_null(au_sol, "un torse hors de portée d'une zone 1 est tombé")
	if au_sol == null:
		return
	var torse: Item = au_sol.data

	# Ramassé en marchant dessus, jamais posé dans le sac à la main : c'est la
	# moitié du trajet, et elle passe par un corps, une aire et le rangement en
	# rectangles.
	var joueur: Player = _zone.player
	joueur.global_position = au_sol.global_position
	await wait_physics_frames(4)
	var case := _case_de(joueur.inventory, torse)
	assert_ne(case, Vector2i(-1, -1), "« %s » est dans le sac" % torse.display_name())
	if case == Vector2i(-1, -1):
		return

	assert_eq(torse.item_level, NIVEAU, "il porte le niveau de sa zone")
	assert_false(
		ItemCatalog.disponibles(1).has(torse.base),
		"« %s » ne tombe pas en zone 1" % torse.base.display_name
	)

	# --- « maintenir Alt dessus et lire T3 (59–74) » ---
	# Non nul : c'est le filtre par lequel le torse a été retenu.
	var affixe := _premier_palier_verrouille(torse)
	var panneau: InventoryPanel = _zone.inventory
	panneau.toggle()
	# La case survolée : c'est elle que le dessin interroge pour savoir quelle
	# infobulle sortir.
	panneau._hover = case
	await wait_process_frames(1)

	# La touche **réellement enfoncée**, et non le drapeau posé à la main : le
	# panneau sonde l'état du clavier à chaque image et effacerait le drapeau à
	# l'image suivante. C'est ce sondage qu'on vient vérifier.
	_touche_alt(true)
	await wait_process_frames(2)
	assert_true(panneau._alt, "le panneau a vu la touche")

	# Le dessin est relancé sous Alt : c'est le seul chemin qui construit les deux
	# colonnes et écrit la plage du palier. Ce que ça donne à l'œil est du ressort
	# de la capture ; ce qu'on peut affirmer ici, c'est que la valeur portée par
	# l'objet tombe dans la fourchette que sa propre ligne annonce — le défaut que
	# deux formatages séparés créeraient.
	panneau.queue_redraw()
	await wait_process_frames(1)
	var ligne := affixe.palier_et_plage()
	assert_string_contains(ligne, "T%d" % affixe.tier)
	var palier: ItemAffixTier = ItemAffixPool.by_id(affixe.affix_id).tiers[affixe.tier - 1]
	assert_between(
		affixe.mod.value, palier.min_value, palier.max_value,
		"« %s » : la valeur portée tombe dans la plage annoncée" % ligne
	)
	gut.p("  %s — %s  %s" % [torse.display_name(), affixe.mod.label(), ligne])

	_touche_alt(false)
	await wait_process_frames(2)
	assert_false(panneau._alt, "et le relâchement aussi")


## « Après cent baguettes ramassées, aucune ne porte de dégâts d'attaque. »
##
## La règle est prouvée sur mille tirages dans test_affixes, directement sur la
## réserve. Ce qui est joué ici est le **chemin de la chute** : la base tirée
## dans le catalogue de la zone, le niveau qu'elle pose, les affixes tirés
## derrière. Une étiquette perdue entre les deux ne se verrait pas là-bas.
func test_cent_baguettes_tombees_sans_degats_d_attaque() -> void:
	var vues := 0
	var essais := 0
	# La chute rend null quatre fois sur cinq : la borne compte les tirages, pas
	# les objets, sinon elle s'arrêterait avant la première baguette.
	while vues < 100 and essais < 20000:
		essais += 1
		var item := LootTable.roll(0, NIVEAU)
		if item == null or item.base.family != "weapon" or not item.base.tags.has("caster"):
			continue
		vues += 1
		for r in item.explicits:
			assert_ne(
				r.mod.portee, MotsCles.ATTAQUE,
				"« %s » : %s" % [item.display_name(), r.mod.label()]
			)
	assert_eq(vues, 100, "cent baguettes sont tombées en %d tirages" % essais)


# --------------------------------------------------------------------------


## Entrer dans une zone, c'est régler le niveau **puis** naître dedans : le
## manager le lit à la construction, et le poser après donnerait une zone de
## niveau 40 peuplée d'ennemis de niveau 1.
func _entrer(niveau: int) -> Node2D:
	Game.niveau_de_zone = niveau
	var zone: Node2D = load("res://world/zone.tscn").instantiate()
	add_child_autofree(zone)
	await wait_physics_frames(1)
	zone.generate_zone(GRAINE)
	return zone


## Le niveau se gagne, il ne se pose pas : c'est la montée qui distribue les
## points, et un `level` écrit à la main donnerait un personnage que le jeu ne
## sait pas produire.
func _monter_a(joueur: Player, niveau: int) -> void:
	while joueur.level < niveau:
		joueur.gain_xp(joueur.xp_to_next - joueur.xp)


## Un grunt au contact, et **un seul** : le paquet complet tue aussi au niveau 1
## en trois secondes, et le test ne dirait plus rien du niveau de la zone.
##
## Rend l'image à laquelle le joueur est tombé, ou -1 s'il a tenu. Par signal et
## non en relevant `is_dead` à la fin : la mort fait repeupler la zone, qui
## ressuscite le joueur au passage — le drapeau serait déjà retombé.
func _exposer(zone: Node2D, images: int) -> int:
	zone.kill_all()
	var joueur: Player = zone.player
	_mort = false
	joueur.died.connect(func() -> void: _mort = true)

	var grunt: Enemy = zone.enemy_manager.spawn(
		load("res://actors/enemies/grunt.tscn"), joueur.global_position + Vector2(14.0, 0.0)
	)
	grunt.is_aggro = true
	for i in images:
		await wait_physics_frames(1)
		if _mort:
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
func _farmer_le_torse(zone: Node2D, rondes: int) -> GroundItem:
	for r in rondes:
		# Une graine par ronde : le butin tire sur Game.rng et changerait de toute
		# façon, mais vingt fois la même carte ne ferait mourir que la même
		# population, aux mêmes endroits.
		zone.generate_zone(GRAINE + r)
		# Sur une copie : mourir retire l'ennemi de la liste qu'on parcourt.
		for e in zone.enemy_manager.enemies.duplicate():
			if is_instance_valid(e):
				e.die()
		await wait_physics_frames(2)

		for enfant in zone.loot.get_children():
			var au_sol := enfant as GroundItem
			if au_sol == null or au_sol.data.base.family != "chest":
				continue
			if _premier_palier_verrouille(au_sol.data) != null:
				return au_sol
	return null


## Le premier affixe de cet objet dont le palier est hors de portée d'une zone de
## niveau 1, ou null. C'est la définition tenable de « il n'existait pas au
## niveau 1 » : la valeur, elle, ne dit rien — deux paliers voisins se
## chevauchent.
func _premier_palier_verrouille(item: Item) -> RolledAffix:
	for a in item.explicits:
		if not a.connu():
			continue
		var definition := ItemAffixPool.by_id(a.affix_id)
		if definition != null and not definition.ouverts(1).has(a.tier - 1):
			return a
	return null


func _case_de(sac: Inventory, item: Item) -> Vector2i:
	for p in sac.placed:
		if p.data == item:
			return p.cell
	return Vector2i(-1, -1)


## Alt enfoncée ou relâchée pour de bon : `Input.parse_input_event` passe par le
## même chemin qu'une frappe réelle, donc `is_key_pressed` la voit — c'est ce que
## le panneau sonde.
func _touche_alt(enfoncee: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = KEY_ALT
	e.physical_keycode = KEY_ALT
	e.pressed = enfoncee
	Input.parse_input_event(e)
