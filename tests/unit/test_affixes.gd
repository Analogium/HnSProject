extends GutTest

## La réserve d'affixes d'objets. Ce qui est vérifié ici n'est pas le hasard
## mais ses garde-fous : un affixe qui vise un champ inexistant ne modifierait
## rien du tout, silencieusement.


func test_chaque_affixe_vise_un_champ_reel_et_nomme() -> void:
	var st := CharacterStats.new()
	for a in ItemAffixPool.ALL:
		assert_not_null(st.get(a.stat), "l'affixe %s vise un champ réel" % a.id)
		assert_true(StatMod.LABELS.has(a.stat), "l'affixe %s a un libellé" % a.id)


func test_chaque_implicite_vise_un_champ_reel_et_nomme() -> void:
	var st := CharacterStats.new()
	for nom in ["epee", "baguette", "plastron"]:
		var base: ItemBase = load("res://resources/items/%s.tres" % nom)
		assert_not_null(st.get(base.implicit_stat), "l'implicite de %s existe" % nom)
		assert_true(StatMod.LABELS.has(base.implicit_stat), "et il a un libellé")


## Tout ce qu'un objet peut donner doit se voir quelque part. Un affixe qui
## modifie une statistique absente de la fiche est invérifiable en jouant.
func test_tout_ce_qui_se_modifie_se_lit_sur_la_fiche() -> void:
	var visibles := {}
	for groupe in StatsPanel.GROUPS:
		for champ in groupe[1]:
			visibles[champ] = true
	for a in ItemAffixPool.ALL:
		assert_true(visibles.has(a.stat), "l'affixe %s est visible sur la fiche" % a.id)


func test_un_affixe_ne_sort_que_sur_le_bon_emplacement() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for nom in ["epee", "plastron"]:
		var base: ItemBase = load("res://resources/items/%s.tres" % nom)
		for i in 400:
			for m in ItemAffixPool.roll(rng, base):
				var trouve := false
				for a in ItemAffixPool.eligible(base):
					if a.stat == m.stat:
						trouve = true
						break
				assert_true(trouve, "%s ne reçoit que ses affixes (%s)" % [nom, m.stat])


## Le nombre tiré est borné par ce que la réserve peut réellement fournir : une
## armure ne peut pas porter six affixes s'il n'en existe que quatre pour elle.
func test_le_nombre_d_affixes_est_borne_par_la_reserve() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var plastron: ItemBase = load("res://resources/items/plastron.tres")
	var dispo := ItemAffixPool.eligible(plastron).size()
	for i in 2000:
		assert_lte(ItemAffixPool.roll(rng, plastron).size(), dispo)


## Deux lignes strictement identiques sur un objet se liraient comme un bug.
##
## L'unicité porte sur le couple (statistique, mode) et non sur la seule
## statistique : « +6 dégâts » et « +10 % dégâts » sont deux affixes distincts
## et cohabiter est voulu — c'est tout l'intérêt d'avoir les deux formes.
func test_pas_de_ligne_en_double_sur_un_objet() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var doublons := 0
	for nom in ["epee", "plastron"]:
		var base: ItemBase = load("res://resources/items/%s.tres" % nom)
		for i in 1000:
			var vus := {}
			for m in ItemAffixPool.roll(rng, base):
				var cle := "%s/%d" % [m.stat, m.mode]
				if vus.has(cle):
					doublons += 1
				vus[cle] = true
	assert_eq(doublons, 0, "aucune ligne répétée sur 2000 objets")


## Le même invariant, vu depuis la réserve : deux définitions qui partagent
## statistique **et** mode produiraient forcément des doublons un jour.
func test_la_reserve_ne_contient_pas_deux_fois_la_meme_ligne() -> void:
	var vus := {}
	for a in ItemAffixPool.ALL:
		var cle := "%s/%s/%s/%s" % [a.stat, a.percent, a.tags, a.exclut]
		assert_false(vus.has(cle), "%s fait doublon avec %s" % [a.id, vus.get(cle, "")])
		vus[cle] = a.id


func test_la_rarete_se_deduit_du_nombre_d_affixes() -> void:
	var base: ItemBase = load("res://resources/items/epee.tres")
	assert_eq(Item.new(base).rarity(), Item.Rarity.COMMUN, "sans affixe")
	var un: Array[StatMod] = [StatMod.new("attack_damage", StatMod.Mode.FLAT, 1.0)]
	assert_eq(Item.new(base, un).rarity(), Item.Rarity.MAGIQUE)
	var trois: Array[StatMod] = [un[0], un[0], un[0]]
	assert_eq(Item.new(base, trois).rarity(), Item.Rarity.RARE)


# --------------------------------------------------------------------------
# Les étiquettes (jalon 5)
# --------------------------------------------------------------------------

## Le cas qui a fait passer le filtre des familles aux étiquettes. Une épée et
## une baguette sont toutes deux de famille `weapon` : tant que le filtre lisait
## la famille, il était **impossible** de donner les dégâts d'attaque à l'une et
## pas à l'autre, et une baguette sortait « acérée ».
func test_une_baguette_ne_tire_jamais_d_affixe_de_melee() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var interdits := ["attack_damage", "attack_speed", "attack_range"]
	var baguette: ItemBase = load("res://resources/items/baguette.tres")
	for i in 1000:
		for m in ItemAffixPool.roll(rng, baguette):
			assert_false(
				m.stat in interdits,
				"une baguette a tiré « %s », qui appartient au corps à corps" % m.stat
			)


## L'épée, elle, doit continuer de les recevoir : un filtre qui ne laisse plus
## rien passer passerait ce test-là sans rien dire.
func test_une_epee_tire_encore_ses_affixes_de_melee() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var epee: ItemBase = load("res://resources/items/epee.tres")
	var vus := {}
	for i in 600:
		for m in ItemAffixPool.roll(rng, epee):
			vus[m.stat] = true
	for attendu in ["attack_damage", "attack_speed", "attack_range"]:
		assert_true(vus.has(attendu), "l'épée tire encore « %s »" % attendu)


## Une statistique qui ne se trouve qu'à un endroit fait de cet endroit une
## décision. La vitesse de déplacement est la seule du jalon 4 à être passée
## d'un emplacement à deux ; elle revient aux bottes seules.
func test_la_vitesse_de_deplacement_ne_sort_que_sur_des_bottes() -> void:
	for base in ItemCatalog.ALL:
		for a in ItemAffixPool.eligible(base):
			if a.stat != "move_speed":
				continue
			assert_eq(
				base.family, "boots",
				"« %s » peut tirer de la vitesse de déplacement" % base.display_name
			)


## Le refus l'emporte sur l'autorisation, sinon « partout sauf les armes » se
## lirait « partout, y compris les armes qui portent une étiquette autorisée ».
func test_une_exclusion_l_emporte_sur_une_etiquette_autorisee() -> void:
	var epee: ItemBase = load("res://resources/items/epee.tres")
	var a := ItemAffix.new()
	a.tags = PackedStringArray(["melee"])
	assert_true(a.fits(epee), "l'étiquette autorise")
	a.exclut = PackedStringArray(["weapon"])
	assert_false(a.fits(epee), "et l'exclusion referme")


## C'est cette forme-là que prendront les résistances : rien à autoriser, une
## seule chose à refuser, et toute base ajoutée plus tard en hérite sans qu'on y
## pense.
func test_un_affixe_sans_etiquette_sort_partout_sauf_ou_il_est_exclu() -> void:
	var a := ItemAffix.new()
	a.exclut = PackedStringArray(["weapon"])
	var recus := 0
	for base in ItemCatalog.ALL:
		if a.fits(base):
			recus += 1
		else:
			assert_true(base.tags.has("weapon"), "seule une arme est refusée")
	assert_eq(recus, ItemCatalog.ALL.size() - 2, "les huit bases qui ne sont pas des armes")


## Une base sans étiquette ne recevrait que les affixes universels, et le
## constater demanderait de ramasser cent objets.
func test_une_base_sans_etiquette_ne_recoit_pas_les_affixes_cibles() -> void:
	var nue := ItemBase.new()
	var a := ItemAffix.new()
	a.tags = PackedStringArray(["melee"])
	assert_false(a.fits(nue))
	assert_false(a.fits(null), "et pas de base du tout n'est pas « partout »")
