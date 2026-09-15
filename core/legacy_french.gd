class_name LegacyFrench

## Les noms français d'avant la traduction du code, tels qu'ils restent sur les disques
## des joueurs : sauvegardes jusqu'à la version 5, réglages, dossiers. **Figés** — un
## renommage futur s'ajoute ailleurs, jamais ici. Une feuille.

const SAVE_FOLDER := "user://personnages"
const SETTINGS_FILE := "user://reglages.json"

const SETTINGS_KEYS := {
	"barres_de_vie": "health_bars",
	"degats_infliges": "damage_dealt",
	"degats_subis": "damage_taken",
	"echelle": "scale_factor",
	"langue": "language",
	"noms_d_affixes": "affix_names",
}

## Les champs d'un personnage et de ses objets.
const SAVE_KEYS := {
	"affixe": "affix",
	"attributs": "attributes",
	"barre": "bar",
	"cellule": "cell",
	"cree_le": "created_on",
	"equipement": "equipment",
	"joue_le": "played_on",
	"manuel": "manual",
	"manuel_offert": "manual_given",
	"niveau": "level",
	"nom": "name",
	"points_a_placer": "unspent_points",
	"portee": "scope",
	"ratelier": "rack",
	"sac": "bag",
	"valeur": "value",
	"valeur_max": "value_max",
}

## Bases, affixes, compétences, passifs, nœuds, statistiques et mots-clés.
const IDS := {
	"allonge": "reach",
	"amulette": "amulet",
	"anneau": "ring",
	"armes": "weapons",
	"attaque": "attack",
	"bague_ouvragee": "ornate_ring",
	"baguette": "wand",
	"baudrier": "baldric",
	"blinde": "armored",
	"bottes": "boots",
	"bottes_cloutees": "studded_boots",
	"bottes_de_marche": "travel_boots",
	"bouclier": "shield",
	"boule_de_feu": "fireball",
	"boule_de_feu_attisement": "fireball_stoking",
	"boule_de_feu_double_langue": "fireball_forked_tongue",
	"boule_de_feu_souffle_ardent": "fireball_searing_breath",
	"capuche": "hood",
	"capuche_de_maitre": "masters_hood",
	"casque": "helmet",
	"ceinture": "belt",
	"ceinturon": "girdle",
	"chaine_d_eclairs": "chain_lightning",
	"chaine_d_eclairs_court_circuit": "chain_lightning_short_circuit",
	"chaine_d_eclairs_haute_tension": "chain_lightning_high_voltage",
	"chaine_d_eclairs_ramification": "chain_lightning_branching",
	"chevaliere": "signet_ring",
	"cibles": "targets",
	"coeur_de_braise": "heart_of_embers",
	"conducteur": "conductor",
	"cotte_de_mailles": "chainmail",
	"coup_en_croix": "cross_slash",
	"coup_en_croix_estoc": "cross_slash_thrust",
	"coup_en_croix_lame_sainte": "cross_slash_holy_blade",
	"coup_en_croix_taille": "cross_slash_edge",
	"cuirasse": "cuirassed",
	"dague": "dagger",
	"degats": "damage",
	"degats_feu": "damage_fire",
	"degats_foudre": "damage_lightning",
	"degats_froid": "damage_cold",
	"degats_necrotique": "damage_necrotic",
	"degats_physique": "damage_physical",
	"degats_sacre": "damage_holy",
	"duree": "duration",
	"eclair_vif": "swift_bolt",
	"eclair_vif_fourche": "swift_bolt_fork",
	"eclair_vif_surcharge": "swift_bolt_overload",
	"eclair_vif_trait_de_glace": "swift_bolt_glacial_bolt",
	"ecu": "kite_shield",
	"embaume": "embalmed",
	"ensorcele": "bewitched",
	"epee": "sword",
	"epee_large": "broadsword",
	"epee_spirale": "spiral_sword",
	"epee_spirale_endurance": "spiral_sword_endurance",
	"epee_spirale_ronde": "spiral_sword_round",
	"epee_spirale_tranchant": "spiral_sword_sharpness",
	"erudit": "erudite",
	"feu": "fire",
	"feu_aux_attaques": "fire_to_attacks",
	"feu_aux_sorts": "fire_to_spells",
	"foudre": "lightning",
	"foudre_aux_attaques": "lightning_to_attacks",
	"foudre_aux_sorts": "lightning_to_spells",
	"fourchu": "forked",
	"frappe_lourde": "heavy_strike",
	"frappe_lourde_elan": "heavy_strike_momentum",
	"frappe_lourde_lame_ardente": "heavy_strike_burning_blade",
	"frappe_lourde_saignee": "heavy_strike_bloodletting",
	"froid": "cold",
	"froid_aux_attaques": "cold_to_attacks",
	"froid_aux_sorts": "cold_to_spells",
	"fuyant": "elusive",
	"gants": "gloves",
	"gants_de_maitre": "masters_gloves",
	"gants_renforces": "reinforced_gloves",
	"garde_de_fer": "iron_guard",
	"givre": "frosted",
	"harnois": "full_plate",
	"heaume": "great_helm",
	"ignifuge": "fireproof",
	"immolation_brasier": "immolation_blaze",
	"immolation_flamme_noire": "immolation_black_flame",
	"immolation_fournaise": "immolation_furnace",
	"impie": "unholy",
	"incantateur": "incanting",
	"isole": "insulated",
	"justaucorps": "jerkin",
	"lame_de_guerre": "war_blade",
	"limpide": "lucid",
	"manuel_armes": "manual_weapons",
	"manuel_feu": "manual_fire",
	"manuel_foudre": "manual_lightning",
	"marteau_de_guerre": "war_hammer",
	"masse": "mace",
	"masse_d_armes": "battle_mace",
	"muscle": "muscular",
	"necrotique": "necrotic",
	"necrotique_aux_attaques": "necrotic_to_attacks",
	"necrotique_aux_sorts": "necrotic_to_spells",
	"nova_de_foudre": "lightning_nova",
	"nova_de_foudre_celerite": "lightning_nova_celerity",
	"nova_de_foudre_couronne": "lightning_nova_crown",
	"nova_de_foudre_deflagration": "lightning_nova_blast",
	"nuage_d_orage": "storm_cloud",
	"nuage_d_orage_front": "storm_cloud_front",
	"nuage_d_orage_grele": "storm_cloud_hail",
	"nuage_d_orage_orage_durable": "storm_cloud_lingering_storm",
	"orageux": "stormy",
	"pavois": "pavise",
	"pendentif": "pendant",
	"physique": "physical",
	"physique_aux_attaques": "physical_to_attacks",
	"physique_aux_sorts": "physical_to_spells",
	"plaque": "plated",
	"plastron": "breastplate",
	"preste": "nimble",
	"rayon": "radius",
	"regenerant": "regenerating",
	"robuste": "sturdy",
	"sacre": "holy",
	"sacre_aux_attaques": "holy_to_attacks",
	"sacre_aux_sorts": "holy_to_spells",
	"sagace": "shrewd",
	"sanglant": "bloody",
	"sceptre": "scepter",
	"sceptre_runique": "runic_scepter",
	"serpent_infernal": "hell_snake",
	"serpent_infernal_crocs": "hell_snake_fangs",
	"serpent_infernal_longue_vie": "hell_snake_long_life",
	"serpent_infernal_mue": "hell_snake_molting",
	"sifflant": "whistling",
	"simultanes": "simultaneous",
	"sort": "spell",
	"tir": "bolt",
	"tunique": "tunic",
	"veloce": "swift",
	"vif": "quick",
	"vigoureux": "vigorous",
	"vitesse_de_projectile": "projectile_speed",
	"vorace": "ravenous",
}

## Du texte libre, jamais traduit : un personnage a le droit de s'appeler « epee ».
const FREE_VALUES := ["name", "id", "created_on", "played_on"]


## Un personnage d'avant la version 6, clés et identifiants en anglais ; le reste est
## rendu tel quel, `Character.from_dict()` le vérifie ensuite comme tout le reste.
static func save(source: Variant, key := "") -> Variant:
	if source is Dictionary:
		var out := {}
		for k: String in source:
			var english: String = SAVE_KEYS.get(k, IDS.get(k, k))
			out[english] = save(source[k], english)
		return out
	if source is Array:
		return (source as Array).map(func(v: Variant) -> Variant: return save(v, key))
	if source is String and not FREE_VALUES.has(key):
		return IDS.get(source, source)
	return source


static func settings(source: Dictionary) -> Dictionary:
	var out := {}
	for k: String in source:
		out[SETTINGS_KEYS.get(k, k)] = source[k]
	return out


## Avant toute lecture : l'ancien dossier prend le nouveau nom. S'ils existent tous les
## deux, on ne touche à rien — fusionner risquerait d'écraser un personnage.
static func move_save_folder(folder: String) -> void:
	if DirAccess.dir_exists_absolute(SAVE_FOLDER) and not DirAccess.dir_exists_absolute(folder):
		DirAccess.rename_absolute(SAVE_FOLDER, folder)
