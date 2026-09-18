# Hack'n'slash top-down — jalon 20

Suite des jalons 1 à 19. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Proposé et livré le 18 septembre 2026.** Les dix compétences du jeu font toutes la même
chose : elles partent, elles frappent, elles s'arrêtent. Immolation est la seule
exception — la seule qu'on **entretient**, au prix de ses PV. Ce jalon prend cette
exception et en fait une famille : **deux gestes neufs**, le **dash** et le **buff
entretenu**, chacun décliné dans les deux manuels existants. Il en profite pour
adosser Immolation aux PV du lanceur, et pour retirer du manuel de foudre la seule
compétence qui n'était qu'un éclair vif à d'autres réglages.

---

## 1. Périmètre

**Dedans :**

- **Le dash**, une forme neuve : le lanceur se porte au curseur, **murs et ennemis
  traversés**. Deux compétences, une par manuel — Ruée ardente (feu), qui laisse une
  trace au sol frappant dans la durée, et Ruée d'orage (foudre), qui ne laisse rien
  derrière mais presse le pas de celui qui l'a lancée.
- **Le buff entretenu**, une seconde forme neuve : une case qu'on allume et qu'on
  éteint, qui **draine une réserve par seconde** et **verse ses lignes dans la fiche**
  tant qu'elle brûle. Deux compétences : Ignition (feu, coûte des PV) et Électricité
  statique (foudre, coûte du mana).
- **Deux statistiques neuves**, parce qu'un buff doit pouvoir promettre autre chose
  que des dégâts : la chance d'embraser et la chance de charge statique.
- **Les charges statiques** : ce qu'un coup laisse sur un engourdi quand le buff est
  allumé.
- **Immolation monte avec les PV du lanceur** : une part de ses PV max s'ajoute à ses
  dégâts propres, à chaque impulsion.
- **Nova de foudre s'en va**, remplacée par Électricité statique dans la case (3, 0).
- **Une case allumée se voit dans la barre.** Aujourd'hui rien ne distingue une
  Immolation en cours d'une Immolation éteinte, et on va passer de une à trois cases
  entretenues.

**Dehors :**

- **Les nouveaux manuels.** Ils arrivent, ils ne sont pas décrits ici : voir §7.
- **Un arbre de talents pour les buffs.** Un nœud vise un nombre de `SkillStats` ; un
  buff n'en a aucun qui compte. Ses points passent par ses lignes, et ça suffit.
- **Une chance d'état par état** (geler, engourdir, pourrir). Une seule arrive —
  embraser —, parce qu'une seule est demandée. Les cinq autres se feront quand une
  compétence les demandera, le jour où elles arriveront avec leur affixe.
- **Ces deux statistiques sur la fiche de personnage.** La bijection du jalon 6 —
  toute statistique affichée est atteignable par un affixe — les ferait arriver avec
  deux affixes de plus, et la fiche tient déjà tout juste dans ses 360 pixels
  (`test_the_sheet_fits_its_height`). Elles se lisent sur la page du manuel, là où le
  buff les promet. À trancher (§7).
- **Un dash qui traverse les murs.** Voir les arbitrages.

---

## 2. Les règles

### Le dash

Une forme de plus, `DASH`, **à la fin** de `Skill.Shape` (invariant 1 : les `.tres`
écrivent l'entier).

| Ce qu'elle fait | Avec quoi |
|---|---|
| Où on atterrit | `Player._aim_point()` — au curseur, à `PLACEMENT_RANGE` (140 px) au plus. **La même fonction que le nuage et le serpent** : la portée de pose est déjà une règle du joueur, elle n'a pas à être une seconde fois sur la compétence |
| Ce qui arrête la course | **Rien sur le chemin** : murs et ennemis sont traversés. Seule l'**arrivée** doit être libre — `Player._landing()` recule de huit pixels en huit le long de la visée jusqu'au premier point où le corps tient, et `_fits_at()` n'interroge que le décor |
| Ce qu'elle laisse derrière | **L'un ou l'autre, jamais les deux.** Un rayon et une période : une trace, `radius` de large autour du segment, un coup par ennemi toutes les `period`, pendant `duration`. Des lignes : un `Buff` de `duration` secondes sur le lanceur, les lignes d'un passif par point placé |
| Ce qu'elle porte | `Keywords.AREA`, par `KEYWORD_OF_SHAPE` : c'est une surface qui frappe, comme le nuage et le serpent |

Aucun nombre neuf sur `SkillStats` : `strikes_over_duration()` compte déjà les
impulsions d'une durée, donc `average_per_cast()` et la fiche du manuel marchent sans
qu'on y touche.

**Les deux ruées ne se distinguent pas par leurs nombres** (règle du jalon 11) : l'une
brûle le couloir qu'elle vient de traverser et se recharge en 4 secondes, l'autre ne
laisse rien au sol, presse le pas pendant 2 secondes et se recharge en 2. On prend la
première pour entrer, la seconde pour sortir.

**Le dash ne fige pas le jeu** et ne secoue pas la caméra : ce qui dure ne fige jamais
(ARCHITECTURE). **Il exige son arme** comme tout le reste depuis le jalon 18 : un sort
part d'une arme d'incantation, donc on ne se rue qu'une baguette à la main. Décidé
plutôt qu'une exception de mobilité, qui aurait ouvert un second chemin dans
`Skill.usable_with()` pour une seule famille de compétences.

### Le buff entretenu

Une seconde forme, `BUFF`, juste après. **Elle ne frappe rien** : elle allume, elle
draine, elle donne des lignes.

- **Elle s'allume et s'éteint** par la même touche, comme l'aura : la touche tenue ne
  fait pas clignoter, et éteindre ne coûte ni mana ni rien d'autre que la recharge.
- **Elle draine une réserve par seconde**, en part de son maximum : `self_burn` pour
  les PV — le champ d'Immolation, et **le chemin d'Immolation**, `Player.burn()`, donc
  réparti par nature et atténué par les résistances, donc **mortel** — et
  `self_mana_burn` pour le mana, neuf. **Le mana épuisé éteint le buff** ; les PV
  épuisés tuent.
- **Elle verse ses lignes dans la fiche** tant qu'elle brûle : un `Array[TalentLine]`
  sur la compétence, exactement celui d'un passif, valeur **par point placé**. Elles
  entrent dans `Player.recompute_stats()` dans la même liste que les objets portés,
  donc elles sont triées par la même règle entre la fiche et les mots-clés.
- **Son nombre de points ne se déduit plus des dégâts.** Une compétence sans table de
  dégâts déclare son `points_max`, comme un passif. `Skill.points_max()` reste le seul
  endroit qui répond.

**Plusieurs buffs à la fois**, et une aura en plus : `Player` ne garde plus une seule
`_aura` mais un dictionnaire d'allumés, par identifiant de compétence. La mort les
éteint tous.

### Ignition — manuel des flammes

Allumée, elle brûle **1 % des PV max par seconde** et donne, par point :

| Ligne | Par point | À 4 points |
|---|---|---|
| `ignite_chance` | +12,5 | **+50 %** de chance d'embraser |
| `move_speed` | +7,5 % | **+30 %** de vitesse |

`ignite_chance` compte en **points de pourcentage qui multiplient la chance de base** :
c'est un « accru » au sens de PoE, et il ne fait rien à qui ne peut pas embraser. Un
coup entièrement de feu embrase 20 fois sur 100 (`StatusEffects.CHANCE`) ; sous
Ignition, 30.

**Où la règle vit** : `StatusEffects.chance()`, qui la calcule déjà, prend un facteur
de plus. Il voyage par `DamageInfo.author` — les états de l'attaquant, **déjà le seul
attribut de l'attaquant qui arrive jusqu'à la hurtbox**, et déjà porteur de
`damage_dealt_factor`, qui est de la même famille : ce que ce corps **inflige**.
`Player.recompute_stats()` y écrit `states.ignite_chance_factor`.

### Électricité statique — manuel de la foudre

Allumée, elle draine **1 % du mana max par seconde** et donne, par point :

| Ligne | Par point | À 4 points |
|---|---|---|
| `static_charge_chance` | +5 | **20 %** par coup porté à un engourdi |

**La charge** : un coup du joueur sur un ennemi **engourdi** tire cette chance ; à la
réussite, une charge naît sur la cible, **s'écarte de quelques pixels** dans le sens
du coup, vit **2 secondes**, et frappe le premier ennemi qui entre dans son petit
rayon — puis disparaît. Elle porte **20 % de ce que le coup a réellement infligé**,
en foudre.

**Où la règle vit** : `Hurtbox.take_damage()` est le point de passage de tous les
coups, mais il est dans `core/`, qui ne fait naître aucun nœud (et un rappel de
collision ne le pourrait pas, invariant 4). Il **signale** : `StatusEffects` gagne un
signal `struck`, émis sur l'auteur du coup après `damaged`. Le joueur l'écoute, tire
sa chance, et `StaticCharge.put()` naît en différé comme l'explosion.

Le tirage suit l'invariant 3 : la condition porte sur **l'état** — chance non nulle et
cible engourdie —, jamais sur le résultat, donc le nombre de tirages ne dépend pas de
ce qui sort.

### Immolation monte avec les PV

Un champ de plus sur `Skill`, `health_scaling` : la part des PV max du lanceur qui
s'ajoute aux **dégâts propres**, par impulsion. Elle entre dans `Skill.resolve()`, au
même endroit que la table de points — donc avant les fourchettes ajoutées, la
conversion, les accrus et les « plus ».

**0,8 % des PV max par impulsion**, premier réglage : à 600 PV, +4,8 par impulsion
contre 8 à 20 pour la table, soit environ un tiers des dégâts d'une case à mi-course.
C'est le geste qui rend la Flamme noire et les PV intéressants ensemble ; c'est aussi
ce qui rend Ignition tenable, puisqu'elle paie en PV ce qu'Immolation transforme en
dégâts.

Le champ est **général mais unique** : il vit sur `Skill`, une compétence sans lui
vaut zéro, et rien d'autre ne l'utilise aujourd'hui.

### Nova de foudre s'en va

Sa case, ses trois nœuds (`lightning_nova_crown`, `_blast`, `_celerity`), son `.tres`,
son `preload` et son icône. La règle du jalon 11 la condamne : huit traits en cercle,
c'est Éclair vif à d'autres réglages.

---

## 3. Ce que ça change dans le code

| Fichier | Ce qui bouge |
|---|---|
| `core/skill.gd` | `Shape.DASH` et `Shape.BUFF` à la fin ; `KEYWORD_OF_SHAPE[DASH] = AREA` ; `lines`, `points_max` déclaré, `self_mana_burn`, `health_scaling` ; `points_max()` retombe sur le champ quand la table est vide ; `resolve()` ajoute les PV à la base et met `sustained` pour les deux formes entretenues |
| `core/character_stats.gd` | `ignite_chance` et `static_charge_chance`, en points de pourcentage |
| `core/stat_mod.gd` | Les deux dans `LABELS` et `AGREEMENT` ; **`PERCENT_POINTS` cesse d'être déduit des seules résistances** — elle prend les deux en plus, et son commentaire le dit |
| `core/status_effects.gd` | `ignite_chance_factor` (écrit par le porteur, pas par `_recompute()`) ; `chance()` le prend ; signal `struck` |
| `core/hurtbox.gd` | Émet `struck` sur l'auteur, après `damaged` et avant `suffer()` |
| `actors/player/player.gd` | `_lit` remplace `_aura` ; le cas `DASH` et le cas `BUFF` dans `cast_slot()` ; `drain()` pour le mana ; `buff_mods()` versé par `recompute_stats()` ; `_on_struck()` |
| `actors/skills/dash_trail.gd` | **Neuf.** La trace : le segment, son rayon, ses impulsions, son dessin teinté par la nature |
| `actors/skills/buff.gd` | **Neuf.** Un buff allumé : le drain, l'extinction, le dessin sur le porteur |
| `actors/skills/static_charge.gd` | **Neuf.** Une charge : sa dérive, ses 2 secondes, son coup, son plafond |
| `ui/skill_bar_panel.gd` | Un anneau sur une case allumée |
| `ui/manual_panel.gd` | `_skill_sheet()` : sans table de dégâts, la fiche montre les lignes du buff (`_effect_lines`, celui des passifs) et son prix par seconde à la place du bloc de dégâts |
| `core/skill_catalog.gd` | Quatre `preload` de plus, un de moins |

**Ce qui ne bouge pas, et c'est le but** : `Targets` ne gagne aucune fonction,
`DamageInfo` aucun argument, et les affixes ne savent rien de tout ça. `SkillStats` gagne
un seul champ, `self_mana_burn`, et pour une seule raison : la fiche du manuel lit les
prix sur le lancer résolu, pas sur la compétence.

---

## 4. Les sauvegardes

**Aucun numéro de version.** Rien de neuf ne s'écrit : les points d'un buff voyagent
dans le dictionnaire du manuel comme ceux d'une compétence, et un buff allumé ne se
sauvegarde pas — on recharge éteint, comme on recharge à PV pleins.

**Les points de Nova de foudre reviennent d'eux-mêmes.** `Character._manual_from_dict()`
ne relit un identifiant que si `item.knows()` le reconnaît ; l'identifiant disparu
tombe, et `points_spent()` ne le compte plus. Le joueur retrouve ses points sur un
livre intact, sans conversion et sans avertissement. **Une case de barre** qui cite
`lightning_nova` rend null par `SkillCatalog.by_id()`, ce qui est déjà le cas prévu.

Un test le fixe, parce que c'est exactement le genre de chose qui ne se voit qu'au
lancement suivant (§8).

---

## 5. Le contenu à écrire

Quatre `.tres` dans `resources/skills/`, leurs cases, leurs icônes. **Premiers
réglages** : ils se règlent en dernier (jalon 13, §7).

| | `flame_dash` | `storm_dash` | `ignition` | `static_electricity` |
|---|---|---|---|---|
| Nom | Ruée ardente | Ruée d'orage | Ignition | Électricité statique |
| Nature | feu | foudre | feu | foudre |
| Forme | `DASH` | `DASH` | `BUFF` | `BUFF` |
| Recharge | 4 s | 2 s | 0,6 s | 0,6 s |
| Mana | 12 | 10 | 0 | 0 |
| Drain | — | — | 1 % PV/s | 1 % mana/s |
| `duration` / `period` | 3 s / 0,5 s | 2 s / — | — | — |
| `radius` | 16 px | — | — | — |
| Points | 5 (table) | 4 (déclarés) | 4 (déclarés) | 4 (déclarés) |
| Ce qu'un point donne | 4 → 10 par impulsion | +5 % de vitesse, 2 s | +12,5 chance d'embraser, +7,5 % de vitesse | +5 chance de charge |
| Niveau de livre | 5 | 5 | 12 | 12 |

La recharge courte d'un buff n'est pas un coût : c'est un anti-rebond, pour qu'un appui
maintenu n'allume et n'éteigne pas soixante fois par seconde.

**Les cases** — la grille fait quatre colonnes sur deux rangées, et aucun manuel ne se
remplit entièrement (`test_no_manual_fills_up_entirely`) :

| Manuel | (0,0) | (1,0) | (2,0) | (3,0) | (0,1) | (1,1) |
|---|---|---|---|---|---|---|
| Flammes | Boule de feu | Serpent infernal | Immolation | **Ruée ardente** | Cœur de braise | **Ignition** |
| Foudre | Éclair vif | Chaîne d'éclairs | Nuage d'orage | **Ruée d'orage** | Conducteur | **Électricité statique** |

Six cases sur huit dans les deux.

**Les quatre icônes** sortent du même tuyau que les neuf autres —
`resources/icons/LISEZMOI.md`, recette du jalon 11 : SDXL 1.0 et le LoRA pixel-art à
pleine force, le gabarit de prompt partagé, fond cramoisi pour le feu et violet pour
la foudre, trois images par compétence jugées sur une planche déjà réduite à 24 px. Un
champ `icon` vide reste un état normal : la case dessine un disque en attendant.

**Et l'anglais** : quatre noms, deux libellés de statistique, dans `i18n/en.po`. La
fiche de chaque case doit tenir dans les deux langues (`test_widths`).

---

## 6. Arbitrages

**Le dash traverse, et recule quand l'arrivée est prise.** La course ne s'arrête sur
rien : c'est ce qui en fait une fuite plutôt qu'une charge. Le seul garde-fou est
l'arrivée, cherchée en reculant vers le départ — on vise un mur, on atterrit juste
devant, et on ne gâche pas son lancer. Le refus pur (« arrivée occupée, rien ne part »)
a été écarté : dans un couloir étroit, viser le mur ne ferait rien du tout.

**La recherche ne regarde que le décor.** Un ennemi sur la case d'arrivée ne bloque
rien : deux corps qui se chevauchent se repoussent d'eux-mêmes à l'image suivante, alors
que la roche, elle, garde le joueur. C'est aussi ce qui évite qu'une nuée fasse rater
toutes les ruées.

**Le dash n'a pas de portée à lui.** Elle est celle de la pose (`PLACEMENT_RANGE`),
donc les nœuds ne peuvent pas l'allonger. Un champ de plus serait un nombre de
`SkillStats` de plus, une ligne de fiche de plus et un cas de plus dans le test des
formes — pour une valeur qu'aucun contenu ne veut encore changer.

**La charge statique frappe une fois et meurt.** L'alternative — elle zappe toutes les
`period` pendant ses 2 secondes — en fait un nuage d'orage miniature, c'est-à-dire la
compétence d'à côté. Une mine qui attend est un geste distinct.

**Elle porte 20 % de ce qui a touché**, pas 20 % de ce que le coup valait avant
défenses : la règle se lit directement sur le chiffre qui s'affiche, et une charge née
d'un coup absorbé par l'armure est petite. Le revers est qu'elle est atténuée deux fois
— une fois sur le coup d'origine, une fois sur sa propre cible.

**Elle est de foudre**, quelle que soit la nature du coup qui l'a déclenchée. Une
charge statique de feu se lirait comme un bug ; et sa nature décide de sa couleur et de
l'état qu'elle peut poser.

**Les charges sont plafonnées.** Une compétence rapide sur une nuée d'engourdis en
sèmerait des centaines, chacune sondant son entourage. Plafond à 24 vivantes, la plus
vieille cède sa place. À remesurer sur le banc (§8).

**Les deux statistiques neuves ne sont pas sur la fiche.** Elles y arriveraient avec
deux affixes de plus (la bijection), et deux lignes de plus dans un panneau qui tient
tout juste. Elles se lisent sur la page du manuel, là où le buff les promet. C'est le
point le plus discutable du jalon.

**Un buff ne se sauvegarde pas allumé.** Rien de calculé ne s'écrit (ARCHITECTURE) ; et
un buff qui reprendrait tout seul au chargement drainerait une réserve que le joueur
n'a pas demandé à dépenser.

---

## 7. À trancher

1. **Les nouveaux manuels.** Le jalon les attend : leur nature, leurs quatre à six
   cases, leur passif. Tant qu'ils ne sont pas décrits, ce document ne porte que les
   deux manuels existants — et la section §5 est le gabarit qu'ils reprendront.
2. **La chance d'embraser sur la fiche de personnage**, avec son affixe (gants,
   bijoux) — ou pas.
3. **Le numéro.** `docs/ARCHITECTURE.md` cite déjà un « jalon 19 » (l'arbre à 418
   nœuds) qui n'a pas son document. Ce jalon-ci prend donc 20 ; si le 19 doit rester
   libre, c'est un `git mv` et trois occurrences.

---

## 8. Ce qui refusera un oubli

**Formes** — `tests/integration/test_shapes.gd` :

- une ruée déplace le joueur vers le curseur, et pas plus loin que `PLACEMENT_RANGE` ;
- elle laisse une trace qui frappe un ennemi posé sur le trajet, et qui meurt à la fin
  de sa durée ;
- un buff s'allume au premier lancer et s'éteint au second ; la touche tenue ne
  l'éteint pas ;
- un buff allumé change la fiche, éteint la rend ;
- la mort éteint tout ce qui était allumé, aura comprise ;
- le mana épuisé éteint le buff qui le draine ;
- un coup sur un engourdi, buff allumé et chance à 100 %, pose une charge ; sur un
  ennemi sain, aucune.

**Compétences** — `tests/unit/test_skills.gd` :

- `test_each_shape_has_the_numbers_it_needs` : `DASH` veut `duration`, `period` et
  `radius` ; `BUFF` veut un drain et au moins une ligne ;
- `test_each_skill_has_what_it_takes_to_deal_damage` **change** : une compétence sans
  table de dégâts est légitime si elle déclare ses points et ses lignes ;
- les lignes d'un buff visent la fiche ou un mot-clé — la règle des passifs, au mot
  près (`test_each_passive_line_targets_the_sheet_or_a_keyword`, à étendre) ;
- Immolation résolue sur une fiche à 600 PV rend plus qu'à 100.

**Sauvegarde** — `tests/unit/test_character.gd` : un fichier qui porte des points sur
`lightning_nova` se relit sans eux, et le manuel les rend.

**États** — `tests/unit/test_status_effects.gd` : un facteur de 1,5 fait passer la
chance de 0,20 à 0,30, et ne fait rien à une nature qui ne pose rien.

**Et les gardes existants** : `test_les_cases_tiennent_dans_le_panneau`,
`test_the_sheet_stays_in_frame`, `test_widths`, `test_each_label_has_its_agreement`,
`test_ids_are_unique`.

**Ce qu'aucun test ne verra** (CLAUDE.md) : le dessin de la trace et des charges — en
fenêtré ; la performance — `world/stress_test.tscn`, graine 4242, après chauffe, avec
les charges au plafond et une ruée tenue, à comparer au tableau de référence
(165 img/s, et le temps figé sous 10 %).

---

## 9. Étapes

1. Les deux formes et leurs champs sur `Skill`, sans contenu : `resolve()`, les tests
   unitaires, rien qui bouge à l'écran.
2. Le dash et sa trace, puis les deux `.tres` de ruée et leurs cases.
3. Le buff, son drain, ses lignes dans la fiche, puis Ignition — le plus simple des
   deux, il ne demande aucune règle de coup.
4. La chance d'embraser : la statistique, le facteur porté par l'auteur, le test.
5. Le signal `struck`, la charge statique, puis Électricité statique.
6. Nova de foudre s'en va.
7. Les PV d'Immolation.
8. L'anneau de la barre, la fiche de manuel d'un buff, les icônes, `en.po`.
9. `tools/catalog.sh`, `tools/balance.sh calculation`, la suite complète, la mesure du
   banc, puis l'équilibrage.

---

## 10. Livré le 18 septembre 2026

**La suite : 789 tests, 789 passent** (779 avant, plus les dix du jalon).

### Écarts avec ce que ce document annonçait

- **`SkillStats` gagne un champ**, `self_mana_burn`, là où le §3 disait aucun. La fiche
  du manuel lit les prix sur le lancer résolu (`cast.self_burn`) : un buff qui aurait
  annoncé son drain depuis la compétence aurait fait deux chemins pour une ligne. Le
  nœud du buff, lui, lit les deux prix sur la compétence — aucun modificateur ne les
  vise.
- **Les deux ruées ont un arbre de talents** de trois nœuds chacune, que ce document ne
  prévoyait pas : durée, rayon, dégâts amplifiés. Une case de compétence sans nœud ouvre
  une vue presque vide, et les quatre autres cases des deux livres en ont un.
- **`test_each_skill_has_what_it_takes_to_deal_damage` n'a pas eu à changer** : il
  demande `points_max() > 0`, ce qu'un buff satisfait par ses points déclarés. La règle
  neuve est portée par un test neuf,
  `test_a_skill_without_a_damage_table_declares_its_points_and_its_lines`, qui exige
  aussi que ses lignes visent la fiche ou un mot-clé.
- **Les icônes ont leur tuyau** : `tools/skill_icons.py`, qui importe le rendu et la
  quantification de `tools/item_icons.py` (passé sous `if __name__ == "__main__"` pour
  ça) et n'en diffère que par le recadrage au centre et le fond suivant la nature. `gen`
  puis `apply`, la table est `tools/skill_icons.json`.

### Tests changés parce que le contenu a disparu

La Nova de foudre était le seul sort à huit traits, donc le véhicule de deux tests qui
jugeaient en fait `Player._roll()` : la couronne d'angles distincts et le tirage par
trait. Ils montent maintenant leur lancer à la main (`_crown()`), ce qui garde la
branche du **cercle fermé** — l'écart divisé par le nombre de traits et non par les
intervalles — qu'aucune compétence n'exerce plus. Trois autres tests la citaient comme
exemple de contenu : ils citent Éclair vif ou Ruée d'orage.

Un seul chiffre mesuré est parti sans être remplacé : la moyenne de la nova dans
`test_a_character_reread_from_version_4_hits_as_before`. Les trois autres restent.

### Le banc de performance

Banc `world/stress_test.tscn`, graine 4242, en fenêtré, combat tenu, moyenne sur
1 440 images après 240 de chauffe — **piloté automatiquement** sur une copie, le banc
se conduisant à la main en temps normal.

| | avant le jalon | après |
|---|---|---|
| images/s | 164 · 164 | 164 · 164 |
| physique | 5,65 · 6,06 ms | 6,00 · 6,17 ms |
| temps figé | 5,3 · 4,8 % | 5,3 · 4,8 % |

**Aucune régression mesurable.** Le seul coût ajouté à la boucle chaude est le signal
`struck`, émis une fois par coup reçu : il n'a d'auditeur que chez le joueur, qui
retourne aussitôt quand sa chance de charge est nulle. Sur des fenêtres courtes
(240 images) la physique de ce banc va de 3,2 à 8,1 ms **des deux côtés** : c'est la
fenêtre qu'il faut allonger, pas la conclusion qu'il faut en tirer.

### L'équilibrage

`tests/run.sh balance` : **toujours 4 tests sur 5 en échec**, les mêmes qu'au jalon 18,
et aucun couloir neuf ne casse. Les couloirs de mêlée sont **identiques au caractère
près** — le manuel du chevalier n'a pas bougé. Ceux de sort s'améliorent partout, parce
que le manuel de la foudre a perdu une case et en a gagné deux : les vingt points du
banc se répartissent autrement, et l'Éclair vif prend la place de la Chaîne d'éclairs
comme meilleur sort au-delà de la zone 40.

| profil, sort | avant | après |
|---|---|---|
| Nu zone 120 | 156 coups | 132 |
| Sous-équipé zone 90 | 22,0 | 19,0 |
| Équipé zone 90 | 20,8 | 18,0 |
| Sur-équipé zone 90 | 19,1 | 16,6 |

**Aucun chiffre de couloir n'a changé** (jalon 13, §4).

### Non fait

- Les nouveaux manuels, qui attendent leur description (§7).
- La chance d'embraser et la chance de charge statique **ne sont pas sur la fiche de
  personnage** : elles se lisent sur la page du manuel, sous le buff qui les promet.
- **Le dessin n'a pas été jugé sur capture** : la trace, les charges et le halo d'un
  buff sont écrits mais pas regardés en fenêtré.

---

## 11. Révision du 18 septembre 2026

Trois demandes, le jour même de la livraison.

**La ruée traverse.** Elle ne s'arrête plus sur rien — ni mur, ni ennemi. Seule
l'arrivée doit être libre : `Player._landing()` part du point visé et recule de huit
pixels en huit jusqu'à ce que le corps tienne, le départ fermant la marche.
`_fits_at()` interroge le **décor seul**, par une requête de forme sur le calque 1 :
l'ennemi qu'on vient d'écraser se repousse tout seul à l'image suivante. Le §6 dit
pourquoi le refus pur a été écarté. `move_and_collide()` a disparu avec.

**La Ruée d'orage ne laisse plus rien au sol.** C'est une téléportation nue — plus de
trace, plus de table de dégâts —, mais elle donne **+5 % de vitesse par point pendant
2 secondes**, par le nœud `Buff` qui a gagné une durée de vie facultative. Son arbre
tombe de trois nœuds à un : Persistance, qui allonge ce buff ; le rayon et les dégâts
amplifiés n'avaient plus rien à mordre.

Le modèle ne sait dire qu'une valeur **par point** : la demande (« 10 %, 15 %,
20 %… ») est une suite qui commence à 10 puis monte de 5, ce qu'un `TalentLine` ne peut
pas écrire sans un champ de base — partagé avec les passifs et les nœuds de l'arbre. On
s'en tient à +5 % par point sur quatre points, soit 5 → 20 % : le pas est le bon, seul
le premier point vaut moins. Un champ `base_value` sur `TalentLine` le corrigerait, et
il servirait à d'autres.

**Les deux ruées se distinguent par leur recharge** : 4 secondes pour la Ruée ardente,
qui brûle le couloir qu'elle vient de traverser, 2 pour la Ruée d'orage, qui ne fait que
partir vite. La première pour entrer, la seconde pour sortir.

**Ce que la forme `DASH` demande a donc changé** : une `duration` toujours — c'est ce
que dure ce qu'elle laisse —, puis **l'un ou l'autre**, un rayon et une période pour une
trace, ou des lignes pour un buff.
`test_each_shape_has_the_numbers_it_needs` le dit maintenant ainsi, et trois tests
d'intégration s'ajoutent : la traversée d'un mur, le recul devant une arrivée prise, et
la Ruée d'orage qui ne laisse rien au sol mais presse le pas pour deux secondes.

**Les quatre icônes sont posées.** ComfyUI rallumé, quatre sujets × trois graines,
jugés sur planche réduite à 24 px et comparés aux neuf existantes. Ce qui a coûté trois
tours : **le modèle ne dessine pas l'abstrait**. « Un éclair en forme de flèche », « une
sphère d'arcs » sortent en taches illisibles ; une **silhouette** — un homme qui bondit,
fait de flammes ou de foudre — se lit à 24 pixels, et une **étoile d'arcs** vaut mieux
qu'une sphère pour l'Électricité statique. Le fond, lui, n'obéit qu'à moitié : violet
demandé, violet obtenu ; cramoisi demandé, gris obtenu — la leçon des objets, où la
couleur du fond ne se commande pas. Les deux icônes de feu sont donc sur gris clair là
où les neuf autres sont sombres. À refaire si ça se voit en jeu : `gen --only` et une
autre graine.

**Le bandeau montre ce qui brûle.** Une icône par geste entretenu, **à gauche des
jauges** : la bande y est déjà réservée aux fenêtres flottantes par `Hud.gauges_top()`,
donc la ligne n'oblige rien à reculer. Le cadre fait `SkillIcon.SIDE` — en dessous, le
facteur entier ne réduit pas et l'icône déborderait —, il est cerné de la couleur de la
nature, et un **voile descend** sur ce qui a une durée : la Ruée d'orage se vide en deux
secondes, l'Ignition et l'Immolation n'ont pas de compte à rebours. Le dernier allumé
s'ajoute à gauche, les autres ne bougent pas.

`SkillIcon` **dessine** maintenant (`draw_into`), ce que son en-tête disait qu'elle ne
ferait pas : la barre et le bandeau montraient la même marque, avec la même règle de
facteur entier et le même disque de repli. Deuxième copie, donc une seule fonction.

Trois tests de plus (`tests/integration/test_hud.gd`) : la ligne reste à gauche des
jauges et dans le cadrage, elle ne descend pas sous le bloc des deux barres, et allumer
une case la remplit — éteindre la vide. Et **une capture réelle en fenêtré**, quatre
gestes allumés, parce qu'aucune assertion ne voit une icône illisible.

**Suite : 795 tests, 795 passent.**

---

## 12. Révision du 18 septembre 2026 (suite)

**La charge statique se voit.** Deux pixels de violet sur un sol sombre ne se voyaient
pas : elle porte maintenant un halo **à son rayon exact** — le dessin dit où elle mord,
sinon on marche dedans sans l'avoir vue —, six branches qui vont jusqu'au bord et un
cœur blanchi qui bat. Blanchi et non blanc : en mélange additif, un cœur blanc pur
ressort comme un éclat physique et l'étincelle perd la couleur de sa nature. Jugé sur
capture, six charges posées côte à côte.

**La fiche de survol se lit comme une gemme de PoE.** Elle donnait vingt valeurs à la
file ; elle donne maintenant, dans cet ordre : le nom, les mots-clés du geste résolu,
**un paragraphe qui dit ce que la compétence fait**, puis les nombres en blocs, chacun
coiffé d'un titre centré sur son filet — « Lancer », « Dégâts », « Forme », « En
moyenne, si tout touche ». Le premier bloc n'a pas de titre : il suit l'en-tête, qui le
dit déjà.

Le paragraphe est un champ de contenu, `Skill.description`, **le geste et jamais les
nombres** : deux vérités sur les mêmes chiffres finiraient par diverger. Quinze
descriptions, leur anglais, et `test_each_displayed_text_has_its_english` qui les couvre
comme les noms.

**Ce que ça a coûté en hauteur, et comment il a été payé.** La fiche la plus chargée du
jeu — le Nuage d'orage — tenait à vingt-quatre pixels près sous la borne des jauges ; le
paragraphe et quatre titres lui en ajoutaient quarante-trois. Quatre gestes l'ont
ramenée à trois pixels près :

- les descriptions font **deux lignes au plus**, soit environ soixante-cinq signes ;
- un titre de groupe prend `TITLE_BAND` (7 px) et non une ligne pleine ;
- la fiche a **sa propre hauteur de ligne**, `SHEET_LINE` (9) et `SHEET_PROSE` (8),
  plus serrées que celle de la page (10) — un pixel par ligne sur vingt lignes ;
- **la note « si tout touche, avant défenses » est devenue le titre de son groupe**,
  ce qui la dit mieux et coûte une ligne de moins.

`test_the_sheet_stays_in_frame` a refusé chacune des trois premières tentatives, case
par case, en nommant la compétence et les deux rectangles. C'est le test qui a réglé
cette mise en page, pas l'œil.

**Suite : 795 tests, 795 passent.**

---

## 13. Révision du 18 septembre 2026 (fin)

**Chaque intitulé de fiche prend sa majuscule**, posée dans `SheetLine._init()` — à la
construction et non au dessin, parce que c'est ce que les tests de largeur mesurent et
que deux capitalisations divergeraient d'une lettre. `RichText.capitalized()`, celle de
l'infobulle d'objet, qui saute la marque du glossaire.

**Un buff est devenu du contenu nommé.** `Skill.lines` était une liste plate, sans nom :
la fiche la versait dans un fourre-tout « Effets », et la durée d'une ruée se lisait
sous « Forme » alors qu'elle est celle du buff. Un `SkillBuff` porte maintenant un
identifiant, un nom et ses lignes, et une compétence en pose **un ou plusieurs**. La
fiche leur ouvre un bloc chacun, **sous leur nom** — la Ruée d'orage n'a donc plus ni
« Forme » ni « Effets », mais un bloc « Appel du tonnerre » avec sa durée et sa vitesse.

C'est `SheetLine.heading` qui les tient ensemble : un bloc s'ouvre quand le groupe
change **ou** quand le nom change, ce qui suffit à séparer deux buffs de suite sans
numéroter les groupes.

Trois noms posés : « Appel du tonnerre » (Ruée d'orage), « Combustion » (Ignition) et
« Champ statique » (Électricité statique). Les deux derniers sont de moi — une case
entretenue est son propre buff, et « Ignition : Ignition » se serait lu comme un bégaiement.

**Le prix d'un geste entretenu a changé de bloc** : la brûlure et le drain se lisent
sous « Lancer », avec le coût et la recharge. C'est un prix par seconde, pas une forme.

**La charge statique ne part plus au premier contact.** Elle vit ses deux secondes quoi
qu'elle touche, et mord **une fois par corps** — `Targets.Contacts` avec sa vie entière
pour période, le mécanisme du serpent et de l'épée en orbite. Une nuée qui la traverse
la paie donc autant de fois qu'elle compte de corps, là où elle ne payait qu'une : à
surveiller au prochain passage d'équilibrage.

**Suite : 797 tests, 797 passent.** Deux de plus : le bloc d'un buff se lit sous son nom
et sa durée n'est nulle part ailleurs ; chaque intitulé commence par une majuscule.

---

## 14. Deux défauts trouvés en jouant

**Espace lançait la première compétence.** `project.godot` liait trois événements à
`skill_1` : le clic gauche, la manette, et **Espace** — un reste d'avant la barre. Le
second déclencheur était invisible : `Keybinds.text_of()` ne rend que le premier, donc
l'onglet des touches montrait « clic G » et l'échange de `rebound()` ne pouvait même pas
le détecter. L'événement est retiré, et `test_a_skill_slot_has_a_single_trigger` refuse
qu'une case de barre en reprenne un second. Les flèches des déplacements restent : c'est
le seul doublon voulu, et il fait la même chose que WASD.

**La Ruée d'orage annonçait des dégâts qu'elle n'inflige pas.** Sa fiche montrait des
fourchettes ajoutées, un « par coup », une chance critique, un bloc « Forme » avec un
nombre de cibles, et des moyennes — parce que le **lancer**, lui, porte tout ce que
l'équipement ajoute à ce qui est « sort », et qu'un déplacement est un sort. Le lancer
n'a pas tort ; c'est la fiche qui mentait, en décrivant un coup qui n'arrive jamais.

`Skill.strikes()` tranche — **sa table de dégâts, et rien d'autre** : sans table, la
fiche retire les blocs « Dégâts », « Forme » et « En moyenne ». La Ruée d'orage se lit
donc en trois blocs : ses points, son coût, et son buff. Ignition et Électricité
statique y gagnent la même clarté.

Au passage, la question posée : `cibles` est le nombre d'ennemis qu'un coup atteint — la
chaîne saute de l'un à l'autre, et c'est ce nombre qui l'arrête. Il valait 2 sur une
ruée parce qu'un modificateur porté l'avait monté, et que la fiche l'imprimait sans se
demander si la compétence frappait.

**Suite : 799 tests, 799 passent.**
