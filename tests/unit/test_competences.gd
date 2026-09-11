extends GutTest

## La compétence hors de tout : la fiche, sa table de dégâts, et la formule qui
## en sort un nombre. Aucun manuel, aucune interface, aucun arbre de scène — au
## jalon 6, c'est la seule règle qui décide de ce que fait un coup.

## Une fiche neutre, dont chaque test ne règle que ce qu'il regarde. Les valeurs
## par défaut de CharacterStats peuvent changer, et un test qui les subit
## mesurerait autre chose que ce qu'il annonce.
func _fiche() -> CharacterStats:
	var f := CharacterStats.new()
	f.strength = 0.0
	f.dexterity = 0.0
	f.intelligence = 0.0
	return f


## Une compétence de test, écrite ici et non lue sur le disque : le contenu du
## jeu changera, la formule non.
func _competence(table: Array[float]) -> Competence:
	var c := Competence.new()
	c.id = "essai"
	c.nom = "Essai"
	c.degats_par_point = table
	return c


# --------------------------------------------------------------------------
# Le catalogue
# --------------------------------------------------------------------------

func test_chaque_competence_a_un_identifiant() -> void:
	for c in CompetenceCatalog.ALL:
		assert_false(c.id.is_empty(), "« %s » n'a pas d'identifiant" % c.nom)
		assert_false(c.nom.is_empty(), "« %s » n'a pas de nom lisible" % c.id)


## Deux compétences de même identifiant, c'est une barre sauvegardée qui rappelle
## l'une pour l'autre au chargement suivant.
func test_les_identifiants_sont_uniques() -> void:
	var vus := {}
	for c in CompetenceCatalog.ALL:
		assert_false(vus.has(c.id), "« %s » est écrit deux fois" % c.id)
		vus[c.id] = true


func test_on_retrouve_une_competence_par_son_identifiant() -> void:
	var c := CompetenceCatalog.by_id(CompetenceCatalog.ID_ATTAQUE)
	assert_not_null(c)
	assert_eq(c.id, CompetenceCatalog.ID_ATTAQUE)


## Une barre sauvegardée peut citer une compétence retirée du projet depuis. Ce
## n'est pas une erreur de programmation, c'est un cas de jeu : la case se vide.
func test_une_competence_disparue_rend_null() -> void:
	assert_null(CompetenceCatalog.by_id("sort_qui_n_existe_pas"))


## Une table vide, c'est une compétence qui ne fait jamais rien : elle ne se
## découvre qu'en la lançant, et elle ressemble alors à une panne.
func test_chaque_competence_a_de_quoi_faire_des_degats() -> void:
	for c in CompetenceCatalog.ALL:
		assert_gt(c.points_max(), 0, "« %s » n'a aucun point dans sa table" % c.nom)


## Un tir à vitesse nulle naît et reste sur place. Il ne se découvre qu'en le
## lançant, et il ressemble alors à une panne du lanceur plutôt qu'à un oubli
## dans le `.tres`.
func test_chaque_competence_qui_lance_des_projectiles_a_une_vitesse() -> void:
	for c in CompetenceCatalog.ALL:
		if c.porte(MotsCles.PROJECTILE):
			assert_gt(c.vitesse_de_projectile, 0.0, "« %s » lance des traits immobiles" % c.nom)


## Un nom de champ mal orthographié dans un `.tres` rend zéro sans rien dire, et
## la compétence paraît simplement faible. C'est ce test qui l'attrape, pas une
## partie.
func test_chaque_competence_vise_des_champs_reels() -> void:
	for c in CompetenceCatalog.ALL:
		if not c.attribut.is_empty():
			assert_true(
				CharacterStats.ATTRIBUTES.has(c.attribut),
				"« %s » monte avec « %s », qui n'est pas un attribut" % [c.nom, c.attribut]
			)


# --------------------------------------------------------------------------
# Les mots-clés (jalon 7)
# --------------------------------------------------------------------------

## **La faute de frappe silencieuse** : un `projectiles` au pluriel dans un `.tres`
## ne casse rien, le sort ne reçoit simplement jamais son bonus. C'est la raison
## d'être de la liste fermée, et ce test en est la porte.
func test_chaque_mot_cle_declare_appartient_a_la_liste() -> void:
	for c in CompetenceCatalog.ALL:
		for id in c.mots_cles_declares:
			assert_true(
				MotsCles.existe(id),
				"« %s » déclare « %s », qui n'est pas dans la liste" % [c.nom, id]
			)


## La nature et la cadence disent déjà `foudre` et `sort`. Les écrire aussi dans
## la déclaration, c'est deux vérités sur la même chose : le jour où la nature
## change, l'une des deux ment.
func test_on_ne_declare_pas_ce_que_la_nature_ou_la_cadence_disent_deja() -> void:
	var deduits := Competence.MOT_CLE_DE_CADENCE.values() + Competence.MOT_CLE_DE_NATURE.values()
	for c in CompetenceCatalog.ALL:
		for id in c.mots_cles_declares:
			assert_false(deduits.has(id), "« %s » déclare « %s », qui se déduit" % [c.nom, id])


## Le joueur lit un libellé, jamais un identifiant. Et une déduction qui visait un
## mot hors de la liste donnerait un mot-clé que la fiche ne sait pas nommer.
func test_chaque_mot_cle_a_un_libelle_et_chaque_deduction_vise_la_liste() -> void:
	for id in MotsCles.LIBELLES:
		assert_false(String(MotsCles.LIBELLES[id]).is_empty(), "« %s » n'a pas de libellé" % id)
	for id in Competence.MOT_CLE_DE_CADENCE.values() + Competence.MOT_CLE_DE_NATURE.values():
		assert_true(MotsCles.existe(id), "la déduction donne « %s », hors de la liste" % id)


func test_une_competence_de_foudre_porte_foudre_sans_l_avoir_ecrit() -> void:
	var c := _competence([1.0] as Array[float])
	c.nature = DamageType.Kind.LIGHTNING
	assert_true(c.mots_cles_declares.is_empty(), "rien n'est déclaré")
	assert_true(c.porte(MotsCles.FOUDRE))


func test_la_cadence_donne_sort_ou_attaque() -> void:
	var c := _competence([1.0] as Array[float])
	c.cadence = Competence.Cadence.INCANTATION
	assert_true(c.porte(MotsCles.SORT), "une incantation est un sort")
	assert_false(c.porte(MotsCles.ATTAQUE))
	c.cadence = Competence.Cadence.ARME
	assert_true(c.porte(MotsCles.ATTAQUE), "un geste à la cadence de l'arme est une attaque")
	assert_false(c.porte(MotsCles.SORT))


## Aucun modificateur ne vise le froid : une compétence de froid ne doit donc pas
## l'afficher. Un mot-clé montré est une promesse, et celle-ci ne serait pas tenue.
func test_une_nature_que_rien_ne_vise_ne_donne_pas_de_mot_cle() -> void:
	var c := _competence([1.0] as Array[float])
	c.nature = DamageType.Kind.COLD
	assert_eq(Array(c.mots_cles()), [MotsCles.SORT])


func test_un_tir_porte_projectile_et_un_coup_d_epee_non() -> void:
	assert_true(CompetenceCatalog.by_id(CompetenceCatalog.ID_TIR).porte(MotsCles.PROJECTILE))
	assert_false(CompetenceCatalog.by_id(CompetenceCatalog.ID_ATTAQUE).porte(MotsCles.PROJECTILE))


## L'ordre est celui de la liste, pas celui de la déclaration ni celui de la
## déduction : deux compétences voisines doivent se lire colonne contre colonne.
func test_la_fiche_ecrit_les_mots_cles_dans_l_ordre_de_la_liste() -> void:
	assert_eq(
		CompetenceCatalog.by_id("eclair_vif").libelle_des_mots_cles(),
		"Projectile · Foudre · Sort"
	)
	assert_eq(CompetenceCatalog.by_id(CompetenceCatalog.ID_ATTAQUE).libelle_des_mots_cles(), "Attaque")


# --------------------------------------------------------------------------
# La résolution (jalon 7)
# --------------------------------------------------------------------------

func _projectile(nombre: int, dispersion := 0.0) -> Competence:
	var c := _competence([10.0] as Array[float])
	c.mots_cles_declares = PackedStringArray([MotsCles.PROJECTILE])
	c.projectiles = nombre
	c.dispersion_en_degres = dispersion
	return c


func _mod(stat: String, mode: StatMod.Mode, valeur: float, portee := MotsCles.PROJECTILE) -> StatMod:
	return StatMod.new(stat, mode, valeur, portee)


## **Le test qui garantit que la résolution ne change pas le jeu** : sans
## modificateur, chaque compétence du catalogue rend exactement les nombres de sa
## fiche. Une borne mal placée dans `conclure()` le ferait tomber ici plutôt
## qu'en jouant.
func test_sans_modificateur_la_resolution_rend_la_fiche() -> void:
	var fiche := CharacterStats.new()
	for c in CompetenceCatalog.ALL:
		var points: int = c.points_max()
		var r: StatsDeCompetence = c.resoudre(points, fiche)
		assert_eq(r.degats_min[c.nature], c.degats(points, fiche), "« %s » : dégâts" % c.nom)
		assert_eq(r.total_min(), c.degats(points, fiche), "« %s » : dans sa seule nature" % c.nom)
		assert_eq(r.total_max(), r.total_min(), "« %s » : sans objet, aucune fourchette" % c.nom)
		assert_eq(r.nombre_de_projectiles(), maxi(c.projectiles, 1), "« %s » : projectiles" % c.nom)
		assert_eq(r.dispersion_en_degres, c.dispersion_en_degres, "« %s » : dispersion" % c.nom)
		assert_eq(r.vitesse_de_projectile, c.vitesse_de_projectile, "« %s » : vitesse" % c.nom)
		assert_eq(r.cout_en_mana, c.cout_en_mana, "« %s » : coût" % c.nom)
		assert_eq(r.intervalle, c.intervalle(fiche), "« %s » : intervalle" % c.nom)


func test_un_projectile_de_plus() -> void:
	var r := _projectile(1).resoudre(1, _fiche(), [_mod("projectiles", StatMod.Mode.FLAT, 1.0)])
	assert_eq(r.nombre_de_projectiles(), 2)


## Deux objets identiques donnent le même sort quel que soit l'ordre dans lequel
## on les porte — la règle de `StatMod.apply_all`, pour la même raison.
func test_les_plats_passent_avant_les_pourcentages() -> void:
	var plat := _mod("projectiles", StatMod.Mode.FLAT, 1.0)
	var pourcent := _mod("projectiles", StatMod.Mode.PERCENT, 50.0)
	var c := _projectile(2, 90.0)
	assert_eq(
		c.resoudre(1, _fiche(), [plat, pourcent]).nombre_de_projectiles(), 5,
		"(2 + 1) × 1,5 = 4,5, arrondi à 5 — et non 2 × 1,5 + 1 = 4"
	)
	assert_eq(
		c.resoudre(1, _fiche(), [pourcent, plat]).nombre_de_projectiles(), 5,
		"dans l'autre ordre aussi"
	)


func test_le_nombre_de_projectiles_s_arrondit_a_la_fin() -> void:
	var mods := [
		_mod("projectiles", StatMod.Mode.PERCENT, 50.0),
		_mod("projectiles", StatMod.Mode.PERCENT, 50.0),
	]
	assert_eq(
		_projectile(3, 90.0).resoudre(1, _fiche(), mods).nombre_de_projectiles(), 7,
		"3 × 1,5 × 1,5 = 6,75, arrondi une fois — arrondi à chaque étape, on aurait 8"
	)


func test_un_modificateur_dont_le_mot_cle_n_est_pas_porte_ne_fait_rien() -> void:
	var epee := _competence([10.0] as Array[float])
	epee.cadence = Competence.Cadence.ARME
	var r := epee.resoudre(1, _fiche(), [
		_mod("projectiles", StatMod.Mode.FLAT, 1.0),
		_mod("degats", StatMod.Mode.PERCENT, 50.0, MotsCles.FOUDRE),
	])
	assert_eq(r.nombre_de_projectiles(), 1, "une épée ne lance rien")
	assert_eq(r.total_min(), 10.0, "et une épée physique n'est pas de la foudre")


## Un modificateur sans portée appartient à la fiche, qui l'a déjà appliqué :
## le reprendre ici le compterait deux fois.
func test_un_modificateur_de_fiche_ne_touche_pas_la_competence() -> void:
	var r := _projectile(1).resoudre(1, _fiche(), [
		StatMod.new("projectiles", StatMod.Mode.FLAT, 3.0),
	])
	assert_eq(r.nombre_de_projectiles(), 1)


func test_les_degats_d_une_nature_visee_montent() -> void:
	var c := _competence([10.0] as Array[float])
	c.nature = DamageType.Kind.LIGHTNING
	var r := c.resoudre(1, _fiche(), [_mod("degats", StatMod.Mode.PERCENT, 50.0, MotsCles.FOUDRE)])
	assert_eq(r.degats_min[DamageType.Kind.LIGHTNING], 15.0)


## Le coût a sa propre voie — la réserve. Un modificateur qui le viserait par un
## mot-clé est écarté, et c'est le test de la réserve d'affixes qui refuse de
## l'écrire.
func test_on_ne_modifie_que_ce_qui_a_un_nom() -> void:
	var c := _projectile(1)
	c.cout_en_mana = 8.0
	var r := c.resoudre(1, _fiche(), [_mod("cout_en_mana", StatMod.Mode.FLAT, -8.0)])
	assert_eq(r.cout_en_mana, 8.0)


## Deux traits partis du même angle se superposent : on en voit un, et il frappe
## deux fois. Le premier projectile ajouté à un trait droit ouvre donc un écart.
func test_deux_traits_ne_partent_jamais_l_un_sur_l_autre() -> void:
	var plus_un := [_mod("projectiles", StatMod.Mode.FLAT, 1.0)]
	assert_eq(
		_projectile(1, 0.0).resoudre(1, _fiche(), plus_un).dispersion_en_degres,
		StatsDeCompetence.ECART_MINIMAL, "un trait droit s'ouvre"
	)
	assert_eq(
		_projectile(3, 24.0).resoudre(1, _fiche(), plus_un).dispersion_en_degres, 24.0,
		"une salve déjà assez large garde la sienne"
	)


## Au-delà du tour complet, le lanceur prendrait l'éventail pour une couronne.
func test_la_dispersion_ne_depasse_pas_le_tour_complet() -> void:
	var r := _projectile(8, 360.0).resoudre(1, _fiche(), [
		_mod("projectiles", StatMod.Mode.FLAT, 60.0),
	])
	assert_eq(r.dispersion_en_degres, 360.0)


# --------------------------------------------------------------------------
# Les dégâts par nature, en fourchette (jalon 8)
# --------------------------------------------------------------------------

func _ajout(nature: DamageType.Kind, bas: float, haut: float, portee := MotsCles.SORT) -> StatMod:
	return StatMod.fourchette(StatsDeCompetence.stat_ajoutee(nature), bas, haut, portee)


## Le froid ajouté à un sort de foudre reste du froid : c'est ce qui le laisse
## passer quand l'ennemi résiste à la foudre.
func test_une_fourchette_ajoutee_va_dans_sa_nature() -> void:
	var c := _competence([10.0] as Array[float])
	c.nature = DamageType.Kind.LIGHTNING
	var r := c.resoudre(1, _fiche(), [_ajout(DamageType.Kind.COLD, 3.0, 7.0)])
	assert_eq(r.degats_min[DamageType.Kind.LIGHTNING], 10.0, "la foudre du sort")
	assert_eq(r.degats_max[DamageType.Kind.LIGHTNING], 10.0, "sans fourchette")
	assert_eq(r.degats_min[DamageType.Kind.COLD], 3.0, "et le froid à part")
	assert_eq(r.degats_max[DamageType.Kind.COLD], 7.0)


## L'attribut multiplie aussi ce que les objets ajoutent. C'était la règle des
## dégâts de sort, et un personnage relu d'une ancienne sauvegarde ne doit pas
## frapper moins fort parce que ses lignes ont changé de forme.
func test_l_attribut_multiplie_aussi_les_degats_ajoutes() -> void:
	var c := _competence([10.0] as Array[float])
	c.attribut = "intelligence"
	c.pourcentage_par_attribut = 4.0
	var f := _fiche()
	f.intelligence = 10.0
	var r := c.resoudre(1, f, [_ajout(DamageType.Kind.COLD, 5.0, 5.0)])
	assert_almost_eq(r.degats_min[DamageType.Kind.PHYSICAL], 14.0, 0.0001, "10 × 1,4")
	assert_almost_eq(r.degats_min[DamageType.Kind.COLD], 7.0, 0.0001, "5 × 1,4")


## « +50 % dégâts (Foudre) » vise la compétence, pas la part : le froid qu'elle
## porte est multiplié avec sa foudre.
func test_un_pourcentage_de_degats_multiplie_toutes_les_parts() -> void:
	var c := _competence([10.0] as Array[float])
	c.nature = DamageType.Kind.LIGHTNING
	var r := c.resoudre(1, _fiche(), [
		_ajout(DamageType.Kind.COLD, 4.0, 8.0),
		_mod("degats", StatMod.Mode.PERCENT, 50.0, MotsCles.FOUDRE),
	])
	assert_eq(r.degats_min[DamageType.Kind.LIGHTNING], 15.0)
	assert_eq(r.degats_min[DamageType.Kind.COLD], 6.0)
	assert_eq(r.degats_max[DamageType.Kind.COLD], 12.0)


## La décomposition que la fiche du manuel affiche **refait** les dégâts du
## lancer : la base et les ajouts, multipliés par l'attribut et l'accroissement.
## Si elle s'en écartait, la fiche écrirait des lignes dont la somme n'est pas le
## coup qui part.
func test_la_decomposition_refait_les_degats() -> void:
	var c := _competence([10.0] as Array[float])
	c.nature = DamageType.Kind.LIGHTNING
	c.attribut = "intelligence"
	c.pourcentage_par_attribut = 4.0
	var f := _fiche()
	f.intelligence = 10.0
	var r := c.resoudre(1, f, [
		_ajout(DamageType.Kind.COLD, 4.0, 8.0),
		_ajout(DamageType.Kind.LIGHTNING, 1.0, 3.0),
		_mod("degats", StatMod.Mode.PERCENT, 50.0, MotsCles.FOUDRE),
		_mod("degats", StatMod.Mode.PERCENT, 10.0, MotsCles.SORT),
	])
	assert_eq(r.degats_de_base, 10.0, "la ligne de la table, avant tout multiplicateur")
	assert_eq(r.ajoutes_min[DamageType.Kind.COLD], 4.0)
	assert_eq(r.ajoutes_max[DamageType.Kind.LIGHTNING], 3.0, "la foudre ajoutée, à part de la base")
	assert_almost_eq(r.facteur_d_attribut, 1.4, 1e-6)
	assert_almost_eq(r.accroissement, 1.65, 1e-6, "1,5 × 1,1 : les accroissements se multiplient")

	var facteur := r.facteur_d_attribut * r.accroissement
	for nature in DamageType.Kind.size():
		var base := r.degats_de_base if nature == c.nature else 0.0
		assert_almost_eq(
			r.degats_min[nature], (base + r.ajoutes_min[nature]) * facteur, 1e-4,
			"borne basse, %s" % DamageType.NAMES[nature]
		)
		assert_almost_eq(
			r.degats_max[nature], (base + r.ajoutes_max[nature]) * facteur, 1e-4,
			"borne haute, %s" % DamageType.NAMES[nature]
		)


## L'estimation d'un lancer : le milieu de chaque fourchette, fois les projectiles,
## puis ramenée à la seconde par l'intervalle.
func test_l_estimation_d_un_lancer_est_la_moyenne_de_ses_projectiles() -> void:
	var r := StatsDeCompetence.new()
	r.poser_la_base(DamageType.Kind.LIGHTNING, 10.0)
	r.ajouter(DamageType.Kind.COLD, 2.0, 6.0)
	r.projectiles = 3.0
	r.intervalle = 0.5
	assert_almost_eq(r.moyenne_par_lancer(), 42.0, 1e-4, "14 en moyenne, trois fois")
	assert_almost_eq(r.moyenne_par_seconde(), 84.0, 1e-4, "deux lancers par seconde")
	r.intervalle = 0.0
	assert_eq(r.moyenne_par_seconde(), 0.0, "sans intervalle, pas d'infini")


## Et elle dit vrai : c'est la moyenne de ce que les tirages font réellement. Un
## tirage local, pour ne rien prendre au fil de `Game.rng`.
func test_l_estimation_rejoint_la_moyenne_des_tirages() -> void:
	var r := StatsDeCompetence.new()
	r.ajouter(DamageType.Kind.COLD, 3.0, 7.0)
	r.ajouter(DamageType.Kind.FIRE, 1.0, 9.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var somme := 0.0
	for i in 20000:
		for part in r.tirer(rng):
			somme += part
	assert_almost_eq(somme / 20000.0, r.moyenne_par_lancer(), 0.1, "10 attendus")


## Une fourchette ajoutée aux attaques ne touche pas un sort, et l'inverse.
func test_une_fourchette_ne_touche_que_sa_famille() -> void:
	var sort := _competence([10.0] as Array[float])
	var r := sort.resoudre(1, _fiche(), [_ajout(DamageType.Kind.FIRE, 5.0, 9.0, MotsCles.ATTAQUE)])
	assert_eq(r.total_max(), 10.0, "un sort n'est pas une attaque")


func test_un_coup_tire_entre_ses_bornes() -> void:
	var r := StatsDeCompetence.new()
	r.ajouter(DamageType.Kind.COLD, 3.0, 7.0)
	r.ajouter(DamageType.Kind.LIGHTNING, 10.0, 10.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 200:
		var parts := r.tirer(rng)
		assert_between(parts[DamageType.Kind.COLD], 3.0, 7.0)
		assert_eq(parts[DamageType.Kind.LIGHTNING], 10.0, "une part sans fourchette ne varie pas")


## **Invariant 3.** Le nombre de tirages ne dépend que des fourchettes ouvertes,
## jamais de ce qui sort : sinon chaque coup décalerait les tirages suivants d'un
## nombre différent.
func test_un_coup_tire_une_fois_par_fourchette_ouverte() -> void:
	var r := StatsDeCompetence.new()
	r.ajouter(DamageType.Kind.COLD, 3.0, 7.0)
	r.ajouter(DamageType.Kind.FIRE, 1.0, 2.0)
	r.ajouter(DamageType.Kind.LIGHTNING, 10.0, 10.0)
	for graine in [1, 2, 3]:
		var tire := RandomNumberGenerator.new()
		tire.seed = graine
		var temoin := RandomNumberGenerator.new()
		temoin.seed = graine
		r.tirer(tire)
		temoin.randf()
		temoin.randf()
		assert_eq(tire.state, temoin.state, "deux fourchettes ouvertes, deux tirages (graine %d)" % graine)


# --------------------------------------------------------------------------
# La formule
# --------------------------------------------------------------------------

## Une compétence non apprise n'est pas une compétence faible : elle n'existe
## pas. Sans ce zéro, une case vide de la barre lancerait un sort gratuit.
func test_zero_point_ne_rend_rien() -> void:
	var c := _competence([10.0, 20.0] as Array[float])
	assert_eq(c.degats(0, _fiche()), 0.0)
	assert_eq(c.degats(-3, _fiche()), 0.0, "et un nombre négatif non plus")


func test_chaque_point_donne_la_valeur_de_sa_ligne() -> void:
	var c := _competence([10.0, 25.0, 45.0] as Array[float])
	var f := _fiche()
	assert_eq(c.degats(1, f), 10.0, "le premier point")
	assert_eq(c.degats(2, f), 25.0, "le deuxième")
	assert_eq(c.degats(3, f), 45.0, "le troisième")
	assert_eq(c.points_max(), 3, "et la table dit combien la case accepte")


## Demander plus de points que la table n'en contient rend le dernier, jamais une
## erreur d'indice : l'appelant qui se trompe doit obtenir le meilleur coup, pas
## interrompre un combat.
func test_au_dela_du_dernier_point_on_garde_le_dernier() -> void:
	var c := _competence([10.0, 25.0] as Array[float])
	assert_eq(c.degats(9, _fiche()), 25.0)


## « +4 % par point d'intelligence », lu sur la fiche **finale** : c'est ce qui
## fait qu'un anneau ramassé en zone 40 change une compétence, et donc que les
## jalons 4 et 5 nourrissent celui-ci au lieu de vivre à côté.
func test_l_attribut_multiplie_les_degats() -> void:
	var c := _competence([100.0] as Array[float])
	c.attribut = "intelligence"
	c.pourcentage_par_attribut = 4.0
	var f := _fiche()
	assert_eq(c.degats(1, f), 100.0, "sans intelligence, la base seule")
	f.intelligence = 10.0
	assert_eq(c.degats(1, f), 140.0, "dix points d'intelligence, quarante pour cent")


## Un attribut non nommé ne multiplie rien. C'est l'état des deux attaques de
## départ, et c'est ce qui les fait sortir exactement les nombres d'avant.
func test_sans_attribut_nomme_rien_ne_multiplie() -> void:
	var c := _competence([10.0] as Array[float])
	var f := _fiche()
	f.intelligence = 100.0
	f.strength = 100.0
	assert_eq(c.degats(1, f), 10.0)


# --------------------------------------------------------------------------
# Les deux attaques de départ, qui ne doivent pas changer de valeur
# --------------------------------------------------------------------------

## Le coup d'épée rend douze, exactement : ce que la fiche du joueur lui donnait
## avant que ce nombre n'entre dans sa table. Le critique n'est pas dedans : il vit
## dans `DamageInfo.roll()`, et une compétence ne le retire ni ne le double.
func test_le_coup_de_base_rend_les_degats_d_avant() -> void:
	var c := CompetenceCatalog.by_id(CompetenceCatalog.ID_ATTAQUE)
	assert_eq(c.degats(1, _fiche()), 12.0)
	assert_eq(c.cout_en_mana, 0.0, "et il reste gratuit")


## Et le tir, sept : les dégâts de sort de l'ancienne fiche.
func test_le_tir_rend_les_degats_d_avant() -> void:
	var c := CompetenceCatalog.by_id(CompetenceCatalog.ID_TIR)
	assert_eq(c.degats(1, _fiche()), 7.0)
	assert_gt(c.cout_en_mana, 0.0, "et il coûte toujours du mana")


## Les deux attaques de départ ne montent avec aucun attribut, et ce n'est pas un
## oubli : la force ajoute déjà ses dégâts physiques aux attaques, et
## l'intelligence nourrit la réserve. Les compter ici les paierait deux fois, et
## les nombres du jalon 1 cesseraient d'être ceux d'aujourd'hui.
func test_les_attaques_de_depart_ne_montent_avec_aucun_attribut() -> void:
	for id in [CompetenceCatalog.ID_ATTAQUE, CompetenceCatalog.ID_TIR]:
		var c := CompetenceCatalog.by_id(id)
		assert_true(
			c.attribut.is_empty(),
			"« %s » monterait deux fois avec « %s »" % [c.nom, c.attribut]
		)


# --------------------------------------------------------------------------
# Les icônes
# --------------------------------------------------------------------------

## Une image de cette taille, unie, pour éprouver la mise au cadre sans dépendre
## d'un fichier du disque : le tuyau doit marcher avant qu'une seule illustration
## n'existe.
func _image(w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.7, 0.5, 1.0))
	return ImageTexture.create_from_image(img)


func _avec_icone(id: String, tex: Texture2D) -> Competence:
	IconeDeCompetence.oublier()
	var c := Competence.new()
	c.id = id
	c.icone = tex
	return c


## Sans image, pas d'icône — et ce n'est pas une erreur. C'est l'état de toutes
## les compétences tant qu'aucune n'a été produite, et la barre doit alors
## retomber sur son disque de couleur au lieu de laisser une case vide.
func test_une_competence_sans_image_n_a_pas_d_icone() -> void:
	assert_null(IconeDeCompetence.texture(null), "aucune compétence")
	assert_null(
		IconeDeCompetence.texture(CompetenceCatalog.by_id(CompetenceCatalog.ID_ATTAQUE)),
		"une compétence sans image"
	)


## Une illustration générée fait mille pixels de côté, pas vingt-quatre. Sans
## cette réduction elle sortirait de sa case et recouvrirait ses voisines.
func test_une_grande_image_est_ramenee_au_cadre() -> void:
	var tex := IconeDeCompetence.texture(_avec_icone("grande", _image(512, 512)))
	assert_not_null(tex)
	assert_eq(tex.get_size(), Vector2(IconeDeCompetence.COTE, IconeDeCompetence.COTE))


## Les proportions sont gardées : une image large et basse ramenée dans un carré
## deviendrait autre chose que ce qu'on a dessiné.
func test_la_reduction_garde_les_proportions() -> void:
	var tex := IconeDeCompetence.texture(_avec_icone("large", _image(400, 200)))
	assert_eq(tex.get_size(), Vector2(24.0, 12.0))


## Une image déjà petite n'est **pas** agrandie ici : c'est la case qui le fera,
## et la barre et la page de manuel n'ont pas la même taille. L'agrandir au
## chargement figerait un facteur qui ne vaut que pour l'une des deux.
func test_une_petite_image_reste_intacte() -> void:
	var tex := IconeDeCompetence.texture(_avec_icone("petite", _image(16, 16)))
	assert_eq(tex.get_size(), Vector2(16.0, 16.0))


## Le facteur d'agrandissement est **entier**, sinon certaines lignes de pixels
## sont doublées et pas d'autres : la trame de l'icône se met à onduler, et ça ne
## se voit qu'à l'écran.
func test_le_facteur_d_agrandissement_est_entier_et_tient_dans_la_case() -> void:
	var douze := _image(12, 12)
	assert_eq(IconeDeCompetence.facteur(douze, 26.0), 2, "deux fois douze tient dans vingt-six")
	assert_eq(IconeDeCompetence.facteur(douze, 34.0), 2, "et trois fois, non")
	var vingt_quatre := _image(24, 24)
	assert_eq(IconeDeCompetence.facteur(vingt_quatre, 26.0), 1)
	assert_eq(IconeDeCompetence.facteur(null, 26.0), 1, "et sans icône, on n'agrandit rien")


## L'image fournie n'est jamais retouchée : c'est une ressource du disque, et la
## redimensionner sur place l'écrirait pour toutes les parties suivantes de la
## session (invariant 2).
func test_l_image_fournie_n_est_pas_modifiee() -> void:
	var source := _image(96, 96)
	IconeDeCompetence.texture(_avec_icone("intacte", source))
	assert_eq(source.get_size(), Vector2(96.0, 96.0), "la source garde sa taille")


## Le cadre des icônes ne doit **jamais** dépasser la plus petite case qui les
## dessine : `facteur()` ne descend pas en dessous de 1, donc une icône plus
## grande que sa case y serait dessinée telle quelle et déborderait sur ses
## voisines. On ne lirait plus la grille, et ça ne se verrait qu'à l'écran.
func test_le_cadre_des_icones_tient_dans_la_plus_petite_case() -> void:
	assert_lte(float(IconeDeCompetence.COTE), BarrePanel.SLOT, "la case de la barre")
	assert_lte(float(IconeDeCompetence.COTE), ManuelPanel.CASE, "la case du manuel")
