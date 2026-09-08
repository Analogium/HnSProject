extends GutTest

## La fiche d'objet de la forge (F4, puis clic sur un objet).
##
## C'est un écran de réglage, mais il porte trois informations qu'on ne peut lire
## nulle part ailleurs d'un seul coup d'œil — ce qu'une base est, entre quels
## niveaux de zone elle tombe, et ce qu'elle peut recevoir. Une fiche fausse est
## pire qu'une fiche absente : on réglerait l'équilibrage sur elle.
##
## Ce qui se casse en silence ici, c'est la hauteur : l'anneau tient à quelques
## lignes près, et le prochain affixe du projet ferait déborder sa fiche sur
## l'aide du bas sans qu'aucune assertion existante ne bronche.
##
## Les règles que la fiche **affiche** — la fenêtre de chute d'une base, celle
## d'un palier d'affixe — sont testées là où elles vivent, dans test_catalogue et
## test_affixes. Ici on ne vérifie que la fiche.

const GALERIE := preload("res://art/forge_gallery.tscn")

var _galerie: ForgeGallery


func before_each() -> void:
	_galerie = GALERIE.instantiate()
	add_child_autofree(_galerie)
	await wait_process_frames(1)


# --------------------------------------------------------------------------
# Le contenu de la fiche
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
		var fenetre := ItemCatalog.fenetre_de_chute(base)
		var dernier: int = Game.NIVEAU_MAX if fenetre.y <= 0 else fenetre.y

		var attendus := 0
		for affixe in ItemAffixPool.compatibles(base):
			attendus += affixe.ouverts_entre(fenetre.x, dernier).size()

		var vus := 0
		for ligne in ForgeGallery.lignes_affixes(base):
			for texte in (ligne as ForgeGallery.Ligne).textes:
				if texte.begins_with("T"):
					vus += 1

		assert_eq(vus, attendus, "« %s » : %d paliers atteignables" % [base.display_name, attendus])


## Le pire cas n'est pas celui qu'on croit : c'est la base dont la **fenêtre de
## chute** est la plus large, pas celle qui accepte le plus d'affixes. Le
## pendentif, qui tombe de la zone 35 jusqu'à la fin, dépasse l'anneau qui
## accepte pourtant les mêmes affixes mais s'arrête en zone 22.
##
## Ce test ne fige pas un nom — il vérifie que la fiche la plus lourde garde de
## la marge. Sans marge, le prochain palier ajouté déborde sans prévenir.
func test_la_fiche_la_plus_lourde_garde_de_la_marge() -> void:
	var pire := 0
	var pire_nom := ""
	for brut in ItemCatalog.ALL:
		var base: ItemBase = brut
		var lignes: int = ForgeGallery.lignes_affixes(base).size()
		if lignes > pire:
			pire = lignes
			pire_nom = base.display_name
	var par_colonne := ceili(float(pire) / float(ForgeGallery.DETAIL_COLS))
	var tiennent := int((_galerie.footer.offset_top - ForgeGallery.DETAIL_TOP) / ForgeGallery.DETAIL_LINE)
	assert_lte(
		par_colonne, tiennent,
		"« %s » : %d lignes par colonne pour %d qui tiennent" % [pire_nom, par_colonne, tiennent]
	)


## L'invariant qui casse en silence : la colonne la plus longue doit s'arrêter
## avant l'aide du bas. La limite vient de la scène et n'est pas recopiée ici —
## déplacer l'aide dans l'éditeur doit suffire à changer ce que ce test exige.
func test_la_fiche_d_objet_tient_dans_sa_hauteur() -> void:
	var plancher: float = _galerie.footer.offset_top
	for base in ItemCatalog.ALL:
		var bas := ForgeGallery.DETAIL_TOP + ForgeGallery.hauteur_de_fiche(base)
		assert_lte(
			bas, plancher,
			"« %s » : %.0f px de fiche pour %.0f disponibles" % [
				base.display_name, bas, plancher
			]
		)


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
