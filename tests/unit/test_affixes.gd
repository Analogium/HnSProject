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
			for m in ItemAffixPool.roll(rng, base, 60):
				var trouve := false
				for a in ItemAffixPool.eligible(base, 60):
					if a.stat == m.mod.stat:
						trouve = true
						break
				assert_true(trouve, "%s ne reçoit que ses affixes (%s)" % [nom, m.mod.stat])


## Le nombre tiré est borné par ce que la réserve peut réellement fournir : une
## armure ne peut pas porter six affixes s'il n'en existe que quatre pour elle.
func test_le_nombre_d_affixes_est_borne_par_la_reserve() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var plastron: ItemBase = load("res://resources/items/plastron.tres")
	var dispo := ItemAffixPool.eligible(plastron, 60).size()
	for i in 2000:
		assert_lte(ItemAffixPool.roll(rng, plastron, 60).size(), dispo)


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
			for m in ItemAffixPool.roll(rng, base, 60):
				var cle := "%s/%d" % [m.mod.stat, m.mod.mode]
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
		for m in ItemAffixPool.roll(rng, baguette, 60):
			assert_false(
				m.mod.stat in interdits,
				"une baguette a tiré « %s », qui appartient au corps à corps" % m.mod.stat
			)


## L'épée, elle, doit continuer de les recevoir : un filtre qui ne laisse plus
## rien passer passerait ce test-là sans rien dire.
func test_une_epee_tire_encore_ses_affixes_de_melee() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var epee: ItemBase = load("res://resources/items/epee.tres")
	var vus := {}
	for i in 600:
		for m in ItemAffixPool.roll(rng, epee, 60):
			vus[m.mod.stat] = true
	for attendu in ["attack_damage", "attack_speed", "attack_range"]:
		assert_true(vus.has(attendu), "l'épée tire encore « %s »" % attendu)


## Une statistique qui ne se trouve qu'à un endroit fait de cet endroit une
## décision. La vitesse de déplacement est la seule du jalon 4 à être passée
## d'un emplacement à deux ; elle revient aux bottes seules.
func test_la_vitesse_de_deplacement_ne_sort_que_sur_des_bottes() -> void:
	for base in ItemCatalog.ALL:
		for a in ItemAffixPool.eligible(base, 60):
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
	var armes := 0
	var recus := 0
	for base in ItemCatalog.ALL:
		if a.fits(base):
			recus += 1
		else:
			armes += 1
			assert_true(base.tags.has("weapon"), "seule une arme est refusée")
	assert_gt(armes, 0, "il y a bien des armes dans le catalogue")
	assert_eq(recus, ItemCatalog.ALL.size() - armes, "et tout le reste reçoit")


## Une base sans étiquette ne recevrait que les affixes universels, et le
## constater demanderait de ramasser cent objets.
func test_une_base_sans_etiquette_ne_recoit_pas_les_affixes_cibles() -> void:
	var nue := ItemBase.new()
	var a := ItemAffix.new()
	a.tags = PackedStringArray(["melee"])
	assert_false(a.fits(nue))
	assert_false(a.fits(null), "et pas de base du tout n'est pas « partout »")


# --------------------------------------------------------------------------
# Les paliers (jalon 5)
# --------------------------------------------------------------------------

## Ce qui remplace la formule. Les paliers sont écrits à la main dans les
## `.tres` — une formule donnerait à tous les affixes la même courbe — et c'est
## ce test qui attrape la faute de frappe : deux fourchettes inversées, un
## niveau qui redescend, un palier plus fort que celui du dessus.
##
## La comparaison porte sur la **valeur absolue** : un affixe dont le bon sens
## est négatif — un temps de recharge qui baisse — s'améliorera en descendant, et
## le test doit le suivre sans qu'on ait à le réécrire.
func test_chaque_echelle_est_monotone() -> void:
	for a in ItemAffixPool.ALL:
		assert_gt(a.tiers.size(), 1, "« %s » n\'a pas d\'échelle" % a.id)
		for i in a.tiers.size():
			var t: ItemAffixTier = a.tiers[i]
			assert_lte(t.min_value, t.max_value, "%s T%d : fourchette à l\'envers" % [a.id, i + 1])
			assert_gt(t.poids, 0, "%s T%d : un palier de poids nul ne sort jamais" % [a.id, i + 1])
			if i + 1 >= a.tiers.size():
				continue
			var pire: ItemAffixTier = a.tiers[i + 1]
			assert_gt(
				t.niveau_requis, pire.niveau_requis,
				"%s : T%d doit demander plus que T%d" % [a.id, i + 1, i + 2]
			)
			assert_gt(
				absf(t.min_value), absf(pire.min_value),
				"%s : T%d n\'est pas meilleur que T%d" % [a.id, i + 1, i + 2]
			)
			assert_gt(absf(t.max_value), absf(pire.max_value))
			assert_eq(
				signf(t.min_value), signf(pire.min_value),
				"%s : deux paliers de signes contraires" % a.id
			)


## Le palier le plus bas exige toujours 1. Sans cette règle, l\'affixe
## n\'existerait pas dans les premières zones, et sa première sortie
## ressemblerait à un ajout de contenu plutôt qu\'à une progression.
func test_chaque_affixe_existe_des_le_niveau_1() -> void:
	for a in ItemAffixPool.ALL:
		assert_eq(a.niveau_minimum(), 1, "« %s » ne sort pas dans les premières zones" % a.id)
		assert_eq(
			a.ouverts(1).size(), 1,
			"« %s » : un seul palier ouvert au niveau 1, le pire" % a.id
		)
		assert_eq(a.ouverts(100).size(), a.tiers.size(), "« %s » : tout est ouvert en fin de course" % a.id)


## Le cœur du jalon : le niveau d\'objet ne corrige pas des probabilités par une
## formule, il ouvre des lignes dans une table.
func test_un_objet_de_niveau_1_ne_tire_jamais_un_palier_verrouille() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 606
	var index := {}
	for a in ItemAffixPool.ALL:
		index[a.id] = a
	for nom in ["epee", "plastron", "bottes", "anneau"]:
		var base: ItemBase = load("res://resources/items/%s.tres" % nom)
		for i in 300:
			for tire in ItemAffixPool.roll(rng, base, 1):
				var a: ItemAffix = index[tire.affix_id]
				var palier: ItemAffixTier = a.tiers[tire.tier - 1]
				assert_lte(
					palier.niveau_requis, 1,
					"« %s » a sorti son T%d sur un objet de niveau 1" % [a.id, tire.tier]
				)


## Et l\'inverse, sans quoi le test précédent passerait avec une réserve vide :
## à haut niveau, **tous** les paliers sortent, le meilleur comme les pires.
## Garder les mauvais est la règle — sinon le niveau d\'objet serait une
## garantie et il n\'y aurait plus rien à espérer en regardant tomber un objet.
func test_a_haut_niveau_tous_les_paliers_sont_atteignables() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8080
	var vigoureux: ItemAffix = load("res://resources/item_affixes/vigoureux.tres")
	var vus := {}
	for i in 4000:
		vus[vigoureux.roll(rng, 60).tier] = true
	assert_eq(
		vus.size(), vigoureux.tiers.size(),
		"les %d paliers doivent tous pouvoir sortir, %d vus" % [vigoureux.tiers.size(), vus.size()]
	)


## La promesse du jalon, mesurée plutôt que déclarée : descendre plus bas
## rapporte mieux. Ce n\'est pas une garantie objet par objet — les mauvais
## paliers sortent encore — mais la moyenne doit bouger, et franchement.
func test_un_objet_de_haut_niveau_tire_mieux_en_moyenne() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	var vigoureux: ItemAffix = load("res://resources/item_affixes/vigoureux.tres")
	var bas := 0.0
	var haut := 0.0
	for i in 2000:
		bas += vigoureux.roll(rng, 1).mod.value
		haut += vigoureux.roll(rng, 60).mod.value
	assert_gt(haut, bas * 3.0, "moyennes : %.1f au niveau 1, %.1f au niveau 60" % [bas / 2000.0, haut / 2000.0])


## Sans provenance, l\'infobulle des tiers ne peut rien montrer — et elle ne doit
## surtout pas la déduire de la valeur : deux paliers voisins se chevauchent.
func test_un_affixe_tire_retient_sa_provenance() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var epee: ItemBase = load("res://resources/items/epee.tres")
	var vus := 0
	for i in 200:
		for tire in ItemAffixPool.roll(rng, epee, 45):
			vus += 1
			assert_true(tire.connu(), "un affixe fraîchement tiré sait d\'où il vient")
			assert_false(tire.affix_id.is_empty())
			assert_between(tire.tier, 1, 9, "un numéro de palier plausible")
	assert_gt(vus, 0, "encore faut-il que quelque chose ait été tiré")


## Un affixe dont même le dernier palier demande plus que le niveau de l\'objet
## n\'est pas dans la réserve. Rendre null plutôt qu\'un palier au rabais : c\'est
## l\'appelant qui décide, et `eligible` l\'a déjà écarté.
func test_un_affixe_sans_palier_ouvert_ne_tire_rien() -> void:
	var a := ItemAffix.new()
	a.id = "tardif"
	var t := ItemAffixTier.new()
	t.niveau_requis = 50
	a.tiers = [t]
	assert_eq(a.niveau_minimum(), 50)
	assert_true(a.ouverts(10).is_empty())
	assert_null(a.roll(RandomNumberGenerator.new(), 10))


## L\'arrondi appartient à l\'affixe, pas au palier. La règle d\'avant les
## paliers le déduisait de la borne haute : les dégâts critiques, dont l\'échelle
## passe sous 1 en bas et au-dessus en haut, se seraient affichés « +0,35 » à un
## palier et « +1 » au suivant.
func test_l_arrondi_est_le_meme_a_tous_les_paliers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var sanglant: ItemAffix = load("res://resources/item_affixes/sanglant.tres")
	assert_almost_eq(sanglant.arrondi, 0.01, 0.0001, "une fraction, à tous ses paliers")
	var fractions := 0
	for i in 500:
		var tire := sanglant.roll(rng, 60)
		var v: float = tire.mod.value
		assert_almost_eq(v, snappedf(v, 0.01), 0.0001, "arrondi au centième")
		if not is_equal_approx(v, roundf(v)):
			fractions += 1
	assert_gt(fractions, 0, "et les décimales ne sont pas perdues en chemin")


## **T1 est le meilleur palier**, et le dernier numéro est le pire — 8 pour les
## PV plats, 9 pour l\'armure, 5 pour la vitesse de déplacement. C\'est la
## convention du genre, celle que l\'infobulle affichera, et celle que la
## monotonie fait respecter sans jamais la nommer : ce test-ci la nomme.
##
## Le numéro n\'est pas un champ saisi mais une **position** dans la liste, qui
## va du meilleur au pire. Écrire une échelle à l\'envers dans un `.tres` ferait
## donc du T1 le palier des premières zones, et personne ne s\'en apercevrait
## avant de survoler un objet.
func test_le_tier_1_est_le_meilleur() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for a in ItemAffixPool.ALL:
		var meilleur: ItemAffixTier = a.tiers[0]
		var pire: ItemAffixTier = a.tiers[a.tiers.size() - 1]
		var dernier: int = a.tiers.size()

		assert_gt(
			absf(meilleur.max_value), absf(pire.max_value),
			"« %s » : le T1 doit taper plus fort que le T%d" % [a.id, dernier]
		)
		assert_gt(
			meilleur.niveau_requis, pire.niveau_requis,
			"« %s » : le T1 doit être le plus exigeant" % a.id
		)
		assert_eq(pire.niveau_requis, 1, "« %s » : le T%d est celui des premières zones" % [a.id, dernier])

		# La même chose vue depuis le tirage, qui est ce que le joueur reçoit :
		# au niveau 1 il ne sort que le dernier numéro, et le T1 est le dernier
		# palier à s\'ouvrir.
		assert_eq(a.roll(rng, 1).tier, dernier, "« %s » : au niveau 1, le pire palier" % a.id)
		assert_eq(
			a.ouverts(meilleur.niveau_requis - 1).size(), dernier - 1,
			"« %s » : le T1 est le dernier à s\'ouvrir" % a.id
		)
		assert_between(a.roll(rng, 999).tier, 1, dernier, "« %s » : un numéro de palier reste dans l'échelle" % a.id)


# --------------------------------------------------------------------------
# La réserve élargie (jalon 5, étape 4)
# --------------------------------------------------------------------------

## L'inverse de `test_tout_ce_qui_se_modifie_se_lit_sur_la_fiche` : une
## statistique que la fiche annonce et qu'aucun affixe ne touche est une ligne
## qu'on regarde monter de niveau en niveau sans jamais pouvoir agir dessus.
##
## Le temps de recharge n'y est pas, et c'est voulu : il n'apparaît pas sur la
## fiche non plus. C'est la cadence de l'outil, la vitesse d'attaque est
## l'adresse de celui qui le tient, et ce sont les multiplicateurs que les
## affixes touchent — « +10 % de vitesse » se lit, « -9 % de recharge » demande
## une conversion mentale à chaque fois.
func test_chaque_statistique_de_la_fiche_est_atteignable_par_un_affixe() -> void:
	var touchees := {}
	for a in ItemAffixPool.ALL:
		touchees[a.stat] = true
	for groupe in StatsPanel.GROUPS:
		for champ in groupe[1]:
			assert_true(
				touchees.has(champ),
				"« %s » s\'affiche sur la fiche mais aucun affixe ne l\'atteint" % champ
			)


## La règle demandée : les résistances partout **sauf** sur les armes. Écrite
## avec une exclusion et aucune autorisation, donc une base ajoutée plus tard en
## hérite sans qu\'on y pense — c\'est tout l\'intérêt d\'`exclut`.
func test_les_resistances_ne_sortent_jamais_sur_une_arme() -> void:
	var armes := 0
	var autres := 0
	for base in ItemCatalog.ALL:
		var resistances := 0
		for a in ItemAffixPool.eligible(base, 60):
			if a.stat in DamageType.RESIST_FIELDS:
				resistances += 1
		if base.tags.has("weapon"):
			armes += 1
			assert_eq(resistances, 0, "« %s » est une arme" % base.display_name)
		else:
			autres += 1
			assert_eq(resistances, 5, "« %s » doit pouvoir tirer les cinq" % base.display_name)
	assert_gt(armes, 0, "il y a bien des armes dans le catalogue")
	assert_gt(autres, 0, "et des objets qui n\'en sont pas")


## Les défenses vont sur ce qui protège. Une épée qui donne des points de vie ou
## de l\'armure ferait de l\'arme un emplacement défensif de plus, et il n\'y
## aurait plus de raison de choisir entre frapper et tenir.
func test_les_defenses_ne_sortent_jamais_sur_une_arme() -> void:
	var defensifs := ["max_health", "armor", "evasion"]
	for base in ItemCatalog.ALL:
		if not base.tags.has("weapon"):
			continue
		for a in ItemAffixPool.eligible(base, 60):
			assert_false(
				a.stat in defensifs,
				"« %s » peut tirer « %s » (%s)" % [base.display_name, a.stat, a.id]
			)


## Ce que l\'étape 1 avait cassé et que celle-ci répare : la baguette avait perdu
## la mêlée sans rien recevoir en échange, et ses deux seuls affixes possibles
## étaient des critiques, qui ne s\'appliquent pas aux tirs.
func test_une_baguette_a_de_quoi_etre_offensive() -> void:
	var baguette: ItemBase = load("res://resources/items/baguette.tres")
	var stats := {}
	for a in ItemAffixPool.eligible(baguette, 1):
		stats[a.stat] = true
	assert_true(stats.has("spell_damage"), "des dégâts de sort")
	assert_true(stats.has("cast_speed"), "et une cadence")
	assert_false(stats.has("attack_damage"), "toujours pas de mêlée")
	assert_false(stats.has("attack_speed"))


## Les attributs sont les seuls affixes volontairement universels : ils ne
## servent à rien par eux-mêmes et n\'existent que par ce qu\'ils dérivent, donc
## les réserver à un emplacement n\'apprendrait rien à personne.
func test_les_attributs_sortent_partout() -> void:
	for base in ItemCatalog.ALL:
		var vus := {}
		for a in ItemAffixPool.eligible(base, 1):
			if a.stat in CharacterStats.ATTRIBUTES:
				vus[a.stat] = true
		assert_eq(
			vus.size(), CharacterStats.ATTRIBUTES.size(),
			"« %s » ne voit que %d attribut(s)" % [base.display_name, vus.size()]
		)


## Les deux étiquettes que l\'étape 5 a enfin posées. L\'armure en pourcentage
## multiplie ce que les plaques apportent, donc elle n\'a de sens que sur elles ;
## l\'esquive va aux pièces légères, qui n\'ont pas de plaques à multiplier. Les
## deux affixes visaient `armour` avant, faute de porteur pour `heavy` et
## `light` — une étiquette sans porteur est une règle qu\'on croit appliquée.
func test_l_armure_en_pourcentage_et_l_esquive_se_partagent_les_armures() -> void:
	var lourdes := 0
	var legeres := 0
	for base in ItemCatalog.ALL:
		var stats := {}
		for a in ItemAffixPool.eligible(base, 60):
			stats[a.stat] = a.percent
		if base.tags.has("heavy"):
			lourdes += 1
			assert_true(stats.has("armor"), "« %s » doit tirer de l\'armure" % base.display_name)
			assert_false(stats.has("evasion"), "« %s » ne tire pas d\'esquive" % base.display_name)
		elif base.tags.has("light"):
			legeres += 1
			assert_true(stats.has("evasion"), "« %s » doit tirer de l\'esquive" % base.display_name)
	assert_gt(lourdes, 0, "il y a bien des pièces lourdes")
	assert_gt(legeres, 0, "et des légères")
