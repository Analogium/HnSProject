extends GutTest

## La sérialisation d'un personnage. Aucun nœud, aucun disque : c'est du calcul
## sur des dictionnaires, exactement comme un module web.
##
## Tous les allers-retours passent **par le texte JSON** et non par le
## dictionnaire seul. Ce n'est pas de la coquetterie : le JSON ne connaît qu'un
## type de nombre, donc un aller-retour en mémoire garde des entiers là où un
## vrai fichier rend des flottants. Un test qui saute l'encodage passerait sur
## un code qui casse dès le premier rechargement.


func _aller_retour(p: Personnage) -> Personnage:
	var texte := JSON.stringify(p.vers_dict())
	var relu: Variant = JSON.parse_string(texte)
	assert_true(relu is Dictionary, "le texte produit est du JSON valide")
	return Personnage.depuis_dict(relu)


func _epee_ouvragee() -> Item:
	return Item.new(ItemCatalog.by_id("epee"), [
		StatMod.new("attack_damage", StatMod.Mode.FLAT, 6.0),
		StatMod.new("attack_speed", StatMod.Mode.PERCENT, 8.0),
	] as Array[StatMod])


## Un personnage qui a vécu : des niveaux, des points placés et d'autres en
## attente, trois objets rangés à des endroits choisis, un plastron sur le dos.
func _personnage_joue() -> Personnage:
	var p := Personnage.nouveau("Brenna", 2)
	p.niveau = 7
	p.experience = 240
	p.attributs["strength"] = 8
	p.attributs["intelligence"] = 6
	p.points_a_placer = 3
	p.sac.place(_epee_ouvragee(), Vector2i(3, 1))
	p.sac.place(Item.new(ItemCatalog.by_id("baguette")), Vector2i(0, 0))
	p.equipement["chest"] = Item.new(ItemCatalog.by_id("plastron"), [
		StatMod.new("max_health", StatMod.Mode.PERCENT, 12.0),
	] as Array[StatMod])
	return p


func test_un_personnage_neuf_part_de_zero() -> void:
	var p := Personnage.nouveau("Aldric", 1)
	assert_false(p.id.is_empty(), "un identifiant est généré")
	assert_eq(p.nom, "Aldric")
	assert_eq(p.niveau, 1)
	assert_eq(p.experience, 0)
	assert_eq(p.points_a_placer, 0, "les points se gagnent en jouant, pas à la création")
	assert_eq(p.sac.placed.size(), 0)
	assert_eq(p.equipement.size(), 0)
	for champ in CharacterStats.ATTRIBUTES:
		assert_eq(p.attributs[champ], 0, "%s vierge" % champ)


## Le nom ne fait pas l'identifiant : deux personnages peuvent s'appeler pareil,
## et un nom peut contenir ce qu'un système de fichiers refuse.
func test_deux_personnages_du_meme_nom_ont_deux_identifiants() -> void:
	var a := Personnage.nouveau("Brenna", 0)
	var b := Personnage.nouveau("Brenna", 0)
	assert_ne(a.id, b.id)


func test_aller_retour_complet_par_le_json() -> void:
	var avant := _personnage_joue()
	var apres := _aller_retour(avant)
	assert_not_null(apres, "le personnage se relit")

	assert_eq(apres.id, avant.id)
	assert_eq(apres.nom, "Brenna")
	assert_eq(apres.silhouette, 2)
	assert_eq(apres.niveau, 7, "un entier relu reste un entier")
	assert_eq(apres.experience, 240)
	assert_eq(apres.points_a_placer, 3, "les points gagnés et non placés ne se perdent pas")
	assert_eq(apres.cree_le, avant.cree_le)
	assert_eq(apres.attributs, avant.attributs)
	assert_eq(apres.sac.placed.size(), 2)
	assert_eq(apres.equipement.size(), 1)


func test_les_objets_gardent_leur_place_dans_le_sac() -> void:
	var apres := _aller_retour(_personnage_joue())
	var i := apres.sac.index_at(Vector2i(3, 1))
	assert_ne(i, Inventory.EMPTY, "l'épée est revenue là où elle était")
	assert_eq(apres.sac.placed[i].data.base.id, "epee")
	assert_ne(apres.sac.index_at(Vector2i(3, 3)), Inventory.EMPTY, "épée sur trois lignes")
	assert_eq(apres.sac.index_at(Vector2i(9, 4)), Inventory.EMPTY, "et le reste est libre")


func test_les_affixes_survivent_avec_leur_mode() -> void:
	var apres := _aller_retour(_personnage_joue())
	var epee: Item = apres.sac.placed[apres.sac.index_at(Vector2i(3, 1))].data
	assert_eq(epee.explicits.size(), 2)
	assert_eq(epee.explicits[0].stat, "attack_damage")
	assert_eq(epee.explicits[0].mode, StatMod.Mode.FLAT)
	assert_almost_eq(epee.explicits[0].value, 6.0, 0.0001)
	assert_eq(epee.explicits[1].mode, StatMod.Mode.PERCENT, "le mode n'est pas retombé sur plat")
	assert_eq(epee.rarity(), Item.Rarity.MAGIQUE, "deux affixes, donc bleu")


## L'implicite n'est **pas** sauvegardé : il appartient à la base et se
## reconstruit. Le sauvegarder figerait les valeurs d'équilibrage du jour.
func test_l_implicite_revient_de_la_base_et_non_du_fichier() -> void:
	var dict := _personnage_joue().vers_dict()
	var texte := JSON.stringify(dict)
	assert_false(texte.contains("implicit"), "rien de la base n'entre dans le fichier")

	var apres := _aller_retour(_personnage_joue())
	var epee: Item = apres.sac.placed[apres.sac.index_at(Vector2i(3, 1))].data
	assert_eq(epee.mods().size(), 3, "l'implicite de l'épée plus ses deux affixes")


## La doctrine du projet : la base est partagée, jamais recopiée ni écrite.
func test_l_objet_recharge_pointe_sur_la_base_du_catalogue() -> void:
	var apres := _aller_retour(_personnage_joue())
	var epee: Item = apres.sac.placed[apres.sac.index_at(Vector2i(3, 1))].data
	assert_eq(epee.base, ItemCatalog.by_id("epee"), "la même ressource, pas une copie")
	assert_eq(epee.base.implicit_value, 4.0, "epee.tres n'a pas été touché")


func test_un_sac_plein_se_recharge_entierement() -> void:
	var p := Personnage.nouveau("Mule", 0)
	var poses := 0
	while p.sac.add(_epee_ouvragee()):
		poses += 1
	assert_eq(poses, 10, "dix épées de 1 x 3 dans une grille de 10 x 5")

	var apres := _aller_retour(p)
	assert_eq(apres.sac.placed.size(), poses, "aucune n'est tombée en route")
	assert_eq(apres.sac.used_cells(), p.sac.used_cells())


func test_un_objet_a_six_affixes_survit() -> void:
	var beaucoup: Array[StatMod] = []
	for i in 6:
		beaucoup.append(StatMod.new("armor", StatMod.Mode.FLAT, float(i) + 0.5))
	var p := Personnage.nouveau("Chargé", 0)
	p.sac.place(Item.new(ItemCatalog.by_id("plastron"), beaucoup), Vector2i(0, 0))

	var recharge: Item = _aller_retour(p).sac.placed[0].data
	assert_eq(recharge.explicits.size(), 6)
	assert_almost_eq(recharge.explicits[5].value, 5.5, 0.0001, "les décimales aussi")


func test_un_personnage_sans_rien_se_recharge() -> void:
	var apres := _aller_retour(Personnage.nouveau("Nu", 3))
	assert_not_null(apres, "sac vide et aucun équipement, ce n'est pas une erreur")
	assert_eq(apres.sac.placed.size(), 0)
	assert_eq(apres.equipement.size(), 0)
	assert_eq(apres.silhouette, 3)


## On écrit ce que le joueur a **placé**, pas son total. Écrire le total figerait
## les valeurs de départ du jour de la sauvegarde : un rééquilibrage de la fiche
## de base n'atteindrait jamais les personnages existants.
func test_on_sauve_la_repartition_et_non_le_total() -> void:
	var p := Personnage.nouveau("Répartie", 0)
	p.attributs["strength"] = 5
	var dict := p.vers_dict()
	assert_eq(dict["attributs"]["strength"], 5, "les points placés, pas la force totale")
	assert_false(dict.has("stats"), "aucune statistique calculée dans le fichier")
	assert_false(dict.has("max_health"))


## Le champ version existe pour refuser, pas pour deviner.
func test_une_version_inconnue_est_refusee() -> void:
	var dict := _personnage_joue().vers_dict()
	dict["version"] = 99
	assert_null(Personnage.depuis_dict(dict), "on ne tente pas de lire un format futur")
	dict.erase("version")
	assert_null(Personnage.depuis_dict(dict), "ni un fichier sans version")


func test_un_contenu_absurde_est_refuse_sans_planter() -> void:
	assert_null(Personnage.depuis_dict({}))
	assert_null(Personnage.depuis_dict({"version": 1}), "sans identifiant, on ne sait pas quoi écraser")


## Perdre une épée est désagréable ; perdre le personnage est inacceptable.
func test_un_objet_dont_la_base_a_disparu_est_ignore() -> void:
	var dict := _personnage_joue().vers_dict()
	dict["sac"][0]["base"] = "hallebarde_de_2027"
	dict["equipement"]["chest"]["base"] = "cape_oubliee"

	var apres := Personnage.depuis_dict(dict)
	assert_not_null(apres, "le personnage se charge quand même")
	assert_eq(apres.niveau, 7, "avec toute sa progression")
	assert_eq(apres.sac.placed.size(), 1, "seul l'objet inconnu manque")
	assert_eq(apres.equipement.size(), 0, "et le plastron inconnu n'est pas porté")


## Un attribut ajouté au jeu après coup part de zéro au lieu de manquer, et un
## nom inconnu dans le fichier n'entre pas dans la répartition.
func test_les_attributs_sont_relus_champ_par_champ() -> void:
	var dict := _personnage_joue().vers_dict()
	dict["attributs"].erase("dexterity")
	dict["attributs"]["chance"] = 12

	var apres := Personnage.depuis_dict(dict)
	assert_eq(apres.attributs["dexterity"], 0, "l'attribut absent repart de zéro")
	assert_false(apres.attributs.has("chance"), "et l'inconnu est écarté")
	assert_eq(apres.attributs.size(), CharacterStats.ATTRIBUTES.size())


func test_le_nom_est_borne_et_sans_caracteres_de_controle() -> void:
	assert_true(Personnage.nom_valide("Brenna"))
	assert_true(Personnage.nom_valide("Jean-Luc de l'Est"))
	assert_false(Personnage.nom_valide(""), "vide")
	assert_false(Personnage.nom_valide("   "), "que des espaces")
	assert_false(Personnage.nom_valide("a".repeat(Personnage.NOM_MAX + 1)), "trop long")
	assert_false(Personnage.nom_valide("Bren\nna"), "retour à la ligne")
	assert_false(Personnage.nom_valide("Bren\tna"), "tabulation")


## Le test qui attrape ce qu'un aller-retour ne peut pas attraper : un champ
## renommé des deux côtés à la fois. Ce fichier-là est figé dans le dépôt, il
## représente les sauvegardes déjà sur les disques des joueurs.
func test_le_fichier_de_reference_se_relit() -> void:
	var fichier := FileAccess.open("res://tests/fixtures/personnage_v1.json", FileAccess.READ)
	assert_not_null(fichier, "le fichier de référence est bien dans le dépôt")
	var contenu: Variant = JSON.parse_string(fichier.get_as_text())
	fichier.close()

	var p := Personnage.depuis_dict(contenu)
	assert_not_null(p, "une sauvegarde de version 1 se lit toujours")
	assert_eq(p.nom, "Brenna")
	assert_eq(p.niveau, 7)
	assert_eq(p.experience, 240)
	assert_eq(p.silhouette, 2)
	assert_eq(p.points_a_placer, 3)
	assert_eq(p.attributs["strength"], 8)
	assert_eq(p.attributs["dexterity"], 4)
	assert_eq(p.attributs["intelligence"], 6)
	assert_eq(p.sac.placed.size(), 2, "l'épée et la baguette")
	assert_ne(p.sac.index_at(Vector2i(3, 1)), Inventory.EMPTY, "l'épée à sa place")
	assert_eq(p.equipement["chest"].base.id, "plastron")
	assert_eq(p.equipement["chest"].explicits[0].mode, StatMod.Mode.PERCENT)
