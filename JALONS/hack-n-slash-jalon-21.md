# Hack'n'slash top-down — jalon 21

Suite des jalons 1 à 20. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Proposé et livré le 19 septembre 2026.** Le jalon 20 s'était arrêté sur une question
laissée ouverte (§7) : les nouveaux manuels. La voici tranchée. Le chevalier gagne les
deux gestes qui lui manquaient — une **vague** qui prolonge son coup, un **cyclone**
qu'on entretient —, et un **quatrième livre** arrive : le Maître du froid, qui apporte
avec lui la première compétence qui **protège** au lieu de frapper.

---

## 1. Périmètre

**Dedans :**

- **Vague tranchante** et **Cyclone**, les cases (3,0) et (1,1) du manuel du chevalier.
  Six cases sur huit, comme les deux autres livres.
- **Le manuel du froid** : quatre compétences — Pics de glace, Nova de glace, Tombeau de
  glace, Désastre hivernal — et un passif, Morsure du gel.
- **Cinq formes neuves** (`WAVE`, `CYCLONE`, `SPIKES`, `NOVA`, `VORTEX`), dont **une sans
  nœud** : la nova réemploie l'explosion de la boule de feu.
- **Le mot-clé `cold`**, avec les deux affixes qui le visent — sans eux, il serait
  décoratif (jalon 7).
- **Trois règles neuves**, chacune parce qu'une compétence la demande : un geste qui
  **enferme** son lanceur, un geste qui **soigne**, et un lancer qui porte **sa propre
  chance d'état**.
- **Une statistique de défense**, `damage_taken`, et une de chance, `chill_chance`.

**Dehors :**

- **Un arbre de talents pour le Tombeau de glace.** Comme les buffs du jalon 20 : un
  nœud vise un nombre de `SkillStats`, et un geste qui ne frappe pas n'en a aucun qui
  compte.
- **Le canal tenu.** Le cyclone s'allume et s'éteint sur la même touche, comme l'aura et
  les buffs, plutôt qu'à la touche maintenue — voir les arbitrages.
- **`chill_chance` et `damage_taken` sur la fiche de personnage.** La bijection du
  jalon 6 les ferait arriver avec deux affixes de plus, et la fiche tient déjà tout
  juste. Elles se lisent sur la page du manuel, là où le passif et le buff les
  promettent.

---

## 2. Les règles

### La vague

`WAVE` : le coup part normalement — `Player._swing()`, la hitbox, le gel d'impact —, et
**l'arc s'en détache**. `SlashWave` avance en ligne droite à `projectile_speed` pendant
`duration`, et mord **une fois par corps** (`Targets.Contacts` avec sa vie entière pour
période, le mécanisme du serpent et de l'épée en orbite).

Elle naît **dix-huit pixels devant** le personnage (`START`) et non sur lui : sur lui,
elle doublerait le coup de hitbox sur tout ce qui est déjà au contact. Le recouvrement
n'est pas nul pour autant — un ennemi collé au joueur prend le coup **et** la vague ; le
premier réglage de la table en tient compte, elle vaut deux tiers de celle du Coup en
croix.

Elle porte `melee` : c'est un geste d'arme, quoi qu'il atteigne au-delà du bras.

### Le cyclone

`CYCLONE` : un geste entretenu de plus, le troisième après l'aura et le buff. Il frappe
son cercle à chaque `period`, draine **10 mana par seconde**, et s'éteint quand
la réserve est vide — là où la brûlure d'une aura tue.

**Dix mana par seconde**, et le plancher à ne pas repasser : la régénération de départ
rend **4 mana par seconde**. Tout drain en dessous est un sort gratuit — le premier
réglage l'était, et le test qui devait le voir s'épuiser tournait sans fin.

Il ne ralentit pas son porteur : le tour d'épée est ce qu'on lance pour **traverser** un
paquet, et le clouer sur place en ferait une seconde Immolation.

### Les pics, la nova, le vortex

| | ce qu'ils font | ce qu'ils veulent |
|---|---|---|
| `SPIKES` | Frappent **une fois** le cercle au point visé (`Player._aim_point()`, la portée de pose), puis retombent. Rien ne reste. | un rayon |
| `NOVA` | Frappe **une fois** le cercle autour du lanceur. **Aucun nœud neuf** : c'est `Explosion.put()`, celle de la boule de feu, posée sur soi. | un rayon |
| `VORTEX` | **Grandit pendant toute sa durée** — de 35 % de son rayon à la totalité — et frappe à chaque période. | une durée, une période, un rayon |

La croissance est la seule chose qui sépare le vortex du nuage d'orage : on le pose tôt,
il paie tard, et ce qui est au bord n'est pris qu'à la fin. `IceVortex.reach()` est le
seul endroit qui la calcule — le dessin et les coups la lisent au même endroit, sinon le
halo mentirait sur ce qu'il mord.

### Le tombeau : enfermer, abriter, soigner

Le Tombeau de glace est un `BUFF` comme Ignition, avec trois choses qu'aucun geste
n'avait :

- **`Skill.binds_caster`** — tant qu'il brûle, `Player.cast_slot()` ne laisse partir que
  lui-même et `_physics_process()` annule le déplacement. La visée et le sprite suivent
  encore : un personnage figé net se lirait comme un gel du jeu. `Player._bound` est tenu
  à jour par `_after_buff_change()` et non relu à chaque image — il est lu par le
  déplacement, donc soixante fois par seconde.
- **`Skill.self_heal`** — une part des PV max rendue par seconde, le pendant exact de
  `self_burn`, par `Player.mend()`. **Sans mitigation** : un soin ne se résiste pas.
- **`CharacterStats.damage_taken`**, en points de pourcentage, appliqué dans
  `mitigate()` **après** la défense de la nature et **sur toutes** : une carapace ne
  choisit pas ce qu'elle arrête. Borné à zéro — l'invulnérabilité pure n'existe pas ici.

Sa durée vient du lancer : `Buff.light()` avait déjà une durée de vie facultative depuis
la Ruée d'orage, et le cas `BUFF` lui passe maintenant `cast.duration`. Zéro pour
Ignition et Électricité statique, qui brûlent tant qu'on les paie.

**Il n'a pas de vraie recharge** (0,6 s, l'anti-rebond des buffs) : une recharge longue
empêcherait de le rouvrir, et `cast_slot()` refuse une case en recharge **avant**
d'atteindre l'extinction. Ce qui le borne est son prix — 25 mana à la pose, 3 par
seconde tenu.

### La chance d'un état

Deux facteurs, et ils ne vivent pas au même endroit :

- **celui du porteur**, `StatusEffects.chance_factors`, **un par sorte**. C'était un
  champ unique pour l'embrasement (jalon 20) ; le gel en demandait un second, et deux
  exceptions valent un tableau. `Player.recompute_stats()` les écrit en parcourant
  `CHANCE_STATS`, la table qui lie une sorte à la statistique qui l'accroît ;
- **celui du lancer**, `Skill.status_chance_increase`, **en points de pourcentage**,
  qui voyage par `DamageInfo.cast` — déjà là pour les dégâts contre un état — et que
  `Hurtbox` passe à `suffer()`. C'est ce qui fait de la Nova de glace un sort qui
  **transit**, sans que rien ne soit écrit sur le personnage. **Hors de portée des
  nœuds** : c'est ce qui distingue une compétence de sa voisine, pas un réglage qu'on
  achète.

Les deux **s'additionnent** avant de multiplier la chance de base, comme tous les accrus
du jeu (`StatMod`) : +50 porté et +50 du lancer font 20 → 40 %, et non les 45 % de deux
multiplications à la suite. `StatusEffects.CHANCE_STATS` est le seul endroit qui lie une
sorte à la statistique qui l'accroît.

Le tirage suit l'invariant 3 des deux côtés : les facteurs multiplient une chance, ils
n'ajoutent aucun tirage.

---

## 3. Ce que ça change dans le code

| Fichier | Ce qui bouge |
|---|---|
| `core/skill.gd` | Cinq formes à la fin ; `KEYWORD_OF_NATURE[COLD]` ; `KEYWORD_OF_SHAPE` des cinq ; `self_heal`, `status_chance_increase`, `binds_caster` ; `mana_per_second` remplace `self_mana_burn` ; `sustained` prend `CYCLONE` |
| `core/keywords.gd` | `COLD`, son libellé, sa phrase de destinataire et son qualificatif |
| `core/character_stats.gd` | `chill_chance`, `damage_taken` ; `mitigate()` applique l'abri après la défense de la nature |
| `core/stat_mod.gd` | Les deux dans `LABELS`, `AGREEMENT` et `PERCENT_POINTS` |
| `core/status_effects.gd` | `chance_factors` remplace `ignite_chance_factor` ; `CHANCE_STATS`, la table des statistiques par sorte ; `suffer()` prend l'accru du lancer |
| `core/hurtbox.gd` | Passe `info.cast.status_chance` à `suffer()` |
| `core/skill_stats.gd` | `self_heal`, `status_chance` — recopiés, jamais visés |
| `actors/player/player.gd` | Cinq cas de lancer ; `_bound` ; `mend()` ; le `BUFF` prend sa durée ; les facteurs par sorte |
| `actors/skills/slash_wave.gd` | **Neuf.** L'arc détaché : sa course, sa morsure unique, son croissant |
| `actors/skills/cyclone.gd` | **Neuf.** Le tour d'arme entretenu : ses impulsions, son drain, ses lames |
| `actors/skills/ice_spikes.gd` | **Neuf.** Les pics : une frappe, puis ils retombent |
| `actors/skills/ice_vortex.gd` | **Neuf.** Le vortex qui grandit |
| `actors/skills/buff.gd` | Le soin, et le bloc de glace de celui qui enferme |
| `ui/manual_panel.gd` | La ligne « soin », sous « Lancer » avec les autres prix ; la ligne de chance d'état, dans le bloc des dégâts |
| `tools/catalog_generator.gd` | La forme dit enfin le **drain de mana** et le soin : sans ça le catalogue donnait le cyclone gratuit |

**Ce qui ne bouge pas, et c'est le but** : `Targets` ne gagne aucune fonction,
`DamageInfo` aucun champ, `SkillStats.LABELS` aucune entrée — donc aucun nœud, aucun
affixe et aucune ligne de fiche neufs à écrire pour les trois règles.

---

## 4. Les sauvegardes

**Aucun numéro de version.** Rien de neuf ne s'écrit : les points d'un manuel de plus
voyagent dans le même dictionnaire, et un geste allumé ne se sauvegarde pas.

---

## 5. Le contenu

**Manuel du chevalier** — deux cases de plus, six sur huit :

| | `wave_slash` | `cyclone` |
|---|---|---|
| Nom | Vague tranchante | Cyclone |
| Forme | `WAVE` | `CYCLONE` |
| Coût | 8 mana | 0, puis 10 mana par seconde |
| Nombres | 0,5 s · rayon 20 · 90 px/s | rayon 34 · toutes les 0,35 s |
| Par point | 11 → 27 | 7 → 17 par impulsion |
| Niveau de livre | 4 | 8 |
| Nœuds | Fil de l'arc, Course | Fauchage, Envergure |

**Manuel du froid** — `manual_cold`, quatre cases et un passif, 38 destinations de points
pour 20 gagnés :

| | `ice_spike` | `ice_nova` | `frost_tomb` | `winter_disaster` |
|---|---|---|---|---|
| Nom | Pics de glace | Nova de glace | Tombeau de glace | Désastre hivernal |
| Forme | `SPIKES` | `NOVA` | `BUFF` | `VORTEX` |
| Recharge | 0,7 s | 1,1 s | 0,6 s (anti-rebond) | 3 s |
| Mana | 14 | 20 | 25, puis 3 mana/s | 26 |
| Nombres | rayon 26 | rayon 46 · +50 % de chance de transir | 3 s · rend 1,7 % PV/s | 4 s · rayon 52 · toutes les 0,5 s |
| Par point | 10 → 25 | 12 → 30 | −17,5 % de dégâts subis | 6 → 15 par impulsion |
| Niveau de livre | 1 | 3 | 8 | 12 |

Le passif **Morsure du gel** donne +10 points de chance de transir par point, quatre
points. Le livre tombe à partir du niveau 10 — après le manuel des flammes (5), avant
rien : c'est le dernier des quatre.

**Les deux affixes de froid**, sans lesquels le mot-clé serait une promesse en l'air :
`glacial` (« de la Banquise », dégâts de froid accrus) et `cold_skill_levels` (« du
Cryomancien »), copiés sur leurs équivalents de feu, aux mêmes paliers et au même poids.

**Les sept icônes** sortent du tuyau du jalon 11 (`tools/skill_icons.py`,
`tools/item_icons.py`) : SDXL et le LoRA pixel-art, trois graines chacune, jugées sur
planche réduite à 24 px. La leçon du jalon 20 s'est confirmée mot pour mot — **le modèle
ne dessine pas l'abstrait** : « un tourbillon de lames » est sorti en taches, « un
guerrier qui tourne sur lui-même, traînées circulaires » se lit. Deux sujets ont demandé
un second tour pour cette raison, le cyclone et le vortex.

---

## 6. Arbitrages

**Le cyclone est une bascule, pas un canal tenu.** PoE le tient enfoncé ; ici il
s'allume et s'éteint sur la même touche, comme l'aura et les deux buffs. La raison est
que `Player._is_sustained()` existe déjà, qu'il porte la garde anti-clignotement et
l'extinction gratuite, et qu'un second mode de conduite dans la boucle de sondage des
cinq cases serait une règle de plus pour un geste. Ce qu'on perd : relâcher n'arrête pas
le tour, il faut rappuyer.

**La nova réemploie l'explosion.** `Explosion` frappe une fois son cercle, se teinte de
la nature du lancer et s'efface : c'est exactement une nova. Lui écrire un nœud propre
aurait donné une seconde boucle de frappe pour un dessin à peine différent. Le revers
est qu'elle porte le dessin d'une explosion — cœur clair, onde, étincelles — et non des
éclats de glace ; jugé sur capture, il tient.

**Les pics frappent au point visé, la nova sur soi.** Deux formes pour un même
mécanisme — un coup, un cercle, rien qui reste — parce que **ce qui les sépare est ce
qu'on en fait** : on pose les pics sur ce qui arrive, on lâche la nova sur ce qui est
déjà là. C'est la règle du jalon 11 prise à l'endroit : elles se distinguent par le
geste, pas par leurs nombres.

**L'abri du tombeau est une statistique de fiche, pas un état.** `StatusEffects` aurait
pu porter un « protégé » de plus ; mais ce qui l'allume est un buff, et un buff verse
des lignes dans la fiche. Une seule voie, celle qui existait.

**La vague double le coup au contact.** Le refus — une vague qui ne mord que ce que le
bras n'a pas touché — demanderait de lui passer la liste des corps déjà frappés, donc un
lien entre la hitbox et un nœud qui n'existe pas encore au moment du swing. Réglé par la
table de dégâts plutôt que par du code.

**Le drain du cyclone est lu sur la compétence**, comme celui des buffs, et non sur le
lancer : aucun modificateur ne le vise, et la fiche prend les prix sur le lancer résolu
qui les recopie.

---

## 7. Ce qui refusera un oubli

**Formes** — `tests/integration/test_shapes.gd`, huit tests neufs :

- la vague dépasse le bras, mord **une fois**, et meurt avec sa durée ;
- le cyclone tourne, frappe son cercle, se paie, et **la réserve vide l'arrête** ;
- les pics frappent une fois au point visé et ne laissent rien ;
- la nova part de soi, pas plus loin que son rayon, et porte sa chance d'état ;
- le tombeau enferme — une autre case est refusée —, abrite, et **seul lui-même peut
  s'éteindre** ;
- il soigne puis fond tout seul, et la fiche retrouve ses nombres ;
- le vortex **grandit** : le bord n'est atteint que plus tard.

**Règles** — `tests/unit/` :

- `test_damage_taken_shelters_every_nature_after_its_defense` : l'abri après la
  résistance, sur toutes les natures, jamais négatif ;
- `test_the_author_factors_do_not_cross_over` : une chance de transir ne fait pas
  embraser mieux ;
- `test_the_cast_factor_multiplies_the_chance_of_its_state` : ce que la nova ajoute à sa
  propre chance.

**Et les gardes existants**, qui ont tous tenu : `test_each_shape_has_the_numbers_it_needs`
(étendu aux cinq formes), `test_each_keyword_is_targeted_by_something` (qui aurait refusé
`cold` sans ses deux affixes), `test_each_displayed_text_has_its_english` (qui a listé les
trente-trois textes neufs, un par un), `test_les_cases_tiennent_dans_le_panneau`,
`test_the_sheet_stays_in_frame`, `test_no_manual_fills_up_entirely`.

**Deux tests ont dû changer**, et c'est le contenu qui les a changés :
`test_a_nature_nothing_targets_gives_no_keyword` prenait le froid comme exemple de nature
que rien ne vise — c'est le nécrotique maintenant ; et le test du facteur d'embrasement
lit le tableau par sorte.

---

## 8. Livré le 19 septembre 2026

**La suite : 811 tests, 811 passent** (801 avant, plus les dix du jalon).

### Le banc de performance

Banc `world/stress_test.tscn`, graine 4242, en fenêtré, moyenne sur 1 440 images après
240 de chauffe, **piloté automatiquement** sur une copie, les deux côtés en alternance
dans la même session (`git worktree` pour l'avant).

| combat tenu, ~270 simulés | avant | après |
|---|---|---|
| images/s | 165,2 · 165,2 | 165,1 · 165,1 |
| physique | 5,59 · 5,32 ms | 6,27 · 6,07 ms |
| temps figé | 5,2 · 5,7 % | 5,2 · 5,7 % |

| sans combat, 300 simulés | avant | après |
|---|---|---|
| physique | 3,44 ms | 3,68 ms |

**Environ +0,7 ms de physique**, à peine au-dessus de l'écart entre deux lancers du même
code que le jalon 12 avait mesuré (0,7 ms à 284 simulés). Les images par seconde et le
temps figé ne bougent pas, et le plafond du tableau de référence (8,62 ms à 935 simulés)
reste loin. Un tiers de l'écart se voit **sans qu'aucun coup ne parte**, donc il ne vient
pas seulement du chemin du coup : le tableau de facteurs par sorte est une allocation de
plus par corps, et l'`EnemyManager` relit ces objets à chaque image. Rien à optimiser
tant que ça ne se mesure pas en images perdues — mais c'est la ligne à relire si une
prochaine addition ajoute encore un champ à `StatusEffects`.

### L'équilibrage

`tests/run.sh balance` : **toujours 4 tests sur 5 en échec**, exactement les mêmes qu'aux
jalons 18 et 20, et aucun couloir neuf ne casse.

Les couloirs de sort et de mêlée **bougent tous les deux**, et pour une raison qui n'est
pas une régression : les deux affixes de froid entrent dans la réserve, donc les profils
équipés du banc tirent d'autres objets. Les lignes **Débutant** et **Nu**, qui ne portent
rien, sont identiques au caractère près — c'est ce qui le prouve. Aucun chiffre de
couloir n'a été touché (jalon 13, §4).

### Le dessin, jugé sur capture

Cinq gestes photographiés en fenêtré, sur la scène de stress, à 1280×720 : la vague
(croissant net devant le personnage), le cyclone (anneau, trois lames, traînées), les
pics (triangles dressés dans leur cercle), le tombeau (bloc à six pans, cerné de clair),
le vortex (spirale et éclats aspirés). **Deux réglages sont sortis de là** : les pics
sont passés de 14 à 18 pixels de haut et de 0,55 à 0,70 d'opacité, la spirale du vortex
de 0,55 à 0,75 — à leurs premières valeurs, les deux se perdaient sur le sol sombre. Le
bandeau des gestes entretenus et l'anneau de la barre montrent le cyclone et le tombeau
sans qu'on y ait touché.

### Non fait

- **Le clavier n'a pas été joué** : `binds_caster` cloue les pieds dans
  `_physics_process()`, ce qu'aucun test ne pilote. Relu sur le diff, vu sur capture — le
  personnage reste dans son bloc —, mais jamais essayé à la main.
- **Le tombeau n'a pas d'arbre**, comme les deux buffs du jalon 20.
- **Les deux statistiques neuves ne sont pas sur la fiche de personnage** : elles se
  lisent sur la page du manuel, sous ce qui les promet.

---

## 9. Révision du 19 septembre 2026

Deux retours en jouant, le jour même.

**« Rien ne dit que la nova transit mieux. »** C'était vrai : elle portait un
multiplicateur brut (×2,5) qu'aucune ligne n'affichait, et qui se **multipliait** avec
les accrus du porteur au lieu de s'y ajouter — deux règles pour une même idée. Il est
devenu un **accru en points de pourcentage**, `status_chance_increase`, dans la même
monnaie que `chill_chance` et que le passif Morsure du gel :

- **+50 sur la Nova de glace**, donc 20 % → **30 %** sur un coup entièrement de froid ;
- **les accrus s'additionnent** avant de multiplier la chance de base, comme partout
  ailleurs : la nova sous un Morsure du gel à quatre points donne 20 × (1 + 0,50 + 0,40)
  = **38 %**, et non les 42 % de deux multiplications ;
- **la fiche le dit, avec ce qu'il donne** : « Chance de transir : +50 % · 30 % », dans
  la couleur de l'état, sur le modèle de la ligne « adossé aux PV ». Le second nombre
  suit le porteur — c'est lui qui montre que le passif s'ajoute.

La ligne ne s'écrit que si la sorte a sa statistique dans `StatusEffects.CHANCE_STATS`,
la table neuve qui lie une sorte d'état au champ qui l'accroît. C'est elle aussi que
`Player.recompute_stats()` parcourt pour écrire ses facteurs : la troisième chance
d'état sera une entrée de table, pas une ligne de code de plus.

**Le prix d'un geste entretenu passe à plat.** `self_mana_burn` était une part du mana
max par seconde ; c'est maintenant `mana_per_second`, du mana tout court. Le cyclone
coûte **10 mana par seconde** au lieu de 15 % de la réserve (9,75/s au départ : le
chiffre ne bouge pas aujourd'hui, il cessera de monter demain).

**Ce que ça change ailleurs** — les deux autres gestes qui drainaient sont restatés dans
la même monnaie, à leur valeur du début de partie : Électricité statique **1 mana/s**
(c'était 1 % de 65) et Tombeau de glace **3 mana/s** (5 % de 65). Le revers est assumé et
se relira le jour où les réserves tardives seront réglées : **un prix à plat s'efface
quand la réserve grandit**, là où une part suivait le personnage. Décidé ainsi parce
qu'un prix se lit sur la jauge sans calcul.

**Suite : 814 tests, 814 passent.** Trois de plus : les deux accrus qui s'additionnent,
la table des statistiques de chance, et la fiche de la nova qui annonce les deux nombres.
