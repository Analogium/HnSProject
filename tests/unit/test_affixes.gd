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
		var cle := "%s/%s/%s" % [a.stat, a.percent, a.families]
		assert_false(vus.has(cle), "%s fait doublon avec %s" % [a.id, vus.get(cle, "")])
		vus[cle] = a.id


func test_la_rarete_se_deduit_du_nombre_d_affixes() -> void:
	var base: ItemBase = load("res://resources/items/epee.tres")
	assert_eq(Item.new(base).rarity(), Item.Rarity.COMMUN, "sans affixe")
	var un: Array[StatMod] = [StatMod.new("attack_damage", StatMod.Mode.FLAT, 1.0)]
	assert_eq(Item.new(base, un).rarity(), Item.Rarity.MAGIQUE)
	var trois: Array[StatMod] = [un[0], un[0], un[0]]
	assert_eq(Item.new(base, trois).rarity(), Item.Rarity.RARE)
