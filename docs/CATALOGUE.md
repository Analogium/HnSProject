# Référence des données

<!-- Fichier généré par tools/catalogue.sh — ne pas éditer à la main. -->

45 bases d'objets, 21 compétences, 52 affixes d'objets, 5 affixes d'ennemis.

Deux règles ne se lisent dans aucun `.tres`, et il faut les avoir en tête
pour lire les tables :

- **la colonne « tombe en zones » est calculée.** Une base tombe de son
  `required_level` jusqu'à **6 niveaux** après l'ouverture du palier suivant
  de sa lignée (`ItemCatalog.READING_MARGIN`). Insérer un palier au milieu
  d'une lignée raccourcit donc celui d'avant ;
- **tous les paliers d'un affixe ne sortent jamais ensemble.** Un objet n'en a
  que **4** d'ouverts à la fois — le meilleur qu'il atteint et les 3 du
  dessous (`ItemAffix.OPEN_TIERS`). La colonne « ouvre à » des échelles
  donne le plancher, pas la garantie.

Niveaux de zone : 1 à 120.

## Bases d'objets

| id | nom | lignée | palier | famille | étiquettes | implicite | critique | cases | tombe en zones |
|---|---|---|---|---|---|---|---|---|---|
| `sword` | Épée | blade | 1 | weapon | weapon, melee, blade | ajoute 2 à 6 dégâts physiques aux attaques | 10 % | 1 × 3 | 1 à 22 |
| `broadsword` | Épée large | blade | 2 | weapon | weapon, melee, blade | ajoute 5 à 13 dégâts physiques aux attaques | 10 % | 1 × 3 | 16 à 40 |
| `war_blade` | Lame de guerre | blade | 3 | weapon | weapon, melee, blade | ajoute 8 à 24 dégâts physiques aux attaques | 10 % | 1 × 3 | 34 et au-delà |
| `dagger` | Dague | dagger | 1 | weapon | weapon, melee, blade | +10 % de vitesse d'attaque accrue | 10 % | 1 × 2 | 1 à 30 |
| `misericorde` | Miséricorde | dagger | 2 | weapon | weapon, melee, blade | +18 % de vitesse d'attaque accrue | 10 % | 1 × 2 | 24 et au-delà |
| `mace` | Masse | contondante | 1 | weapon | weapon, melee, blunt | ajoute 3 à 9 dégâts physiques aux attaques | 10 % | 1 × 3 | 6 à 28 |
| `battle_mace` | Masse d'armes | contondante | 2 | weapon | weapon, melee, blunt | ajoute 6 à 18 dégâts physiques aux attaques | 10 % | 1 × 3 | 22 à 46 |
| `war_hammer` | Marteau de guerre | contondante | 3 | weapon | weapon, melee, blunt | ajoute 10 à 32 dégâts physiques aux attaques | 10 % | 1 × 3 | 40 et au-delà |
| `wand` | Baguette | focus | 1 | weapon | weapon, caster | +15 % de vitesse d'incantation accrue | 5 % | 1 × 2 | 1 à 24 |
| `scepter` | Sceptre | focus | 2 | weapon | weapon, caster | +24 % de vitesse d'incantation accrue | 5 % | 1 × 2 | 18 à 42 |
| `runic_scepter` | Sceptre runique | focus | 3 | weapon | weapon, caster | +34 % de vitesse d'incantation accrue | 5 % | 1 × 2 | 36 et au-delà |
| `shield` | Bouclier | shield | 1 | offhand | offhand, armour, heavy | +18 armure | — | 2 × 2 | 1 à 21 |
| `kite_shield` | Écu | shield | 2 | offhand | offhand, armour, heavy | +38 armure | — | 2 × 2 | 15 à 39 |
| `pavise` | Pavois | shield | 3 | offhand | offhand, armour, heavy | +68 armure | — | 2 × 2 | 33 et au-delà |
| `grimoire` | Grimoire | grimoire | 1 | offhand | offhand, caster | ajoute 3 à 7 dégâts de foudre aux sorts | — | 2 × 2 | 10 à 34 |
| `codex` | Codex | grimoire | 2 | offhand | offhand, caster | ajoute 6 à 16 dégâts de foudre aux sorts | — | 2 × 2 | 28 et au-delà |
| `helmet` | Casque | casque_lourd | 1 | helmet | helmet, armour, heavy | +12 PV | — | 2 × 2 | 1 à 20 |
| `great_helm` | Heaume | casque_lourd | 2 | helmet | helmet, armour, heavy | +26 PV | — | 2 × 2 | 14 à 38 |
| `armet` | Armet | casque_lourd | 3 | helmet | helmet, armour, heavy | +44 PV | — | 2 × 2 | 32 et au-delà |
| `hood` | Capuche | casque_leger | 1 | helmet | helmet, armour, light | +14 esquive | — | 2 × 2 | 1 à 26 |
| `masters_hood` | Capuche de maître | casque_leger | 2 | helmet | helmet, armour, light | +34 esquive | — | 2 × 2 | 20 et au-delà |
| `breastplate` | Plastron | torse_lourd | 1 | chest | chest, armour, heavy | +20 PV | — | 2 × 3 | 1 à 23 |
| `chainmail` | Cotte de mailles | torse_lourd | 2 | chest | chest, armour, heavy | +42 PV | — | 2 × 3 | 17 à 41 |
| `full_plate` | Harnois | torse_lourd | 3 | chest | chest, armour, heavy | +72 PV | — | 2 × 3 | 35 et au-delà |
| `tunic` | Tunique | torse_leger | 1 | chest | chest, armour, light | +20 esquive | — | 2 × 3 | 1 à 25 |
| `jerkin` | Justaucorps | torse_leger | 2 | chest | chest, armour, light | +46 esquive | — | 2 × 3 | 19 et au-delà |
| `gloves` | Gants | gloves | 1 | gloves | gloves, armour, light | +8 % de vitesse d'attaque accrue | — | 2 × 2 | 1 à 19 |
| `reinforced_gloves` | Gants renforcés | gloves | 2 | gloves | gloves, armour, light | +14 % de vitesse d'attaque accrue | — | 2 × 2 | 13 à 37 |
| `masters_gloves` | Gants de maître | gloves | 3 | gloves | gloves, armour, light | +21 % de vitesse d'attaque accrue | — | 2 × 2 | 31 et au-delà |
| `boots` | Bottes | boots | 1 | boots | boots, armour, light | +8 vitesse | — | 2 × 2 | 1 à 18 |
| `studded_boots` | Bottes cloutées | boots | 2 | boots | boots, armour, light | +14 vitesse | — | 2 × 2 | 12 à 36 |
| `travel_boots` | Bottes de marche | boots | 3 | boots | boots, armour, light | +20 vitesse | — | 2 × 2 | 30 et au-delà |
| `belt` | Ceinture | belt | 1 | belt | belt | +1.5 PV/s | — | 2 × 1 | 1 à 17 |
| `girdle` | Ceinturon | belt | 2 | belt | belt | +3 PV/s | — | 2 × 1 | 11 à 35 |
| `baldric` | Baudrier | belt | 3 | belt | belt | +5 PV/s | — | 2 × 1 | 29 et au-delà |
| `amulet` | Amulette | amulet | 1 | amulet | amulet, jewellery | +15 mana | — | 1 × 1 | 1 à 23 |
| `talisman` | Talisman | amulet | 2 | amulet | amulet, jewellery | +34 mana | — | 1 × 1 | 17 à 41 |
| `pendant` | Pendentif | amulet | 3 | amulet | amulet, jewellery | +58 mana | — | 1 × 1 | 35 et au-delà |
| `ring` | Anneau | ring | 1 | ring | ring, jewellery | +8 % de chance critique de base accrue | — | 1 × 1 | 1 à 22 |
| `ornate_ring` | Bague ouvragée | ring | 2 | ring | ring, jewellery | +14 % de chance critique de base accrue | — | 1 × 1 | 16 à 40 |
| `signet_ring` | Chevalière | ring | 3 | ring | ring, jewellery | +20 % de chance critique de base accrue | — | 1 × 1 | 34 et au-delà |
| `manual_lightning` | Manuel de la foudre | manual_lightning | 1 | manual | manual | — | — | 2 × 2 | 1 et au-delà |
| `manual_weapons` | Manuel du chevalier | manual_weapons | 1 | manual | manual | — | — | 2 × 2 | 1 et au-delà |
| `manual_fire` | Manuel des flammes | manual_fire | 1 | manual | manual | — | — | 2 × 2 | 5 et au-delà |
| `manual_cold` | Manuel du froid | manual_cold | 1 | manual | manual | — | — | 2 × 2 | 10 et au-delà |

## Manuels

Un manuel gagne **un point par niveau**, 20 au plafond
(`Manual.MAX_LEVEL`), et ses cases, ses passifs et ses nœuds se servent
dans le même sac : la colonne « points » dit ce que chacun accepte, et leur
somme dépasse volontairement ce qu'un livre peut gagner.

### Maître de la foudre — `manual_lightning`

| case | sorte | ouvre à | points | coût | cadence | forme | par point |
|---|---|---|---|---|---|---|---|
| Éclair vif | sort foudre | niveau 1 | 5 | 8 mana | 0.42 s | bolt | 21 · 27 · 34 · 42 · 51 |
| Chaîne d'éclairs | sort foudre | niveau 3 | 5 | 12 mana | 0.70 s | chain · 3 cibles | 17 · 22 · 28 · 35 · 43 |
| Nuage d'orage | sort foudre | niveau 5 | 5 | 22 mana | 1.60 s | cloud · 3.0 s · rayon 34 · toutes les 0.50 s | 9 · 11 · 14 · 17 · 21 |
| Ruée d'orage | sort foudre | niveau 5 | 4 | 10 mana | 0.35 s · recharge 2.00 s | dash · 2.0 s | Appel du tonnerre : +5 % de vitesse accrue |
| Conducteur | passif | niveau 2 | 4 | — | — | — | +6 % de dégâts de foudre accrus · +10 mana |
| Électricité statique | sort foudre | niveau 12 | 4 | 0 mana | recharge 0.60 s | buff · draine 1 mana/s | Champ statique : +5 % chance de charge statique |

| nœud | compétence | parent | demande | points | par point |
|---|---|---|---|---|---|
| Surcharge | Éclair vif | — | 1 point de compétence | 3 | +12 % de dégâts amplifiés |
| Fourche | Éclair vif | Surcharge | 2 points de compétence | 1 | +1 nombre de projectiles |
| Trait de glace | Éclair vif | — | 3 points de compétence | 1 | +20 % de dégâts amplifiés · convertit 50 % en froid |
| Ramification | Chaîne d'éclairs | — | 1 point de compétence | 2 | +1 nombre de cibles |
| Haute tension | Chaîne d'éclairs | Ramification | 2 points de compétence | 3 | +12 % de dégâts amplifiés |
| Court-circuit | Chaîne d'éclairs | — | 3 points de compétence | 1 | -1 nombre de cibles · +35 % de dégâts amplifiés |
| Front orageux | Nuage d'orage | — | 1 point de compétence | 2 | +20 % de rayon accru |
| Orage durable | Nuage d'orage | Front orageux | 2 points de compétence | 2 | +25 % de durée accrue |
| Grêle | Nuage d'orage | — | 3 points de compétence | 1 | +15 % de dégâts amplifiés · convertit 60 % en froid |
| Persistance | Ruée d'orage | — | 1 point de compétence | 2 | +25 % de durée accrue |

45 destinations de points pour 20 gagnés.

### Maître chevalier — `manual_weapons`

| case | sorte | ouvre à | points | coût | cadence | forme | par point |
|---|---|---|---|---|---|---|---|
| Frappe lourde | attaque physique | niveau 1 | 5 | 6 mana | cadence de l'arme | strike | 20 · 26 · 33 · 41 · 50 |
| Coup en croix | attaque physique | niveau 3 | 5 | 7 mana | cadence de l'arme | cross | 13 · 17 · 21 · 26 · 32 |
| Épée spirale | attaque physique | niveau 6 | 5 | 10 mana | cadence de l'arme | orbit · 5.0 s · toutes les 0.50 s · 3 au plus | 8 · 10 · 13 · 16 · 20 |
| Vague tranchante | attaque physique | niveau 4 | 5 | 8 mana | cadence de l'arme | wave · 0.5 s · rayon 20 | 11 · 14 · 18 · 22 · 27 |
| Cyclone | attaque physique | niveau 8 | 5 | 0 mana | cadence de l'arme | cyclone · rayon 34 · toutes les 0.35 s · draine 10 mana/s | 7 · 9 · 11 · 14 · 17 |
| Garde de fer | passif | niveau 2 | 4 | — | — | — | +12 armure · +14 PV |

| nœud | compétence | parent | demande | points | par point |
|---|---|---|---|---|---|
| Élan | Frappe lourde | — | 1 point de compétence | 3 | +14 % de dégâts amplifiés |
| Lame ardente | Frappe lourde | Élan | 2 points de compétence | 1 | convertit 40 % en feu · donne le mot-clé Feu |
| Saignée | Frappe lourde | — | 2 points de compétence | 2 | ajoute 3 à 8 dégâts physiques |
| Taille | Coup en croix | — | 1 point de compétence | 3 | +12 % de dégâts amplifiés |
| Estoc | Coup en croix | Taille | 2 points de compétence | 2 | ajoute 2 à 6 dégâts physiques |
| Lame sainte | Coup en croix | — | 3 points de compétence | 1 | convertit 50 % en sacré |
| Ronde | Épée spirale | — | 1 point de compétence | 2 | +1 maximum simultané |
| Tranchant | Épée spirale | Ronde | 2 points de compétence | 3 | +12 % de dégâts amplifiés |
| Endurance | Épée spirale | — | 2 points de compétence | 2 | +30 % de durée accrue |
| Fil de l'arc | Vague tranchante | — | 1 point de compétence | 3 | +12 % de dégâts amplifiés |
| Course | Vague tranchante | Fil de l'arc | 2 points de compétence | 2 | +25 % de durée accrue |
| Fauchage | Cyclone | — | 1 point de compétence | 3 | +10 % de dégâts amplifiés |
| Envergure | Cyclone | Fauchage | 2 points de compétence | 2 | +12 % de rayon accru |

58 destinations de points pour 20 gagnés.

### Maître des flammes — `manual_fire`

| case | sorte | ouvre à | points | coût | cadence | forme | par point |
|---|---|---|---|---|---|---|---|
| Boule de feu | sort feu | niveau 1 | 5 | 11 mana | 0.60 s | ball · rayon 20 | 30 · 38 · 48 · 59 · 73 |
| Serpent infernal | sort feu | niveau 4 | 5 | 18 mana | 1.20 s | snake · 4.0 s · toutes les 0.40 s | 10 · 13 · 16 · 20 · 25 |
| Immolation | sort feu | niveau 9 | 5 | 25 mana | recharge 1.00 s | aura · rayon 40 · toutes les 0.50 s · brûle 3 % PV/s · adossé aux PV 0.8 % | 8 · 10 · 13 · 16 · 20 |
| Ruée ardente | sort feu | niveau 5 | 5 | 12 mana | 0.50 s · recharge 4.00 s | dash · 3.0 s · rayon 16 · toutes les 0.50 s | 4 · 5 · 6 · 8 · 10 |
| Cœur de braise | passif | niveau 2 | 4 | — | — | — | +7 % de dégâts de feu accrus · +3 % rés. feu |
| Ignition | sort feu | niveau 12 | 4 | 0 mana | recharge 0.60 s | buff · brûle 1 % PV/s | Combustion : +13 % chance d'embraser · +8 % de vitesse accrue |

| nœud | compétence | parent | demande | points | par point |
|---|---|---|---|---|---|
| Attisement | Boule de feu | — | 1 point de compétence | 3 | +13 % de dégâts amplifiés |
| Souffle ardent | Boule de feu | Attisement | 2 points de compétence | 2 | +30 % de rayon accru |
| Double langue | Boule de feu | — | 3 points de compétence | 1 | +1 nombre de projectiles |
| Longue vie | Serpent infernal | — | 1 point de compétence | 2 | +25 % de durée accrue |
| Crocs | Serpent infernal | Longue vie | 2 points de compétence | 2 | ajoute 4 à 9 dégâts de feu |
| Mue | Serpent infernal | — | 2 points de compétence | 3 | +12 % de dégâts amplifiés |
| Brasier | Immolation | — | 1 point de compétence | 2 | +20 % de rayon accru |
| Fournaise | Immolation | Brasier | 2 points de compétence | 3 | +14 % de dégâts amplifiés |
| Flamme noire | Immolation | — | 3 points de compétence | 1 | +15 % de dégâts amplifiés · convertit 50 % en nécrotique |
| Sillage | Ruée ardente | — | 1 point de compétence | 2 | +25 % de durée accrue |
| Braises | Ruée ardente | Sillage | 2 points de compétence | 2 | +20 % de rayon accru |
| Bûcher | Ruée ardente | — | 2 points de compétence | 3 | +12 % de dégâts amplifiés |

54 destinations de points pour 20 gagnés.

### Maître du froid — `manual_cold`

| case | sorte | ouvre à | points | coût | cadence | forme | par point |
|---|---|---|---|---|---|---|---|
| Pics de glace | sort froid | niveau 1 | 5 | 14 mana | 0.70 s | spikes · rayon 26 | 10 · 13 · 16 · 20 · 25 |
| Nova de glace | sort froid | niveau 3 | 5 | 20 mana | 1.10 s | nova · rayon 46 · +50 % de chance d'état | 12 · 15 · 19 · 24 · 30 |
| Tombeau de glace | sort froid | niveau 8 | 4 | 25 mana | recharge 0.60 s | buff · 3.0 s · draine 3 mana/s · rend 1.7 % PV/s | Carapace de givre : -18 % dégâts subis |
| Désastre hivernal | sort froid | niveau 12 | 5 | 26 mana | 0.80 s · recharge 3.00 s | vortex · 4.0 s · rayon 52 · toutes les 0.50 s | 6 · 8 · 10 · 12 · 15 |
| Morsure du gel | passif | niveau 2 | 4 | — | — | — | +10 % chance de transir |

| nœud | compétence | parent | demande | points | par point |
|---|---|---|---|---|---|
| Éclats | Pics de glace | — | 1 point de compétence | 3 | +12 % de dégâts amplifiés |
| Poussée | Pics de glace | Éclats | 2 points de compétence | 2 | +10 % de rayon accru |
| Souffle | Nova de glace | — | 1 point de compétence | 3 | +10 % de rayon accru |
| Morsure | Nova de glace | Souffle | 2 points de compétence | 2 | +12 % de dégâts amplifiés |
| Blizzard | Désastre hivernal | — | 1 point de compétence | 2 | +20 % de durée accrue |
| Œil du cyclone | Désastre hivernal | Blizzard | 2 points de compétence | 3 | +12 % de dégâts amplifiés |

38 destinations de points pour 20 gagnés.

## Arbre de passifs

Un point par niveau après le premier (`PassiveTree.points_gained()`), 418 nœuds
hors du départ. Un nœud se prend voisin d'un nœud pris, se reprend tant qu'il ne
coupe rien. Les petits nœuds sont listés par région, dans l'ordre du fichier.

| nœud | sorte | case | voisins | effet |
|---|---|---|---|---|
| int_1 | small | 0, -3 | start, int_2 | +10 intelligence |
| int_2 | small | 0, -6 | int_1, int_3 | +10 intelligence |
| int_3 | small | 0, -8 | int_2, int_4, inner_int_dex_1, inner_str_int_3 | +10 intelligence |
| int_4 | small | 0, -10 | int_3, int_5 | +10 intelligence |
| int_5 | small | 0, -13 | int_4, int_6, blaze_1, storm_1 | +10 intelligence |
| int_6 | small | 0, -16 | int_5, int_7 | +10 intelligence |
| int_7 | small | 0, -18 | int_6, int_8, outer_int_dex_1, outer_str_int_6 | +10 intelligence |
| int_8 | small | 0, -20 | int_7, int_9 | +10 intelligence |
| int_9 | small | 0, -23 | int_8, int_10, ember_1 | +10 intelligence |
| int_10 | small | 0, -26 | int_9, storm_mind, int_bridge | +10 intelligence |
| **Esprit d'orage** `storm_mind` | keystone | 0, -29 | int_10 | +30 % de dégâts de sort amplifiés · -25 % d'armure réduite |
| dex_1 | small | 3, 1 | start, dex_2 | +10 dextérité |
| dex_2 | small | 5, 3 | dex_1, dex_3 | +10 dextérité |
| dex_3 | small | 7, 4 | dex_2, dex_4, inner_int_dex_3, inner_dex_str_1 | +10 dextérité |
| dex_4 | small | 9, 5 | dex_3, dex_5 | +10 dextérité |
| dex_5 | small | 11, 6 | dex_4, dex_6, volley_1, eye_1 | +10 dextérité |
| dex_6 | small | 13, 8 | dex_5, dex_7 | +10 dextérité |
| dex_7 | small | 16, 9 | dex_6, dex_8, outer_int_dex_6, outer_dex_str_1 | +10 dextérité |
| dex_8 | small | 18, 10 | dex_7, dex_9 | +10 dextérité |
| dex_9 | small | 20, 11 | dex_8, dex_10, frost_1 | +10 dextérité |
| dex_10 | small | 22, 13 | dex_9, hunter_eye, dex_bridge | +10 dextérité |
| **Œil du chasseur** `hunter_eye` | keystone | 25, 14 | dex_10 | +25 % de dégâts de projectile amplifiés · -20 % de PV atténués |
| str_1 | small | -3, 1 | start, str_2 | +10 force |
| str_2 | small | -5, 3 | str_1, str_3 | +10 force |
| str_3 | small | -7, 4 | str_2, str_4, inner_dex_str_3, inner_str_int_1 | +10 force |
| str_4 | small | -9, 5 | str_3, str_5 | +10 force |
| str_5 | small | -11, 6 | str_4, str_6, strike_1, flesh_1 | +10 force |
| str_6 | small | -13, 8 | str_5, str_7 | +10 force |
| str_7 | small | -16, 9 | str_6, str_8, outer_dex_str_6, outer_str_int_1 | +10 force |
| str_8 | small | -18, 10 | str_7, str_9 | +10 force |
| str_9 | small | -20, 11 | str_8, str_10, wound_1 | +10 force |
| str_10 | small | -22, 13 | str_9, colossus, str_bridge, vigor_1 | +10 force |
| **Colosse** `colossus` | keystone | -25, 14 | str_10 | +25 % de dégâts d'attaque amplifiés · -15 % de vitesse d'attaque réduite |
| inner_int_dex_1 | small | 4, -7 | int_3, inner_int_dex_2 | +5 intelligence · +5 dextérité |
| inner_int_dex_2 | small | 7, -4 | inner_int_dex_1, inner_int_dex_3 | +5 intelligence · +5 dextérité |
| inner_int_dex_3 | small | 8, 0 | inner_int_dex_2, dex_3 | +5 dextérité · +5 intelligence |
| inner_dex_str_1 | small | 4, 7 | dex_3, inner_dex_str_2 | +5 dextérité · +5 force |
| inner_dex_str_2 | small | 0, 8 | inner_dex_str_1, inner_dex_str_3 | +5 dextérité · +5 force |
| inner_dex_str_3 | small | -4, 7 | inner_dex_str_2, str_3 | +5 force · +5 dextérité |
| inner_str_int_1 | small | -8, 0 | str_3, inner_str_int_2 | +5 force · +5 intelligence |
| inner_str_int_2 | small | -7, -4 | inner_str_int_1, inner_str_int_3 | +5 force · +5 intelligence |
| inner_str_int_3 | small | -4, -7 | inner_str_int_2, int_3 | +5 intelligence · +5 force |
| outer_int_dex_1 | small | 5, -17 | int_7, outer_int_dex_2, shock_1 | +5 intelligence · +5 dextérité |
| outer_int_dex_2 | small | 10, -15 | outer_int_dex_1, outer_int_dex_3, wave_1 | +5 intelligence · +5 dextérité |
| outer_int_dex_3 | small | 14, -11 | outer_int_dex_2, outer_int_dex_4, lore_1 | +5 intelligence · +5 dextérité |
| outer_int_dex_4 | small | 17, -7 | outer_int_dex_3, outer_int_dex_5, mastery_1 | +5 dextérité · +5 intelligence |
| outer_int_dex_5 | small | 18, -1 | outer_int_dex_4, outer_int_dex_6, breath_1 | +5 dextérité · +5 intelligence |
| outer_int_dex_6 | small | 18, 4 | outer_int_dex_5, dex_7, spear_1 | +5 dextérité · +5 intelligence |
| outer_dex_str_1 | small | 12, 13 | dex_7, outer_dex_str_2 | +5 dextérité · +5 force |
| outer_dex_str_2 | small | 8, 16 | outer_dex_str_1, outer_dex_str_3, run_1 | +5 dextérité · +5 force |
| outer_dex_str_3 | small | 3, 18 | outer_dex_str_2, outer_dex_str_4, flee_1 | +5 dextérité · +5 force |
| outer_dex_str_4 | small | -3, 18 | outer_dex_str_3, outer_dex_str_5, regrowth_1 | +5 force · +5 dextérité |
| outer_dex_str_5 | small | -8, 16 | outer_dex_str_4, outer_dex_str_6, arms_1 | +5 force · +5 dextérité |
| outer_dex_str_6 | small | -12, 13 | outer_dex_str_5, str_7 | +5 force · +5 dextérité |
| outer_str_int_1 | small | -18, 4 | str_7, outer_str_int_2, reach_1 | +5 force · +5 intelligence |
| outer_str_int_2 | small | -18, -1 | outer_str_int_1, outer_str_int_3, plates_1 | +5 force · +5 intelligence |
| outer_str_int_3 | small | -17, -7 | outer_str_int_2, outer_str_int_4, deep_1 | +5 force · +5 intelligence |
| outer_str_int_4 | small | -14, -11 | outer_str_int_3, outer_str_int_5, reserve_1 | +5 intelligence · +5 force |
| outer_str_int_5 | small | -10, -15 | outer_str_int_4, outer_str_int_6, spells_1 | +5 intelligence · +5 force |
| outer_str_int_6 | small | -5, -17 | outer_str_int_5, int_7, hold_1 | +5 intelligence · +5 force |
| blaze_1 | small | -2, -13 | int_5, blaze_2, blaze_4 | +10 % de dégâts de feu accrus |
| blaze_2 | small | -4, -10 | blaze_1, blaze_3 | +10 % de dégâts de feu accrus |
| blaze_3 | small | -6, -9 | blaze_2, inner_blaze | +10 % de dégâts de feu accrus |
| **Brasier intérieur** `inner_blaze` | notable | -8, -10 | blaze_3 | +20 % de dégâts de feu accrus · +10 intelligence |
| blaze_4 | small | -4, -15 | blaze_1, blaze_5 | +12 % de dégâts de feu accrus contre les embrasés |
| blaze_5 | small | -7, -15 | blaze_4, vivid_embers | +12 % de dégâts de feu accrus contre les embrasés |
| **Cendres vives** `vivid_embers` | notable | -9, -13 | blaze_5 | +25 % de dégâts de feu accrus contre les embrasés · +10 % de dégâts de feu accrus |
| storm_1 | small | 2, -13 | int_5, storm_2, storm_4 | +10 % de dégâts de foudre accrus |
| storm_2 | small | 4, -15 | storm_1, storm_3 | +10 % de dégâts de foudre accrus |
| storm_3 | small | 7, -15 | storm_2, quick_lightning | +10 % de dégâts de foudre accrus |
| **Foudre vive** `quick_lightning` | notable | 9, -13 | storm_3 | +20 % de dégâts de foudre accrus · +6 % de vitesse d'incantation accrue |
| storm_4 | small | 4, -10 | storm_1, storm_5 | +12 % de dégâts de foudre accrus contre les engourdis |
| storm_5 | small | 6, -9 | storm_4, storm_crash | +12 % de dégâts de foudre accrus contre les engourdis |
| **Fracas d'orage** `storm_crash` | notable | 8, -10 | storm_5 | +25 % de dégâts de foudre accrus contre les engourdis · +10 % de dégâts de foudre accrus |
| spells_1 | small | -12, -17 | outer_str_int_5, spells_2, spells_6 | +8 % de dégâts de sort accrus |
| spells_2 | small | -15, -17 | spells_1, spells_3 | +8 % de dégâts de sort accrus |
| spells_3 | small | -16, -20 | spells_2, spells_4 | +8 % de dégâts de sort accrus |
| spells_4 | small | -15, -22 | spells_3, spells_5, sharp_incantation | +8 % de dégâts de sort accrus |
| spells_5 | small | -12, -23 | spells_4, spells_6 | +8 % de dégâts de sort accrus |
| spells_6 | small | -10, -20 | spells_5, spells_1 | +8 % de dégâts de sort accrus |
| **Incantation acérée** `sharp_incantation` | notable | -13, -20 | spells_4 | +20 % de dégâts de sort accrus · +10 intelligence |
| wave_1 | small | 12, -17 | outer_int_dex_2, wave_2, wave_6 | +6 % de rayon accru aux sorts |
| wave_2 | small | 10, -20 | wave_1, wave_3 | +8 % de durée accrue aux sorts |
| wave_3 | small | 12, -23 | wave_2, wave_4 | +6 % de rayon accru aux sorts |
| wave_4 | small | 15, -22 | wave_3, wave_5, wide_wave | +8 % de durée accrue aux sorts |
| wave_5 | small | 16, -20 | wave_4, wave_6 | +6 % de rayon accru aux sorts |
| wave_6 | small | 15, -17 | wave_5, wave_1 | +8 % de durée accrue aux sorts |
| **Onde large** `wide_wave` | notable | 13, -20 | wave_4 | +15 % de rayon accru aux sorts · +15 % de durée accrue aux sorts |
| reserve_1 | small | -17, -12 | outer_str_int_4, reserve_2, reserve_6 | +8 % de mana accru |
| reserve_2 | small | -19, -11 | reserve_1, reserve_3 | +0.4 mana/s |
| reserve_3 | small | -22, -12 | reserve_2, reserve_4 | +8 % de mana accru |
| reserve_4 | small | -22, -16 | reserve_3, reserve_5, mana_well | +0.4 mana/s |
| reserve_5 | small | -19, -17 | reserve_4, reserve_6 | +8 % de mana accru |
| reserve_6 | small | -17, -16 | reserve_5, reserve_1 | +0.4 mana/s |
| **Puits de mana** `mana_well` | notable | -19, -14 | reserve_4 | +20 % de mana accru · +3 mana/s |
| lore_1 | small | 17, -12 | outer_int_dex_3, lore_2, lore_6 | +4 % de vitesse d'incantation accrue |
| lore_2 | small | 17, -15 | lore_1, lore_3 | +4 % de vitesse d'incantation accrue |
| lore_3 | small | 19, -17 | lore_2, lore_4 | +4 % de vitesse d'incantation accrue |
| lore_4 | small | 22, -16 | lore_3, lore_5, arcane_lore | +4 % de vitesse d'incantation accrue |
| lore_5 | small | 22, -12 | lore_4, lore_6 | +4 % de vitesse d'incantation accrue |
| lore_6 | small | 19, -11 | lore_5, lore_1 | +4 % de vitesse d'incantation accrue |
| **Savoir des arcanes** `arcane_lore` | notable | 19, -14 | lore_4 | +1 niveau de compétence de sort · +10 intelligence |
| strike_1 | small | -12, 3 | str_5, strike_2, strike_6 | +8 % de dégâts d'attaque accrus |
| strike_2 | small | -15, 3 | strike_1, strike_3 | +8 % de dégâts d'attaque accrus |
| strike_3 | small | -16, 0 | strike_2, strike_4 | +8 % de dégâts d'attaque accrus |
| strike_4 | small | -14, -2 | strike_3, strike_5, brute_force | +8 % de dégâts d'attaque accrus |
| strike_5 | small | -11, -2 | strike_4, strike_6 | +8 % de dégâts d'attaque accrus |
| strike_6 | small | -10, 1 | strike_5, strike_1 | +8 % de dégâts d'attaque accrus |
| **Force brute** `brute_force` | notable | -13, 0 | strike_4 | +16 % de dégâts d'attaque accrus · +10 % de PV accrus |
| flesh_1 | small | -9, 8 | str_5, flesh_2, flesh_6 | +8 % de PV accrus |
| flesh_2 | small | -6, 8 | flesh_1, flesh_3 | +8 % de PV accrus |
| flesh_3 | small | -4, 10 | flesh_2, flesh_4 | +8 % de PV accrus |
| flesh_4 | small | -5, 13 | flesh_3, flesh_5, sturdy_blood | +8 % de PV accrus |
| flesh_5 | small | -8, 13 | flesh_4, flesh_6 | +8 % de PV accrus |
| flesh_6 | small | -10, 11 | flesh_5, flesh_1 | +8 % de PV accrus |
| **Sang robuste** `sturdy_blood` | notable | -7, 11 | flesh_4 | +15 % de PV accrus · +3 PV/s |
| plates_1 | small | -21, -1 | outer_str_int_2, plates_2, plates_6 | +10 % d'armure accrue |
| plates_2 | small | -23, 1 | plates_1, plates_3 | +8 % rés. feu |
| plates_3 | small | -26, 1 | plates_2, plates_4 | +10 % d'armure accrue |
| plates_4 | small | -27, -1 | plates_3, plates_5, iron_skin | +8 % rés. froid |
| plates_5 | small | -25, -4 | plates_4, plates_6 | +10 % d'armure accrue |
| plates_6 | small | -22, -4 | plates_5, plates_1 | +8 % rés. feu |
| **Peau de fer** `iron_skin` | notable | -24, -1 | plates_4 | +25 % d'armure accrue · +2 PV/s |
| arms_1 | small | -9, 19 | outer_dex_str_5, arms_2, arms_6 | +4 % de vitesse d'attaque accrue |
| arms_2 | small | -8, 21 | arms_1, arms_3 | +2 % de vitesse d'attaque accrue · +5 % d'allonge accrue |
| arms_3 | small | -9, 24 | arms_2, arms_4 | +4 % de vitesse d'attaque accrue |
| arms_4 | small | -12, 24 | arms_3, arms_5, weapon_master | +2 % de vitesse d'attaque accrue · +5 % d'allonge accrue |
| arms_5 | small | -14, 22 | arms_4, arms_6 | +4 % de vitesse d'attaque accrue |
| arms_6 | small | -12, 19 | arms_5, arms_1 | +2 % de vitesse d'attaque accrue · +5 % d'allonge accrue |
| **Maître d'armes** `weapon_master` | notable | -11, 21 | arms_4 | +20 % de dégâts d'attaque accrus · +8 % de vitesse d'attaque accrue |
| regrowth_1 | small | -3, 21 | outer_dex_str_4, regrowth_2, regrowth_6 | +0.5 PV/s |
| regrowth_2 | small | 0, 22 | regrowth_1, regrowth_3 | +4 % de PV accrus |
| regrowth_3 | small | 0, 26 | regrowth_2, regrowth_4 | +0.5 PV/s |
| regrowth_4 | small | -3, 27 | regrowth_3, regrowth_5, regrowing_flesh | +4 % de PV accrus |
| regrowth_5 | small | -6, 26 | regrowth_4, regrowth_6 | +0.5 PV/s |
| regrowth_6 | small | -6, 22 | regrowth_5, regrowth_1 | +4 % de PV accrus |
| **Chair qui repousse** `regrowing_flesh` | notable | -3, 24 | regrowth_4 | +3 PV/s · +8 % de PV accrus |
| wound_1 | small | -18, 13 | str_9, wound_2, wound_6 | +12 % de dégâts d'attaque accrus contre les saignants |
| wound_2 | small | -15, 13 | wound_1, wound_3 | +12 % de dégâts d'attaque accrus contre les saignants |
| wound_3 | small | -13, 15 | wound_2, wound_4 | +12 % de dégâts d'attaque accrus contre les saignants |
| wound_4 | small | -14, 18 | wound_3, wound_5, open_wound | +12 % de dégâts d'attaque accrus contre les saignants |
| wound_5 | small | -17, 18 | wound_4, wound_6 | +12 % de dégâts d'attaque accrus contre les saignants |
| wound_6 | small | -19, 16 | wound_5, wound_1 | +12 % de dégâts d'attaque accrus contre les saignants |
| **Plaie ouverte** `open_wound` | notable | -16, 16 | wound_4 | +25 % de dégâts d'attaque accrus contre les saignants · +10 % de dégâts d'attaque accrus |
| volley_1 | small | 12, 4 | dex_5, volley_2, volley_4 | +8 % de dégâts de projectile accrus |
| volley_2 | small | 10, 1 | volley_1, volley_3 | +8 % de dégâts de projectile accrus |
| volley_3 | small | 10, -1 | volley_2, precise_shot | +8 % de dégâts de projectile accrus |
| **Tir précis** `precise_shot` | notable | 13, -3 | volley_3 | +20 % de dégâts de projectile accrus · +20 % de chance critique de base accrue |
| volley_4 | small | 15, 3 | volley_1, volley_5 | +6 % de vitesse de projectile accrue aux projectiles |
| volley_5 | small | 16, 1 | volley_4, volley_shot | +6 % de vitesse de projectile accrue aux projectiles |
| **Volée** `volley_shot` | notable | 16, -2 | volley_5 | +1 nombre de projectiles aux projectiles · +10 % de vitesse de projectile accrue aux projectiles |
| eye_1 | small | 9, 8 | dex_5, eye_2, eye_6 | +6 % de chance critique de base accrue |
| eye_2 | small | 10, 11 | eye_1, eye_3 | +8 % de dégâts critiques accrus |
| eye_3 | small | 8, 13 | eye_2, eye_4 | +6 % de chance critique de base accrue |
| eye_4 | small | 5, 13 | eye_3, eye_5, lynx_eye | +8 % de dégâts critiques accrus |
| eye_5 | small | 4, 10 | eye_4, eye_6 | +6 % de chance critique de base accrue |
| eye_6 | small | 6, 8 | eye_5, eye_1 | +8 % de dégâts critiques accrus |
| **Œil de lynx** `lynx_eye` | notable | 7, 11 | eye_4 | +30 % de chance critique de base accrue · +30 % dégâts critiques |
| breath_1 | small | 21, -1 | outer_int_dex_5, breath_2, breath_6 | +8 % d'esquive accrue |
| breath_2 | small | 22, -4 | breath_1, breath_3 | +8 % d'esquive accrue |
| breath_3 | small | 25, -4 | breath_2, breath_4 | +8 % d'esquive accrue |
| breath_4 | small | 27, -1 | breath_3, breath_5, reflexes | +8 % d'esquive accrue |
| breath_5 | small | 26, 1 | breath_4, breath_6 | +8 % d'esquive accrue |
| breath_6 | small | 23, 1 | breath_5, breath_1 | +8 % d'esquive accrue |
| **Réflexes** `reflexes` | notable | 24, -1 | breath_4 | +25 % d'esquive accrue · +3 % de vitesse accrue |
| run_1 | small | 9, 19 | outer_dex_str_2, run_2, run_6 | +3 % de vitesse accrue |
| run_2 | small | 12, 19 | run_1, run_3 | +3 % de vitesse accrue |
| run_3 | small | 14, 22 | run_2, run_4 | +3 % de vitesse accrue |
| run_4 | small | 12, 24 | run_3, run_5, swiftness | +3 % de vitesse accrue |
| run_5 | small | 9, 24 | run_4, run_6 | +3 % de vitesse accrue |
| run_6 | small | 8, 21 | run_5, run_1 | +3 % de vitesse accrue |
| **Vivacité** `swiftness` | notable | 11, 21 | run_4 | +8 % de vitesse d'attaque accrue · +4 % de vitesse accrue |
| frost_1 | small | 18, 13 | dex_9, frost_2, frost_6 | +12 % de dégâts de projectile accrus contre les transis |
| frost_2 | small | 19, 16 | frost_1, frost_3 | +12 % de dégâts de projectile accrus contre les transis |
| frost_3 | small | 17, 18 | frost_2, frost_4 | +12 % de dégâts de projectile accrus contre les transis |
| frost_4 | small | 14, 18 | frost_3, frost_5, frostbite | +12 % de dégâts de projectile accrus contre les transis |
| frost_5 | small | 13, 15 | frost_4, frost_6 | +12 % de dégâts de projectile accrus contre les transis |
| frost_6 | small | 15, 13 | frost_5, frost_1 | +12 % de dégâts de projectile accrus contre les transis |
| **Morsure du gel** `frostbite` | notable | 16, 16 | frost_4 | +25 % de dégâts de projectile accrus contre les transis · +10 % de dégâts de projectile accrus |
| far_int | small | 0, -35 | far_int_dex_1, far_str_int_10, int_bridge, rod_1 | +10 intelligence |
| far_dex | small | 31, 17 | far_int_dex_10, far_dex_str_1, dex_bridge, rime_1 | +10 dextérité |
| far_str | small | -31, 17 | far_dex_str_10, far_str_int_1, str_bridge, sanctity_1 | +10 force |
| far_int_dex_1 | small | 7, -34 | far_int, far_int_dex_2, breadth_1 | +5 intelligence · +5 dextérité |
| far_int_dex_2 | small | 13, -33 | far_int_dex_1, far_int_dex_3 | +5 intelligence · +5 dextérité |
| far_int_dex_3 | small | 19, -30 | far_int_dex_2, far_int_dex_4, arc_1 | +5 intelligence · +5 dextérité |
| far_int_dex_4 | small | 24, -25 | far_int_dex_3, far_int_dex_5, coord_1 | +5 intelligence · +5 dextérité |
| far_int_dex_5 | small | 28, -20 | far_int_dex_4, far_int_dex_6, gale_1, word_1 | +5 intelligence · +5 dextérité |
| far_int_dex_6 | small | 32, -15 | far_int_dex_5, far_int_dex_7, blight_1 | +5 dextérité · +5 intelligence |
| far_int_dex_7 | small | 34, -9 | far_int_dex_6, far_int_dex_8 | +5 dextérité · +5 intelligence |
| far_int_dex_8 | small | 35, -2 | far_int_dex_7, far_int_dex_9, hunt_1 | +5 dextérité · +5 intelligence |
| far_int_dex_9 | small | 35, 5 | far_int_dex_8, far_int_dex_10 | +5 dextérité · +5 intelligence |
| far_int_dex_10 | small | 33, 11 | far_int_dex_9, far_dex, kill_1 | +5 dextérité · +5 intelligence |
| far_dex_str_1 | small | 27, 23 | far_dex, far_dex_str_2 | +5 dextérité · +5 force |
| far_dex_str_2 | small | 22, 27 | far_dex_str_1, far_dex_str_3 | +5 dextérité · +5 force |
| far_dex_str_3 | small | 16, 31 | far_dex_str_2, far_dex_str_4, falcon_1 | +5 dextérité · +5 force |
| far_dex_str_4 | small | 10, 34 | far_dex_str_3, far_dex_str_5 | +5 dextérité · +5 force |
| far_dex_str_5 | small | 3, 35 | far_dex_str_4, far_dex_str_6, guard_1 | +5 dextérité · +5 force |
| far_dex_str_6 | small | -3, 35 | far_dex_str_5, far_dex_str_7 | +5 force · +5 dextérité |
| far_dex_str_7 | small | -10, 34 | far_dex_str_6, far_dex_str_8, gore_1, bark_1 | +5 force · +5 dextérité |
| far_dex_str_8 | small | -16, 31 | far_dex_str_7, far_dex_str_9, whirl_1 | +5 force · +5 dextérité |
| far_dex_str_9 | small | -22, 27 | far_dex_str_8, far_dex_str_10, heart_1 | +5 force · +5 dextérité |
| far_dex_str_10 | small | -27, 23 | far_dex_str_9, far_str, sweep_1 | +5 force · +5 dextérité |
| far_str_int_1 | small | -33, 11 | far_str, far_str_int_2, crush_1 | +5 force · +5 intelligence |
| far_str_int_2 | small | -35, 5 | far_str_int_1, far_str_int_3 | +5 force · +5 intelligence |
| far_str_int_3 | small | -35, -2 | far_str_int_2, far_str_int_4 | +5 force · +5 intelligence |
| far_str_int_4 | small | -34, -9 | far_str_int_3, far_str_int_5, hide_1 | +5 force · +5 intelligence |
| far_str_int_5 | small | -32, -15 | far_str_int_4, far_str_int_6, spellblade_1 | +5 force · +5 intelligence |
| far_str_int_6 | small | -28, -20 | far_str_int_5, far_str_int_7 | +5 intelligence · +5 force |
| far_str_int_7 | small | -24, -25 | far_str_int_6, far_str_int_8, pyre_1 | +5 intelligence · +5 force |
| far_str_int_8 | small | -19, -30 | far_str_int_7, far_str_int_9, spring_1 | +5 intelligence · +5 force |
| far_str_int_9 | small | -13, -33 | far_str_int_8, far_str_int_10 | +5 intelligence · +5 force |
| far_str_int_10 | small | -7, -34 | far_str_int_9, far_int, blast_1 | +5 intelligence · +5 force |
| int_bridge | small | 4, -30 | int_10, far_int | +10 intelligence |
| dex_bridge | small | 24, 18 | dex_10, far_dex, hand_1 | +10 dextérité |
| str_bridge | small | -28, 11 | str_10, far_str | +10 force |
| rod_1 | small | 0, -39 | far_int, rod_2, rod_6 | +8 % rés. foudre |
| rod_2 | small | -3, -40 | rod_1, rod_3 | +0.3 mana/s |
| rod_3 | small | -3, -44 | rod_2, rod_4 | +8 % rés. foudre |
| rod_4 | small | 0, -45 | rod_3, rod_5, lightning_rod | +0.3 mana/s |
| rod_5 | small | 3, -44 | rod_4, rod_6 | +8 % rés. foudre |
| rod_6 | small | 3, -40 | rod_5, rod_1 | +0.3 mana/s |
| **Paratonnerre** `lightning_rod` | notable | 0, -42 | rod_4 | +20 % rés. foudre · +10 % de mana accru |
| arc_1 | small | 19, -34 | far_int_dex_3, arc_2, arc_4 | +6 % de dégâts de foudre accrus |
| arc_2 | small | 18, -39 | arc_1, arc_3 | +8 % de dégâts de foudre accrus |
| arc_3 | small | 16, -42 | arc_2, arcing_current | +8 % de dégâts de foudre accrus |
| **Courant en arc** `arcing_current` | notable | 17, -46 | arc_3 | +1 nombre de cibles aux compétences de foudre · +10 % de dégâts de foudre accrus |
| arc_4 | small | 25, -35 | arc_1, arc_5 | +10 % de chance critique de base accrue aux sorts |
| arc_5 | small | 29, -35 | arc_4, spell_focus | +10 % de chance critique de base accrue aux sorts |
| **Focalisation** `spell_focus` | notable | 31, -38 | arc_5 | +30 % de chance critique de base accrue aux sorts · +20 % dégâts critiques |
| blight_1 | small | 34, -18 | far_int_dex_6, blight_2, blight_6 | +12 % de dégâts de sort accrus contre les pourrissants |
| blight_2 | small | 34, -21 | blight_1, blight_3 | +12 % de dégâts de sort accrus contre les pourrissants |
| blight_3 | small | 37, -23 | blight_2, blight_4 | +12 % de dégâts de sort accrus contre les pourrissants |
| blight_4 | small | 40, -21 | blight_3, blight_5, withering | +12 % de dégâts de sort accrus contre les pourrissants |
| blight_5 | small | 40, -18 | blight_4, blight_6 | +12 % de dégâts de sort accrus contre les pourrissants |
| blight_6 | small | 37, -17 | blight_5, blight_1 | +12 % de dégâts de sort accrus contre les pourrissants |
| **Flétrissure** `withering` | notable | 37, -20 | blight_4 | +25 % de dégâts de sort accrus contre les pourrissants · ajoute 2 à 5 dégâts nécrotiques aux sorts |
| hunt_1 | small | 39, 1 | far_int_dex_8, hunt_2, hunt_6 | +3 % de vitesse d'attaque accrue |
| hunt_2 | small | 40, -1 | hunt_1, hunt_3 | +6 % de dégâts critiques accrus |
| hunt_3 | small | 44, -1 | hunt_2, hunt_4 | +3 % de vitesse d'attaque accrue |
| hunt_4 | small | 45, 2 | hunt_3, hunt_5, deadly_rhythm | +6 % de dégâts critiques accrus |
| hunt_5 | small | 43, 4 | hunt_4, hunt_6 | +3 % de vitesse d'attaque accrue |
| hunt_6 | small | 40, 4 | hunt_5, hunt_1 | +6 % de dégâts critiques accrus |
| **Rythme mortel** `deadly_rhythm` | notable | 42, 1 | hunt_4 | +8 % de vitesse d'attaque accrue · +20 % dégâts critiques |
| rime_1 | small | 34, 19 | far_dex, rime_2, rime_6 | ajoute 1 à 3 dégâts de froid aux projectiles |
| rime_2 | small | 37, 17 | rime_1, rime_3 | +8 % de dégâts de projectile accrus contre les transis |
| rime_3 | small | 39, 19 | rime_2, rime_4 | ajoute 1 à 3 dégâts de froid aux projectiles |
| rime_4 | small | 39, 22 | rime_3, rime_5, frost_tips | +8 % de dégâts de projectile accrus contre les transis |
| rime_5 | small | 37, 24 | rime_4, rime_6 | ajoute 1 à 3 dégâts de froid aux projectiles |
| rime_6 | small | 34, 22 | rime_5, rime_1 | +8 % de dégâts de projectile accrus contre les transis |
| **Pointes de givre** `frost_tips` | notable | 37, 21 | rime_4 | ajoute 3 à 7 dégâts de froid aux projectiles · +10 % de vitesse de projectile accrue aux projectiles |
| guard_1 | small | 0, 39 | far_dex_str_5, guard_2, guard_6 | +6 % d'armure accrue |
| guard_2 | small | 3, 40 | guard_1, guard_3 | +6 % d'esquive accrue |
| guard_3 | small | 3, 44 | guard_2, guard_4 | +6 % d'armure accrue |
| guard_4 | small | 0, 45 | guard_3, guard_5, supple_guard | +6 % d'esquive accrue |
| guard_5 | small | -3, 44 | guard_4, guard_6 | +6 % d'armure accrue |
| guard_6 | small | -3, 40 | guard_5, guard_1 | +6 % d'esquive accrue |
| **Garde souple** `supple_guard` | notable | 0, 42 | guard_4 | +20 % d'armure accrue · +20 % d'esquive accrue |
| whirl_1 | small | -19, 34 | far_dex_str_8, whirl_2, whirl_6 | +6 % de durée accrue aux attaques |
| whirl_2 | small | -18, 36 | whirl_1, whirl_3 | +5 % de dégâts d'attaque accrus |
| whirl_3 | small | -19, 39 | whirl_2, whirl_4 | +6 % de durée accrue aux attaques |
| whirl_4 | small | -23, 39 | whirl_3, whirl_5, whirling_blades | +5 % de dégâts d'attaque accrus |
| whirl_5 | small | -24, 36 | whirl_4, whirl_6 | +6 % de durée accrue aux attaques |
| whirl_6 | small | -23, 34 | whirl_5, whirl_1 | +5 % de dégâts d'attaque accrus |
| **Lames tournoyantes** `whirling_blades` | notable | -21, 36 | whirl_4 | +1 maximum simultané aux attaques · +10 % de durée accrue aux attaques |
| sanctity_1 | small | -34, 19 | far_str, sanctity_2, sanctity_6 | +8 % rés. sacré |
| sanctity_2 | small | -34, 22 | sanctity_1, sanctity_3 | +8 % rés. nécrotique |
| sanctity_3 | small | -37, 24 | sanctity_2, sanctity_4 | +8 % rés. sacré |
| sanctity_4 | small | -39, 22 | sanctity_3, sanctity_5, hallowed_soul | +8 % rés. nécrotique |
| sanctity_5 | small | -39, 19 | sanctity_4, sanctity_6 | +8 % rés. sacré |
| sanctity_6 | small | -37, 17 | sanctity_5, sanctity_1 | +8 % rés. nécrotique |
| **Âme consacrée** `hallowed_soul` | notable | -37, 21 | sanctity_4 | +15 % rés. sacré · +6 % de PV accrus |
| spellblade_1 | small | -34, -20 | far_str_int_5, spellblade_2, spellblade_4 | +6 % de dégâts d'attaque accrus |
| spellblade_2 | small | -39, -18 | spellblade_1, spellblade_3 | ajoute 1 à 3 dégâts de feu aux attaques |
| spellblade_3 | small | -42, -16 | spellblade_2, burning_edge | ajoute 1 à 3 dégâts de feu aux attaques |
| **Tranchant ardent** `burning_edge` | notable | -46, -17 | spellblade_3 | ajoute 3 à 7 dégâts de feu aux attaques · +10 % de dégâts de feu accrus |
| spellblade_4 | small | -35, -25 | spellblade_1, spellblade_5 | ajoute 1 à 3 dégâts sacrés aux attaques |
| spellblade_5 | small | -35, -29 | spellblade_4, blessed_edge | ajoute 1 à 3 dégâts sacrés aux attaques |
| **Tranchant béni** `blessed_edge` | notable | -38, -31 | spellblade_5 | ajoute 3 à 7 dégâts sacrés aux attaques · +20 % de dégâts d'attaque accrus contre les bénis |
| crush_1 | small | -35, 9 | far_str_int_1, crush_2, crush_6 | +8 % de dégâts de mêlée accrus |
| crush_2 | small | -35, 12 | crush_1, crush_3 | +8 % de dégâts de mêlée accrus |
| crush_3 | small | -38, 13 | crush_2, crush_4 | +8 % de dégâts de mêlée accrus |
| crush_4 | small | -41, 11 | crush_3, crush_5, crusher | +8 % de dégâts de mêlée accrus |
| crush_5 | small | -40, 8 | crush_4, crush_6 | +8 % de dégâts de mêlée accrus |
| crush_6 | small | -37, 7 | crush_5, crush_1 | +8 % de dégâts de mêlée accrus |
| **Broyeur** `crusher` | notable | -38, 10 | crush_4 | +20 % de dégâts de mêlée accrus · +10 force |
| sweep_1 | small | -26, 26 | far_dex_str_10, sweep_2, sweep_5 | +3 % de vitesse d'attaque accrue |
| sweep_2 | small | -26, 30 | sweep_1, sweep_3 | +6 % de dégâts de mêlée accrus |
| sweep_3 | small | -29, 32 | sweep_2, sweep_4, windmill | +3 % de vitesse d'attaque accrue |
| sweep_4 | small | -32, 29 | sweep_3, sweep_5 | +6 % de dégâts de mêlée accrus |
| sweep_5 | small | -30, 26 | sweep_4, sweep_1 | +3 % de vitesse d'attaque accrue |
| **Moulinet** `windmill` | notable | -29, 29 | sweep_3 | +8 % de vitesse d'attaque accrue · +12 % de dégâts de mêlée accrus |
| reach_1 | small | -23, 6 | outer_str_int_1, reach_2 | +6 % de dégâts de mêlée accrus |
| reach_2 | small | -26, 6 | reach_1, reach_3 | +6 % de dégâts de mêlée accrus |
| reach_3 | small | -28, 7 | reach_2, high_guard | +6 % de dégâts de mêlée accrus |
| **Grande garde** `high_guard` | notable | -31, 8 | reach_3 | +15 % de dégâts de mêlée accrus · +10 % d'allonge accrue |
| gore_1 | small | -13, 34 | far_dex_str_7, gore_2, gore_6 | +10 % de dégâts de mêlée accrus contre les saignants |
| gore_2 | small | -11, 37 | gore_1, gore_3 | +10 % de dégâts de mêlée accrus contre les saignants |
| gore_3 | small | -12, 40 | gore_2, gore_4 | +10 % de dégâts de mêlée accrus contre les saignants |
| gore_4 | small | -15, 40 | gore_3, gore_5, bloodletting | +10 % de dégâts de mêlée accrus contre les saignants |
| gore_5 | small | -17, 38 | gore_4, gore_6 | +10 % de dégâts de mêlée accrus contre les saignants |
| gore_6 | small | -16, 35 | gore_5, gore_1 | +10 % de dégâts de mêlée accrus contre les saignants |
| **Ouvre-chair** `bloodletting` | notable | -14, 37 | gore_4 | +25 % de dégâts de mêlée accrus contre les saignants · +10 % de dégâts de mêlée accrus |
| blast_1 | small | -9, -35 | far_str_int_10, blast_2, blast_6 | +8 % de dégâts de zone accrus |
| blast_2 | small | -12, -35 | blast_1, blast_3 | +8 % de dégâts de zone accrus |
| blast_3 | small | -13, -38 | blast_2, blast_4 | +8 % de dégâts de zone accrus |
| blast_4 | small | -11, -41 | blast_3, blast_5, detonation | +8 % de dégâts de zone accrus |
| blast_5 | small | -8, -40 | blast_4, blast_6 | +8 % de dégâts de zone accrus |
| blast_6 | small | -7, -37 | blast_5, blast_1 | +8 % de dégâts de zone accrus |
| **Éclatement** `detonation` | notable | -10, -38 | blast_4 | +20 % de dégâts de zone accrus · +10 % de rayon accru aux compétences de zone |
| breadth_1 | small | 9, -35 | far_int_dex_1, breadth_2, breadth_6 | +6 % de rayon accru aux compétences de zone |
| breadth_2 | small | 7, -37 | breadth_1, breadth_3 | +6 % de durée accrue aux compétences de zone |
| breadth_3 | small | 8, -40 | breadth_2, breadth_4 | +6 % de rayon accru aux compétences de zone |
| breadth_4 | small | 11, -41 | breadth_3, breadth_5, wide_blast | +6 % de durée accrue aux compétences de zone |
| breadth_5 | small | 13, -38 | breadth_4, breadth_6 | +6 % de rayon accru aux compétences de zone |
| breadth_6 | small | 12, -35 | breadth_5, breadth_1 | +6 % de durée accrue aux compétences de zone |
| **Souffle élargi** `wide_blast` | notable | 10, -38 | breadth_4 | +15 % de rayon accru aux compétences de zone · +12 % de dégâts de zone accrus |
| hold_1 | small | -5, -21 | outer_str_int_6, hold_2, hold_5 | +8 % de durée accrue aux compétences de zone |
| hold_2 | small | -8, -23 | hold_1, hold_3 | +8 % de durée accrue aux compétences de zone |
| hold_3 | small | -8, -27 | hold_2, hold_4, lasting_hold | +8 % de durée accrue aux compétences de zone |
| hold_4 | small | -4, -27 | hold_3, hold_5 | +8 % de durée accrue aux compétences de zone |
| hold_5 | small | -2, -24 | hold_4, hold_1 | +8 % de durée accrue aux compétences de zone |
| **Emprise durable** `lasting_hold` | notable | -5, -24 | hold_3 | +20 % de durée accrue aux compétences de zone · +8 % de rayon accru aux compétences de zone |
| pyre_1 | small | -23, -28 | far_str_int_7, pyre_2, pyre_5 | +8 % de dégâts de feu accrus |
| pyre_2 | small | -26, -28 | pyre_1, pyre_3 | +8 % de dégâts de feu accrus |
| pyre_3 | small | -28, -31 | pyre_2, pyre_4, burning_cloud | +8 % de dégâts de feu accrus |
| pyre_4 | small | -25, -34 | pyre_3, pyre_5 | +8 % de dégâts de feu accrus |
| pyre_5 | small | -22, -31 | pyre_4, pyre_1 | +8 % de dégâts de feu accrus |
| **Nuée ardente** `burning_cloud` | notable | -25, -30 | pyre_3 | +18 % de dégâts de zone accrus · +10 % de dégâts de feu accrus |
| gale_1 | small | 28, -23 | far_int_dex_5, gale_2, gale_5 | +8 % de dégâts de foudre accrus |
| gale_2 | small | 28, -26 | gale_1, gale_3 | +8 % de dégâts de foudre accrus |
| gale_3 | small | 31, -28 | gale_2, gale_4, spread_storm | +8 % de dégâts de foudre accrus |
| gale_4 | small | 34, -25 | gale_3, gale_5 | +8 % de dégâts de foudre accrus |
| gale_5 | small | 31, -22 | gale_4, gale_1 | +8 % de dégâts de foudre accrus |
| **Orage étendu** `spread_storm` | notable | 30, -25 | gale_3 | +18 % de dégâts de zone accrus · +10 % de dégâts de foudre accrus |
| ember_1 | small | 6, -23 | int_9, ember_2 | +10 % de dégâts de zone accrus contre les embrasés |
| ember_2 | small | 6, -26 | ember_1, ember_3 | +10 % de dégâts de zone accrus contre les embrasés |
| ember_3 | small | 7, -28 | ember_2, live_coals | +10 % de dégâts de zone accrus contre les embrasés |
| **Braise** `live_coals` | notable | 8, -31 | ember_3 | +22 % de dégâts de zone accrus contre les embrasés · +10 % de dégâts de zone accrus |
| shock_1 | small | 9, -23 | outer_int_dex_1, shock_2 | +10 % de dégâts de zone accrus contre les engourdis |
| shock_2 | small | 9, -26 | shock_1, shock_3 | +10 % de dégâts de zone accrus contre les engourdis |
| shock_3 | small | 10, -28 | shock_2, shockwave | +10 % de dégâts de zone accrus contre les engourdis |
| **Onde de choc** `shockwave` | notable | 11, -31 | shock_3 | +22 % de dégâts de zone accrus contre les engourdis · +10 % de rayon accru aux compétences de zone |
| mastery_1 | small | 23, -8 | outer_int_dex_4, mastery_2 | +6 % de dégâts de zone accrus |
| mastery_2 | small | 25, -9 | mastery_1, mastery_3 | +6 % de dégâts de zone accrus |
| mastery_3 | small | 27, -10 | mastery_2, field_master | +6 % de dégâts de zone accrus |
| **Maître des zones** `field_master` | notable | 30, -11 | mastery_3 | +1 niveau de compétence de zone · +10 % de dégâts de zone accrus |
| kill_1 | small | 35, 9 | far_int_dex_10, kill_2, kill_6 | +6 % de chance critique de base accrue |
| kill_2 | small | 37, 7 | kill_1, kill_3 | +8 % de dégâts critiques accrus |
| kill_3 | small | 40, 8 | kill_2, kill_4 | +6 % de chance critique de base accrue |
| kill_4 | small | 41, 11 | kill_3, kill_5, assassination | +8 % de dégâts critiques accrus |
| kill_5 | small | 38, 13 | kill_4, kill_6 | +6 % de chance critique de base accrue |
| kill_6 | small | 35, 12 | kill_5, kill_1 | +8 % de dégâts critiques accrus |
| **Assassinat** `assassination` | notable | 38, 10 | kill_4 | +30 % de chance critique de base accrue · +20 % dégâts critiques |
| falcon_1 | small | 19, 31 | far_dex_str_3, falcon_2, falcon_6 | +8 % de dégâts de projectile accrus |
| falcon_2 | small | 24, 31 | falcon_1, falcon_3 | +6 % de vitesse de projectile accrue aux projectiles |
| falcon_3 | small | 25, 34 | falcon_2, falcon_4 | +8 % de dégâts de projectile accrus |
| falcon_4 | small | 24, 36 | falcon_3, falcon_5, falcon_flight | +6 % de vitesse de projectile accrue aux projectiles |
| falcon_5 | small | 21, 37 | falcon_4, falcon_6 | +8 % de dégâts de projectile accrus |
| falcon_6 | small | 18, 34 | falcon_5, falcon_1 | +6 % de vitesse de projectile accrue aux projectiles |
| **Vol du faucon** `falcon_flight` | notable | 22, 34 | falcon_4 | +20 % de dégâts de projectile accrus · +15 % de vitesse de projectile accrue aux projectiles |
| flee_1 | small | 5, 25 | outer_dex_str_3, flee_2, flee_5 | +3 % de vitesse accrue |
| flee_2 | small | 9, 27 | flee_1, flee_3 | +6 % d'esquive accrue |
| flee_3 | small | 8, 31 | flee_2, flee_4, light_foot | +3 % de vitesse accrue |
| flee_4 | small | 5, 31 | flee_3, flee_5 | +6 % d'esquive accrue |
| flee_5 | small | 3, 28 | flee_4, flee_1 | +3 % de vitesse accrue |
| **Pied léger** `light_foot` | notable | 6, 28 | flee_3 | +5 % de vitesse accrue · +15 % d'esquive accrue |
| spear_1 | small | 24, 4 | outer_int_dex_6, spear_2 | +6 % de dégâts de projectile accrus |
| spear_2 | small | 26, 5 | spear_1, spear_3 | +6 % de dégâts de projectile accrus |
| spear_3 | small | 29, 5 | spear_2, spearhead | +6 % de dégâts de projectile accrus |
| **Fer de lance** `spearhead` | notable | 31, 6 | spear_3 | +15 % de dégâts de projectile accrus · +10 % dégâts critiques |
| hand_1 | small | 15, 20 | dex_bridge, hand_2 | +3 % de vitesse d'attaque accrue |
| hand_2 | small | 17, 22 | hand_1, hand_3 | +3 % de vitesse d'attaque accrue |
| hand_3 | small | 17, 24 | hand_2, deft_hand | +3 % de vitesse d'attaque accrue |
| **Main leste** `deft_hand` | notable | 19, 26 | hand_3 | +8 % de vitesse d'attaque accrue · +2 % de vitesse accrue |
| vigor_1 | small | -20, 18 | str_10, vigor_2, vigor_6 | +8 % de PV accrus |
| vigor_2 | small | -19, 21 | vigor_1, vigor_3 | +8 % de PV accrus |
| vigor_3 | small | -22, 23 | vigor_2, vigor_4 | +8 % de PV accrus |
| vigor_4 | small | -25, 22 | vigor_3, vigor_5, constitution | +8 % de PV accrus |
| vigor_5 | small | -25, 19 | vigor_4, vigor_6 | +8 % de PV accrus |
| vigor_6 | small | -23, 17 | vigor_5, vigor_1 | +8 % de PV accrus |
| **Constitution** `constitution` | notable | -22, 20 | vigor_4 | +15 % de PV accrus · +2 PV/s |
| hide_1 | small | -36, -6 | far_str_int_4, hide_2, hide_5 | +8 % rés. feu |
| hide_2 | small | -39, -3 | hide_1, hide_3 | +8 % rés. froid |
| hide_3 | small | -42, -5 | hide_2, hide_4, tanned_skin | +8 % rés. feu |
| hide_4 | small | -42, -8 | hide_3, hide_5 | +8 % rés. froid |
| hide_5 | small | -38, -9 | hide_4, hide_1 | +8 % rés. feu |
| **Peau tannée** `tanned_skin` | notable | -40, -6 | hide_3 | +15 % rés. feu · +15 % rés. froid |
| bark_1 | small | -9, 37 | far_dex_str_7, bark_2 | +8 % d'armure accrue |
| bark_2 | small | -9, 39 | bark_1, bark_3 | +8 % d'armure accrue |
| bark_3 | small | -8, 42 | bark_2, bark_skin | +8 % d'armure accrue |
| **Écorce** `bark_skin` | notable | -7, 44 | bark_3 | +20 % d'armure accrue · +1.5 PV/s |
| heart_1 | small | -24, 31 | far_dex_str_9, heart_2 | +6 % de PV accrus |
| heart_2 | small | -26, 33 | heart_1, heart_3 | +6 % de PV accrus |
| heart_3 | small | -27, 35 | heart_2, hardened_heart | +6 % de PV accrus |
| **Cœur endurci** `hardened_heart` | notable | -29, 37 | heart_3 | +12 % de PV accrus · +10 % rés. feu |
| deep_1 | small | -24, -8 | outer_str_int_3, deep_2, deep_6 | +8 % de mana accru |
| deep_2 | small | -26, -6 | deep_1, deep_3 | +4 % de vitesse d'incantation accrue |
| deep_3 | small | -29, -7 | deep_2, deep_4 | +8 % de mana accru |
| deep_4 | small | -30, -10 | deep_3, deep_5, deep_thoughts | +4 % de vitesse d'incantation accrue |
| deep_5 | small | -27, -12 | deep_4, deep_6 | +8 % de mana accru |
| deep_6 | small | -24, -11 | deep_5, deep_1 | +4 % de vitesse d'incantation accrue |
| **Pensées profondes** `deep_thoughts` | notable | -27, -9 | deep_4 | +20 % de mana accru · +8 % de vitesse d'incantation accrue |
| spring_1 | small | -21, -33 | far_str_int_8, spring_2 | +0.3 mana/s |
| spring_2 | small | -22, -35 | spring_1, spring_3 | +0.3 mana/s |
| spring_3 | small | -23, -37 | spring_2, deep_spring | +0.3 mana/s |
| **Source profonde** `deep_spring` | notable | -25, -40 | spring_3 | +2 mana/s · +10 % de mana accru |
| word_1 | small | 25, -20 | far_int_dex_5, word_2 | +4 % de vitesse d'incantation accrue |
| word_2 | small | 23, -20 | word_1, word_3 | +4 % de vitesse d'incantation accrue |
| word_3 | small | 20, -20 | word_2, quick_word | +4 % de vitesse d'incantation accrue |
| **Verbe rapide** `quick_word` | notable | 18, -20 | word_3 | +10 % de vitesse d'incantation accrue · +8 % de mana accru |
| coord_1 | small | 26, -28 | far_int_dex_4, coord_2, coord_6 | +3 % de vitesse d'attaque accrue |
| coord_2 | small | 25, -31 | coord_1, coord_3 | +3 % de vitesse d'incantation accrue |
| coord_3 | small | 27, -34 | coord_2, coord_4 | +3 % de vitesse d'attaque accrue |
| coord_4 | small | 30, -33 | coord_3, coord_5, coordination | +3 % de vitesse d'incantation accrue |
| coord_5 | small | 31, -30 | coord_4, coord_6 | +3 % de vitesse d'attaque accrue |
| coord_6 | small | 29, -28 | coord_5, coord_1 | +3 % de vitesse d'incantation accrue |
| **Coordination** `coordination` | notable | 28, -31 | coord_4 | +8 % de vitesse d'attaque accrue · +8 % de vitesse d'incantation accrue |

## Affixes d'objets

`vise` vide veut dire « partout », sous réserve d'`interdit`, qui l'emporte.

| id | statistique | vise | interdit | poids | paliers | bases éligibles |
|---|---|---|---|---|---|---|
| `agile` | dextérité | *partout* | — | 8 | 6 | 41 / 45 |
| `ardent` | dégâts de feu (%) | caster, jewellery | — | 8 | 6 | 11 / 45 |
| `bewitched` | dégâts de sort (%) | caster | — | 8 | 6 | 5 / 45 |
| `bloody` | dégâts critiques | weapon, jewellery | — | 6 | 5 | 17 / 45 |
| `butchering` | dégâts d'attaque contre les saignants (%) | melee, gloves | — | 3 | 5 | 11 / 45 |
| `cold_skill_levels` | niveaux de compétence de froid | caster | — | 1 | 2 | 5 / 45 |
| `cold_to_attacks` | dégâts de froid aux attaques | melee, jewellery | — | 2 | 8 | 14 / 45 |
| `cold_to_spells` | dégâts de froid aux sorts | caster, jewellery | — | 2 | 8 | 11 / 45 |
| `cruel` | chance critique de base | weapon | — | 7 | 3 | 11 / 45 |
| `crushing` | dégâts de mêlée (%) | melee, gloves | — | 3 | 5 | 11 / 45 |
| `cuirassed` | armure | armour | — | 9 | 9 | 19 / 45 |
| `electrocuting` | dégâts de sort contre les engourdis (%) | caster, gloves | offhand | 3 | 5 | 6 / 45 |
| `elusive` | esquive | light | — | 9 | 8 | 10 / 45 |
| `embalmed` | rés. nécrotique | *partout* | weapon | 9 | 5 | 30 / 45 |
| `erudite` | intelligence | *partout* | — | 8 | 6 | 41 / 45 |
| `expansive` | dégâts de zone (%) | caster, gloves | — | 3 | 5 | 8 / 45 |
| `fire_skill_levels` | niveaux de compétence de feu | caster | — | 1 | 2 | 5 / 45 |
| `fire_to_attacks` | dégâts de feu aux attaques | melee, jewellery | — | 2 | 8 | 14 / 45 |
| `fire_to_spells` | dégâts de feu aux sorts | caster, jewellery | — | 2 | 8 | 11 / 45 |
| `fireproof` | rés. feu | *partout* | weapon | 9 | 5 | 30 / 45 |
| `forked` | nombre de projectiles aux projectiles | caster | — | 3 | 2 | 5 / 45 |
| `frosted` | rés. froid | *partout* | weapon | 9 | 5 | 30 / 45 |
| `glacial` | dégâts de froid (%) | caster, jewellery | — | 8 | 6 | 11 / 45 |
| `holy_to_attacks` | dégâts sacrés aux attaques | melee, jewellery | — | 2 | 8 | 14 / 45 |
| `holy_to_spells` | dégâts sacrés aux sorts | caster, jewellery | — | 2 | 8 | 11 / 45 |
| `incanting` | vitesse d'incantation (%) | caster, gloves, jewellery | — | 8 | 6 | 14 / 45 |
| `insulated` | rés. foudre | *partout* | weapon | 9 | 5 | 30 / 45 |
| `keen` | chance critique de base (%) | gloves, jewellery | — | 7 | 5 | 9 / 45 |
| `lightning_skill_levels` | niveaux de compétence de foudre | caster | — | 1 | 2 | 5 / 45 |
| `lightning_to_attacks` | dégâts de foudre aux attaques | melee, jewellery | — | 2 | 8 | 14 / 45 |
| `lightning_to_spells` | dégâts de foudre aux sorts | caster, jewellery | — | 2 | 8 | 11 / 45 |
| `lucid` | mana/s | caster, belt, jewellery | — | 6 | 5 | 14 / 45 |
| `muscular` | force | *partout* | — | 8 | 6 | 41 / 45 |
| `necrotic_to_attacks` | dégâts nécrotiques aux attaques | melee, jewellery | — | 2 | 8 | 14 / 45 |
| `necrotic_to_spells` | dégâts nécrotiques aux sorts | caster, jewellery | — | 2 | 8 | 11 / 45 |
| `nimble` | vitesse (%) | boots | — | 10 | 5 | 3 / 45 |
| `physical_to_attacks` | dégâts physiques aux attaques | melee, jewellery | — | 2 | 8 | 14 / 45 |
| `physical_to_spells` | dégâts physiques aux sorts | caster, jewellery | — | 2 | 8 | 11 / 45 |
| `plated` | armure (%) | heavy | — | 8 | 6 | 9 / 45 |
| `precise` | chance critique de base (%) | weapon | — | 7 | 5 | 11 / 45 |
| `quick` | vitesse d'attaque (%) | melee, gloves, jewellery | — | 8 | 6 | 17 / 45 |
| `reach` | allonge | melee | — | 8 | 5 | 8 / 45 |
| `regenerating` | PV/s | belt, jewellery | — | 6 | 5 | 9 / 45 |
| `scorching` | dégâts de sort contre les embrasés (%) | caster, gloves | offhand | 3 | 5 | 6 / 45 |
| `second_wind` | récupération de recharge | boots, jewellery | — | 5 | 5 | 9 / 45 |
| `shattering` | dégâts d'attaque contre les transis (%) | melee, gloves | — | 3 | 5 | 11 / 45 |
| `shrewd` | mana | caster, helmet, jewellery | — | 8 | 7 | 16 / 45 |
| `stormy` | dégâts de foudre (%) | caster, jewellery | — | 8 | 6 | 11 / 45 |
| `sturdy` | PV (%) | armour, belt | — | 10 | 6 | 22 / 45 |
| `unholy` | rés. sacré | *partout* | weapon | 9 | 5 | 30 / 45 |
| `vigorous` | PV | armour, belt, jewellery | — | 12 | 8 | 28 / 45 |
| `whistling` | vitesse de projectile aux projectiles (%) | caster, gloves | — | 8 | 5 | 8 / 45 |

### Affixes d'ennemis

| id | nom | PV | vitesse | dégâts | temps d'attaque | armure | vol de vie | exp |
|---|---|---|---|---|---|---|---|---|
| `colossal` | Colossal | ×2.00 | ×0.80 | ×1.00 | ×1.00 | +0 | 0 % | ×1.80 |
| `swift` | Véloce | ×0.75 | ×1.45 | ×1.00 | ×1.00 | +0 | 0 % | ×1.40 |
| `brutal` | Brutal | ×1.00 | ×1.00 | ×1.60 | ×1.20 | +0 | 0 % | ×1.50 |
| `armored` | Blindé | ×1.00 | ×0.90 | ×1.00 | ×1.00 | +50 | 0 % | ×1.60 |
| `ravenous` | Vorace | ×0.90 | ×1.00 | ×1.00 | ×1.00 | +0 | 25 % | ×1.50 |

Un affixe apparaît sur 18 % des ennemis, deux sur 4 %.

## Échelles de paliers

T1 est le meilleur. « ouvre à » est le niveau d'objet minimum du palier.

**`agile`** — « de l'Agilité », dextérité, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 33–42 | 10 |
| T2 | 42 | 25–32 | 10 |
| T3 | 31 | 18–24 | 10 |
| T4 | 20 | 12–17 | 10 |
| T5 | 10 | 7–11 | 10 |
| T6 | 1 | 3–6 | 10 |

**`ardent`** — « de la Fournaise », dégâts de feu, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 57 | 34–42 % | 10 |
| T2 | 45 | 26–33 % | 10 |
| T3 | 33 | 19–25 % | 10 |
| T4 | 22 | 13–18 % | 10 |
| T5 | 11 | 8–12 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`bewitched`** — « du Maléfice », dégâts de sort, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 57 | 34–42 % | 10 |
| T2 | 45 | 26–33 % | 10 |
| T3 | 33 | 19–25 % | 10 |
| T4 | 22 | 13–18 % | 10 |
| T5 | 11 | 8–12 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`bloody`** — « du Carnage », dégâts critiques, arrondi 0.01

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 125–150 % | 10 |
| T2 | 36 | 95–120 % | 10 |
| T3 | 24 | 70–90 % | 10 |
| T4 | 12 | 45–65 % | 10 |
| T5 | 1 | 20–40 % | 10 |

**`butchering`** — « de la Boucherie », dégâts d'attaque contre les saignants, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 40–50 % | 10 |
| T2 | 34 | 30–39 % | 10 |
| T3 | 19 | 20–29 % | 10 |
| T4 | 6 | 13–19 % | 10 |
| T5 | 1 | 8–12 % | 10 |

**`cold_skill_levels`** — « du Cryomancien », niveaux de compétence de froid, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 60 | 2–2 | 10 |
| T2 | 1 | 1–1 | 10 |

**`cold_to_attacks`** — « du Givre », dégâts de froid aux attaques, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 22–27 à 66–81 | 10 |
| T2 | 43 | 18–22 à 53–65 | 10 |
| T3 | 34 | 14–17 à 41–51 | 10 |
| T4 | 26 | 10–13 à 30–39 | 10 |
| T5 | 19 | 7–10 à 21–29 | 10 |
| T6 | 12 | 5–7 à 14–20 | 10 |
| T7 | 6 | 3–4 à 8–12 | 10 |
| T8 | 1 | 1–2 à 3–6 | 10 |

**`cold_to_spells`** — « du Blizzard », dégâts de froid aux sorts, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 22–27 à 66–81 | 10 |
| T2 | 43 | 18–22 à 53–65 | 10 |
| T3 | 34 | 14–17 à 41–51 | 10 |
| T4 | 26 | 10–13 à 30–39 | 10 |
| T5 | 19 | 7–10 à 21–29 | 10 |
| T6 | 12 | 5–7 à 14–20 | 10 |
| T7 | 6 | 3–4 à 8–12 | 10 |
| T8 | 1 | 1–2 à 3–6 | 10 |

**`cruel`** — « de la Cruauté », chance critique de base, arrondi 0.01

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 3–4 % | 10 |
| T2 | 24 | 2–3 % | 10 |
| T3 | 1 | 1–2 % | 10 |

**`crushing`** — « de l'Écrasement », dégâts de mêlée, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 32–40 % | 10 |
| T2 | 34 | 24–31 % | 10 |
| T3 | 19 | 16–23 % | 10 |
| T4 | 6 | 10–15 % | 10 |
| T5 | 1 | 6–9 % | 10 |

**`cuirassed`** — « de la Cuirasse », armure, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 57 | 216–265 | 10 |
| T2 | 48 | 173–215 | 10 |
| T3 | 39 | 135–172 | 10 |
| T4 | 31 | 103–134 | 10 |
| T5 | 23 | 76–102 | 10 |
| T6 | 16 | 53–75 | 10 |
| T7 | 10 | 35–52 | 10 |
| T8 | 5 | 21–34 | 10 |
| T9 | 1 | 12–20 | 10 |

**`electrocuting`** — « de l'Électrocution », dégâts de sort contre les engourdis, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 40–50 % | 10 |
| T2 | 34 | 30–39 % | 10 |
| T3 | 19 | 20–29 % | 10 |
| T4 | 6 | 13–19 % | 10 |
| T5 | 1 | 8–12 % | 10 |

**`elusive`** — « de l'Ombre », esquive, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 146–185 | 10 |
| T2 | 43 | 114–145 | 10 |
| T3 | 34 | 87–113 | 10 |
| T4 | 26 | 64–86 | 10 |
| T5 | 19 | 45–63 | 10 |
| T6 | 12 | 30–44 | 10 |
| T7 | 6 | 18–29 | 10 |
| T8 | 1 | 10–17 | 10 |

**`embalmed`** — « de l'Embaumement », rés. nécrotique, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`erudite`** — « de l'Érudition », intelligence, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 33–42 | 10 |
| T2 | 42 | 25–32 | 10 |
| T3 | 31 | 18–24 | 10 |
| T4 | 20 | 12–17 | 10 |
| T5 | 10 | 7–11 | 10 |
| T6 | 1 | 3–6 | 10 |

**`expansive`** — « de l'Ampleur », dégâts de zone, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 32–40 % | 10 |
| T2 | 34 | 24–31 % | 10 |
| T3 | 19 | 16–23 % | 10 |
| T4 | 6 | 10–15 % | 10 |
| T5 | 1 | 6–9 % | 10 |

**`fire_skill_levels`** — « du Pyromancien », niveaux de compétence de feu, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 60 | 2–2 | 10 |
| T2 | 1 | 1–1 | 10 |

**`fire_to_attacks`** — « de la Braise », dégâts de feu aux attaques, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 22–27 à 66–81 | 10 |
| T2 | 43 | 18–22 à 53–65 | 10 |
| T3 | 34 | 14–17 à 41–51 | 10 |
| T4 | 26 | 10–13 à 30–39 | 10 |
| T5 | 19 | 7–10 à 21–29 | 10 |
| T6 | 12 | 5–7 à 14–20 | 10 |
| T7 | 6 | 3–4 à 8–12 | 10 |
| T8 | 1 | 1–2 à 3–6 | 10 |

**`fire_to_spells`** — « de l'Incendie », dégâts de feu aux sorts, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 22–27 à 66–81 | 10 |
| T2 | 43 | 18–22 à 53–65 | 10 |
| T3 | 34 | 14–17 à 41–51 | 10 |
| T4 | 26 | 10–13 à 30–39 | 10 |
| T5 | 19 | 7–10 à 21–29 | 10 |
| T6 | 12 | 5–7 à 14–20 | 10 |
| T7 | 6 | 3–4 à 8–12 | 10 |
| T8 | 1 | 1–2 à 3–6 | 10 |

**`fireproof`** — « de la Salamandre », rés. feu, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`forked`** — « de la Fourche », nombre de projectiles aux projectiles, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 50 | 2–2 | 10 |
| T2 | 1 | 1–1 | 10 |

**`frosted`** — « de la Fourrure », rés. froid, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`glacial`** — « de la Banquise », dégâts de froid, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 57 | 34–42 % | 10 |
| T2 | 45 | 26–33 % | 10 |
| T3 | 33 | 19–25 % | 10 |
| T4 | 22 | 13–18 % | 10 |
| T5 | 11 | 8–12 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`holy_to_attacks`** — « de la Croisade », dégâts sacrés aux attaques, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 22–27 à 66–81 | 10 |
| T2 | 43 | 18–22 à 53–65 | 10 |
| T3 | 34 | 14–17 à 41–51 | 10 |
| T4 | 26 | 10–13 à 30–39 | 10 |
| T5 | 19 | 7–10 à 21–29 | 10 |
| T6 | 12 | 5–7 à 14–20 | 10 |
| T7 | 6 | 3–4 à 8–12 | 10 |
| T8 | 1 | 1–2 à 3–6 | 10 |

**`holy_to_spells`** — « de la Litanie », dégâts sacrés aux sorts, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 22–27 à 66–81 | 10 |
| T2 | 43 | 18–22 à 53–65 | 10 |
| T3 | 34 | 14–17 à 41–51 | 10 |
| T4 | 26 | 10–13 à 30–39 | 10 |
| T5 | 19 | 7–10 à 21–29 | 10 |
| T6 | 12 | 5–7 à 14–20 | 10 |
| T7 | 6 | 3–4 à 8–12 | 10 |
| T8 | 1 | 1–2 à 3–6 | 10 |

**`incanting`** — « de l'Incantation », vitesse d'incantation, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 24–28 % | 10 |
| T2 | 42 | 20–23 % | 10 |
| T3 | 31 | 16–19 % | 10 |
| T4 | 20 | 12–15 % | 10 |
| T5 | 10 | 8–11 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`insulated`** — « du Paratonnerre », rés. foudre, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`keen`** — « du Tranchant », chance critique de base, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 30–36 % | 10 |
| T2 | 36 | 24–29 % | 10 |
| T3 | 24 | 18–23 % | 10 |
| T4 | 12 | 13–17 % | 10 |
| T5 | 1 | 8–12 % | 10 |

**`lightning_skill_levels`** — « du Foudroyeur », niveaux de compétence de foudre, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 60 | 2–2 | 10 |
| T2 | 1 | 1–1 | 10 |

**`lightning_to_attacks`** — « de l'Étincelle », dégâts de foudre aux attaques, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 22–27 à 66–81 | 10 |
| T2 | 43 | 18–22 à 53–65 | 10 |
| T3 | 34 | 14–17 à 41–51 | 10 |
| T4 | 26 | 10–13 à 30–39 | 10 |
| T5 | 19 | 7–10 à 21–29 | 10 |
| T6 | 12 | 5–7 à 14–20 | 10 |
| T7 | 6 | 3–4 à 8–12 | 10 |
| T8 | 1 | 1–2 à 3–6 | 10 |

**`lightning_to_spells`** — « de l'Orage », dégâts de foudre aux sorts, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 22–27 à 66–81 | 10 |
| T2 | 43 | 18–22 à 53–65 | 10 |
| T3 | 34 | 14–17 à 41–51 | 10 |
| T4 | 26 | 10–13 à 30–39 | 10 |
| T5 | 19 | 7–10 à 21–29 | 10 |
| T6 | 12 | 5–7 à 14–20 | 10 |
| T7 | 6 | 3–4 à 8–12 | 10 |
| T8 | 1 | 1–2 à 3–6 | 10 |

**`lucid`** — « de la Lucidité », mana/s, arrondi 0.1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 3.7–4.9 | 10 |
| T2 | 36 | 2.6–3.6 | 10 |
| T3 | 24 | 1.7–2.5 | 10 |
| T4 | 12 | 1–1.6 | 10 |
| T5 | 1 | 0.4–0.9 | 10 |

**`muscular`** — « du Titan », force, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 33–42 | 10 |
| T2 | 42 | 25–32 | 10 |
| T3 | 31 | 18–24 | 10 |
| T4 | 20 | 12–17 | 10 |
| T5 | 10 | 7–11 | 10 |
| T6 | 1 | 3–6 | 10 |

**`necrotic_to_attacks`** — « de la Charogne », dégâts nécrotiques aux attaques, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 22–27 à 66–81 | 10 |
| T2 | 43 | 18–22 à 53–65 | 10 |
| T3 | 34 | 14–17 à 41–51 | 10 |
| T4 | 26 | 10–13 à 30–39 | 10 |
| T5 | 19 | 7–10 à 21–29 | 10 |
| T6 | 12 | 5–7 à 14–20 | 10 |
| T7 | 6 | 3–4 à 8–12 | 10 |
| T8 | 1 | 1–2 à 3–6 | 10 |

**`necrotic_to_spells`** — « de la Peste », dégâts nécrotiques aux sorts, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 22–27 à 66–81 | 10 |
| T2 | 43 | 18–22 à 53–65 | 10 |
| T3 | 34 | 14–17 à 41–51 | 10 |
| T4 | 26 | 10–13 à 30–39 | 10 |
| T5 | 19 | 7–10 à 21–29 | 10 |
| T6 | 12 | 5–7 à 14–20 | 10 |
| T7 | 6 | 3–4 à 8–12 | 10 |
| T8 | 1 | 1–2 à 3–6 | 10 |

**`nimble`** — « de la Célérité », vitesse, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 19–22 % | 10 |
| T2 | 36 | 15–18 % | 10 |
| T3 | 24 | 11–14 % | 10 |
| T4 | 12 | 7–10 % | 10 |
| T5 | 1 | 3–6 % | 10 |

**`physical_to_attacks`** — « de la Brutalité », dégâts physiques aux attaques, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 22–27 à 66–81 | 10 |
| T2 | 43 | 18–22 à 53–65 | 10 |
| T3 | 34 | 14–17 à 41–51 | 10 |
| T4 | 26 | 10–13 à 30–39 | 10 |
| T5 | 19 | 7–10 à 21–29 | 10 |
| T6 | 12 | 5–7 à 14–20 | 10 |
| T7 | 6 | 3–4 à 8–12 | 10 |
| T8 | 1 | 1–2 à 3–6 | 10 |

**`physical_to_spells`** — « de la Poigne », dégâts physiques aux sorts, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 22–27 à 66–81 | 10 |
| T2 | 43 | 18–22 à 53–65 | 10 |
| T3 | 34 | 14–17 à 41–51 | 10 |
| T4 | 26 | 10–13 à 30–39 | 10 |
| T5 | 19 | 7–10 à 21–29 | 10 |
| T6 | 12 | 5–7 à 14–20 | 10 |
| T7 | 6 | 3–4 à 8–12 | 10 |
| T8 | 1 | 1–2 à 3–6 | 10 |

**`plated`** — « du Rempart », armure, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 46–58 % | 10 |
| T2 | 42 | 36–45 % | 10 |
| T3 | 31 | 27–35 % | 10 |
| T4 | 20 | 19–26 % | 10 |
| T5 | 10 | 12–18 % | 10 |
| T6 | 1 | 6–11 % | 10 |

**`precise`** — « de la Précision », chance critique de base, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 50–60 % | 10 |
| T2 | 36 | 40–49 % | 10 |
| T3 | 24 | 30–39 % | 10 |
| T4 | 12 | 20–29 % | 10 |
| T5 | 1 | 10–19 % | 10 |

**`quick`** — « de la Prestesse », vitesse d'attaque, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 24–28 % | 10 |
| T2 | 42 | 20–23 % | 10 |
| T3 | 31 | 16–19 % | 10 |
| T4 | 20 | 12–15 % | 10 |
| T5 | 10 | 8–11 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`reach`** — « de l'Allonge », allonge, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 14–17 | 10 |
| T2 | 36 | 11–13 | 10 |
| T3 | 24 | 8–10 | 10 |
| T4 | 12 | 5–7 | 10 |
| T5 | 1 | 2–4 | 10 |

**`regenerating`** — « de la Régénération », PV/s, arrondi 0.1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 4.9–6.4 | 10 |
| T2 | 36 | 3.5–4.8 | 10 |
| T3 | 24 | 2.3–3.4 | 10 |
| T4 | 12 | 1.3–2.2 | 10 |
| T5 | 1 | 0.5–1.2 | 10 |

**`scorching`** — « du Bûcher », dégâts de sort contre les embrasés, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 40–50 % | 10 |
| T2 | 34 | 30–39 % | 10 |
| T3 | 19 | 20–29 % | 10 |
| T4 | 6 | 13–19 % | 10 |
| T5 | 1 | 8–12 % | 10 |

**`second_wind`** — « du Second Souffle », récupération de recharge, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 17–20 % | 10 |
| T2 | 38 | 13–16 % | 10 |
| T3 | 24 | 9–12 % | 10 |
| T4 | 10 | 5–8 % | 10 |
| T5 | 1 | 3–4 % | 10 |

**`shattering`** — « de la Brisure », dégâts d'attaque contre les transis, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 40–50 % | 10 |
| T2 | 34 | 30–39 % | 10 |
| T3 | 19 | 20–29 % | 10 |
| T4 | 6 | 13–19 % | 10 |
| T5 | 1 | 8–12 % | 10 |

**`shrewd`** — « de la Sagacité », mana, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 78–100 | 10 |
| T2 | 44 | 59–77 | 10 |
| T3 | 34 | 43–58 | 10 |
| T4 | 25 | 30–42 | 10 |
| T5 | 16 | 20–29 | 10 |
| T6 | 8 | 12–19 | 10 |
| T7 | 1 | 6–11 | 10 |

**`stormy`** — « de la Tempête », dégâts de foudre, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 57 | 34–42 % | 10 |
| T2 | 45 | 26–33 % | 10 |
| T3 | 33 | 19–25 % | 10 |
| T4 | 22 | 13–18 % | 10 |
| T5 | 11 | 8–12 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`sturdy`** — « du Colosse », PV, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 35–42 % | 10 |
| T2 | 42 | 27–34 % | 10 |
| T3 | 31 | 20–26 % | 10 |
| T4 | 20 | 14–19 % | 10 |
| T5 | 10 | 9–13 % | 10 |
| T6 | 1 | 5–8 % | 10 |

**`unholy`** — « du Blasphème », rés. sacré, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`vigorous`** — « de la Vigueur », PV, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 52 | 93–112 | 10 |
| T2 | 43 | 75–92 | 10 |
| T3 | 34 | 59–74 | 10 |
| T4 | 26 | 45–58 | 10 |
| T5 | 19 | 33–44 | 10 |
| T6 | 12 | 23–32 | 10 |
| T7 | 6 | 15–22 | 10 |
| T8 | 1 | 8–14 | 10 |

**`whistling`** — « du Sifflement », vitesse de projectile aux projectiles, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 56 | 26–32 % | 10 |
| T2 | 42 | 20–25 % | 10 |
| T3 | 28 | 15–19 % | 10 |
| T4 | 14 | 10–14 % | 10 |
| T5 | 1 | 5–9 % | 10 |

