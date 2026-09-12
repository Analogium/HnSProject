# Référence des données

<!-- Fichier généré par tools/catalogue.sh — ne pas éditer à la main. -->

44 bases d'objets, 11 compétences, 39 affixes d'objets, 5 affixes d'ennemis.

Deux règles ne se lisent dans aucun `.tres`, et il faut les avoir en tête
pour lire les tables :

- **la colonne « tombe en zones » est calculée.** Une base tombe de son
  `niveau_requis` jusqu'à **6 niveaux** après l'ouverture du palier suivant
  de sa lignée (`ItemCatalog.MARGE_DE_RELEVE`). Insérer un palier au milieu
  d'une lignée raccourcit donc celui d'avant ;
- **tous les paliers d'un affixe ne sortent jamais ensemble.** Un objet n'en a
  que **4** d'ouverts à la fois — le meilleur qu'il atteint et les 3 du
  dessous (`ItemAffix.PALIERS_OUVERTS`). La colonne « ouvre à » des échelles
  donne le plancher, pas la garantie.

Niveaux de zone : 1 à 60.

## Bases d'objets

| id | nom | lignée | palier | famille | étiquettes | implicite | cases | tombe en zones |
|---|---|---|---|---|---|---|---|---|
| `epee` | Épée | lame | 1 | weapon | weapon, melee, blade | ajoute 2 à 6 dégâts physiques aux attaques | 1 × 3 | 1 à 22 |
| `epee_large` | Épée large | lame | 2 | weapon | weapon, melee, blade | ajoute 5 à 13 dégâts physiques aux attaques | 1 × 3 | 16 à 40 |
| `lame_de_guerre` | Lame de guerre | lame | 3 | weapon | weapon, melee, blade | ajoute 8 à 24 dégâts physiques aux attaques | 1 × 3 | 34 et au-delà |
| `dague` | Dague | dague | 1 | weapon | weapon, melee, blade | +10 % vitesse d'attaque | 1 × 2 | 1 à 30 |
| `misericorde` | Miséricorde | dague | 2 | weapon | weapon, melee, blade | +18 % vitesse d'attaque | 1 × 2 | 24 et au-delà |
| `masse` | Masse | contondante | 1 | weapon | weapon, melee, blunt | ajoute 3 à 9 dégâts physiques aux attaques | 1 × 3 | 6 à 28 |
| `masse_d_armes` | Masse d'armes | contondante | 2 | weapon | weapon, melee, blunt | ajoute 6 à 18 dégâts physiques aux attaques | 1 × 3 | 22 à 46 |
| `marteau_de_guerre` | Marteau de guerre | contondante | 3 | weapon | weapon, melee, blunt | ajoute 10 à 32 dégâts physiques aux attaques | 1 × 3 | 40 et au-delà |
| `baguette` | Baguette | focus | 1 | weapon | weapon, caster | +15 % vitesse d'incantation | 1 × 2 | 1 à 24 |
| `sceptre` | Sceptre | focus | 2 | weapon | weapon, caster | +24 % vitesse d'incantation | 1 × 2 | 18 à 42 |
| `sceptre_runique` | Sceptre runique | focus | 3 | weapon | weapon, caster | +34 % vitesse d'incantation | 1 × 2 | 36 et au-delà |
| `bouclier` | Bouclier | bouclier | 1 | offhand | offhand, armour, heavy | +18 armure | 2 × 2 | 1 à 21 |
| `ecu` | Écu | bouclier | 2 | offhand | offhand, armour, heavy | +38 armure | 2 × 2 | 15 à 39 |
| `pavois` | Pavois | bouclier | 3 | offhand | offhand, armour, heavy | +68 armure | 2 × 2 | 33 et au-delà |
| `grimoire` | Grimoire | grimoire | 1 | offhand | offhand, caster | ajoute 3 à 7 dégâts de foudre aux sorts | 2 × 2 | 10 à 34 |
| `codex` | Codex | grimoire | 2 | offhand | offhand, caster | ajoute 6 à 16 dégâts de foudre aux sorts | 2 × 2 | 28 et au-delà |
| `casque` | Casque | casque_lourd | 1 | helmet | helmet, armour, heavy | +12 PV | 2 × 2 | 1 à 20 |
| `heaume` | Heaume | casque_lourd | 2 | helmet | helmet, armour, heavy | +26 PV | 2 × 2 | 14 à 38 |
| `armet` | Armet | casque_lourd | 3 | helmet | helmet, armour, heavy | +44 PV | 2 × 2 | 32 et au-delà |
| `capuche` | Capuche | casque_leger | 1 | helmet | helmet, armour, light | +14 esquive | 2 × 2 | 1 à 26 |
| `capuche_de_maitre` | Capuche de maître | casque_leger | 2 | helmet | helmet, armour, light | +34 esquive | 2 × 2 | 20 et au-delà |
| `plastron` | Plastron | torse_lourd | 1 | chest | chest, armour, heavy | +20 PV | 2 × 3 | 1 à 23 |
| `cotte_de_mailles` | Cotte de mailles | torse_lourd | 2 | chest | chest, armour, heavy | +42 PV | 2 × 3 | 17 à 41 |
| `harnois` | Harnois | torse_lourd | 3 | chest | chest, armour, heavy | +72 PV | 2 × 3 | 35 et au-delà |
| `tunique` | Tunique | torse_leger | 1 | chest | chest, armour, light | +20 esquive | 2 × 3 | 1 à 25 |
| `justaucorps` | Justaucorps | torse_leger | 2 | chest | chest, armour, light | +46 esquive | 2 × 3 | 19 et au-delà |
| `gants` | Gants | gants | 1 | gloves | gloves, armour, light | +8 % vitesse d'attaque | 2 × 2 | 1 à 19 |
| `gants_renforces` | Gants renforcés | gants | 2 | gloves | gloves, armour, light | +14 % vitesse d'attaque | 2 × 2 | 13 à 37 |
| `gants_de_maitre` | Gants de maître | gants | 3 | gloves | gloves, armour, light | +21 % vitesse d'attaque | 2 × 2 | 31 et au-delà |
| `bottes` | Bottes | bottes | 1 | boots | boots, armour, light | +8 vitesse | 2 × 2 | 1 à 18 |
| `bottes_cloutees` | Bottes cloutées | bottes | 2 | boots | boots, armour, light | +14 vitesse | 2 × 2 | 12 à 36 |
| `bottes_de_marche` | Bottes de marche | bottes | 3 | boots | boots, armour, light | +20 vitesse | 2 × 2 | 30 et au-delà |
| `ceinture` | Ceinture | ceinture | 1 | belt | belt | +1.5 PV/s | 2 × 1 | 1 à 17 |
| `ceinturon` | Ceinturon | ceinture | 2 | belt | belt | +3 PV/s | 2 × 1 | 11 à 35 |
| `baudrier` | Baudrier | ceinture | 3 | belt | belt | +5 PV/s | 2 × 1 | 29 et au-delà |
| `amulette` | Amulette | amulette | 1 | amulet | amulet, jewellery | +15 mana | 1 × 1 | 1 à 23 |
| `talisman` | Talisman | amulette | 2 | amulet | amulet, jewellery | +34 mana | 1 × 1 | 17 à 41 |
| `pendentif` | Pendentif | amulette | 3 | amulet | amulet, jewellery | +58 mana | 1 × 1 | 35 et au-delà |
| `anneau` | Anneau | anneau | 1 | ring | ring, jewellery | +2 % chance critique | 1 × 1 | 1 à 22 |
| `bague_ouvragee` | Bague ouvragée | anneau | 2 | ring | ring, jewellery | +4 % chance critique | 1 × 1 | 16 à 40 |
| `chevaliere` | Chevalière | anneau | 3 | ring | ring, jewellery | +6 % chance critique | 1 × 1 | 34 et au-delà |
| `manuel_foudre` | Manuel de la foudre | manuel_foudre | 1 | manual | manual | — | 2 × 2 | 1 et au-delà |
| `manuel_armes` | Manuel d'armes | manuel_armes | 1 | manual | manual | — | 2 × 2 | 1 et au-delà |
| `manuel_feu` | Manuel des flammes | manuel_feu | 1 | manual | manual | — | 2 × 2 | 5 et au-delà |

## Manuels

Un manuel gagne **un point par niveau**, 20 au plafond
(`Manuel.NIVEAU_MAX`), et ses cases, ses passifs et ses nœuds se servent
dans le même sac : la colonne « points » dit ce que chacun accepte, et leur
somme dépasse volontairement ce qu'un livre peut gagner.

### Maître de la foudre — `manuel_foudre`

| case | sorte | ouvre à | points | coût | recharge | traits | par point |
|---|---|---|---|---|---|---|---|
| Éclair vif | sort foudre | niveau 1 | 5 | 8 mana | 0.42 s | 1 | 21 · 27 · 34 · 42 · 51 |
| Salve d'éclairs | sort foudre | niveau 3 | 5 | 14 mana | 0.62 s | 3 | 16 · 19 · 23 · 28 · 34 |
| Fulguration | sort foudre | niveau 5 | 5 | 18 mana | 0.95 s | 1 | 41 · 53 · 68 · 86 · 107 |
| Nova de foudre | sort foudre | niveau 8 | 5 | 26 mana | 1.40 s | 8 | 18 · 22 · 27 · 33 · 40 |
| Conducteur | passif | niveau 2 | 4 | — | — | — | +6 % dégâts (Foudre) · +10 mana |

| nœud | compétence | parent | demande | points | par point |
|---|---|---|---|---|---|
| Surcharge | Éclair vif | — | 1 point de compétence | 3 | +12 % dégâts |
| Fourche | Éclair vif | Surcharge | 2 points de compétence | 1 | +1 nombre de projectiles |
| Trait de glace | Éclair vif | — | 3 points de compétence | 1 | +20 % dégâts · convertit 50 % en froid |
| Volée | Salve d'éclairs | — | 1 point de compétence | 2 | +1 nombre de projectiles |
| Empennage | Salve d'éclairs | Volée | 2 points de compétence | 2 | +20 % vitesse de projectile |
| Percée | Salve d'éclairs | — | 3 points de compétence | 3 | +14 % dégâts |
| Amplitude | Fulguration | — | 1 point de compétence | 3 | +15 % dégâts |
| Embrasement | Fulguration | Amplitude | 3 points de compétence | 1 | convertit 60 % en feu · donne le mot-clé Feu |
| Éclats | Fulguration | — | 2 points de compétence | 1 | +2 nombre de projectiles · -25 % dégâts |
| Couronne | Nova de foudre | — | 1 point de compétence | 2 | +2 nombre de projectiles |
| Déflagration | Nova de foudre | Couronne | 3 points de compétence | 3 | +12 % dégâts |
| Célérité | Nova de foudre | — | 2 points de compétence | 2 | +35 % vitesse de projectile |

48 destinations de points pour 20 gagnés.

### Maître d'armes — `manuel_armes`

| case | sorte | ouvre à | points | coût | recharge | traits | par point |
|---|---|---|---|---|---|---|---|
| Frappe lourde | attaque physique | niveau 1 | 5 | 6 mana | arme | 1 | 20 · 26 · 33 · 41 · 50 |
| Lames tournoyantes | attaque physique | niveau 3 | 5 | 9 mana | arme | 2 | 11 · 14 · 18 · 22 · 27 |
| Garde de fer | passif | niveau 2 | 4 | — | — | — | +12 armure · +14 PV |

| nœud | compétence | parent | demande | points | par point |
|---|---|---|---|---|---|
| Élan | Frappe lourde | — | 1 point de compétence | 3 | +14 % dégâts |
| Lame ardente | Frappe lourde | Élan | 2 points de compétence | 1 | convertit 40 % en feu · donne le mot-clé Feu |
| Saignée | Frappe lourde | — | 2 points de compétence | 2 | ajoute 3 à 8 dégâts physiques |
| Gerbe d'acier | Lames tournoyantes | — | 1 point de compétence | 2 | +1 nombre de projectiles |
| Affûtage | Lames tournoyantes | Gerbe d'acier | 2 points de compétence | 3 | +12 % dégâts |
| Retour de lame | Lames tournoyantes | — | 2 points de compétence | 2 | +30 % vitesse de projectile |

27 destinations de points pour 20 gagnés.

### Maître des flammes — `manuel_feu`

| case | sorte | ouvre à | points | coût | recharge | traits | par point |
|---|---|---|---|---|---|---|---|
| Trait de feu | sort feu | niveau 1 | 5 | 10 mana | 0.55 s | 1 | 28 · 35 · 44 · 54 · 67 |
| Gerbe de flammes | sort feu | niveau 4 | 5 | 20 mana | 0.85 s | 5 | 15 · 18 · 22 · 27 · 33 |
| Comète | sort feu | niveau 9 | 5 | 30 mana | 1.50 s | 1 | 62 · 78 · 98 · 123 · 154 |
| Cœur de braise | passif | niveau 2 | 4 | — | — | — | +7 % dégâts (Feu) · +3 % rés. feu |

| nœud | compétence | parent | demande | points | par point |
|---|---|---|---|---|---|
| Attisement | Trait de feu | — | 1 point de compétence | 3 | +13 % dégâts |
| Double langue | Trait de feu | Attisement | 2 points de compétence | 1 | +1 nombre de projectiles |
| Braises | Trait de feu | — | 2 points de compétence | 2 | ajoute 4 à 9 dégâts de feu |
| Souffle | Gerbe de flammes | — | 1 point de compétence | 3 | +12 % dégâts |
| Nuée | Gerbe de flammes | Souffle | 2 points de compétence | 2 | +2 nombre de projectiles |
| Cendres | Gerbe de flammes | — | 3 points de compétence | 1 | +15 % dégâts · convertit 50 % en nécrotique |
| Masse | Comète | — | 1 point de compétence | 3 | +16 % dégâts |
| Fragmentation | Comète | Masse | 3 points de compétence | 1 | +3 nombre de projectiles · -35 % dégâts |
| Chute rapide | Comète | — | 2 points de compétence | 2 | +25 % vitesse de projectile |

37 destinations de points pour 20 gagnés.

## Affixes d'objets

`vise` vide veut dire « partout », sous réserve d'`interdit`, qui l'emporte.

| id | statistique | vise | interdit | poids | paliers | bases éligibles |
|---|---|---|---|---|---|---|
| `agile` | dextérité | *partout* | — | 8 | 6 | 41 / 44 |
| `allonge` | allonge | melee | — | 8 | 5 | 8 / 44 |
| `ardent` | dégâts (Feu) (%) | caster, jewellery | — | 8 | 6 | 11 / 44 |
| `cruel` | chance critique | weapon, gloves, jewellery | — | 7 | 5 | 20 / 44 |
| `cuirasse` | armure | armour | — | 9 | 9 | 19 / 44 |
| `embaume` | rés. nécrotique | *partout* | weapon | 9 | 5 | 30 / 44 |
| `ensorcele` | dégâts (Sort) (%) | caster | — | 8 | 6 | 5 / 44 |
| `erudit` | intelligence | *partout* | — | 8 | 6 | 41 / 44 |
| `feu_aux_attaques` | dégâts de feu aux attaques | melee | — | 2 | 8 | 8 / 44 |
| `feu_aux_sorts` | dégâts de feu aux sorts | caster, jewellery | — | 2 | 8 | 11 / 44 |
| `foudre_aux_attaques` | dégâts de foudre aux attaques | melee | — | 2 | 8 | 8 / 44 |
| `foudre_aux_sorts` | dégâts de foudre aux sorts | caster, jewellery | — | 2 | 8 | 11 / 44 |
| `fourchu` | nombre de projectiles (Projectile) | caster | — | 3 | 2 | 5 / 44 |
| `froid_aux_attaques` | dégâts de froid aux attaques | melee | — | 2 | 8 | 8 / 44 |
| `froid_aux_sorts` | dégâts de froid aux sorts | caster, jewellery | — | 2 | 8 | 11 / 44 |
| `fuyant` | esquive | light | — | 9 | 8 | 10 / 44 |
| `givre` | rés. froid | *partout* | weapon | 9 | 5 | 30 / 44 |
| `ignifuge` | rés. feu | *partout* | weapon | 9 | 5 | 30 / 44 |
| `impie` | rés. sacré | *partout* | weapon | 9 | 5 | 30 / 44 |
| `incantateur` | vitesse d'incantation (%) | caster, gloves, jewellery | — | 8 | 6 | 14 / 44 |
| `isole` | rés. foudre | *partout* | weapon | 9 | 5 | 30 / 44 |
| `limpide` | mana/s | caster, belt, jewellery | — | 6 | 5 | 14 / 44 |
| `muscle` | force | *partout* | — | 8 | 6 | 41 / 44 |
| `necrotique_aux_attaques` | dégâts nécrotiques aux attaques | melee | — | 2 | 8 | 8 / 44 |
| `necrotique_aux_sorts` | dégâts nécrotiques aux sorts | caster, jewellery | — | 2 | 8 | 11 / 44 |
| `orageux` | dégâts (Foudre) (%) | caster, jewellery | — | 8 | 6 | 11 / 44 |
| `physique_aux_attaques` | dégâts physiques aux attaques | melee | — | 2 | 8 | 8 / 44 |
| `physique_aux_sorts` | dégâts physiques aux sorts | caster, jewellery | — | 2 | 8 | 11 / 44 |
| `plaque` | armure (%) | heavy | — | 8 | 6 | 9 / 44 |
| `preste` | vitesse (%) | boots | — | 10 | 5 | 3 / 44 |
| `regenerant` | PV/s | belt, jewellery | — | 6 | 5 | 9 / 44 |
| `robuste` | PV (%) | armour, belt | — | 10 | 6 | 22 / 44 |
| `sacre_aux_attaques` | dégâts sacrés aux attaques | melee | — | 2 | 8 | 8 / 44 |
| `sacre_aux_sorts` | dégâts sacrés aux sorts | caster, jewellery | — | 2 | 8 | 11 / 44 |
| `sagace` | mana | caster, helmet, jewellery | — | 8 | 7 | 16 / 44 |
| `sanglant` | dégâts critiques | weapon, jewellery | — | 6 | 5 | 17 / 44 |
| `sifflant` | vitesse de projectile (Projectile) (%) | caster, gloves | — | 8 | 5 | 8 / 44 |
| `vif` | vitesse d'attaque (%) | melee, gloves, jewellery | — | 8 | 6 | 17 / 44 |
| `vigoureux` | PV | armour, belt, jewellery | — | 12 | 8 | 28 / 44 |

### Affixes d'ennemis

| id | nom | PV | vitesse | dégâts | recharge | armure | vol de vie | exp |
|---|---|---|---|---|---|---|---|---|
| `colossal` | Colossal | ×2.00 | ×0.80 | ×1.00 | ×1.00 | +0 | 0 % | ×1.80 |
| `veloce` | Véloce | ×0.75 | ×1.45 | ×1.00 | ×1.00 | +0 | 0 % | ×1.40 |
| `brutal` | Brutal | ×1.00 | ×1.00 | ×1.60 | ×1.20 | +0 | 0 % | ×1.50 |
| `blinde` | Blindé | ×1.00 | ×0.90 | ×1.00 | ×1.00 | +50 | 0 % | ×1.60 |
| `vorace` | Vorace | ×0.90 | ×1.00 | ×1.00 | ×1.00 | +0 | 25 % | ×1.50 |

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

**`allonge`** — allonge, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 14–17 | 10 |
| T2 | 36 | 11–13 | 10 |
| T3 | 24 | 8–10 | 10 |
| T4 | 12 | 5–7 | 10 |
| T5 | 1 | 2–4 | 10 |

**`ardent`** — dégâts (Feu), arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 57 | 34–42 % | 10 |
| T2 | 45 | 26–33 % | 10 |
| T3 | 33 | 19–25 % | 10 |
| T4 | 22 | 13–18 % | 10 |
| T5 | 11 | 8–12 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`cruel`** — chance critique, arrondi 0.01

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 15–18 % | 10 |
| T2 | 36 | 11–14 % | 10 |
| T3 | 24 | 8–10 % | 10 |
| T4 | 12 | 5–7 % | 10 |
| T5 | 1 | 2–4 % | 10 |

**`cuirasse`** — armure, arrondi 1

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

**`embaume`** — rés. nécrotique, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`ensorcele`** — dégâts (Sort), arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 57 | 34–42 % | 10 |
| T2 | 45 | 26–33 % | 10 |
| T3 | 33 | 19–25 % | 10 |
| T4 | 22 | 13–18 % | 10 |
| T5 | 11 | 8–12 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`erudit`** — intelligence, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 33–42 | 10 |
| T2 | 42 | 25–32 | 10 |
| T3 | 31 | 18–24 | 10 |
| T4 | 20 | 12–17 | 10 |
| T5 | 10 | 7–11 | 10 |
| T6 | 1 | 3–6 | 10 |

**`feu_aux_attaques`** — dégâts de feu aux attaques, arrondi 1

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

**`feu_aux_sorts`** — dégâts de feu aux sorts, arrondi 1

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

**`foudre_aux_attaques`** — dégâts de foudre aux attaques, arrondi 1

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

**`foudre_aux_sorts`** — dégâts de foudre aux sorts, arrondi 1

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

**`fourchu`** — nombre de projectiles (Projectile), arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 50 | 2–2 | 10 |
| T2 | 1 | 1–1 | 10 |

**`froid_aux_attaques`** — dégâts de froid aux attaques, arrondi 1

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

**`froid_aux_sorts`** — dégâts de froid aux sorts, arrondi 1

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

**`fuyant`** — esquive, arrondi 1

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

**`givre`** — rés. froid, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`ignifuge`** — rés. feu, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`impie`** — rés. sacré, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`incantateur`** — vitesse d'incantation, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 24–28 % | 10 |
| T2 | 42 | 20–23 % | 10 |
| T3 | 31 | 16–19 % | 10 |
| T4 | 20 | 12–15 % | 10 |
| T5 | 10 | 8–11 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`isole`** — rés. foudre, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 29–36 % | 10 |
| T2 | 36 | 22–28 % | 10 |
| T3 | 24 | 16–21 % | 10 |
| T4 | 12 | 10–15 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`limpide`** — mana/s, arrondi 0.1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 3.7–4.9 | 10 |
| T2 | 36 | 2.6–3.6 | 10 |
| T3 | 24 | 1.7–2.5 | 10 |
| T4 | 12 | 1–1.6 | 10 |
| T5 | 1 | 0.4–0.9 | 10 |

**`muscle`** — force, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 33–42 | 10 |
| T2 | 42 | 25–32 | 10 |
| T3 | 31 | 18–24 | 10 |
| T4 | 20 | 12–17 | 10 |
| T5 | 10 | 7–11 | 10 |
| T6 | 1 | 3–6 | 10 |

**`necrotique_aux_attaques`** — dégâts nécrotiques aux attaques, arrondi 1

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

**`necrotique_aux_sorts`** — dégâts nécrotiques aux sorts, arrondi 1

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

**`orageux`** — dégâts (Foudre), arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 57 | 34–42 % | 10 |
| T2 | 45 | 26–33 % | 10 |
| T3 | 33 | 19–25 % | 10 |
| T4 | 22 | 13–18 % | 10 |
| T5 | 11 | 8–12 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`physique_aux_attaques`** — dégâts physiques aux attaques, arrondi 1

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

**`physique_aux_sorts`** — dégâts physiques aux sorts, arrondi 1

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

**`plaque`** — armure, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 46–58 % | 10 |
| T2 | 42 | 36–45 % | 10 |
| T3 | 31 | 27–35 % | 10 |
| T4 | 20 | 19–26 % | 10 |
| T5 | 10 | 12–18 % | 10 |
| T6 | 1 | 6–11 % | 10 |

**`preste`** — vitesse, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 19–22 % | 10 |
| T2 | 36 | 15–18 % | 10 |
| T3 | 24 | 11–14 % | 10 |
| T4 | 12 | 7–10 % | 10 |
| T5 | 1 | 3–6 % | 10 |

**`regenerant`** — PV/s, arrondi 0.1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 4.9–6.4 | 10 |
| T2 | 36 | 3.5–4.8 | 10 |
| T3 | 24 | 2.3–3.4 | 10 |
| T4 | 12 | 1.3–2.2 | 10 |
| T5 | 1 | 0.5–1.2 | 10 |

**`robuste`** — PV, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 35–42 % | 10 |
| T2 | 42 | 27–34 % | 10 |
| T3 | 31 | 20–26 % | 10 |
| T4 | 20 | 14–19 % | 10 |
| T5 | 10 | 9–13 % | 10 |
| T6 | 1 | 5–8 % | 10 |

**`sacre_aux_attaques`** — dégâts sacrés aux attaques, arrondi 1

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

**`sacre_aux_sorts`** — dégâts sacrés aux sorts, arrondi 1

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

**`sagace`** — mana, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 78–100 | 10 |
| T2 | 44 | 59–77 | 10 |
| T3 | 34 | 43–58 | 10 |
| T4 | 25 | 30–42 | 10 |
| T5 | 16 | 20–29 | 10 |
| T6 | 8 | 12–19 | 10 |
| T7 | 1 | 6–11 | 10 |

**`sanglant`** — dégâts critiques, arrondi 0.01

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 48 | 125–150 % | 10 |
| T2 | 36 | 95–120 % | 10 |
| T3 | 24 | 70–90 % | 10 |
| T4 | 12 | 45–65 % | 10 |
| T5 | 1 | 20–40 % | 10 |

**`sifflant`** — vitesse de projectile (Projectile), arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 56 | 26–32 % | 10 |
| T2 | 42 | 20–25 % | 10 |
| T3 | 28 | 15–19 % | 10 |
| T4 | 14 | 10–14 % | 10 |
| T5 | 1 | 5–9 % | 10 |

**`vif`** — vitesse d'attaque, arrondi 1

| palier | ouvre à | plage | poids |
|---|---|---|---|
| T1 | 54 | 24–28 % | 10 |
| T2 | 42 | 20–23 % | 10 |
| T3 | 31 | 16–19 % | 10 |
| T4 | 20 | 12–15 % | 10 |
| T5 | 10 | 8–11 % | 10 |
| T6 | 1 | 4–7 % | 10 |

**`vigoureux`** — PV, arrondi 1

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

