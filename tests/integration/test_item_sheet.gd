extends GutTest

## La fiche d'objet de la forge (F4, puis clic sur un objet).
##
## C'est un écran de réglage, mais il porte des informations qu'on ne peut lire
## nulle part ailleurs d'un seul coup d'œil — ce qu'une base est, entre quelles
## zones elle tombe, et ce qu'elle peut recevoir. Une fiche fausse est pire
## qu'une fiche absente : on réglerait l'équilibrage sur elle.
##
## Deux choses se cassent en silence ici. Les **bornes** : la fiche annonce des
## zones, et une borne non ramenée à la fenêtre de la base oblige à faire une
## intersection de tête sans que rien ne le signale. Et la **hauteur** : la liste
## de gauche grandit avec chaque affixe ajouté au projet.
##
## Les règles que la fiche affiche — la fenêtre de chute d'une base, celle d'un
## palier d'affixe — sont testées là où elles vivent, dans test_catalogue et
## test_affixes. Ici on ne vérifie que la fiche.

const GALLERY := preload("res://art/forge_gallery.tscn")

var _gallery: ForgeGallery


func before_each() -> void:
	_gallery = GALLERY.instantiate()
	add_child_autofree(_gallery)
	await wait_process_frames(1)


# --------------------------------------------------------------------------
# Ce que la fiche montre
# --------------------------------------------------------------------------

## **Ni un palier de trop, ni un de moins.** Un de trop décrit un objet qui ne
## peut pas exister — une épée large avec un palier que seule une zone de niveau
## 52 ouvrirait, alors qu'elle cesse de tomber en zone 40. Un de moins se lirait
## comme « cet objet ne peut pas l'avoir ».
##
## Compté sur **toutes** les bases : c'est le croisement de deux fenêtres, et il
## se trompe justement sur les cas qu'on ne pense pas à regarder.
func test_the_sheet_only_shows_reachable_tiers() -> void:
	for raw in ItemCatalog.ALL:
		var base: ItemBase = raw
		var zones := ForgeGallery.zones_of(base)
		for affix in ForgeGallery.affixes_of(base):
			assert_eq(
				ForgeGallery.tiers_of(base, affix).size(),
				(affix as ItemAffix).open_between(zones.x, zones.y).size(),
				"« %s » / « %s »" % [base.display_name, (affix as ItemAffix).id]
			)


## Les zones annoncées sont celles où **cette base-ci** sort ce palier : jamais
## avant qu'elle tombe, jamais après qu'elle a cessé. C'est tout l'intérêt de la
## ligne — sans ces bornes il faut intersecter de tête à chaque fois.
func test_announced_zones_fit_in_the_base_window() -> void:
	for raw in ItemCatalog.ALL:
		var base: ItemBase = raw
		var zones := ForgeGallery.zones_of(base)
		for affix in ForgeGallery.affixes_of(base):
			for entry in ForgeGallery.tiers_of(base, affix):
				var tier: ForgeGallery.Tier = entry
				assert_gte(
					tier.zones.x, zones.x,
					"« %s » T%d ne sort pas avant que la base tombe"
						% [base.display_name, tier.number]
				)
				assert_lte(
					tier.zones.y, zones.y,
					"« %s » T%d ne sort pas après qu'elle a cessé"
						% [base.display_name, tier.number]
				)
				assert_lte(
					tier.zones.x, tier.zones.y,
					"« %s » T%d a une plage non vide" % [base.display_name, tier.number]
				)


## Les paliers arrivent du meilleur au pire, comme partout ailleurs dans le
## projet. Une échelle affichée à l'envers ferait lire le T1 comme le palier des
## premières zones.
func test_tiers_are_listed_from_best_to_worst() -> void:
	for raw in ItemCatalog.ALL:
		var base: ItemBase = raw
		for affix in ForgeGallery.affixes_of(base):
			var previous := 0
			for entry in ForgeGallery.tiers_of(base, affix):
				var tier: ForgeGallery.Tier = entry
				assert_gt(
					tier.number, previous,
					"« %s » : les numéros montent" % (affix as ItemAffix).id
				)
				previous = tier.number


## Le singulier n'est pas de la coquetterie : « zones 34 à 34 » se lit comme une
## erreur d'affichage, et le cas se produit dès qu'un palier n'ouvre que sur la
## dernière zone où la base tombe.
func test_a_single_zone_is_said_in_singular() -> void:
	assert_eq(ForgeGallery._zones_text(Vector2i(34, 34)), "zone 34")
	assert_eq(ForgeGallery._zones_text(Vector2i(19, 22)), "zones 19 à 22")


## Le dernier niveau du jeu est une fin d'échelle, pas une borne : le tableau
## doit le dire comme l'en-tête, sinon les deux phrases se contredisent à trois
## centimètres l'une de l'autre.
func test_the_end_of_the_scale_reads_like_the_header() -> void:
	assert_eq(
		ForgeGallery._zones_text(Vector2i(34, Game.MAX_LEVEL)),
		"zones 34 et au-delà"
	)
	var signet_ring := ItemCatalog.by_id("signet_ring")
	assert_true(
		ForgeGallery._window_text(signet_ring).ends_with("et au-delà"),
		"et l'en-tête de la même base le dit pareil"
	)


# --------------------------------------------------------------------------
# Ce qui tient à l'écran
# --------------------------------------------------------------------------

## L'invariant qui casse en silence : le plus haut des deux volets doit s'arrêter
## avant l'aide du bas. La limite vient de la scène et n'est pas recopiée ici —
## déplacer l'aide dans l'éditeur doit suffire à changer ce que ce test exige.
func test_the_item_sheet_fits_its_height() -> void:
	var floor_value: float = _gallery.footer.offset_top
	for raw in ItemCatalog.ALL:
		var base: ItemBase = raw
		assert_lte(
			ForgeGallery.sheet_height(base), floor_value,
			"« %s » : %.0f px de fiche pour %.0f disponibles" % [
				base.display_name, ForgeGallery.sheet_height(base), floor_value
			]
		)


## Le volet de gauche et celui de droite ne doivent pas se recouvrir : la liste
## porte des noms d'affixes et des plages, et un chevauchement d'un pixel se lit
## comme un défaut d'affichage.
func test_the_two_tabs_do_not_overlap() -> void:
	assert_lte(
		ForgeGallery.LIST_X + ForgeGallery.LIST_W, ForgeGallery.TABLE_X,
		"la liste s'arrête avant le tableau"
	)
	assert_lte(
		ForgeGallery.TABLE_X + ForgeGallery.TABLE_W, 640.0,
		"et le tableau tient dans le cadrage"
	)


# --------------------------------------------------------------------------
# L'en-tête
# --------------------------------------------------------------------------

## L'en-tête est une phrase : rien autour d'elle ne signale qu'elle est fausse.
## Elle a annoncé « tombe dans les zones 35 à 0 » — le zéro de « sans fin » lu
## comme un niveau — et aucune assertion ne l'a vu, seule une capture.
func test_the_header_states_the_drop_window() -> void:
	assert_eq(
		ForgeGallery._window_text(ItemCatalog.by_id("broadsword")),
		"tombe dans les zones 16 à 40",
		"une fenêtre qui se referme donne ses deux bornes"
	)
	assert_eq(
		ForgeGallery._window_text(ItemCatalog.by_id("pendant")),
		"tombe dans les zones 35 et au-delà",
		"le meilleur palier d'une lignée n'a pas de fin"
	)


## Et la même chose pour toutes les bases : aucune ne doit annoncer une borne
## haute plus petite que sa borne basse, ce qui est la forme qu'avait le défaut.
func test_no_header_announces_a_reversed_window() -> void:
	for raw in ItemCatalog.ALL:
		var base: ItemBase = raw
		var text_value := ForgeGallery._window_text(base)
		assert_false(
			text_value.ends_with(" à 0"), "« %s » : %s" % [base.display_name, text_value]
		)
		assert_false(
			text_value.begins_with("NE TOMBE"), "« %s » : %s" % [base.display_name, text_value]
		)
