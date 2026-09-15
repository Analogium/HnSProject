extends GutTest

## La fiche de personnage. Les deux compétences de départ y ont leur ligne, parce
## qu'aucune page de manuel ne les décrit ; ces lignes doivent dire ce que le
## lancer fera, équipement compris.

var _sheet: StatsPanel
var _player: Player


func before_each() -> void:
	_player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_player)
	_sheet = StatsPanel.new()
	# Le titre est un nœud de la scène de zone, que le panneau cherche à son
	# arrivée dans l'arbre.
	var title_text := Label.new()
	title_text.name = "Title"
	_sheet.add_child(title_text)
	add_child_autofree(_sheet)
	await wait_process_frames(1)
	_sheet.bind(_player)


func _per_cast(id: String) -> String:
	var cast := _player.resolve(SkillCatalog.by_id(id), _player.skill_points(id))
	return SkillStats.readable_range(cast.total_min(), cast.total_max())


## Chaque ligne vient de la résolution du lancer. Une épée monte l'attaque et
## laisse le trait tel quel : c'est la séparation des attaques et des sorts, à
## l'endroit où le joueur la cherche.
func test_starting_skills_have_their_damage_resolved() -> void:
	var bare_attack := _sheet._value_of(SkillCatalog.ID_ATTACK)
	var bare_bolt := _sheet._value_of(SkillCatalog.ID_BOLT)
	assert_eq(bare_attack, _per_cast(SkillCatalog.ID_ATTACK))
	assert_eq(bare_bolt, _per_cast(SkillCatalog.ID_BOLT))

	_player.equip(Item.new(ItemCatalog.by_id("sword")))
	assert_ne(_sheet._value_of(SkillCatalog.ID_ATTACK), bare_attack, "l'épée monte l'attaque")
	assert_eq(
		_sheet._value_of(SkillCatalog.ID_ATTACK), _per_cast(SkillCatalog.ID_ATTACK)
	)
	assert_eq(_sheet._value_of(SkillCatalog.ID_BOLT), bare_bolt, "et ne touche pas au trait")


## `bewitched` vise `spell` : la baguette qui le porte monte le trait de ce qu'elle
## annonce, et laisse l'attaque telle quelle.
func test_a_spell_damage_percentage_only_raises_the_bolt() -> void:
	var starting_bolt := SkillCatalog.by_id(SkillCatalog.ID_BOLT)
	var points := _player.skill_points(SkillCatalog.ID_BOLT)
	var bare := _player.resolve(starting_bolt, points)
	var bare_attack := _per_cast(SkillCatalog.ID_ATTACK)

	_player.equip(Item.new(
		ItemCatalog.by_id("wand"), [ItemAffixPool.by_id("bewitched").modifier(40.0)]
	))
	var bewitched := _player.resolve(starting_bolt, points)
	assert_almost_eq(bewitched.total_max(), bare.total_max() * 1.4, 1e-4, "+40 % au trait")
	assert_almost_eq(bewitched.total_min(), bare.total_min() * 1.4, 1e-4)
	assert_eq(_per_cast(SkillCatalog.ID_ATTACK), bare_attack, "et rien à l'attaque")


## L'intitulé est le nom que le joueur lit sur la barre, pas l'identifiant : la
## compétence de tir s'appelle « Trait » à l'écran.
func test_lines_carry_the_skill_names() -> void:
	assert_eq(
		_sheet._label_of(SkillCatalog.ID_ATTACK),
		SkillCatalog.by_id(SkillCatalog.ID_ATTACK).name.to_lower()
	)
	assert_eq(
		_sheet._label_of(SkillCatalog.ID_BOLT),
		SkillCatalog.by_id(SkillCatalog.ID_BOLT).name.to_lower()
	)
	assert_eq(_sheet._label_of("armor"), StatMod.LABELS["armor"], "une statistique garde le sien")


## Le dessin traverse la fiche entière, les deux lignes de compétence comprises.
func test_drawing_does_not_crash() -> void:
	_sheet.toggle()
	_sheet.queue_redraw()
	await wait_process_frames(2)
	_sheet.toggle()
	assert_true(true, "aucun plantage au dessin")
