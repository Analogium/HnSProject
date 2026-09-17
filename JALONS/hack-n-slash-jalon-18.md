# Hack'n'slash top-down — jalon 18

Suite des jalons 1 à 17. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Écrit le 17 septembre 2026, après la livraison.** Depuis le jalon 6, une compétence
est un livre et un point, et l'arme n'est qu'un porteur de lignes : une épée lance un
éclair aussi bien qu'une baguette, et la chance critique est un nombre de la fiche,
identique pour tout ce qui part. Ce jalon rend l'arme **nécessaire** : elle décide ce
qu'on peut lancer, et elle porte la base critique de tout ce qu'on lance.

---

## 1. Périmètre

**Dedans :**

- **Une compétence exige son arme.** Un sort ne part que d'une arme d'incantation, une
  attaque que d'une autre arme. Les mains vides ne lancent rien.
- **Chaque arme a sa chance critique de base**, et **elle seule** en donne une :
  « Chance critique de base : 10 % » sous l'implicite pour les armes d'attaque, 5 % pour
  les armes d'incantation.
- **Les lignes de critique d'une arme sont locales**, de deux sortes : « +4 % de chance
  critique de base (local) », un plat, et « +30 % de chance critique de base accrue
  (local) ». Elles changent le chiffre de l'arme, que l'infobulle montre.
- **Hors de l'arme, une chance critique n'est qu'accrue** — « +20 % de chance critique de
  base accrue » : implicites d'anneaux, affixes de gants et de bijoux, nœuds de l'arbre.
  Elle multiplie la base, globale, aux attaques ou aux sorts.
- **Un kit de départ**, puisqu'un personnage neuf sans arme ne lancerait rien.

**Dehors :**

- **Des types d'armes plus fins** (arc, bâton, deux mains). Deux familles suffisent pour
  la règle ; la troisième se fera quand une compétence la demandera.
- **Une main gauche qui compte.** Le grimoire est `caster` mais n'est pas une arme : il
  ne rend aucun sort lançable.
- **Un retour visuel du refus** dans la barre (case grisée, message). La touche ne fait
  rien, comme pour une réserve vide.
- **Le multiplicateur critique par arme.** Il reste celui de la fiche.

---

## 2. Les règles

### Quelle arme pour quelle compétence

La cadence d'une compétence donne déjà son mot-clé (`WEAPON` → `attack`, `CAST` →
`spell`). L'arme en donne un aussi :

| Arme | Étiquette | Laisse lancer |
|---|---|---|
| épée, dague, masse et leurs paliers | `melee` | les attaques |
| baguette, sceptre, sceptre runique | `caster` | les sorts |
| rien, ou un objet d'une autre famille | — | rien |

`Skill.usable_with(weapon)` compare les deux. `Player.cast_slot()` y gagne un sixième
refus, **placé après l'extinction d'une aura** : changer d'arme ne doit pas laisser une
Immolation allumée qu'on ne peut plus éteindre. Le refus ne coûte ni mana ni recharge.

### D'où vient la chance critique d'un coup

```
arme   = (base de l'arme + plats locaux) × (1 + accrus locaux)
chance = arme × (1 + accrus du reste : globaux, et ceux qui visent la compétence)
```

bornée à [0, 1], tirée à chaque coup par `DamageInfo.roll()`.

- **L'arme** : `Item.crit_chance()`. `Item.mods()` ne verse pas les lignes locales à la
  fiche ; il verse **une seule** ligne plate, le total de l'arme. C'est tout ce que porte
  `CharacterStats.crit_chance` : la base du lancer.
- **Les accrus** ne touchent jamais la fiche. `Player.recompute_stats()` les envoie au
  lancer, et `Skill.resolve()` les applique avec ceux que porte un mot-clé.

Une ligne est locale quand `ItemBase.is_local()` le dit : aujourd'hui, la chance critique
sur une arme, plate ou accrue.

| Affixe | Sur | Ligne |
|---|---|---|
| `cruel` | armes | « +1 à +4 % de chance critique de base (local) », plat, trois paliers (niveaux 1, 24, 48) |
| `precise` (neuf) | armes | « +10 à +60 % de chance critique de base accrue (local) » |
| `keen` (neuf) | gants, bijoux | « +8 à +36 % de chance critique de base accrue » |

Les implicites d'anneaux passent de +2/+4/+6 plats à **+8/+14/+20 % accrus** ; Tir précis
de +2 plats à +20 % accrus, Œil de lynx de +3 plats à +30 % accrus. Les libellés suivent :
`StatMod.LABELS` dit « chance critique de base », un plat s'écrit « +4 % de chance critique
de base » (`StatMod.ADDED_TO_BASE`, « +4% to base crit chance »). Seule la page du manuel
garde « chance critique » : elle montre la chance du coup, accrus compris.

---

## 3. Ce que ça change dans le code

| Fichier | Ce qui change |
|---|---|
| `core/item_base.gd` | `crit_chance` (groupe « Arme »), `allowed_keyword()`, `is_local()`, `WEAPON_FAMILY`, `CASTER_TAG` |
| `core/item.gd` | `crit_chance()`, `crit_line()`, `explicit_line()` ; `mods()` remplace les lignes locales par le total |
| `core/skill.gd` | `usable_with()` ; `resolve()` part de `stats.crit_chance`. Le champ `Skill.crit_chance` disparaît |
| `actors/player/player.gd` | le refus dans `cast_slot()` ; l'accru de critique sans portée part au lancer |
| `core/damage_info.gd` | `roll()` prend le lancer et non la fiche : un tir, une chaîne, un nuage critiquent aussi |
| `core/save_store.gd` | le kit de départ, dans `create()` |
| `world/zone.gd`, `world/test_arena.gd` | l'épée de départ quand aucun personnage n'est chargé |
| `ui/inventory_panel.gd` | la ligne « Chance critique : X % » sous l'implicite, bleue quand une ligne locale l'a montée ; « (local) » |
| `resources/items/*.tres` | `crit_chance` sur les onze armes |
| `tools/balance/profiles.gd` | le débutant reçoit l'arme nue de sa voie |
| `tools/catalog_generator.gd`, `art/forge_gallery.gd` | la base critique de chaque arme |

**Le kit dans `SaveStore.create()` et non dans `Character.create_new()`.** Ce dernier
fabrique aussi les personnages des tests et du banc : une vingtaine de tests de
sauvegarde comptent le sac et l'équipement d'un personnage neuf, et n'ont rien à voir
avec le kit. `create()` est le chemin de l'écran de sélection, le seul qui fait un
personnage qu'on va jouer.

---

## 4. Les sauvegardes

**Aucun format ne change.** La base critique est sur le `.tres`, jamais dans le fichier
(invariant 7 intact, `Character.VERSION` inchangé). Une ligne `cruel` déjà tirée sur
une arme se relit telle quelle et devient locale d'elle-même — même valeur, même calcul
pour une arme : plat avant les accrus.

**Une chance critique plate relue hors d'une arme est retirée**, avec un avertissement
(`Character._current_line()`) : un plat n'a pas d'équivalent en accru, et la doctrine
des sauvegardes interdit de deviner. Aucun personnage de l'utilisateur n'en portait.

**Un personnage existant sans aucune arme ne lance plus rien** tant qu'il n'en ramasse
pas une. Pas de rattrapage à la relecture : deviner ce qu'il aurait voulu porter serait
une seconde vérité, et les personnages joués jusqu'ici ont une arme.

---

## 5. Le banc et ce qu'on attend

- **Attendu** : la Mêlée critique deux fois plus (10 % contre 5 %), donc un peu moins
  de coups partout ; le Sort ne bouge pas (5 %, comme avant).
- **Non attendu** : un couloir qui passe. Les échecs du jalon 17 sont des murs de
  zones 90 et 120 et un débutant tendu en zone 1 ; quelques pour cent de critique ne
  les comblent pas.
- **Aucun chiffre de couloir ne se change pour faire passer un couloir** (jalon 13, §4).

---

## 6. Arbitrages

**La base est une ligne de la fiche, pas un champ à part du lancer.** On aurait pu
passer l'arme à `Skill.resolve()`. Mais tout est additif avant les accrus : verser le
total de l'arme en ligne plate donne le même nombre, sans nouvel argument dans la seule
fonction qui résout un lancer — et la fiche de personnage affiche la base telle qu'elle
est.

**Locale par une règle, pas par un affixe.** `ItemBase.is_local()` lit la ligne là où
elle est posée : un `cruel` déjà tiré sur une arme devient local sans conversion.
`cruel` garde son identifiant et ne va plus que sur les armes ; l'accru a ses deux
affixes neufs, parce qu'un affixe n'a qu'un mode.

**La main gauche ne compte pas.** Un grimoire qui rendrait les sorts lançables
ferait d'une épée + grimoire un personnage qui lance tout, et la règle ne vaudrait plus
rien.

**L'arme de départ est une vraie base du catalogue**, pas un objet fabriqué : elle
tombe aussi en zone et se compare aux autres. L'épée en main parce que la première
touche de la barre est l'attaque ; la baguette dans le sac parce que le premier manuel est
celui de la foudre, et qu'aller l'équiper est le premier geste qu'on apprend.

**Les tests lancent avec une arme sans implicite** (`tests/weapons.gd`). La baguette du
catalogue ajoute 15 % de vitesse d'incantation : un test d'intervalle aurait vu sa fiche
changer pour une raison qui n'est pas la sienne.

---

## 7. À trancher

1. ~~Les critiques plats hors arme~~ — tranché le 17 septembre : seule l'arme donne une
   base, tout le reste est accru (§2).
2. **Le refus visible** : griser dans la barre une compétence que l'arme portée ne laisse
   pas lancer.

---

## 8. Ce qui refusera un oubli

- **`test_each_weapon_has_its_crit_and_its_kind`** (`tests/unit/test_loot.gd`) — chaque
  base : 10 % et `attack` pour une arme d'attaque, 5 % et `spell` pour une arme
  d'incantation, zéro et rien hors des armes. Une arme ajoutée sans `crit_chance` y
  échoue.
- **`test_a_crit_line_is_local_on_a_weapon_only`** — la ligne monte l'arme, n'arrive
  qu'une fois à la fiche, s'écrit « (local) » ; sur un anneau, rien de tout ça.
- **`test_a_skill_wants_the_weapon_of_its_cadence`** (`test_skills.gd`) — épée,
  baguette, grimoire et mains vides, contre l'attaque et le tir.
- **`test_the_crit_chance_starts_from_the_sheet`** — base, accrus portés et non portés,
  borne.
- **`test_cast_refuses_a_skill_its_weapon_does_not_allow`** (`test_player.gd`) — mains
  vides, épée, baguette ; le refus ne coûte rien.
- **`test_the_sheet_announces_the_crit_of_the_skill`** (`test_manual_panel.gd`) — la page
  du manuel lit la baguette, sa ligne locale et l'accru aux sorts : (5 + 3) × 1,5 = 12 %.
- **Le critère du jalon 6** refuse l'éclair à l'épée de départ, puis le lance après avoir
  équipé la baguette du sac.
- `test_persistence.gd` — un personnage neuf arrive épée en main, baguette au sac, et
  les retrouve après relecture.
- `test_bench_profiles.gd` — le débutant porte la seule arme de sa voie.
- **`test_no_flat_crit_outside_a_weapon`** (`test_loot.gd`) — aucun implicite, affixe ni
  nœud de l'arbre ne donne de chance critique plate hors d'une arme.
- **`test_crit_lines_name_the_base`** (`test_stat_mod.gd`) — les deux libellés, en français
  et en anglais.
- **`test_a_flat_crit_outside_a_weapon_is_removed`** (`test_save.gd`) — la relecture.

---

## 9. Livré le 17 septembre 2026

**Suite : 734 tests, 734 passent.**

### Écarts avec ce que la demande disait

- **Critiques plats hors arme laissés additifs** (§7, point 1) — corrigé le même jour,
  voir « Révision » plus bas.
- **Kit de départ ajouté** : la demande ne le disait pas, mais sans lui un personnage
  neuf ne lançait rien.

### Tests changés parce que le comportement voulu a changé

- Les tests qui lancent reçoivent une arme nue (`test_player`, `test_shapes`,
  `test_hold`, `test_impact`, `test_skill_bar`). **Piège rencontré** : équiper recalcule
  la fiche et **efface `skill_mods`** ; l'arme se pose avant les lignes que le test
  assigne à la main.
- `Item.mods()` d'une épée compte une ligne de plus : sa chance critique.
- Les tests de personnage neuf passés par `SaveStore.create()` voient le kit.
- **Supprimé** : `test_each_skill_can_crit`, qui gardait le champ `Skill.crit_chance`
  disparu. `test_the_crit_chance_starts_from_the_skill` devient `…_from_the_sheet`.

### L'infobulle

Vérifiée en capture réelle, en fenêtré, avant la révision : une épée à « +4 % chance
critique (local) » affiche « Chance critique : 14 % » en bleu sous l'implicite, un trait, puis ses lignes.
Rien ne déborde.

### Le banc

`tests/run.sh balance` : **4 tests sur 5 en échec, les mêmes qu'au commit du jalon 17**,
relancé à part sur ce commit pour comparer. Les chiffres du Sort sont identiques ; la
Mêlée gagne un peu partout :

| Mêlée | jalon 17 | jalon 18 |
|---|---|---|
| Débutant zone 1 | 1,30 coups | 1,05 |
| Nu zone 90 | 22,02 | 19,46 |
| Nu zone 120 | 120,29 | 105,64 |
| Équipé zone 120 | 95,23 | 90,17 |
| Sur-équipé zone 90 | 10,24 | 9,36 |
| Sur-équipé zone 120 | 69,27 | 65,72 |

Aucun couloir ne change d'état : le débutant reste tendu en zone 1 à 1,05 coup, et les
zones 90 et 120 restent des murs. **Aucun chiffre de couloir n'a changé.**

### Non fait

- Pas de nouvelle mesure de performance : `cast_slot()` gagne une comparaison de
  chaînes, hors de toute boucle par ennemi.
- Pas de test clavier : la touche passe par `cast_slot()`, que les tests couvrent.

### Révision du 17 septembre 2026

**Déclencheur** : le personnage « ad » affichait 11 % de chance critique — 5 % de son
sceptre runique, plus les +6 % plats de sa chevalière. L'utilisateur voulait que seule
l'arme donne une base : §1, §2 et §4 sont réécrits en conséquence.

**Suite : 738 tests, 738 passent.**

**Défaut trouvé en chemin, antérieur au jalon** : l'établi n'ajoutait plus aucun
affixe. La ligne dessinée portait l'action `affixe:<id>`, `_apply()` attendait `affix` —
un reste du passage des identifiants en anglais (`1f86358`). Aucun test ne cliquait :
tous appelaient `toggle_affix()`. `test_clicking_a_drawn_affix_line_selects_it` clique
maintenant au centre d'une ligne réellement dessinée.

**Le banc** — `tests/run.sh balance` : toujours 4 tests sur 5 en échec, mais **un
couloir de plus casse : la Mêlée Équipée en zone 90** (7,17 coups au jalon 17 → 8,09, mur).

| | jalon 18 avant révision | après |
|---|---|---|
| Mêlée Équipé zone 90 | passe | 8,09 coups, survie 18,4 s |
| Mêlée Équipé zone 120 | 90,17, survie 10,2 s | 98,52, survie 8,1 s |
| Sort Équipé zone 90 | 24,19 | 25,11 |
| Sort Équipé zone 120 | 103,18 | 125,47 |
| Sort Sur-équipé zone 90 | 14,59 | 17,56 |
| Mêlée Sur-équipé zone 90 | 9,36 | 12,03 |

La survie bouge aussi, ce que le critique n'explique pas : **deux affixes de plus dans la
réserve changent chaque objet que le banc tire** sur sa graine. La perte des plats de
critique hors arme s'y ajoute. Les deux ne se séparent pas sans un banc à objets fixés.
**Aucun chiffre de couloir n'a changé** (jalon 13, §4).

**Plats de `cruel` abaissés** (même jour) : ils allaient de +2 à +18 %, contre une base
d'arme de 5 à 10 % ; le T1 plafonne maintenant à +4 %. Trois paliers et non cinq :
arrondis au centième, cinq paliers strictement croissants ne tiennent pas sous 4 %
(`test_each_scale_is_monotonic`). Une ligne déjà tirée garde sa valeur écrite. Au banc,
la Mêlée Équipée en zone 90 passe de 8,09 à 9,68 coups ; aucun autre couloir ne bouge.
