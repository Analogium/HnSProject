extends GutTest

## Les formes du jalon 11, lancées pour de vrai par `Player.lancer()` sur des
## hurtbox posées à la main : qui elles touchent, combien de fois, et quand elles
## s'arrêtent.
##
## Des hurtbox nues et non des ennemis : un ennemi avance vers le joueur, et la
## cible qu'on voulait hors du nuage y entrerait pendant l'attente.

var _p: Player
var _effets: Node2D
## Les montants reçus par chaque cible. Un membre et non une locale : une lambda
## GDScript capture par valeur.
var _recus := {}
var _duree_du_gel: float
var _periode_du_gel: float


func before_each() -> void:
	_duree_du_gel = Game.hit_stop_duration
	_periode_du_gel = Game.hit_stop_periode
	# Sans gel : il ralentit le temps de jeu, et les attentes ci-dessous sont en
	# secondes de jeu.
	Game.hit_stop_duration = 0.0
	_recus.clear()
	_p = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_p)
	_effets = Node2D.new()
	add_child_autofree(_effets)
	_p.projectile_parent = _effets
	# La visée à la manette : la souris d'un lancement sans fenêtre est n'importe où.
	_p._aim_with_mouse = false
	_p.facing = Vector2.RIGHT
	await wait_physics_frames(1)


func after_each() -> void:
	Game.hit_stop_duration = _duree_du_gel
	Game.hit_stop_periode = _periode_du_gel
	Engine.time_scale = 1.0
	Input.action_release("competence_3")


## Le livre au plafond, ces points placés par le seul chemin, la compétence sur la
## troisième case, et de quoi la lancer autant qu'on veut.
func _apprendre(id_base: String, points: Array) -> void:
	var livre := Item.new(ItemCatalog.by_id(id_base))
	livre.manuel.gagner_experience(999999)
	_p.etudier(livre, 0)
	for id: String in points:
		assert_true(_p.investir(0, id), "« %s »" % id)
	_p.barre.poser(2, points[0])
	_p.stats.max_mana = 9999.0
	_p._set_mana(9999.0)


func _cible(position: Vector2) -> Hurtbox:
	var h := Hurtbox.new()
	h.collision_layer = Cibles.ENNEMIS
	h.collision_mask = 0
	var forme := CollisionShape2D.new()
	var cercle := CircleShape2D.new()
	cercle.radius = 8.0
	forme.shape = cercle
	h.add_child(forme)
	add_child_autofree(h)
	h.global_position = position
	_recus[h] = []
	h.damaged.connect(_sur_coup.bind(h))
	return h


func _sur_coup(info: DamageInfo, cible: Hurtbox) -> void:
	_recus[cible].append(info.amount)


func _coups(cible: Hurtbox) -> int:
	return (_recus[cible] as Array).size()


func _enfants(classe: Variant) -> Array:
	return _effets.get_children().filter(func(n: Node) -> bool: return is_instance_of(n, classe))


# --------------------------------------------------------------------------
# Chaîne d'éclairs
# --------------------------------------------------------------------------

func test_la_chaine_touche_trois_ennemis_et_pas_le_quatrieme() -> void:
	_apprendre("manuel_foudre", ["chaine_d_eclairs"])
	var cibles := [_cible(Vector2(60, 0)), _cible(Vector2(120, 0)), _cible(Vector2(180, 0)), _cible(Vector2(240, 0))]
	await wait_physics_frames(2)

	assert_true(_p.lancer(2))
	for i in 3:
		assert_eq(_coups(cibles[i]), 1, "la cible %d est touchée une fois" % (i + 1))
	assert_eq(_coups(cibles[3]), 0, "la quatrième n'est pas touchée : trois cibles")


func test_la_chaine_ne_saute_pas_plus_loin_que_sa_portee() -> void:
	_apprendre("manuel_foudre", ["chaine_d_eclairs"])
	var proche := _cible(Vector2(60, 0))
	var trop_loin := _cible(Vector2(60 + ChaineDEclairs.SAUT + 20.0, 0))
	await wait_physics_frames(2)

	assert_true(_p.lancer(2))
	assert_eq(_coups(proche), 1)
	assert_eq(_coups(trop_loin), 0, "hors de portée d'un saut")


## L'auteur voyage avec les formes, qui ne naissent pas d'une collision : un lanceur
## béni frappe moins fort par sa chaîne comme par son épée.
func test_la_chaine_frappe_au_nom_de_son_lanceur() -> void:
	_apprendre("manuel_foudre", ["chaine_d_eclairs"])
	var cible := _cible(Vector2(60, 0))
	await wait_physics_frames(2)

	assert_true(_p.lancer(2))
	_p._recharges[2] = 0.0
	_p.etats.poser(Etats.Sorte.BENEDICTION, 1.0)
	assert_true(_p.lancer(2))
	assert_eq(_coups(cible), 2)
	assert_almost_eq(float(_recus[cible][1]), float(_recus[cible][0]) * (1.0 - Etats.BENEDICTION), 0.001)


## Sans cible dans le cône, elle part quand même : un sort payé qui ne montre rien
## se lirait comme une touche morte.
func test_la_chaine_part_dans_le_vide_sans_cible_devant() -> void:
	_apprendre("manuel_foudre", ["chaine_d_eclairs"])
	var sur_le_cote := _cible(Vector2(0, 60))
	await wait_physics_frames(2)

	var mana := _p.mana
	assert_true(_p.lancer(2))
	assert_eq(_coups(sur_le_cote), 0, "hors du cône de la visée")
	assert_lt(_p.mana, mana, "le mana est dépensé")
	assert_eq(_enfants(ChaineDEclairs).size(), 1, "et la décharge se voit")


# --------------------------------------------------------------------------
# Nuage d'orage
# --------------------------------------------------------------------------

func test_le_nuage_frappe_dessous_pas_a_cote_puis_disparait() -> void:
	_apprendre("manuel_foudre", ["nuage_d_orage"])
	# Une durée raccourcie, pour ne pas attendre trois secondes.
	_p.mods_de_competence.assign([StatMod.new("duree", StatMod.Mode.PERCENT, -50.0, MotsCles.SORT)])
	var point := Vector2(Player.PORTEE_DE_POSE, 0)
	var dessous := _cible(point)
	var a_cote := _cible(point + Vector2(0, 80))
	await wait_physics_frames(2)

	Game.hit_stop_duration = 0.05
	Game.hit_stop_periode = 0.0
	Game.gels = 0
	assert_true(_p.lancer(2))
	var nuage: NuageDOrage = _enfants(NuageDOrage)[0]
	# Gardé avant l'attente : le nuage sera libéré à la fin.
	var geste := nuage._geste
	assert_eq(nuage.global_position, point, "posé à la portée, devant")
	await wait_physics_frames(3)
	assert_eq(_coups(dessous), 1, "la première impulsion part à la pose")
	assert_eq(_coups(a_cote), 0)

	await wait_seconds(geste.duree + 0.2)
	assert_eq(_coups(dessous), geste.frappes_dans_la_duree(), "une frappe par période")
	assert_eq(Game.gels, 0, "ce qui dure ne fige jamais le jeu")
	assert_eq(_enfants(NuageDOrage).size(), 0, "et il s'est dissipé")


# --------------------------------------------------------------------------
# Immolation
# --------------------------------------------------------------------------

func test_l_aura_s_allume_frappe_brule_et_s_eteint_sans_couter() -> void:
	_apprendre("manuel_feu", ["immolation"])
	var proche := _cible(Vector2(20, 0))
	var loin := _cible(Vector2(100, 0))
	await wait_physics_frames(2)

	var mana := _p.mana
	assert_true(_p.lancer(2))
	assert_true(_p.aura_allumee())
	assert_lt(_p.mana, mana, "l'allumer coûte")
	await wait_physics_frames(3)
	assert_eq(_coups(proche), 1, "l'ennemi du cercle brûle")
	assert_eq(_coups(loin), 0)
	assert_lt(_p.health, _p.stats.max_health, "et le porteur aussi")

	_p._recharges[2] = 0.0
	mana = _p.mana
	assert_true(_p.lancer(2))
	assert_false(_p.aura_allumee(), "le second lancer éteint")
	assert_eq(_p.mana, mana, "sans coût")


## **Le piège de la touche tenue** : elle relance à chaque fin de recharge, et une
## aura qui s'allume et s'éteint en boucle serait inutilisable.
func test_l_aura_ne_clignote_pas_sous_la_touche_tenue() -> void:
	_apprendre("manuel_feu", ["immolation"])
	Input.action_press("competence_3")
	await wait_physics_frames(2)
	assert_true(_p.aura_allumee(), "l'appui l'allume")
	await wait_seconds(_p.resoudre(CompetenceCatalog.by_id("immolation"), 1).intervalle * 2.5)
	assert_true(_p.aura_allumee(), "la touche tenue ne l'éteint pas")


func _toute_en(nature: DamageType.Kind) -> Array[float]:
	var parts := DamageType.parts_vides()
	parts[nature] = 1.0
	return parts


func test_la_brulure_suit_la_resistance_et_peut_tuer() -> void:
	_p.stats.max_health = 100.0
	_p._set_health(100.0)
	_p.stats.res_fire = 0.0
	_p.bruler(0.5, _toute_en(DamageType.Kind.FIRE), 1.0)
	assert_almost_eq(_p.health, 50.0, 0.001)

	_p._set_health(100.0)
	_p.stats.res_fire = 50.0
	_p.bruler(0.5, _toute_en(DamageType.Kind.FIRE), 1.0)
	assert_almost_eq(_p.health, 75.0, 0.001, "la moitié de la brûlure résistée")

	_p.bruler(10.0, _toute_en(DamageType.Kind.FIRE), 1.0)
	assert_true(_p.is_dead, "c'est le prix du sort")


## Convertie à moitié en nécrotique, elle n'est résistée qu'à moitié par le feu.
func test_chaque_part_de_la_brulure_rencontre_sa_propre_defense() -> void:
	_p.stats.max_health = 100.0
	_p._set_health(100.0)
	_p.stats.res_fire = 50.0
	_p.stats.res_necrotic = 0.0
	var moitie := DamageType.parts_vides()
	moitie[DamageType.Kind.FIRE] = 0.5
	moitie[DamageType.Kind.NECROTIC] = 0.5
	_p.bruler(0.5, moitie, 1.0)
	assert_almost_eq(_p.health, 100.0 - (12.5 + 25.0), 0.001)


## La résistance que donne un objet porté sert contre la brûlure comme contre un
## coup, plafond compris : elle passe par la fiche recalculée, et par la même règle.
func test_un_objet_de_resistance_au_feu_reduit_la_brulure() -> void:
	var sans := _perte_par_brulure()
	_p.equip(Item.new(ItemCatalog.by_id("anneau"), [ItemAffixPool.by_id("ignifuge").modificateur(40.0)]))
	assert_almost_eq(_perte_par_brulure(), sans * (1.0 - _p.stats.resistance(DamageType.Kind.FIRE) * 0.01), 0.001)
	assert_lt(_perte_par_brulure(), sans)

	_p.stats.res_fire = 500.0
	assert_almost_eq(
		_perte_par_brulure(), sans * (1.0 - CharacterStats.MAX_RESISTANCE * 0.01), 0.001,
		"plafonnée comme contre un coup"
	)


func _perte_par_brulure() -> float:
	_p._set_health(_p.stats.max_health)
	var avant := _p.health
	_p.bruler(0.1, _toute_en(DamageType.Kind.FIRE), 1.0)
	return avant - _p.health


func test_l_aura_s_eteint_quand_son_livre_quitte_le_ratelier() -> void:
	_apprendre("manuel_feu", ["immolation"])
	assert_true(_p.lancer(2))
	_p.cesser_d_etudier(0)
	await wait_physics_frames(2)
	assert_false(_p.aura_allumee())


# --------------------------------------------------------------------------
# Serpent infernal
# --------------------------------------------------------------------------

func test_le_serpent_brule_ce_qu_il_touche_une_fois_par_periode() -> void:
	_apprendre("manuel_feu", ["serpent_infernal"])
	var point := Vector2(Player.PORTEE_DE_POSE, 0)
	var dessous := _cible(point)
	await wait_physics_frames(2)

	assert_true(_p.lancer(2))
	var serpent: SerpentInfernal = _enfants(SerpentInfernal)[0]
	await wait_physics_frames(3)
	assert_eq(_coups(dessous), 1, "la tête tombe sur elle")
	await wait_seconds(serpent._geste.periode * 0.5)
	assert_eq(_coups(dessous), 1, "pas deux fois dans la même période")


func test_le_serpent_reste_pres_de_son_point_de_chute() -> void:
	_apprendre("manuel_feu", ["serpent_infernal"])
	assert_true(_p.lancer(2))
	var serpent: SerpentInfernal = _enfants(SerpentInfernal)[0]
	var plus_loin := 0.0
	for i in 30:
		await wait_physics_frames(6)
		if not is_instance_valid(serpent):
			break
		plus_loin = maxf(plus_loin, serpent._tete.distance_to(serpent._ancre))
	assert_lt(plus_loin, SerpentInfernal.LAISSE * 1.5, "la laisse le ramène")


# --------------------------------------------------------------------------
# Épée spirale
# --------------------------------------------------------------------------

func test_l_epee_spirale_refuse_la_quatrieme_sans_rien_prendre() -> void:
	_apprendre("manuel_armes", ["epee_spirale"])
	for i in 3:
		_p._recharges[2] = 0.0
		assert_true(_p.lancer(2), "épée %d" % (i + 1))
	assert_eq(_p.epees_en_orbite(), 3)

	_p._recharges[2] = 0.0
	var mana := _p.mana
	assert_false(_p.lancer(2), "la quatrième est refusée")
	assert_eq(_p.mana, mana, "sans mana")
	assert_eq(_p.recharge_restante(2), 0.0, "ni recharge")


func test_l_epee_frappe_en_tournant_puis_disparait() -> void:
	_apprendre("manuel_armes", ["epee_spirale"])
	_p.mods_de_competence.assign([StatMod.new("duree", StatMod.Mode.PERCENT, -80.0, MotsCles.ATTAQUE)])
	var sur_le_cercle := _cible(Vector2(CouronneDeLames.RAYON, 0))
	await wait_physics_frames(2)

	assert_true(_p.lancer(2))
	await wait_seconds(0.5)
	assert_gt(_coups(sur_le_cercle), 0, "elle passe sur la cible")
	await wait_seconds(0.8)
	assert_eq(_p.epees_en_orbite(), 0, "et elle a fini de tourner")


# --------------------------------------------------------------------------
# Coup en croix et boule de feu
# --------------------------------------------------------------------------

## Deux coups, la hitbox rouverte entre les deux : c'est ce qui le distingue d'un
## arc plus large.
func test_la_croix_touche_la_meme_cible_deux_fois() -> void:
	_apprendre("manuel_armes", ["coup_en_croix"])
	var devant := _cible(Vector2(20, 0))
	await wait_physics_frames(2)

	assert_true(_p.lancer(2))
	await wait_seconds(_p.swing_duration * 2.0 + 0.3)
	assert_eq(_coups(devant), 2)


func test_la_boule_blesse_le_voisin_et_la_cible_une_seule_fois() -> void:
	_apprendre("manuel_feu", ["boule_de_feu"])
	var directe := _cible(Vector2(40, 0))
	var voisine := _cible(Vector2(40, 16))
	var loin := _cible(Vector2(40, 70))
	await wait_physics_frames(2)

	assert_true(_p.lancer(2))
	await wait_seconds(0.5)
	assert_eq(_coups(directe), 1, "la touche directe, sans l'explosion en plus")
	assert_eq(_coups(voisine), 1, "l'explosion atteint le voisin")
	assert_eq(_coups(loin), 0)
