# Hack'n'slash top-down — jalon 22

Suite des jalons 1 à 21. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Proposé et livré le 19 septembre 2026.** Le jeu n'avait pas de recharges : il avait
**un seul nombre par compétence**, que la cadence du lanceur divisait. Une Ruée ardente
« de 4 secondes » tombait à 2,7 s avec 50 % de vitesse d'incantation, et le champ qui
portait ce nombre s'appelait `cooldown` alors qu'il décrivait un temps d'incantation.
Ce jalon sépare les deux notions, à la manière de Path of Exile.

---

## 1. Le défaut

Trois choses portaient le mot « recharge » sans en être une :

| Ce qui s'appelait ainsi | Ce que c'était vraiment |
|---|---|
| `Skill.cooldown` | Le **temps d'incantation** d'un sort : divisé par `cast_speed`, donc rien d'un délai fixe |
| `CharacterStats.attack_cooldown` | Le **temps d'un coup d'arme**, divisé par `attack_speed` |
| `Affix.cooldown_mult` | Ce qu'un affixe d'ennemi fait à ce même temps d'attaque |

Et la conséquence en jeu : **la vitesse d'incantation accélérait les ruées**. Un stuff de
cast speed rendait spammable ce qui devait être un geste qu'on choisit.

---

## 2. La règle

**Deux nombres, et rien ne les change ensemble.**

| | Le temps du geste | La recharge |
|---|---|---|
| Sur la compétence | `cast_time` | `cooldown` |
| Qui le raccourcit | `attack_speed` à la cadence de l'arme, `cast_speed` à l'incantation | `CharacterStats.cooldown_recovery`, **et rien d'autre** |
| Qui le lit | `Skill.use_time()` | `Skill.recharge()` |

Ce que la case attend est `Skill.interval()` : **le plus long des deux**.

Le maximum plutôt que la somme, parce que **les deux courent ensemble depuis le
lancer** : c'est le modèle de PoE, où l'on ne « paie » pas son temps d'incantation avant
de commencer à récupérer. Une compétence sans recharge n'est donc bornée que par son
geste — le cas de presque tous les sorts.

`SkillStats` porte les deux, et `interval` y est **calculé et jamais rangé** (une
propriété à getter) : deux champs qui auraient pu diverger ne le peuvent pas.

**La cadence de l'arme ignore `cast_time`** : son temps vient de l'arme, et un nombre
posé là serait un nombre que personne ne lit. Un sort, lui, veut l'un **ou** l'autre —
sans rien, sa case repartirait à chaque image.

### La statistique neuve

`CharacterStats.cooldown_recovery`, en points de pourcentage : à +50, une recharge de 3 s
tombe à 2 s. Bornée en bas comme les cadences (`recovery_factor()` ne descend pas sous
0,1) : une récupération de −100 % figerait la compétence pour toujours.

Elle arrive **avec son affixe**, comme la règle l'exige (jalon 6, et
`test_everything_modifiable_reads_on_the_sheet` / `test_each_sheet_stat_is_reachable_by_an_affix`
qui se répondent) : `second_wind`, « du Second Souffle », sur les bottes et les bijoux,
+3 à +20 selon le palier. Elle est donc **sur la fiche de personnage**, sous les deux
cadences — là où le joueur compare les trois.

### Les renommages

- `CharacterStats.attack_cooldown` → **`attack_time`**, libellé « temps d'attaque » ;
- `Affix.cooldown_mult` → **`attack_time_mult`** ;
- l'ancien `Skill.cooldown` des sorts → **`cast_time`**, et `cooldown` reprend son nom
  pour désigner une vraie recharge.

Aucun affixe d'objet ne visait `attack_cooldown` : **rien à convertir dans les
sauvegardes**, et aucun fichier de référence ne le cite.

---

## 3. Ce que le contenu devient

Les huit sorts ordinaires gardent leur nombre **comme temps d'incantation** : rien ne
change pour eux, leur case n'a jamais eu de délai propre.

| | temps d'incantation | recharge |
|---|---|---|
| Trait, Éclair vif, Chaîne d'éclairs, Boule de feu | 0,30 · 0,42 · 0,70 · 0,60 s | — |
| Nuage d'orage, Serpent infernal, Pics de glace, Nova de glace | 1,60 · 1,20 · 0,70 · 1,10 s | — |
| **Ruée ardente** | 0,50 s | **4,00 s** |
| **Ruée d'orage** | 0,35 s | **2,00 s** |
| **Désastre hivernal** | 0,80 s | **3,00 s** |
| Immolation, Ignition, Électricité statique, Tombeau de glace | — | 1,00 · 0,60 · 0,60 · 0,60 s |
| Les cinq gestes d'arme | l'arme | — |

**Les trois gestes « à délai »** — les deux ruées et le vortex — partent vite et
reviennent lentement : c'est exactement ce qu'ils voulaient dire, et ce qu'un seul nombre
ne pouvait pas écrire. **Les quatre gestes entretenus** voient leur anti-rebond devenir
une recharge, et c'est le point qui corrige un défaut silencieux : un stuff de vitesse
d'incantation faisait clignoter les bascules de plus en plus vite.

**La fiche de compétence montre les deux**, séparément : « Temps d'incantation 1,06 s »
et, seulement quand elle existe, « Recharge 4,00 s ». Un sort sans recharge n'a donc
qu'une ligne — c'est le cas des sorts dont la fiche est la plus chargée, et
`test_the_sheet_stays_in_frame` n'a pas bronché.

---

## 4. Arbitrages

**Pas de « charges » (stored uses).** PoE laisse certaines compétences empiler deux ou
trois usages d'avance. C'est ce qui donne aux dash leur feel d'enchaînement, et c'est un
état de plus par case dans `Player._recharges`. Écarté tant qu'aucun contenu ne le
demande ; le jour où il arrive, il se pose sur `Skill.recharge()` sans rien déplacer
d'autre.

**Le maximum, pas la somme.** Une compétence de 0,8 s de geste et 3 s de recharge repart
en 3 s, pas 3,8. L'alternative — la recharge ne démarre qu'à la fin du geste — demande de
compter deux timers par case pour un dixième de seconde de différence.

**La récupération est sur la fiche de personnage**, contrairement aux deux chances du
jalon 21. Ce n'est pas une préférence : les deux tests de bijection l'imposent dès qu'un
affixe la donne, et il fallait un affixe pour qu'elle existe autrement que sur le papier.
La fiche tenait à 13 px près, elle tient maintenant à 3 (`test_the_sheet_fits_its_height`) —
**c'est la dernière ligne gratuite**, la prochaine statistique affichée demandera de
resserrer la mise en page.

**Le gel ralentit toujours les recharges**, parce qu'il ralentit le temps de jeu de la
case (`Player._physics_process()` décompte `delta * speed_factor`). C'est la même règle
qu'avant le jalon, et c'est celle de PoE, où le gel réduit la vitesse d'action.

---

## 5. Ce qui refusera un oubli

`tests/unit/test_skills.gd`, quatre tests neufs :

- `test_casting_speed_shortens_the_gesture_and_never_the_cooldown` — **le test du
  jalon** : ×2 de vitesse d'incantation divise le geste par deux et laisse la recharge
  entière, donc la ruée attend toujours ses 4 secondes ;
- `test_recovery_shortens_only_the_cooldown`, et son plancher à −500 % ;
- `test_the_slot_waits_for_the_longer_of_the_two`, jusque sur le lancer résolu ;
- `test_each_skill_declares_the_pace_its_cadence_reads` — un geste d'arme ne déclare pas
  de temps d'incantation, un sort déclare l'un des deux.

Et les gardes existants qui ont fait leur travail : les deux tests de bijection de la
fiche ont **exigé** l'affixe et la ligne de fiche, `test_no_orphan_translation` a réclamé
la suppression des deux anciens textes, et `test_the_sheet_fits_its_height` a mesuré la
marge restante.

---

## 6. Livré le 19 septembre 2026

**La suite : 818 tests, 818 passent** (814 avant, plus les quatre du jalon).

**L'équilibrage** : `tests/run.sh balance` reste à 4 échecs sur 5, les mêmes qu'aux
jalons 18, 20 et 21. Les couloirs bougent de quelques dixièmes parce qu'un affixe de plus
entre dans la réserve — les lignes **Débutant** et **Nu**, qui ne portent rien, sont
identiques au caractère près.

**Le banc n'a pas été relancé** : rien de ce jalon n'est dans une boucle chaude. Le seul
calcul ajouté est un `maxf()` au moment du lancer, et `recovery_factor()` une division de
plus sur une compétence qui a une recharge.

### Non fait

- **Les charges** (voir §4).
- **Une recharge par nœud de talent** : aucun nœud ne vise `cooldown`, et la fiche ne
  l'annoncerait pas comme un nombre de lancer — `SkillStats` ne porte pas la recharge
  parmi ses `LABELS`, elle la recopie seulement.
- **Le jeu au clavier** : la cadence des cinq cases se relit sur le diff, comme d'habitude.
