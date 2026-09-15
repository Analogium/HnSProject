extends GutTest

## Les profils du banc d'équilibrage (jalon 13, étape 1). Reconstruits par les règles à
## chaque lancement, ils doivent redonner le même personnage, porter ce qui tombe à leur
## niveau et avoir placé tous leurs points — sinon le banc mesure un personnage que
## personne ne jouerait.


## Sans l'identifiant ni les dates, que `Personnage.nouveau()` tire à chaque appel.
func _empreinte(p: Personnage) -> String:
	var d := p.vers_dict()
	for champ in ["id", "cree_le", "joue_le"]:
		d.erase(champ)
	return JSON.stringify(d)


func test_un_profil_est_reproductible() -> void:
	for build in ProfilsDuBanc.builds():
		assert_eq(
			_empreinte(ProfilsDuBanc.personnage(build, ProfilsDuBanc.Profil.EQUIPE, 40)),
			_empreinte(ProfilsDuBanc.personnage(build, ProfilsDuBanc.Profil.EQUIPE, 40)),
			build.nom
		)


## Le jumeau négatif : une graine qui ignorerait la zone passerait le test d'au-dessus.
func test_deux_zones_ne_donnent_pas_les_memes_objets() -> void:
	var build := ProfilsDuBanc.builds()[0]
	assert_ne(
		JSON.stringify(ProfilsDuBanc.personnage(build, ProfilsDuBanc.Profil.EQUIPE, 40).vers_dict()["equipement"]),
		JSON.stringify(ProfilsDuBanc.personnage(build, ProfilsDuBanc.Profil.EQUIPE, 60).vers_dict()["equipement"])
	)


func test_les_objets_sont_ceux_qui_tombent_a_leur_niveau() -> void:
	for build in ProfilsDuBanc.builds():
		for profil in ProfilsDuBanc.Profil.values():
			var p := ProfilsDuBanc.personnage(build, profil, 60)
			var niveau := ProfilsDuBanc.niveau_d_objet(profil, 60)
			var cas := "%s %s" % [build.nom, ProfilsDuBanc.NOMS_DE_PROFIL[profil]]
			if niveau == 0:
				assert_true(p.equipement.is_empty(), cas)
				continue
			assert_eq(p.equipement.size(), EquipmentSlots.count(), "%s : tout est porté" % cas)
			for emplacement in p.equipement:
				var item: Item = p.equipement[emplacement]
				assert_true(EquipmentSlots.accepts(emplacement, item), "%s : %s" % [cas, emplacement])
				assert_eq(item.item_level, niveau, cas)
				assert_has(ItemCatalog.disponibles(niveau), item.base, "%s : %s tombe à %d" % [cas, item.base.id, niveau])
				assert_false(item.base.tags.has(build.ecarte), "%s : %s" % [cas, item.base.id])


func test_tous_les_points_sont_places() -> void:
	for build in ProfilsDuBanc.builds():
		for zone in ProfilsDuBanc.ZONES:
			for profil in ProfilsDuBanc.Profil.values():
				var p := ProfilsDuBanc.personnage(build, profil, zone)
				var cas := "%s %s zone %d" % [build.nom, ProfilsDuBanc.NOMS_DE_PROFIL[profil], zone]
				var places := 0
				for champ in p.attributs:
					places += int(p.attributs[champ])
				assert_eq(places, (p.niveau - 1) * Player.POINTS_PER_LEVEL, "%s : attributs" % cas)
				assert_eq(p.points_a_placer, 0, cas)
				assert_eq(p.ratelier.a(0).manuel.points_restants(), 0, "%s : manuel" % cas)
				assert_false(p.barre.id_de(0).is_empty(), "%s : de quoi lancer" % cas)


func test_le_niveau_attendu_croit_avec_la_zone() -> void:
	assert_eq(ProfilsDuBanc.niveau_attendu(1), Vector2i(1, 0), "rien de vidé avant la zone 1")
	var avant := 1
	for zone in ProfilsDuBanc.ZONES.slice(1):
		var niveau := ProfilsDuBanc.niveau_attendu(zone).x
		assert_gt(niveau, avant, "zone %d" % zone)
		avant = niveau
