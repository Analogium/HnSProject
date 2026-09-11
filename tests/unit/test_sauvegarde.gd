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
		StatMod.fourchette("degats_physique", 4.0, 9.0, MotsCles.ATTAQUE),
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
	assert_eq(epee.explicits[0].mod.stat, "degats_physique")
	assert_eq(epee.explicits[0].mod.mode, StatMod.Mode.FLAT)
	assert_almost_eq(epee.explicits[0].mod.value, 4.0, 0.0001)
	assert_almost_eq(epee.explicits[0].mod.value_max, 9.0, 0.0001, "et la borne haute de la fourchette")
	assert_eq(epee.explicits[1].mod.mode, StatMod.Mode.PERCENT, "le mode n'est pas retombé sur plat")
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
	assert_eq(epee.base.implicit_value, 2.0, "epee.tres n'a pas été touché")
	assert_eq(epee.base.implicit_value_max, 6.0)


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
	assert_almost_eq(recharge.explicits[5].mod.value, 5.5, 0.0001, "les décimales aussi")


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
	assert_eq(p.equipement["chest"].explicits[0].mod.mode, StatMod.Mode.PERCENT)
	# Une version 1 ne dit pas d'où venaient ses objets. Ils valent 1, et pas un
	# niveau déduit du personnage : ce serait inventer.
	assert_eq(p.equipement["chest"].item_level, 1, "un objet de version 1 vaut le niveau 1")
	for pose in p.sac.placed:
		assert_eq(pose.data.item_level, 1)


# --------------------------------------------------------------------------
# Le niveau d'objet et la version 2 (jalon 5)
# --------------------------------------------------------------------------

## Le niveau est posé à la chute et ne bouge plus : il doit donc traverser le
## disque intact. Sans lui, un objet rechargé perdrait ce qui dit ce qu'il a pu
## recevoir comme tiers, et deux objets identiques à l'écran n'auraient pas la
## même histoire.
func test_le_niveau_d_objet_survit_a_l_aller_retour() -> void:
	var p := Personnage.nouveau("Niveaux", 0)
	p.sac.place(Item.new(ItemCatalog.by_id("epee"), [], 42), Vector2i(0, 0))
	p.equipement["chest"] = Item.new(ItemCatalog.by_id("plastron"), [], 28)

	var relu := Personnage.depuis_dict(p.vers_dict())
	assert_not_null(relu)
	assert_eq(relu.sac.placed[0].data.item_level, 42, "l'épée garde son niveau")
	assert_eq(relu.equipement["chest"].item_level, 28, "le plastron aussi")


## Le format qu'on écrit aujourd'hui, figé dans le dépôt à côté de celui d'hier.
## Le fichier de version 1 prouve qu'on lit encore les sauvegardes des joueurs ;
## celui-ci prouve que le champ qu'on vient d'ajouter porte bien le nom qu'on
## croit — un renommage des deux côtés à la fois passerait l'aller-retour.
func test_le_fichier_de_reference_v2_se_relit() -> void:
	var fichier := FileAccess.open("res://tests/fixtures/personnage_v2.json", FileAccess.READ)
	assert_not_null(fichier, "le fichier de référence est bien dans le dépôt")
	var contenu: Variant = JSON.parse_string(fichier.get_as_text())
	fichier.close()

	var p := Personnage.depuis_dict(contenu)
	assert_not_null(p, "une sauvegarde de version 2 se lit")
	assert_eq(p.nom, "Brenna")
	assert_eq(p.equipement["chest"].item_level, 28, "le niveau écrit dans le fichier")
	# Le plastron du fichier n'a ni « affixe » ni « tier » : c'est le cas d'un
	# objet relu d'une version 1 puis resauvegardé. Sa ligne s'applique, elle n'a
	# simplement rien à dire sur son tirage.
	assert_false(p.equipement["chest"].explicits[0].connu(), "une provenance absente le reste")
	var niveaux := {}
	for pose in p.sac.placed:
		niveaux[pose.data.base.id] = pose.data.item_level
	assert_eq(niveaux["epee"], 42)
	assert_eq(niveaux["baguette"], 12)


## La version écrite est bien celle qu'on annonce, et pas un numéro laissé
## derrière : un fichier neuf marqué « version 1 » se relirait aujourd'hui et
## deviendrait indéchiffrable le jour où la version 1 cessera d'être lue.
func test_ce_qu_on_ecrit_porte_la_version_courante() -> void:
	assert_eq(Personnage.nouveau("Version", 0).vers_dict()["version"], Personnage.VERSION)
	assert_true(Personnage.VERSIONS_LUES.has(Personnage.VERSION), "on sait relire ce qu'on écrit")


## La provenance accompagne la valeur jusque sur le disque : sans elle,
## l'infobulle des paliers n'aurait rien à montrer sur un objet rechargé, et un
## objet ramassé hier ne se lirait pas comme un objet ramassé à l'instant.
func test_la_provenance_d_un_affixe_survit_au_disque() -> void:
	var p := Personnage.nouveau("Paliers", 0)
	var tire := RolledAffix.new("cuirasse", 3, StatMod.new("armor", StatMod.Mode.FLAT, 29.0))
	p.equipement["chest"] = Item.new(ItemCatalog.by_id("plastron"), [tire], 40)

	var relu := Personnage.depuis_dict(p.vers_dict())
	var repris: RolledAffix = relu.equipement["chest"].explicits[0]
	assert_eq(repris.affix_id, "cuirasse")
	assert_eq(repris.tier, 3)
	assert_almost_eq(repris.mod.value, 29.0, 0.0001, "et la valeur, qui fait foi")
	assert_true(repris.connu())


## L'inverse, et c'est le cas des sauvegardes déjà sur les disques : un affixe
## sans provenance n'en gagne pas une en passant par le disque. Un palier deviné
## depuis la valeur serait faux une fois sur trois, les fourchettes de deux
## paliers voisins se chevauchant.
func test_un_affixe_sans_provenance_ne_s_en_invente_pas() -> void:
	var p := Personnage.nouveau("Orphelin", 0)
	var mod := StatMod.new("max_health", StatMod.Mode.FLAT, 22.0)
	p.equipement["chest"] = Item.new(ItemCatalog.by_id("plastron"), [mod])

	var dict := p.vers_dict()
	var ecrit: Dictionary = dict["equipement"]["chest"]["affixes"][0]
	assert_false(ecrit.has("affixe"), "rien d'inventé dans le fichier")
	assert_false(ecrit.has("tier"))

	var repris: RolledAffix = Personnage.depuis_dict(dict).equipement["chest"].explicits[0]
	assert_false(repris.connu())
	assert_eq(repris.tier, 0)
	assert_almost_eq(repris.mod.value, 22.0, 0.0001, "mais le bonus, lui, s'applique")


# --------------------------------------------------------------------------
# Les manuels, le râtelier et la barre (jalon 6, version 3)
# --------------------------------------------------------------------------

## Ce qu'un manuel a appris traverse le disque : c'est la seule chose du jalon 6
## qui ne se recalcule pas, et la perdre serait perdre des heures de jeu.
func test_les_points_d_un_manuel_survivent_a_l_aller_retour() -> void:
	var p := Personnage.nouveau("Studieuse", 0)
	var livre := Item.new(ItemCatalog.by_id("manuel_foudre"), [], 30)
	livre.manuel.experience = 340
	livre.manuel.points["eclair_vif"] = 3
	p.sac.place(livre, Vector2i(0, 0))

	var relu := Personnage.depuis_dict(p.vers_dict())
	assert_not_null(relu)
	var repris: Item = relu.sac.placed[0].data
	assert_not_null(repris.manuel, "il est revenu manuel")
	assert_eq(repris.manuel.experience, 340)
	assert_eq(repris.manuel.points_de("eclair_vif"), 3)
	assert_eq(repris.item_level, 30, "et il garde son niveau d'objet")


## Le niveau d'un manuel se **déduit** de son expérience. L'écrire créerait la
## deuxième vérité que ce format refuse partout ailleurs : ni PV, ni statistiques,
## ni total d'attributs.
func test_le_niveau_d_un_manuel_ne_s_ecrit_pas() -> void:
	var p := Personnage.nouveau("Deduite", 0)
	var livre := Item.new(ItemCatalog.by_id("manuel_foudre"))
	livre.manuel.experience = 900
	p.sac.place(livre, Vector2i(0, 0))

	var ecrit: Dictionary = p.vers_dict()["sac"][0]["manuel"]
	assert_true(ecrit.has("exp"), "l'expérience, oui")
	assert_false(ecrit.has("niveau"), "le niveau, non : il se recalcule")


## Un manuel au râtelier a quitté le sac : il est écrit là et **nulle part
## ailleurs**. Deux écritures feraient deux vérités sur ses points, et le
## rechargement en choisirait une au hasard.
func test_un_manuel_au_ratelier_revient_au_ratelier() -> void:
	var p := Personnage.nouveau("Rangee", 0)
	var livre := Item.new(ItemCatalog.by_id("manuel_foudre"), [], 30)
	livre.manuel.points["eclair_vif"] = 2
	assert_null(p.ratelier.poser(1, livre), "l'emplacement du milieu était libre")

	var relu := Personnage.depuis_dict(p.vers_dict())
	assert_not_null(relu)
	assert_eq(relu.sac.placed.size(), 0, "il n'est pas aussi dans le sac")
	assert_null(relu.ratelier.a(0), "ni ailleurs sur le râtelier")
	var repris := relu.ratelier.a(1)
	assert_not_null(repris, "il est revenu à sa place")
	assert_eq(repris.manuel.points_de("eclair_vif"), 2)


func test_la_barre_survit_a_l_aller_retour() -> void:
	var p := Personnage.nouveau("Barree", 0)
	p.barre.poser(2, "eclair_vif")
	p.barre.vider(1)

	var relu := Personnage.depuis_dict(p.vers_dict())
	assert_not_null(relu)
	assert_eq(relu.barre.id_de(0), CompetenceCatalog.ID_ATTAQUE)
	assert_eq(relu.barre.id_de(1), "", "une case vidée exprès le reste")
	assert_eq(relu.barre.id_de(2), "eclair_vif")
	assert_eq(relu.barre.id_de(4), "")


## Une compétence retirée du projet vide sa case. Le fichier reste lisible : on
## perd une touche, pas un personnage.
func test_une_competence_disparue_laisse_sa_case_vide() -> void:
	var source := Personnage.nouveau("Oubliee", 0).vers_dict()
	source["barre"] = ["attaque", "sort_retire_du_projet", null, null, null]

	var relu := Personnage.depuis_dict(source)
	assert_not_null(relu, "le personnage se charge quand même")
	assert_eq(relu.barre.id_de(0), CompetenceCatalog.ID_ATTAQUE)
	assert_eq(relu.barre.id_de(1), "", "la case de la disparue est vide")


## Des points placés dans une case que l'archétype n'a plus ne sont dépensables
## nulle part : les garder ferait un manuel qui doit des points à personne.
func test_des_points_pour_une_competence_inconnue_sont_ignores() -> void:
	var p := Personnage.nouveau("Rature", 0)
	var livre := Item.new(ItemCatalog.by_id("manuel_foudre"))
	livre.manuel.points["eclair_vif"] = 1
	p.sac.place(livre, Vector2i(0, 0))
	var source := p.vers_dict()
	source["sac"][0]["manuel"]["points"]["case_qui_n_existe_plus"] = 4

	var relu := Personnage.depuis_dict(source)
	assert_not_null(relu)
	var repris: Item = relu.sac.placed[0].data
	assert_eq(repris.manuel.points_de("eclair_vif"), 1, "ce que le livre enseigne reste")
	assert_eq(repris.manuel.points_de("case_qui_n_existe_plus"), 0, "le reste est oublié")
	assert_eq(repris.manuel.points_places(), 1)


## Une sauvegarde d'avant le jalon 6 arrive avec le jeu d'avant : rien au
## râtelier, le coup d'épée et le tir sous les doigts, et un manuel de départ
## qu'on n'a pas encore reçu.
func test_une_version_2_arrive_avec_le_jeu_d_avant() -> void:
	var fichier := FileAccess.open("res://tests/fixtures/personnage_v2.json", FileAccess.READ)
	assert_not_null(fichier)
	var contenu: Variant = JSON.parse_string(fichier.get_as_text())
	fichier.close()

	var p := Personnage.depuis_dict(contenu)
	assert_not_null(p)
	assert_true(p.ratelier.vide(), "aucun manuel à l'étude")
	assert_eq(p.barre.id_de(0), CompetenceCatalog.ID_ATTAQUE, "le coup d'épée")
	assert_eq(p.barre.id_de(1), CompetenceCatalog.ID_TIR, "et le tir")
	assert_eq(p.barre.id_de(2), "", "rien d'autre")
	assert_false(p.manuel_offert, "le manuel de départ reste à donner")


## Le format qu'on écrit aujourd'hui, figé dans le dépôt à côté de ceux d'hier.
## Il attrape ce qu'un aller-retour en mémoire laisse passer : un champ renommé
## des deux côtés à la fois.
func test_le_fichier_de_reference_v3_se_relit() -> void:
	var fichier := FileAccess.open("res://tests/fixtures/personnage_v3.json", FileAccess.READ)
	assert_not_null(fichier, "le fichier de référence est bien dans le dépôt")
	var contenu: Variant = JSON.parse_string(fichier.get_as_text())
	fichier.close()

	var p := Personnage.depuis_dict(contenu)
	assert_not_null(p, "une sauvegarde de version 3 se lit")
	assert_eq(p.nom, "Brenna")
	assert_true(p.manuel_offert, "celui-ci a déjà eu son manuel")

	var etudie := p.ratelier.a(0)
	assert_not_null(etudie, "le manuel du râtelier")
	assert_eq(etudie.base.id, "manuel_foudre")
	assert_eq(etudie.item_level, 30)
	assert_eq(etudie.manuel.experience, 340)
	assert_eq(etudie.manuel.points_de("eclair_vif"), 3)

	assert_eq(p.barre.id_de(2), "eclair_vif", "la case du milieu")
	assert_eq(p.barre.id_de(3), "", "et les deux dernières sont vides")

	# Un second manuel dort dans le sac, vierge : c'est le cas qu'on oublie —
	# celui qui n'apprend rien parce qu'il n'est pas à l'étude.
	var range_dans_le_sac := 0
	for pose in p.sac.placed:
		if pose.data.manuel != null:
			range_dans_le_sac += 1
			assert_eq(pose.data.manuel.points_places(), 0)
	assert_eq(range_dans_le_sac, 1)


# --------------------------------------------------------------------------
# La portée d'un affixe (jalon 7, version 4)
# --------------------------------------------------------------------------

## La portée traverse le disque. Perdue, un « +1 projectile » relu deviendrait une
## ligne de fiche visant un champ que la fiche n'a pas.
func test_la_portee_d_un_affixe_survit_a_l_aller_retour() -> void:
	var p := Personnage.nouveau("Portee", 0)
	p.equipement["weapon"] = Item.new(ItemCatalog.by_id("baguette"), [
		ItemAffixPool.by_id("fourchu").modificateur(1.0),
		StatMod.new("max_mana", StatMod.Mode.FLAT, 4.0),
	])

	var dict := p.vers_dict()
	var ecrits: Array = dict["equipement"]["weapon"]["affixes"]
	assert_eq(ecrits[0]["portee"], MotsCles.PROJECTILE, "écrite quand elle existe")
	assert_false((ecrits[1] as Dictionary).has("portee"), "et absente d'une ligne de fiche")

	var relus: Array[RolledAffix] = Personnage.depuis_dict(dict).equipement["weapon"].explicits
	assert_eq(relus[0].mod.portee, MotsCles.PROJECTILE)
	assert_eq(relus[0].mod.stat, "projectiles")
	assert_eq(relus[1].mod.portee, "", "la ligne de fiche le reste")


## Le format qu'on écrit aujourd'hui, avec une ligne de fiche et deux lignes
## portées sur la même baguette.
func test_le_fichier_de_reference_v4_se_relit() -> void:
	var fichier := FileAccess.open("res://tests/fixtures/personnage_v4.json", FileAccess.READ)
	assert_not_null(fichier, "le fichier de référence est bien dans le dépôt")
	var contenu: Variant = JSON.parse_string(fichier.get_as_text())
	fichier.close()

	var p := Personnage.depuis_dict(contenu)
	assert_not_null(p, "une sauvegarde de version 4 se lit")
	assert_eq(p.nom, "Ysolde")

	var baguette: Item = p.equipement["weapon"]
	var portees := []
	for r in baguette.explicits:
		portees.append(r.mod.portee)
	# La première ligne était « +5 dégâts de sort » : la version 5 la relit en
	# foudre ajoutée aux sorts. Les deux lignes portées passent telles quelles.
	assert_eq(portees, [MotsCles.SORT, MotsCles.PROJECTILE, MotsCles.FOUDRE])
	assert_eq(baguette.explicits[2].mod.stat, "degats")
	assert_eq(baguette.explicits[2].tier, 5, "avec sa provenance")


# --------------------------------------------------------------------------
# Les fourchettes et la conversion des dégâts plats (jalon 8, version 5)
# --------------------------------------------------------------------------

## Le format qu'on écrit aujourd'hui : deux lignes de dégâts ajoutés, avec leur
## borne haute.
func test_le_fichier_de_reference_v5_se_relit() -> void:
	var fichier := FileAccess.open("res://tests/fixtures/personnage_v5.json", FileAccess.READ)
	assert_not_null(fichier, "le fichier de référence est bien dans le dépôt")
	var contenu: Variant = JSON.parse_string(fichier.get_as_text())
	fichier.close()

	var p := Personnage.depuis_dict(contenu)
	assert_not_null(p, "une sauvegarde de version 5 se lit")
	var epee: Item = p.equipement["weapon"]
	var feu: StatMod = epee.explicits[0].mod
	assert_eq(feu.stat, "degats_feu")
	assert_eq(feu.value, 3.0)
	assert_eq(feu.value_max, 8.0, "la borne haute écrite dans le fichier")
	assert_eq(feu.portee, MotsCles.ATTAQUE)
	assert_true(epee.explicits[0].connu(), "une ligne du format courant garde sa provenance")
	assert_eq(p.equipement["offhand"].explicits[0].mod.value_max, 5.0)


## Un objet relu d'un fichier de version 4, portant ces lignes.
func _objet_d_une_version_4(lignes: Array) -> Item:
	var dict := Personnage.nouveau("Ancien", 0).vers_dict()
	dict["version"] = 4
	dict["equipement"] = {"weapon": {"base": "epee", "niveau": 10, "affixes": lignes}}
	var relu: Variant = JSON.parse_string(JSON.stringify(dict))
	return Personnage.depuis_dict(relu).equipement["weapon"]


## « +6 dégâts » faisait six points de plus à la seule attaque du jeu, qui était
## physique : « ajoute 6 à 6 dégâts physiques aux attaques » fait exactement ça.
func test_des_degats_d_attaque_deviennent_du_physique_aux_attaques() -> void:
	var ligne: RolledAffix = _objet_d_une_version_4([
		{"stat": "attack_damage", "mode": 0, "valeur": 6.0, "affixe": "acere", "tier": 7},
	]).explicits[0]
	assert_eq(ligne.mod.stat, "degats_physique")
	assert_eq(ligne.mod.value, 6.0)
	assert_eq(ligne.mod.value_max, 6.0)
	assert_eq(ligne.mod.portee, MotsCles.ATTAQUE)
	assert_false(ligne.connu(), "le palier 7 d'acéré n'est pas un palier du nouvel affixe")


## Tous les sorts étaient de foudre : des dégâts de sort étaient de la foudre.
func test_des_degats_de_sort_deviennent_de_la_foudre_aux_sorts() -> void:
	var ligne: RolledAffix = _objet_d_une_version_4([
		{"stat": "spell_damage", "mode": 0, "valeur": 5.0, "affixe": "arcanique", "tier": 6},
	]).explicits[0]
	assert_eq(ligne.mod.stat, "degats_foudre")
	assert_eq(ligne.mod.value_max, 5.0)
	assert_eq(ligne.mod.portee, MotsCles.SORT)


## La seule perte du jalon : un pourcentage de dégâts n'a plus rien à multiplier.
## La ligne part, et le reste de l'objet reste.
func test_un_pourcentage_de_degats_est_retire() -> void:
	var epee := _objet_d_une_version_4([
		{"stat": "attack_damage", "mode": 1, "valeur": 12.0, "affixe": "meurtrier", "tier": 3},
		{"stat": "attack_speed", "mode": 1, "valeur": 8.0},
	])
	assert_eq(epee.explicits.size(), 1, "seule la vitesse reste")
	assert_eq(epee.explicits[0].mod.stat, "attack_speed")


## Une borne haute plus basse que la basse — un fichier trafiqué — ne donne pas
## une fourchette à l'envers.
func test_une_fourchette_a_l_envers_est_redressee() -> void:
	var ligne: RolledAffix = _objet_d_une_version_4([
		{"stat": "degats_feu", "mode": 0, "valeur": 9.0, "valeur_max": 2.0, "portee": "attaque"},
	]).explicits[0]
	assert_eq(ligne.mod.value_max, 9.0)
