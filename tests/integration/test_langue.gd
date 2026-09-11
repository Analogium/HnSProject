extends GutTest

## Le changement de langue en pleine partie : ce qui est déjà à l'écran se
## retraduit, sans être recréé.
##
## Les `Label` et les `Button` des scènes se retraduisent seuls — Godot s'en
## charge. Mais **tout ce que ce jeu dessine à la main** ne change qu'en
## redessinant, et ce qui **mesure** un texte une fois pour toutes garderait une
## largeur calculée dans l'autre langue. Ce sont les deux pièges du §9, et ils ne
## se voient qu'en changeant de langue devant un panneau ouvert.

var _joueur: Player
var _panneau: ManuelPanel


func before_each() -> void:
	_joueur = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_joueur)
	_panneau = ManuelPanel.new()
	_panneau.size = Vector2(210.0, 196.0)
	add_child_autofree(_panneau)
	await wait_process_frames(1)
	_panneau.bind(_joueur)
	_panneau.visible = true


## Le filet du §9 : un test qui laisse le jeu en anglais fait échouer les suivants
## loin de sa propre cause.
func after_each() -> void:
	if Settings.langue != Settings.FRANCAIS:
		Settings.depuis_dict({"langue": Settings.FRANCAIS})


## Une fiche de compétence ouverte passe à l'anglais sur place : le panneau n'est
## ni recréé, ni rouvert, et ses lignes viennent toujours du même livre.
func test_une_fiche_ouverte_se_retraduit_sans_etre_recreee() -> void:
	var livre := _livre_ouvert()
	var competence: Competence = livre.base.manuel.cases[0].competence
	var identite := _panneau.get_instance_id()

	var avant := _libelles(livre, competence)
	assert_has(avant, "coût", "en français : %s" % [avant])

	Settings.depuis_dict({"langue": Settings.ANGLAIS})
	await wait_process_frames(1)

	assert_eq(_panneau.get_instance_id(), identite, "c'est le même panneau")
	var apres := _libelles(livre, competence)
	assert_has(apres, "cost", "en anglais : %s" % [apres])
	assert_does_not_have(apres, "coût", "et plus rien de français")


## Et il **redessine** : sans la notification, la fiche garderait ses mots
## français à l'écran jusqu'au prochain survol, alors que ses données ont changé.
func test_le_panneau_redessine_au_changement_de_langue() -> void:
	_livre_ouvert()
	await wait_process_frames(1)

	var dessins := [0]
	_panneau.draw.connect(func() -> void: dessins[0] += 1)

	Settings.depuis_dict({"langue": Settings.ANGLAIS})
	await wait_process_frames(2)
	assert_gt(dessins[0], 0, "le panneau s'est repeint tout seul")


## L'étiquette au-dessus d'un ennemi mesure son texte **une fois**, à
## l'apparition. Après un changement de langue, un nom plus long resterait centré
## sur l'ancienne largeur — ou pire, resterait dans l'ancienne langue.
func test_l_etiquette_d_un_elite_se_remesure() -> void:
	var etiquette := AffixTag.new()
	add_child_autofree(etiquette)
	await wait_process_frames(1)

	var vorace: Affix = AffixPool.ALL[4]
	etiquette.set_affixes([vorace] as Array[Affix])
	var ligne: AffixTag.Ligne = etiquette._lines[0]
	assert_eq(ligne.text, "Vorace")
	var demi_largeur := ligne.half

	Settings.depuis_dict({"langue": Settings.ANGLAIS})
	await wait_process_frames(1)

	var apres: AffixTag.Ligne = etiquette._lines[0]
	assert_eq(apres.text, "Ravenous", "le nom a suivi")
	assert_ne(apres.half, demi_largeur, "et il a été re-mesuré")


## Un livre posé au râtelier, monté au plafond, avec un point placé dans sa
## première case — de quoi que la fiche ait des lignes à montrer.
func _livre_ouvert() -> Item:
	var livre := Item.new(ItemCatalog.by_id("manuel_foudre"))
	livre.manuel.gagner_experience(999999)
	livre.manuel.investir(livre.base.manuel, livre.base.manuel.cases[0].competence.id)
	_joueur.etudier(livre)
	return livre


## Les intitulés de la fiche, dans l'ordre où elle les écrit.
func _libelles(livre: Item, competence: Competence) -> PackedStringArray:
	var out := PackedStringArray()
	for ligne in _panneau._lignes_de_fiche(livre.manuel, competence):
		out.append(ligne.libelle)
	return out
