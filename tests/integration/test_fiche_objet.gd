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

const GALERIE := preload("res://art/forge_gallery.tscn")

var _galerie: ForgeGallery


func before_each() -> void:
	_galerie = GALERIE.instantiate()
	add_child_autofree(_galerie)
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
func test_la_fiche_ne_montre_que_les_paliers_atteignables() -> void:
	for brut in ItemCatalog.ALL:
		var base: ItemBase = brut
		var zones := ForgeGallery.zones_de(base)
		for affixe in ForgeGallery.affixes_de(base):
			assert_eq(
				ForgeGallery.paliers_de(base, affixe).size(),
				(affixe as ItemAffix).ouverts_entre(zones.x, zones.y).size(),
				"« %s » / « %s »" % [base.display_name, (affixe as ItemAffix).id]
			)


## Les zones annoncées sont celles où **cette base-ci** sort ce palier : jamais
## avant qu'elle tombe, jamais après qu'elle a cessé. C'est tout l'intérêt de la
## ligne — sans ces bornes il faut intersecter de tête à chaque fois.
func test_les_zones_annoncees_tiennent_dans_la_fenetre_de_la_base() -> void:
	for brut in ItemCatalog.ALL:
		var base: ItemBase = brut
		var zones := ForgeGallery.zones_de(base)
		for affixe in ForgeGallery.affixes_de(base):
			for entree in ForgeGallery.paliers_de(base, affixe):
				var palier: ForgeGallery.Palier = entree
				assert_gte(
					palier.zones.x, zones.x,
					"« %s » T%d ne sort pas avant que la base tombe"
						% [base.display_name, palier.numero]
				)
				assert_lte(
					palier.zones.y, zones.y,
					"« %s » T%d ne sort pas après qu'elle a cessé"
						% [base.display_name, palier.numero]
				)
				assert_lte(
					palier.zones.x, palier.zones.y,
					"« %s » T%d a une plage non vide" % [base.display_name, palier.numero]
				)


## Les paliers arrivent du meilleur au pire, comme partout ailleurs dans le
## projet. Une échelle affichée à l'envers ferait lire le T1 comme le palier des
## premières zones.
func test_les_paliers_sont_listes_du_meilleur_au_pire() -> void:
	for brut in ItemCatalog.ALL:
		var base: ItemBase = brut
		for affixe in ForgeGallery.affixes_de(base):
			var precedent := 0
			for entree in ForgeGallery.paliers_de(base, affixe):
				var palier: ForgeGallery.Palier = entree
				assert_gt(
					palier.numero, precedent,
					"« %s » : les numéros montent" % (affixe as ItemAffix).id
				)
				precedent = palier.numero


## Le singulier n'est pas de la coquetterie : « zones 34 à 34 » se lit comme une
## erreur d'affichage, et le cas se produit dès qu'un palier n'ouvre que sur la
## dernière zone où la base tombe.
func test_une_zone_unique_se_dit_au_singulier() -> void:
	assert_eq(ForgeGallery._zones_texte(Vector2i(34, 34)), "zone 34")
	assert_eq(ForgeGallery._zones_texte(Vector2i(19, 22)), "zones 19 à 22")


## Le dernier niveau du jeu est une fin d'échelle, pas une borne : le tableau
## doit le dire comme l'en-tête, sinon les deux phrases se contredisent à trois
## centimètres l'une de l'autre.
func test_la_fin_de_l_echelle_se_dit_comme_dans_l_entete() -> void:
	assert_eq(
		ForgeGallery._zones_texte(Vector2i(34, Game.NIVEAU_MAX)),
		"zones 34 et au-delà"
	)
	var chevaliere := ItemCatalog.by_id("chevaliere")
	assert_true(
		ForgeGallery._fenetre_texte(chevaliere).ends_with("et au-delà"),
		"et l'en-tête de la même base le dit pareil"
	)


# --------------------------------------------------------------------------
# Ce qui tient à l'écran
# --------------------------------------------------------------------------

## L'invariant qui casse en silence : le plus haut des deux volets doit s'arrêter
## avant l'aide du bas. La limite vient de la scène et n'est pas recopiée ici —
## déplacer l'aide dans l'éditeur doit suffire à changer ce que ce test exige.
func test_la_fiche_d_objet_tient_dans_sa_hauteur() -> void:
	var plancher: float = _galerie.footer.offset_top
	for brut in ItemCatalog.ALL:
		var base: ItemBase = brut
		assert_lte(
			ForgeGallery.hauteur_de_fiche(base), plancher,
			"« %s » : %.0f px de fiche pour %.0f disponibles" % [
				base.display_name, ForgeGallery.hauteur_de_fiche(base), plancher
			]
		)


## Le volet de gauche et celui de droite ne doivent pas se recouvrir : la liste
## porte des noms d'affixes et des plages, et un chevauchement d'un pixel se lit
## comme un défaut d'affichage.
func test_les_deux_volets_ne_se_recouvrent_pas() -> void:
	assert_lte(
		ForgeGallery.LISTE_X + ForgeGallery.LISTE_W, ForgeGallery.TABLE_X,
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
func test_l_entete_dit_la_fenetre_de_chute() -> void:
	assert_eq(
		ForgeGallery._fenetre_texte(ItemCatalog.by_id("epee_large")),
		"tombe dans les zones 16 à 40",
		"une fenêtre qui se referme donne ses deux bornes"
	)
	assert_eq(
		ForgeGallery._fenetre_texte(ItemCatalog.by_id("pendentif")),
		"tombe dans les zones 35 et au-delà",
		"le meilleur palier d'une lignée n'a pas de fin"
	)


## Et la même chose pour toutes les bases : aucune ne doit annoncer une borne
## haute plus petite que sa borne basse, ce qui est la forme qu'avait le défaut.
func test_aucune_entete_n_annonce_une_fenetre_a_l_envers() -> void:
	for brut in ItemCatalog.ALL:
		var base: ItemBase = brut
		var texte := ForgeGallery._fenetre_texte(base)
		assert_false(
			texte.ends_with(" à 0"), "« %s » : %s" % [base.display_name, texte]
		)
		assert_false(
			texte.begins_with("NE TOMBE"), "« %s » : %s" % [base.display_name, texte]
		)
