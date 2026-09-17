extends RefCounted

## L'arme qu'exige une compétence, **sans implicite** : un test qui lance n'a pas à voir
## sa fiche changer pour autant.


static func bare(caster: bool) -> Item:
	var base := ItemBase.new()
	base.tags = PackedStringArray([ItemBase.WEAPON_FAMILY, ItemBase.CASTER_TAG if caster else "melee"])
	# Non nulle : un test de critique multiplie cette base.
	base.crit_chance = 0.05
	return Item.new(base)


static func arm(player: Player, skill_id: String) -> void:
	var caster := SkillCatalog.by_id(skill_id).cadence == Skill.Cadence.CAST
	player.equip(bare(caster), EquipmentSlots.WEAPON)
