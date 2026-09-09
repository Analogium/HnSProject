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
		assert_eq(
			a.ouverts(100).size(), mini(a.tiers.size(), ItemAffix.PALIERS_OUVERTS),
			"« %s » : en fin de course, la fenêtre est pleine et pas davantage" % a.id
		)


## La fenêtre glisse : elle ne s\'ouvre pas, elle **se déplace**. Le meilleur
## palier atteint monte avec le niveau d\'objet, et le pire ouvert monte avec lui.
##
## C\'est la moitié qui manquait. Le plafond existait depuis le jalon 5 ; sans
## plancher, un objet de niveau 60 pouvait sortir le palier des premières zones,
## et le meilleur objet du jeu valait parfois moins que le premier ramassé.
func test_la_fenetre_de_paliers_glisse_avec_le_niveau() -> void:
	var acere: ItemAffix = load("res://resources/item_affixes/acere.tres")
	var precedent := acere.ouverts(1)

	for niveau in range(2, 61):
		var courant := acere.ouverts(niveau)
		assert_lte(
			courant.size(), ItemAffix.PALIERS_OUVERTS,
			"niveau %d : jamais plus que la fenêtre" % niveau
		)
		if courant.is_empty() or precedent.is_empty():
			continue
		# Les indices vont du meilleur (0) au pire : la fenêtre ne peut que
		# glisser vers le meilleur, jamais revenir en arrière.
		assert_lte(
			int(courant[0]), int(precedent[0]),
			"niveau %d : le meilleur palier ouvert ne redescend pas" % niveau
		)
		assert_lte(
			int(courant[courant.size() - 1]), int(precedent[precedent.size() - 1]),
			"niveau %d : le pire palier ouvert ne redescend pas non plus" % niveau
		)
		precedent = courant


## Vu depuis le tirage plutôt que depuis la table : le même affixe sur deux
## objets de niveaux éloignés ne peut pas rendre la même chose.
func test_un_objet_de_haut_niveau_ne_tire_plus_les_paliers_de_debut() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var acere: ItemAffix = load("res://resources/item_affixes/acere.tres")
	var dernier := acere.tiers.size()

	for i in 500:
		assert_eq(acere.roll(rng, 1).tier, dernier, "au niveau 1, le pire palier et lui seul")
		assert_lte(
			acere.roll(rng, 60).tier, ItemAffix.PALIERS_OUVERTS,
			"au niveau 60, rien sous la fenêtre"
		)


## Ce qu\'une plage de niveaux atteint, c\'est **exactement** l\'union des fenêtres
## de cette plage. Un palier de trop décrirait un objet qui ne peut pas exister,
## un de moins cacherait une sortie possible.
func test_les_paliers_atteignables_sur_une_plage_sont_l_union_des_fenetres() -> void:
	for brut in ItemAffixPool.ALL:
		var a: ItemAffix = brut
		for plage in [Vector2i(1, 22), Vector2i(34, 60)]:
			var union := a.ouverts_entre(plage.x, plage.y)
			for index in a.tiers.size():
				var atteignable := false
				for niveau in range(plage.x, plage.y + 1):
					if a.ouverts(niveau).has(index):
						atteignable = true
						break
				assert_eq(
					union.has(index), atteignable,
					"« %s » T%d entre les niveaux %d et %d" % [a.id, index + 1, plage.x, plage.y]
				)


## Le cas qui a motivé le filtrage de la fiche, écrit avec ses vrais chiffres :
## l\'épée large cesse de tomber en zone 40, et le T1 d\'« acéré » demande le
## niveau 52. Aucune épée large ne peut donc porter ce palier — l\'afficher
## décrivait un objet impossible.
func test_une_base_n_atteint_pas_un_palier_hors_de_sa_fenetre() -> void:
	var acere: ItemAffix = load("res://resources/item_affixes/acere.tres")
	var large := ItemCatalog.by_id("epee_large")
	var fenetre := ItemCatalog.fenetre_de_chute(large)

	assert_eq(acere.tiers[0].niveau_requis, 52, "le T1 d\'acéré demande le niveau 52")
	assert_eq(fenetre.y, 40, "et l\'épée large cesse de tomber en zone 40")
	assert_false(
		acere.ouverts_entre(fenetre.x, fenetre.y).has(0),
		"donc aucune épée large ne porte ce palier"
	)

	# La lame de guerre, elle, y arrive : sans ça le filtre serait simplement
	# en train de tout couper.
	var guerre := ItemCatalog.by_id("lame_de_guerre")
	assert_true(
		acere.ouverts_entre(guerre.niveau_requis, Game.NIVEAU_MAX).has(0),
		"la lame de guerre, elle, atteint le T1"
	)


## La fenêtre d\'un palier doit dire exactement ce que le tirage accepte : c\'est
## elle que la fiche de la forge affiche, et une fiche qui annonce un palier que
## le tirage refuse est pire qu\'une fiche absente.
func test_la_fenetre_d_un_palier_dit_ce_que_le_tirage_accepte() -> void:
	for brut in ItemAffixPool.ALL:
		var a: ItemAffix = brut
		for index in a.tiers.size():
			var fenetre := a.fenetre_du_palier(index, 1, Game.NIVEAU_MAX)
			assert_eq(
				fenetre.x, a.tiers[index].niveau_requis,
				"« %s » T%d ouvre à son niveau requis" % [a.id, index + 1]
			)
			assert_true(
				a.ouverts(fenetre.x).has(index),
				"« %s » T%d sort au niveau %d" % [a.id, index + 1, fenetre.x]
			)
			assert_true(
				a.ouverts(fenetre.y).has(index),
				"« %s » T%d sort encore au niveau %d" % [a.id, index + 1, fenetre.y]
			)
			if fenetre.y >= Game.NIVEAU_MAX:
				continue
			assert_false(
				a.ouverts(fenetre.y + 1).has(index),
				"« %s » T%d ne sort plus au niveau %d" % [a.id, index + 1, fenetre.y + 1]
			)


## Bornée à une plage, la fenêtre d'un palier reste dans cette plage : c'est ce
## qui permet à la fiche d'annoncer « zones 19 à 22 » sur une base qui s'arrête
## en 22, au lieu de « 19 à 51 » qu'il faut intersecter de tête.
func test_la_fenetre_d_un_palier_reste_dans_la_plage_demandee() -> void:
	var acere: ItemAffix = load("res://resources/item_affixes/acere.tres")
	var epee := ItemCatalog.by_id("epee")
	var zones := ItemCatalog.fenetre_de_chute(epee)
	assert_eq(zones, Vector2i(1, 22), "l\'épée tombe des zones 1 à 22")

	for brut in acere.ouverts_entre(zones.x, zones.y):
		var index := int(brut)
		var fenetre := acere.fenetre_du_palier(index, zones.x, zones.y)
		assert_gte(fenetre.x, zones.x, "T%d ne commence pas avant la base" % [index + 1])
		assert_lte(fenetre.y, zones.y, "T%d ne finit pas après elle" % [index + 1])
		assert_lte(fenetre.x, fenetre.y, "T%d a une fenêtre non vide" % [index + 1])

	# Et un palier hors de portée rend une fenêtre vide plutôt qu'une fenêtre
	# fausse : le T1 demande le niveau 52, l'épée s'arrête à 22.
	assert_eq(acere.fenetre_du_palier(0, zones.x, zones.y), Vector2i(0, 0))


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


## Et l\'inverse, sans quoi le test précédent passerait avec une réserve vide : à
## haut niveau, c\'est **la fenêtre entière** qui sort, le meilleur palier comme
## le moins bon des quatre. Garder plusieurs paliers ouverts est la règle — sinon
## le niveau d\'objet serait une garantie et il n\'y aurait plus rien à espérer en
## regardant tomber un objet.
##
## Ce que ce test dit maintenant et ne disait pas avant : les paliers **sous** la
## fenêtre ne sortent plus. Un objet de niveau 60 ne peut plus recevoir le T8,
## celui des premières zones.
func test_a_haut_niveau_la_fenetre_entiere_sort_et_rien_dessous() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8080
	var vigoureux: ItemAffix = load("res://resources/item_affixes/vigoureux.tres")
	var vus := {}
	for i in 4000:
		vus[vigoureux.roll(rng, 60).tier] = true

	assert_eq(
		vus.size(), ItemAffix.PALIERS_OUVERTS,
		"les %d paliers de la fenêtre sortent, %d vus" % [ItemAffix.PALIERS_OUVERTS, vus.size()]
	)
	for tier in vus:
		assert_lte(
			int(tier), ItemAffix.PALIERS_OUVERTS,
			"le T%d est sous la fenêtre d\'un objet de niveau 60" % tier
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
			a.ouverts(meilleur.niveau_requis - 1).size(),
			mini(dernier - 1, ItemAffix.PALIERS_OUVERTS),
			"« %s » : le T1 est le dernier à s\'ouvrir" % a.id
		)
		assert_false(
			a.ouverts(meilleur.niveau_requis - 1).has(0),
			"« %s » : juste en dessous, le T1 n\'est pas encore là" % a.id
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
		# « Partout sauf sur les armes » parle de ce qu'on **porte**. Un manuel se
		# lit : il ne reçoit aucun affixe, pas même universel, et l'attendre à
		# cinq résistances reviendrait à demander des résistances à un livre.
		if not EquipmentSlots.famille_equipable(base.family):
			continue
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
		# « Partout » veut dire sur tout ce qui se porte : un manuel ne reçoit rien.
		if not EquipmentSlots.famille_equipable(base.family):
			continue
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


# --------------------------------------------------------------------------
# L\'affichage des paliers (jalon 5, étape 7)
# --------------------------------------------------------------------------

func test_on_retrouve_un_affixe_par_son_identifiant() -> void:
	for a in ItemAffixPool.ALL:
		assert_eq(ItemAffixPool.by_id(a.id), a, "aller-retour sur « %s »" % a.id)
	assert_null(ItemAffixPool.by_id("affixe_de_2027"), "un affixe retiré rend null")
	assert_null(ItemAffixPool.by_id(""))


## Ce que l\'infobulle écrit à droite d\'une ligne, sous Alt : le palier et la
## fourchette **de ce palier**, pas celle de l\'affixe entier.
func test_un_affixe_tire_annonce_son_palier_et_sa_plage() -> void:
	var vigoureux: ItemAffix = load("res://resources/item_affixes/vigoureux.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 314
	var tire := vigoureux.roll(rng, 60)
	var palier: ItemAffixTier = vigoureux.tiers[tire.tier - 1]

	var texte := tire.palier_et_plage()
	assert_true(texte.begins_with("T%d" % tire.tier), "le numéro d\'abord : « %s »" % texte)
	assert_true(
		texte.contains(StatMod.range_label(
			tire.mod.stat, tire.mod.mode, palier.min_value, palier.max_value
		)),
		"puis la fourchette du palier : « %s »" % texte
	)
	assert_between(tire.mod.value, palier.min_value, palier.max_value, "et la valeur en vient")


## Un objet d\'avant les paliers n\'a pas de palier, et on ne le devine pas :
## deux paliers voisins se chevauchent, la déduction serait fausse une fois sur
## trois. Pas de colonne vaut mieux qu\'une colonne fausse.
func test_un_affixe_sans_provenance_n_affiche_pas_de_palier() -> void:
	var orphelin := RolledAffix.orphelin(StatMod.new("max_health", StatMod.Mode.FLAT, 40.0))
	assert_eq(orphelin.palier_et_plage(), "")


## Et un affixe retiré du projet depuis : sa valeur s\'applique toujours, c\'est
## son palier qui devient inaffichable.
func test_un_affixe_disparu_n_affiche_pas_de_palier() -> void:
	var perdu := RolledAffix.new("affixe_de_2027", 3, StatMod.new("armor", StatMod.Mode.FLAT, 12.0))
	assert_eq(perdu.palier_et_plage(), "")
	# Et un numéro de palier hors de l\'échelle, si une échelle raccourcit.
	var vieux := RolledAffix.new("preste", 99, StatMod.new("move_speed", StatMod.Mode.PERCENT, 5.0))
	assert_eq(vieux.palier_et_plage(), "")
