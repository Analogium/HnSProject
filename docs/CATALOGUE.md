# Référence des données

<!-- Fichier généré par tools/catalogue.sh — ne pas éditer à la main. -->

44 bases d'objets, 12 compétences, 39 affixes d'objets, 5 affixes d'ennemis.

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

| id | nom | lignée | palier | famille | étiquettes | implicite | cases | tombe en zones |
|---|---|---|---|---|---|---|---|---|
| `sword` | Épée | blade | 1 | weapon | weapon, melee, blade | ajoute 2 à 6 dégâts physiques aux attaques | 1 × 3 | 1 à 22 |
| `broadsword` | Épée large | blade | 2 | weapon | weapon, melee, blade | ajoute 5 à 13 dégâts physiques aux attaques | 1 × 3 | 16 à 40 |
| `war_blade` | Lame de guerre | blade | 3 | weapon | weapon, melee, blade | ajoute 8 à 24 dégâts physiques aux attaques | 1 × 3 | 34 et au-delà |
| `dagger` | Dague | dagger | 1 | weapon | weapon, melee, blade | +10 % vitesse d'attaque | 1 × 2 | 1 à 30 |
| `misericorde` | Miséricorde | dagger | 2 | weapon | weapon, melee, blade | +18 % vitesse d'attaque | 1 × 2 | 24 et au-delà |
| `mace` | Masse | contondante | 1 | weapon | weapon, melee, blunt | ajoute 3 à 9 dégâts physiques aux attaques | 1 × 3 | 6 à 28 |
| `battle_mace` | Masse d'armes | contondante | 2 | weapon | weapon, melee, blunt | ajoute 6 à 18 dégâts physiques aux attaques | 1 × 3 | 22 à 46 |
| `war_hammer` | Marteau de guerre | contondante | 3 | weapon | weapon, melee, blunt | ajoute 10 à 32 dégâts physiques aux attaques | 1 × 3 | 40 et au-delà |
| `wand` | Baguette | focus | 1 | weapon | weapon, caster | +15 % vitesse d'incantation | 1 × 2 | 1 à 24 |
| `scepter` | Sceptre | focus | 2 | weapon | weapon, caster | +24 % vitesse d'incantation | 1 × 2 | 18 à 42 |
| `runic_scepter` | Sceptre runique | focus | 3 | weapon | weapon, caster | +34 % vitesse d'incantation | 1 × 2 | 36 et au-delà |
| `shield` | Bouclier | shield | 1 | offhand | offhand, armour, heavy | +18 armure | 2 × 2 | 1 à 21 |
| `kite_shield` | Écu | shield | 2 | offhand | offhand, armour, heavy | +38 armure | 2 × 2 | 15 à 39 |
| `pavise` | Pavois | shield | 3 | offhand | offhand, armour, heavy | +68 armure | 2 × 2 | 33 et au-delà |
| `grimoire` | Grimoire | grimoire | 1 | offhand | offhand, caster | ajoute 3 à 7 dégâts de foudre aux sorts | 2 × 2 | 10 à 34 |
| `codex` | Codex | grimoire | 2 | offhand | offhand, caster | ajoute 6 à 16 dégâts de foudre aux sorts | 2 × 2 | 28 et au-delà |
| `helmet` | Casque | casque_lourd | 1 | helmet | helmet, armour, heavy | +12 PV | 2 × 2 | 1 à 20 |
| `great_helm` | Heaume | casque_lourd | 2 | helmet | helmet, armour, heavy | +26 PV | 2 × 2 | 14 à 38 |
| `armet` | Armet | casque_lourd | 3 | helmet | helmet, armour, heavy | +44 PV | 2 × 2 | 32 et au-delà |
| `hood` | Capuche | casque_leger | 1 | helmet | helmet, armour, light | +14 esquive | 2 × 2 | 1 à 26 |
| `masters_hood` | Capuche de maître | casque_leger | 2 | helmet | helmet, armour, light | +34 esquive | 2 × 2 | 20 et au-delà |
| `breastplate` | Plastron | torse_lourd | 1 | chest | chest, armour, heavy | +20 PV | 2 × 3 | 1 à 23 |
| `chainmail` | Cotte de mailles | torse_lourd | 2 | chest | chest, armour, heavy | +42 PV | 2 × 3 | 17 à 41 |
| `full_plate` | Harnois | torse_lourd | 3 | chest | chest, armour, heavy | +72 PV | 2 × 3 | 35 et au-delà |
| `tunic` | Tunique | torse_leger | 1 | chest | chest, armour, light | +20 esquive | 2 × 3 | 1 à 25 |
| `jerkin` | Justaucorps | torse_leger | 2 | chest | chest, armour, light | +46 esquive | 2 × 3 | 19 et au-delà |
| `gloves` | Gants | gloves | 1 | gloves | gloves, armour, light | +8 % vitesse d'attaque | 2 × 2 | 1 à 19 |
| `reinforced_gloves` | Gants renforcés | gloves | 2 | gloves | gloves, armour, light | +14 % vitesse d'attaque | 2 × 2 | 13 à 37 |
| `masters_gloves` | Gants de maître | gloves | 3 | gloves | gloves, armour, light | +21 % vitesse d'attaque | 2 × 2 | 31 et au-delà |
| `boots` | Bottes | boots | 1 | boots | boots, armour, light | +8 vitesse | 2 × 2 | 1 à 18 |
| `studded_boots` | Bottes cloutées | boots | 2 | boots | boots, armour, light | +14 vitesse | 2 × 2 | 12 à 36 |
| `travel_boots` | Bottes de marche | boots | 3 | boots | boots, armour, light | +20 vitesse | 2 × 2 | 30 et au-delà |
| `belt` | Ceinture | belt | 1 | belt | belt | +1.5 PV/s | 2 × 1 | 1 à 17 |
| `girdle` | Ceinturon | belt | 2 | belt | belt | +3 PV/s | 2 × 1 | 11 à 35 |
| `baldric` | Baudrier | belt | 3 | belt | belt | +5 PV/s | 2 × 1 | 29 et au-delà |
| `amulet` | Amulette | amulet | 1 | amulet | amulet, jewellery | +15 mana | 1 × 1 | 1 à 23 |
| `talisman` | Talisman | amulet | 2 | amulet | amulet, jewellery | +34 mana | 1 × 1 | 17 à 41 |
| `pendant` | Pendentif | amulet | 3 | amulet | amulet, jewellery | +58 mana | 1 × 1 | 35 et au-delà |
| `ring` | Anneau | ring | 1 | ring | ring, jewellery | +2 % chance critique | 1 × 1 | 1 à 22 |
| `ornate_ring` | Bague ouvragée | ring | 2 | ring | ring, jewellery | +4 % chance critique | 1 × 1 | 16 à 40 |
| `signet_ring` | Chevalière | ring | 3 | ring | ring, jewellery | +6 % chance critique | 1 × 1 | 34 et au-delà |
| `manual_lightning` | Manuel de la foudre | manual_lightning | 1 | manual | manual | — | 2 × 2 | 1 et au-delà |
| `manual_weapons` | Manuel du chevalier | manual_weapons | 1 | manual | manual | — | 2 × 2 | 1 et au-delà |
| `manual_fire` | Manuel des flammes | manual_fire | 1 | manual | manual | — | 2 × 2 | 5 et au-delà |

## Manuels

Un manuel gagne **un point par niveau**, 20 au plafond
(`Manual.MAX_LEVEL`), et ses cases, ses passifs et ses nœuds se servent
dans le même sac : la colonne « points » dit ce que chacun accepte, et leur
somme dépasse volontairement ce qu'un livre peut gagner.

### Maître de la foudre — `manual_lightning`

| case | sorte | ouvre à | points | coût | recharge | forme | par point |
|---|---|---|---|---|---|---|---|
| Éclair vif | spell foudre | niveau 1 | 5 | 8 mana | 0.42 s | bolt | 21 · 27 · 34 · 42 · 51 |
| Chaîne d'éclairs | spell foudre | niveau 3 | 5 | 12 mana | 0.70 s | chain · 3 cibles | 17 · 22 · 28 · 35 · 43 |
| Nuage d'orage | spell foudre | niveau 5 | 5 | 22 mana | 1.60 s | cloud · 3.0 s · rayon 34 · toutes les 0.50 s | 9 · 11 · 14 · 17 · 21 |
| Nova de foudre | spell foudre | niveau 8 | 5 | 26 mana | 1.40 s | bolt · ×8 sur 360° | 18 · 22 · 27 · 33 · 40 |
| Conducteur | passif | niveau 2 | 4 | — | — | — | +6 % dégâts (Foudre) · +10 mana |

| nœud | compétence | parent | demande | points | par point |
|---|---|---|---|---|---|
| Surcharge | Éclair vif | — | 1 point de compétence | 3 | +12 % dégâts |
| Fourche | Éclair vif | Surcharge | 2 points de compétence | 1 | +1 nombre de projectiles |
| Trait de glace | Éclair vif | — | 3 points de compétence | 1 | +20 % dégâts · convertit 50 % en froid |
| Ramification | Chaîne d'éclairs | — | 1 point de compétence | 2 | +1 nombre de cibles |
| Haute tension | Chaîne d'éclairs | Ramification | 2 points de compétence | 3 | +12 % dégâts |
| Court-circuit | Chaîne d'éclairs | — | 3 points de compétence | 1 | -1 nombre de cibles · +35 % dégâts |
| Front orageux | Nuage d'orage | — | 1 point de compétence | 2 | +20 % rayon |
| Orage durable | Nuage d'orage | Front orageux | 2 points de compétence | 2 | +25 % durée |
| Grêle | Nuage d'orage | — | 3 points de compétence | 1 | +15 % dégâts · convertit 60 % en froid |
| Couronne | Nova de foudre | — | 1 point de compétence | 2 | +2 nombre de projectiles |
| Déflagration | Nova de foudre | Couronne | 3 points de compétence | 3 | +12 % dégâts |
| Célérité | Nova de foudre | — | 2 points de compétence | 2 | +35 % vitesse de projectile |

47 destinations de points pour 20 gagnés.

### Maître chevalier — `manual_weapons`

| case | sorte | ouvre à | points | coût | recharge | forme | par point |
|---|---|---|---|---|---|---|---|
| Frappe lourde | attack physique | niveau 1 | 5 | 6 mana | weapon | strike | 20 · 26 · 33 · 41 · 50 |
| Coup en croix | attack physique | niveau 3 | 5 | 7 mana | weapon | cross | 13 · 17 · 21 · 26 · 32 |
| Épée spirale | attack physique | niveau 6 | 5 | 10 mana | weapon | orbit · 5.0 s · toutes les 0.50 s · 3 au plus | 8 · 10 · 13 · 16 · 20 |
| Garde de fer | passif | niveau 2 | 4 | — | — | — | +12 armure · +14 PV |

| nœud | compétence | parent | demande | points | par point |
|---|---|---|---|---|---|
| Élan | Frappe lourde | — | 1 point de compétence | 3 | +14 % dégâts |
| Lame ardente | Frappe lourde | Élan | 2 points de compétence | 1 | convertit 40 % en feu · donne le mot-clé Feu |
| Saignée | Frappe lourde | — | 2 points de compétence | 2 | ajoute 3 à 8 dégâts physiques |
| Taille | Coup en croix | — | 1 point de compétence | 3 | +12 % dégâts |
| Estoc | Coup en croix | Taille | 2 points de compétence | 2 | ajoute 2 à 6 dégâts physiques |
| Lame sainte | Coup en croix | — | 3 points de compétence | 1 | convertit 50 % en sacré |
| Ronde | Épée spirale | — | 1 point de compétence | 2 | +1 maximum simultané |
| Tranchant | Épée spirale | Ronde | 2 points de compétence | 3 | +12 % dégâts |
| Endurance | Épée spirale | — | 2 points de compétence | 2 | +30 % durée |

38 destinations de points pour 20 gagnés.

### Maître des flammes — `manual_fire`

| case | sorte | ouvre à | points | coût | recharge | forme | par point |
|---|---|---|---|---|---|---|---|
| Boule de feu | spell feu | niveau 1 | 5 | 11 mana | 0.60 s | ball · rayon 20 | 30 · 38 · 48 · 59 · 73 |
| Serpent infernal | spell feu | niveau 4 | 5 | 18 mana | 1.20 s | snake · 4.0 s · toutes les 0.40 s | 10 · 13 · 16 · 20 · 25 |
| Immolation | spell feu | niveau 9 | 5 | 25 mana | 1.00 s | aura · rayon 40 · toutes les 0.50 s · brûle 3 % PV/s | 8 · 10 · 13 · 16 · 20 |
| Cœur de braise | passif | niveau 2 | 4 | — | — | — | +7 % dégâts (Feu) · +3 % rés. feu |

| nœud | compétence | parent | demande | points | par point |
|---|---|---|---|---|---|
| Attisement | Boule de feu | — | 1 point de compétence | 3 | +13 % dégâts |
| Souffle ardent | Boule de feu | Attisement | 2 points de compétence | 2 | +30 % rayon |
| Double langue | Boule de feu | — | 3 points de compétence | 1 | +1 nombre de projectiles |
| Longue vie | Serpent infernal | — | 1 point de compétence | 2 | +25 % durée |
| Crocs | Serpent infernal | Longue vie | 2 points de compétence | 2 | ajoute 4 à 9 dégâts de feu |
| Mue | Serpent infernal | — | 2 points de compétence | 3 | +12 % dégâts |
| Brasier | Immolation | — | 1 point de compétence | 2 | +20 % rayon |
| Fournaise | Immolation | Brasier | 2 points de compétence | 3 | +14 % dégâts |
| Flamme noire | Immolation | — | 3 points de compétence | 1 | +15 % dégâts · convertit 50 % en nécrotique |

38 destinations de points pour 20 gagnés.

## Affixes d'objets

`vise` vide veut dire « partout », sous réserve d'`interdit`, qui l'emporte.

| id | statistique | vise | interdit | poids | paliers | bases éligibles |
|---|---|---|---|---|---|---|
| `agile` | dextérité | *partout* | — | 8 | 6 | 41 / 44 |
| `ardent` | dégâts (Feu) (%) | caster, jewellery | — | 8 | 6 | 11 / 44 |
| `bewitched` | dégâts (Sort) (%) | caster | — | 8 | 6 | 5 / 44 |
| `bloody` | dégâts critiques | weapon, jewellery | — | 6 | 5 | 17 / 44 |
| `cold_to_attacks` | dégâts de froid aux attaques | melee | — | 2 | 8 | 8 / 44 |
| `cold_to_spells` | dégâts de froid aux sorts | caster, jewellery | — | 2 | 8 | 11 / 44 |
| `cruel` | chance critique | weapon, gloves, jewellery | — | 7 | 5 | 20 / 44 |
| `cuirassed` | armure | armour | — | 9 | 9 | 19 / 44 |
| `elusive` | esquive | light | — | 9 | 8 | 10 / 44 |
| `embalmed` | rés. nécrotique | *partout* | weapon | 9 | 5 | 30 / 44 |
| `erudite` | intelligence | *partout* | — | 8 | 6 | 41 / 44 |
| `fire_to_attacks` | dégâts de feu aux attaques | melee | — | 2 | 8 | 8 / 44 |
| `fire_to_spells` | dégâts de feu aux sorts | caster, jewellery | — | 2 | 8 | 11 / 44 |
| `fireproof` | rés. feu | *partout* | weapon | 9 | 5 | 30 / 44 |
| `forked` | nombre de projectiles (Projectile) | caster | — | 3 | 2 | 5 / 44 |
| `frosted` | rés. froid | *partout* | weapon | 9 | 5 | 30 / 44 |
| `holy_to_attacks` | dégâts sacrés aux attaques | melee | — | 2 | 8 | 8 / 44 |
| `holy_to_spells` | dégâts sacrés aux sorts | caster, jewellery | — | 2 | 8 | 11 / 44 |
| `incanting` | vitesse d'incantation (%) | caster, gloves, jewellery | — | 8 | 6 | 14 / 44 |
| `insulated` | rés. foudre | *partout* | weapon | 9 | 5 | 30 / 44 |
| `lightning_to_attacks` | dégâts de foudre aux attaques | melee | — | 2 | 8 | 8 / 44 |
| `lightning_to_spells` | dégâts de foudre aux sorts | caster, jewellery | — | 2 | 8 | 11 / 44 |
| `lucid` | mana/s | caster, belt, jewellery | — | 6 | 5 | 14 / 44 |
| `muscular` | force | *partout* | — | 8 | 6 | 41 / 44 |
| `necrotic_to_attacks` | dégâts nécrotiques aux attaques | melee | — | 2 | 8 | 8 / 44 |
| `necrotic_to_spells` | dégâts nécrotiques aux sorts | caster, jewellery | — | 2 | 8 | 11 / 44 |
| `nimble` | vitesse (%) | boots | — | 10 | 5 | 3 / 44 |
| `physical_to_attacks` | dégâts physiques aux attaques | melee | — | 2 | 8 | 8 / 44 |
| `physical_to_spells` | dégâts physiques aux sorts | caster, jewellery | — | 2 | 8 | 11 / 44 |
| `plated` | armure (%) | heavy | — | 8 | 6 | 9 / 44 |
| `quick` | vitesse d'attaque (%) | melee, gloves, jewellery | — | 8 | 6 | 17 / 44 |
| `reach` | allonge | melee | — | 8 | 5 | 8 / 44 |
| `regenerating` | PV/s | belt, jewellery | — | 6 | 5 | 9 / 44 |
| `shrewd` | mana | caster, helmet, jewellery | — | 8 | 7 | 16 / 44 |
| `stormy` | dégâts (Foudre) (%) | caster, jewellery | — | 8 | 6 | 11 / 44 |
| `sturdy` | PV (%) | armour, belt | — | 10 | 6 | 22 / 44 |
| `unholy` | rés. sacré | *partout* | weapon | 9 | 5 | 30 / 44 |
| `vigorous` | PV | armour, belt, jewellery | — | 12 | 8 | 28 / 44 |
| `whistling` | vitesse de projectile (Projectile) (%) | caster, gloves | — | 8 | 5 | 8 / 44 |

### Affixes d'ennemis

| id | nom | PV | vitesse | dégâts | recharge | armure | vol de vie | exp |
|---|---|---|---|---|---|---|---|---|
| `colossal` | Colossal | ×2.00 | ×0.80 | ×1.00 | ×1.00 | +0 | 0 % | ×1.80 |
| `swift` | Véloce | ×0.75 | ×1.45 | ×1.00 | ×1.00 | +0 | 0 % | ×1.40 |
| `brutal` | Brutal | ×1.00 | ×1.00 | ×1.60 | ×1.20 | +0 | 0 % | ×1.50 |
| `armored` | Blindé | ×1.00 | ×0.90 | ×1.00 | ×1.00 | +50 | 0 % | ×1.60 |
| `ravenous` | Vorace | ×0.90 | ×1.00 | ×1.00 | ×1.00 | +0 | 25 % | ×1.50 |

Un affixe apparaît sur 18 % des ennemis, deux sur 4 %.

## Échelles de paliers

T1 est le meilleur. « ouvre à » est le niveau d'objet minimum du palier.

**`agile`** — dextérité, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 33–42 | 10 |
| T2 | 42 | 25–32 | 10 |
| T3 | 31 | 18–24 | 10 |
| T4 | 20 | 12–17 | 10 |
| T5 | 10 | 7–11 | 10 |
| T6 | 1 | 3–6 | 10 |

**`ardent`** — dégâts (Feu), arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 57 | 34–42 % | 10 |
| T2 | 45 | 26–33 % | 10 |
| T3 | 33 | 19–25 % | 10 |
| T4 | 22 | 13–18 % | 10 |
| T5 | 11 | 8–12 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`bewitched`** — dégâts (Sort), arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 57 | 34–42 % | 10 |
| T2 | 45 | 26–33 % | 10 |
| T3 | 33 | 19–25 % | 10 |
| T4 | 22 | 13–18 % | 10 |
| T5 | 11 | 8–12 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`bloody`** — dégâts critiques, arrondi 0.01

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 125–150 % | 10 |
| T2 | 36 | 95–120 % | 10 |
| T3 | 24 | 70–90 % | 10 |
| T4 | 12 | 45–65 % | 10 |
| T5 | 1 | 20–40 % | 10 |

**`cold_to_attacks`** — dégâts de froid aux attaques, arrondi 1

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

**`cold_to_spells`** — dégâts de froid aux sorts, arrondi 1

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

**`cruel`** — chance critique, arrondi 0.01

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 15–18 % | 10 |
| T2 | 36 | 11–14 % | 10 |
| T3 | 24 | 8–10 % | 10 |
| T4 | 12 | 5–7 % | 10 |
| T5 | 1 | 2–4 % | 10 |

**`cuirassed`** — armure, arrondi 1

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

**`elusive`** — esquive, arrondi 1

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

**`embalmed`** — rés. nécrotique, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`erudite`** — intelligence, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 33–42 | 10 |
| T2 | 42 | 25–32 | 10 |
| T3 | 31 | 18–24 | 10 |
| T4 | 20 | 12–17 | 10 |
| T5 | 10 | 7–11 | 10 |
| T6 | 1 | 3–6 | 10 |

**`fire_to_attacks`** — dégâts de feu aux attaques, arrondi 1

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

**`fire_to_spells`** — dégâts de feu aux sorts, arrondi 1

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

**`fireproof`** — rés. feu, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`forked`** — nombre de projectiles (Projectile), arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 50 | 2–2 | 10 |
| T2 | 1 | 1–1 | 10 |

**`frosted`** — rés. froid, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`holy_to_attacks`** — dégâts sacrés aux attaques, arrondi 1

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

**`holy_to_spells`** — dégâts sacrés aux sorts, arrondi 1

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

**`incanting`** — vitesse d'incantation, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 24–28 % | 10 |
| T2 | 42 | 20–23 % | 10 |
| T3 | 31 | 16–19 % | 10 |
| T4 | 20 | 12–15 % | 10 |
| T5 | 10 | 8–11 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`insulated`** — rés. foudre, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`lightning_to_attacks`** — dégâts de foudre aux attaques, arrondi 1

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

**`lightning_to_spells`** — dégâts de foudre aux sorts, arrondi 1

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

**`lucid`** — mana/s, arrondi 0.1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 3.7–4.9 | 10 |
| T2 | 36 | 2.6–3.6 | 10 |
| T3 | 24 | 1.7–2.5 | 10 |
| T4 | 12 | 1–1.6 | 10 |
| T5 | 1 | 0.4–0.9 | 10 |

**`muscular`** — force, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 33–42 | 10 |
| T2 | 42 | 25–32 | 10 |
| T3 | 31 | 18–24 | 10 |
| T4 | 20 | 12–17 | 10 |
| T5 | 10 | 7–11 | 10 |
| T6 | 1 | 3–6 | 10 |

**`necrotic_to_attacks`** — dégâts nécrotiques aux attaques, arrondi 1

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

**`necrotic_to_spells`** — dégâts nécrotiques aux sorts, arrondi 1

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

**`nimble`** — vitesse, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 19–22 % | 10 |
| T2 | 36 | 15–18 % | 10 |
| T3 | 24 | 11–14 % | 10 |
| T4 | 12 | 7–10 % | 10 |
| T5 | 1 | 3–6 % | 10 |

**`physical_to_attacks`** — dégâts physiques aux attaques, arrondi 1

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

**`physical_to_spells`** — dégâts physiques aux sorts, arrondi 1

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

**`plated`** — armure, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 46–58 % | 10 |
| T2 | 42 | 36–45 % | 10 |
| T3 | 31 | 27–35 % | 10 |
| T4 | 20 | 19–26 % | 10 |
| T5 | 10 | 12–18 % | 10 |
| T6 | 1 | 6–11 % | 10 |

**`quick`** — vitesse d'attaque, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 24–28 % | 10 |
| T2 | 42 | 20–23 % | 10 |
| T3 | 31 | 16–19 % | 10 |
| T4 | 20 | 12–15 % | 10 |
| T5 | 10 | 8–11 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`reach`** — allonge, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 14–17 | 10 |
| T2 | 36 | 11–13 | 10 |
| T3 | 24 | 8–10 | 10 |
| T4 | 12 | 5–7 | 10 |
| T5 | 1 | 2–4 | 10 |

**`regenerating`** — PV/s, arrondi 0.1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 4.9–6.4 | 10 |
| T2 | 36 | 3.5–4.8 | 10 |
| T3 | 24 | 2.3–3.4 | 10 |
| T4 | 12 | 1.3–2.2 | 10 |
| T5 | 1 | 0.5–1.2 | 10 |

**`shrewd`** — mana, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 78–100 | 10 |
| T2 | 44 | 59–77 | 10 |
| T3 | 34 | 43–58 | 10 |
| T4 | 25 | 30–42 | 10 |
| T5 | 16 | 20–29 | 10 |
| T6 | 8 | 12–19 | 10 |
| T7 | 1 | 6–11 | 10 |

**`stormy`** — dégâts (Foudre), arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 57 | 34–42 % | 10 |
| T2 | 45 | 26–33 % | 10 |
| T3 | 33 | 19–25 % | 10 |
| T4 | 22 | 13–18 % | 10 |
| T5 | 11 | 8–12 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`sturdy`** — PV, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 35–42 % | 10 |
| T2 | 42 | 27–34 % | 10 |
| T3 | 31 | 20–26 % | 10 |
| T4 | 20 | 14–19 % | 10 |
| T5 | 10 | 9–13 % | 10 |
| T6 | 1 | 5–8 % | 10 |

**`unholy`** — rés. sacré, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`vigorous`** — PV, arrondi 1

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

**`whistling`** — vitesse de projectile (Projectile), arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 56 | 26–32 % | 10 |
| T2 | 42 | 20–25 % | 10 |
| T3 | 28 | 15–19 % | 10 |
| T4 | 14 | 10–14 % | 10 |
| T5 | 1 | 5–9 % | 10 |

