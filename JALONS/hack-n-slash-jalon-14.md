# Hack'n'slash top-down — jalon 14

Suite des jalons 1 à 13. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Proposé le 16 septembre 2026.** Le jalon 13 a montré un mur de dégâts dès la zone 60 :
la vie des ennemis est composée (×1,055 par niveau), et plus rien ne suit côté joueur
que les objets. Un arbre de passifs à la PoE arrive ensuite. Avant de le dessiner, il
faut savoir **ce que vaut un nœud** : ce jalon pose les trois leviers de scaling sur
lesquels l'arbre s'appuiera.

---

## 1. Périmètre

**Dedans :**

- **Deux sortes de pourcentage : « accru » et « plus ».** Les accrus d'une même
  statistique s'additionnent entre eux, puis chaque « plus » multiplie le résultat.
- **Des niveaux de compétence en bonus** : « +1 niveau aux compétences de feu », au-delà
  de ce que le manuel a placé, et au-delà de la table de la compétence.
- **Des dégâts conditionnels selon l'état de la cible** : « +30 % de dégâts contre les
  ennemis embrasés », un par état du jalon 12.
- **Le contenu qui s'en sert** : des affixes pour les deux dernières lignes, et le tri
  des lignes de talent existantes entre accru et plus (§6).
- **Ce qui se voit** : l'infobulle d'objet, la fiche de personnage et la page du manuel
  distinguent les trois.

**Dehors :**

- **L'arbre de passifs.** C'est le jalon suivant ; celui-ci lui prépare ses lignes.
- **Des objets uniques porteurs de « plus ».** `ItemAffix` ne donne que de l'accru.
- **« +N niveaux à toutes les compétences ».** La liste de `Keywords` est fermée ; un
  mot-clé « toutes » s'ajoutera quand un contenu le demandera.
- **Des conditions autres que les états** : ennemi à faible vie, joueur à pleine vie,
  distance. Même tuyau, jalon suivant si l'arbre en veut.
- **Le banc d'équilibrage face aux conditions** : le calcul mesure une cible sans état
  (§4, fin).

---

## 2. Accru et plus

### La règle

Pour une statistique, dans cet ordre :

```
valeur = (base + plats) × (1 + Σ accrus) × Π (1 + chaque plus)
```

- **`StatMod.Mode` gagne `MORE`, ajouté à la fin** : l'entier est écrit dans les
  sauvegardes (`Character._item_to_dict()`), et `PERCENT` garde sa valeur 1. `PERCENT`
  **signifie désormais « accru »** ; le renommer ne changerait rien sur le disque, mais
  toucherait tout le dépôt sans rien apporter.
- **`StatMod.apply()` reste le seul endroit** qui l'écrit pour la fiche : les plats, puis
  la somme des accrus par champ, puis les plus un par un.
- **`SkillStats.increase_by()` se scinde** : les « dégâts » accrus d'un lancer se somment,
  les plus se multiplient. `SkillStats.increase` devient deux champs, `increased` (la
  somme) et `more` (le produit), pour que la page du manuel dise les deux sans les
  recalculer.

### Qui donne quoi

| Source | Accru | Plus |
|---|---|---|
| Affixes et implicites (`ItemAffix.percent`) | oui | non |
| Passifs de manuel (`TalentLine`) | oui | non, dans ce jalon |
| Nœuds de talent (`TalentLine`) | le reste | les lignes `damage` en pourcentage |

`TalentLine` gagne `@export var more := false`, lu par `StatMod.from_definition()`. Un
champ plutôt qu'un changement de `percentage` en énumération : les `.tres` existants
se relisent sans retouche.

### Ce qui change pour le contenu existant

**Tous les pourcentages du jeu sont aujourd'hui des « plus » sans le nom** : deux
« +10 % » font 1,21. Passés en accru, ils rapportent moins dès qu'ils s'empilent.
C'est un changement de règle, pas un réglage :

- `test_skills.gd` (« 1,5 × 1,1 : les accroissements se multiplient ») et
  `test_talents.gd` (`r.increase`, 1,25) **changent parce que la règle change**, et le
  disent dans leur message. Ce n'est pas un chiffre ajusté pour passer.
- **`docs/EQUILIBRAGE.md` se régénère avant et après**, et la comparaison, case par case,
  va au §9. Un couloir qui casse se lit comme au jalon 13, §4 : on décide, ici, avec la
  date.

### Libellés

- Accru : « +20 % dégâts », inchangé.
- Plus : « 20 % de dégâts en plus » — la tournure de PoE en français, et la seule qui ne
  se confonde pas avec l'accru. Une phrase entière dans `Texts`, pas des morceaux collés.
- Page du manuel : une ligne « dégâts accrus » (+X %) et une ligne « dégâts en plus »
  (+Y %), chacune seulement quand elle ne vaut pas le neutre.

---

## 3. Niveaux de compétence

### La règle

- **Une statistique `skill_levels`, toujours portée par un mot-clé** (`StatMod.scope`),
  à plat. Sans portée, elle ne voudrait rien dire : la fiche n'a pas de niveau de
  compétence. `SkillStats.LABELS` la nomme, mais `Skill._store()` la compte avant d'y
  chercher un champ du lancer.
- **Lue dans `Skill.resolve()`, et nulle part ailleurs** : c'est là que les mots-clés du
  lancer, nœuds compris, filtrent déjà les lignes d'objet. Un nœud qui convertit en feu
  rend donc « +1 aux compétences de feu » mordant, comme il le fait déjà pour les
  dégâts ajoutés.
- **Les points résolus sont `points + bonus`**, et seulement si `points ≥ 1` : un bonus
  n'apprend pas une compétence qu'on n'a pas.
- **Au-delà de la table**, `Skill.damage()` ne rend plus la dernière valeur : il la
  prolonge par `Skill.GROWTH_PER_EXTRA_LEVEL` par niveau, composé. Les tables actuelles
  montent d'environ 25 % par point (fireball : 30 → 73 en cinq). Voir §6.
- **Ce que le bonus n'ouvre pas** : `TalentNode.required_points` compte les points
  **placés**, et `Manual.can_invest()` / `can_refund()` ne voient jamais le bonus. Sinon
  retirer un anneau fermerait des nœuds investis, et `can_refund()` devrait connaître
  l'équipement.

### Ce qui se voit

- Page du manuel et barre : « 5 (+2) » là où s'affichent les points.
- Infobulle d'objet : « +1 niveau aux compétences de feu », par `Keywords.recipient()`
  comme les dégâts ajoutés.

### Contenu

Deux affixes, rares :

| Id | Portée | Valeur | Niveau requis | Bases |
|---|---|---|---|---|
| `fire_skill_levels` | `fire` | +1 | 1 ; +2 au palier 60 | armes et grimoires de lanceur (`caster`) |
| `lightning_skill_levels` | `lightning` | +1 | 1 ; +2 au palier 60 | armes et grimoires de lanceur (`caster`) |

Pas d'« attaques » ni de « sorts » dans ce jalon : ils toucheraient toutes les
compétences d'un build d'un coup, à régler après une première mesure.

---

## 4. Dégâts conditionnels

### La règle

- **Une statistique par état : `damage_vs_<état>`**, en pourcentage accru ou plus. Les
  identifiants d'état entrent dans `StatusEffects.IDS` (`ignite`, `numb`, `chill`,
  `rot`, `blessing`, `bleed`), **sur le disque dès qu'un affixe les nomme** :
  invariant 1, à ajouter à la liste d'`ARCHITECTURE.md`.
- **Résolue dans `Skill.resolve()`, appliquée dans `Hurtbox.take_damage()`.** Le lancer
  ne connaît pas sa cible ; la hurtbox ne connaît pas les lignes du lanceur. Le coup
  transporte donc la différence :
  - `SkillStats` garde, par état, l'accru et le plus conditionnels ;
  - `SkillStats.against_factor(states)` rend
    `(1 + Σ accrus + Σ accrus des états présents) / (1 + Σ accrus) × Π plus des états présents` ;
    l'accru conditionnel **s'additionne aux accrus du lancer**, il ne les multiplie pas.
    C'est tout le sens du §2 ;
  - `DamageInfo` porte une référence au `SkillStats` du lancer (`info.cast`), nulle
    pour un coup d'ennemi ;
  - `Hurtbox.take_damage()` applique le facteur **après la bénédiction de l'auteur et
    avant l'esquive et l'armure**, comme la bénédiction : c'est le coup qui est plus
    fort, et l'armure doit le voir comme tel.
- **Les trois endroits qui fabriquent un coup du joueur** posent `info.cast` :
  `Player` (le coup d'arc, `player.gd:759`), `Projectile._on_area_entered()` et
  `Targets.strike()`. Un test par forme refuse l'oubli.
- **L'état que ce coup pose ne compte pas pour lui-même** : `StatusEffects.suffer()`
  tourne après le signal. Aucun tirage de plus (invariant 3).
- **Hors de la brûlure** : ce qui brûle sort de `StatusEffects.advance()`, sans coup.
  L'embrasement brûle ce que le coup a porté, conditionnel compris : le bonus y entre
  une fois, pas deux.

### Ce qui se voit

- Page du manuel : une ligne par condition présente, « contre les embrasés : +30 % ».
  Le total « par coup » reste **sans condition**.
- Infobulle : « +30 % de dégâts aux sorts contre les ennemis embrasés ».

### Contenu

Un affixe par nature, dont l'état naît :

| Id | Stat | Portée | Bases |
|---|---|---|---|
| `scorching` | `damage_vs_ignite` | `spell` | sceptres, baguettes, gants (pas la main gauche) |
| `electrocuting` | `damage_vs_numb` | `spell` | sceptres, baguettes, gants (pas la main gauche) |
| `shattering` | `damage_vs_chill` | `attack` | armes de mêlée, gants |
| `butchering` | `damage_vs_bleed` | `attack` | armes de mêlée, gants |

Pourriture et bénédiction attendent des compétences nécrotiques et sacrées.
Premier réglage : 8–12 % au niveau 1, 40–50 % au niveau 52, en cinq paliers.

**Le banc** mesure une cible sans état : il ne sait pas quelle part du temps un grunt
passe embrasé. C'est une limite écrite, pas une omission ; la simulation, elle, les voit.

---

## 5. Arbitrages

**Accru par défaut, plus par exception.** Si tout multiplie, un arbre de 100 nœuds à
+5 % donne ×131 ; en accru, ×6. C'est ce qui rend un arbre réglable, et ce qui laisse le
« plus » aux sources rares qui font un build.

**Le conditionnel voyage avec le coup, pas la cible avec le lancer.** Résoudre le lancer
par cible multiplierait `Skill.resolve()` (21,6 µs) par le nombre d'ennemis touchés. Le
facteur par état, lu dans la hurtbox, coûte une boucle de six. **À mesurer** sur
`world/stress_test.tscn`, `[5]`, à 300 ennemis, contre la référence de `CLAUDE.md`.

**`info.cast` et non six facteurs recopiés dans `DamageInfo`.** Le `SkillStats` d'un
lancer n'est jamais gardé ni modifié après `finalize()` ; le partager entre les coups
d'un même geste ne peut pas mentir.

**Le bonus de niveau ne touche que les dégâts propres.** Il passe par `Skill.damage()`,
comme un point placé. Les nœuds, les passifs et la table de mana ne bougent pas.

**Pas de « +niveau » sans portée.** Une ligne de fiche serait lue par `StatMod.apply()`,
qui la poserait sur un champ inexistant de `CharacterStats`.

---

## 6. À trancher avant de commencer

1. **Quelles lignes existantes deviennent « plus » ?** Recommandé : **les lignes
   `damage` en pourcentage des nœuds de talent**. Ils jouent le rôle des gemmes de
   soutien de PoE, bornés par les points du manuel ; objets et passifs restent accrus.
   Sans ça, le jalon ne fait que retirer des dégâts avant le mur de la zone 60.
2. **`Skill.GROWTH_PER_EXTRA_LEVEL`** : recommandé **1,25**, la pente des tables
   actuelles. Plus bas, un +2 ne vaut pas l'affixe ; plus haut, il vaut mieux qu'un point
   placé.
3. **Le libellé du « plus »** : « 20 % de dégâts en plus » (recommandé) ou « ×1,2 dégâts ».
4. **Les couloirs du jalon 13** : on accepte qu'ils bougent, et on écrit la décision au
   §9 après lecture du rapport, ou on règle le contenu pour les tenir.

### Décidé le 16 septembre 2026

- **§6.1 — les lignes `damage` en pourcentage des nœuds de talent passent en « plus »**,
  une quinzaine dans les trois manuels. Une ou deux par compétence, payées en points de
  manuel : le rôle des gemmes de soutien. Les passifs de manuel, comme les objets,
  restent accrus. Les autres sources de « plus » — clés de voûte de l'arbre, nœuds à
  double tranchant, charges, uniques — viendront chacune à son jalon.
- **§6.2 — `Skill.GROWTH_PER_EXTRA_LEVEL` = 1,25**, composé : la Boule de feu à
  5 points et +2 niveaux fait 73 × 1,25² ≈ 114.
- **§6.3 — « 20 % de dégâts en plus ».**
- **§6.4 — les couloirs se décident à la lecture du rapport**, avant → après, écrit au
  §9 : accepter le nouveau verdict ou régler le contenu, jamais changer le chiffre du
  test.
- **Le conditionnel rejoint les accrus, à la PoE**, et non un groupe multiplicatif à part
  comme chez Hero Siege. Ici chaque nature pose son état sans investissement : en groupe
  à part, « contre les embrasés » serait un multiplicateur quasi permanent de tout build
  de feu, donc un affixe obligé ; le banc, qui mesure une cible sans état, ne le verrait
  pas ; et il échapperait à la dilution qui rend l'arbre réglable. Un « plus »
  conditionnel reste possible par `TalentLine.more`, **sur un nœud rare seulement** ;
  les affixes n'en donnent jamais.

---

## 7. Étapes

Chaque étape se livre seule et passe la suite.

1. **Accru et plus.** `StatMod.Mode.MORE`, `StatMod.apply()`, `SkillStats.increased` et
   `more`, `TalentLine.more`, les libellés, la page du manuel. Régénérer
   `EQUILIBRAGE.md` avant la retouche, puis après ; tri du contenu selon §6.1.
2. **Niveaux de compétence.** `skill_levels`, `Skill.resolve()`, le prolongement de
   `Skill.damage()`, l'affichage « (+N) », les deux affixes, `tools/catalog.sh`.
3. **Dégâts conditionnels.** `StatusEffects.IDS`, `damage_vs_<état>`, le facteur dans
   `SkillStats`, `DamageInfo.cast`, `Hurtbox.take_damage()`, les trois fabriques de coup,
   l'affichage, les quatre affixes. Mesure de performance `[5]`.
4. **La doc.** `ARCHITECTURE.md` : les lignes « Combien un coup fait-il vraiment ? »,
   « Ce qu'un lancer fait vraiment ? », « Combien de points dans une compétence ? », et
   une ligne « Quand un bonus conditionnel s'applique-t-il ? » ; l'invariant 1 gagne
   `StatusEffects.IDS`. `RECETTES.md` : « ajouter un affixe conditionnel ».

---

## 8. Ce qui refusera un oubli

- `tests/unit/test_stat_mod.gd` — deux accrus s'additionnent, deux plus se multiplient,
  l'ordre plats → accrus → plus, un `MORE` relu d'une sauvegarde reste `MORE`, un
  `PERCENT` d'une sauvegarde d'avant est accru.
- `tests/unit/test_skills.gd` — les accrus d'un lancer se somment ; le plus d'un nœud
  multiplie ; `skill_levels` ne compte qu'avec la portée portée par le lancer, nœuds
  compris ; zéro point placé reste zéro ; au-delà de la table, la croissance composée ;
  le bonus n'ouvre aucun nœud.
- `tests/unit/test_status_effects.gd` — `IDS` couvre chaque état une fois ; le facteur
  conditionnel additionne son accru aux accrus du lancer.
- `tests/integration/test_shapes.gd` — **chaque forme** porte `info.cast` jusqu'à la
  hurtbox : un coup sur une cible embrasée fait plus que sur une cible nue, et le coup
  qui embrase ne profite pas de son propre état.
- `tests/unit/test_save.gd` — une ligne `damage_vs_ignite` et une ligne `skill_levels`
  survivent à l'aller-retour.
- `tests/unit/test_translations.gd` — les nouveaux libellés.

---

## 9. Ce qui a été fait, et comment

### Étape 1 — accru et plus, livrée le 16 septembre 2026

- **`StatMod.Mode.MORE`**, `StatMod.apply()` (plats, somme des accrus par champ, puis
  chaque « plus »), `SkillStats.scale_damage()` avec `increased` et `more`, et
  `TalentLine.more`. La page du manuel écrit « dégâts accrus » et « dégâts en plus »
  sur deux lignes.
- **Contenu** : les 13 lignes `damage` en pourcentage des nœuds de talent ont
  `more = true` (4 feu, 6 foudre, 3 armes) ; les 2 des passifs restent accrues.
- **Relecture d'une sauvegarde** : tout entier de `Mode` connu est gardé ; il retombait
  sur plat s'il ne valait pas `PERCENT`.
- **Tests qui ont changé parce que la règle a changé**, chacun le dit :
  `test_the_breakdown_rebuilds_the_damage` (1,65 → 1,60),
  `test_the_projectile_count_is_rounded_at_the_end` (ses deux lignes passent en
  « plus », sinon 3 × 2 n'exerce plus l'arrondi ; le 7 attendu ne bouge pas),
  `test_the_sheet_announces_what_a_node_changes` (la Surcharge sous « dégâts en plus »).
  Ajoutés : les accrus qui s'additionnent et les « plus » qui multiplient, sur la fiche
  et au lancer, les libellés, l'aller-retour d'un `MORE`.

**Équilibrage, calcul avant → après : aucun verdict ne change.** Tous les pourcentages
se multipliaient déjà ; les nœuds, passés en « plus », gardent ce comportement, et seuls
les accrus d'objets empilés sur un même champ perdent un peu. Les plus gros écarts :
Sort Sous-équipé en zone 120, 160 → 182 coups (+14 %) ; zone 60, 6,28 → 6,46 ; la
survie bouge d'au plus 8 % (Mêlée Sur-équipé zone 90, 26,4 → 24,4 s). Le mur de la
zone 60 est donc **inchangé**, ni pire ni repoussé : c'est aux étapes 2 et 3, puis à
l'arbre, de le traiter.

**`tests/run.sh balance` échoue**, mais sur des verdicts identiques avant et après : ces
échecs précèdent le jalon (Sort Équipé en zone 40 et au-delà, profils Nu, Débutant en
zone 1). §6.4 : rien à décider pour cette étape.

La simulation n'a pas été relancée ; sa section d'`EQUILIBRAGE.md` date du jalon 13.

### Étapes 2 à 4 — niveaux, conditions, doc, livrées le 16 septembre 2026

- **Niveaux** : `SkillStats.LEVELS` (`skill_levels`) compté par `Skill._store()`, la base
  posée **après** le tri, `Skill.damage()` prolongé par `GROWTH_PER_EXTRA_LEVEL`. Page du
  manuel : « 1 / 5 (+2) ».
- **Conditions** : `StatusEffects.IDS` et `AGAINST`, `SkillStats.against()` /
  `against_factor()`, `DamageInfo.cast`, appliqué dans `Hurtbox.take_damage()` juste
  après la bénédiction. `Targets.strike()` et `Explosion.put()` **exigent** le lancer :
  un appelant oublié ne compile pas. La page du manuel montre chaque condition dans la
  couleur de l'état, hors du total « par coup ».

**Écarts avec le plan :**

- **Aucun affixe sur les bijoux, aucun conditionnel sur la main gauche.** La fiche de
  la forge (`ForgeGallery.sheet_height()`) tient 24 affixes par base ; les bijoux y
  étaient déjà et les grimoires y arrivent. Paginer la forge est un chantier d'outil,
  pas de ce jalon — noté dans RECETTES.
- **« +1 niveau » dès le niveau 1**, et non 30 : `test_each_affix_exists_from_level_1`
  l'exige de tout affixe. Il pèse 1 dans la réserve, contre 2 à 10 ailleurs.
- **Libellés** : « +1 niveau de compétence (Feu) », « +30 % dégâts contre les embrasés
  (Sort) » — la forme des autres lignes portées, `Keywords.recipient()` ne connaissant
  que les attaques et les sorts.

**Tests qui ont changé parce que la règle a changé** :
`test_beyond_the_last_point_the_table_grows` (on gardait la dernière valeur) ;
`test_a_character_reread_from_version_4_hits_as_before` résout l'Attaque et le Trait à
leur point unique — la mesure d'alors prenait la dernière valeur de la table, et les
chiffres attendus ne bougent pas. Ajoutés : niveaux portés ou non, zéro point, table
prolongée, libellés, facteur contre un état ajouté aux accrus, identifiants des états,
page du manuel, et **un coup réel par chemin** — chaîne (`Targets.strike`), boule
(tir et explosion), coup d'arc — sur une cible qui saigne contre une cible nue.

**Équilibrage, calcul après les étapes 2 et 3.** Les chiffres bougent, mais **par les
tirages** : le banc tire les objets de ses profils dans la réserve, qui a six affixes de
plus, et il ne compte pas les conditions. Deux verdicts changent, en sens contraires —
Mêlée Sous-équipé zone 60, tendu → mur (7,92 → 8,34 coups) ; Mêlée Sur-équipé zone 60,
mur → tendu (8,22 → 7,76). Les quatre tests de `tests/run.sh balance` échouent comme
avant. §6.4 : **ces deux cases sont du bruit de tirage, pas un effet des règles** ; rien
n'est réglé ici. Le mur de la zone 60 reste entier pour le banc, qui ne voit ni les
conditions ni un +2 au-delà de la table qu'aucun profil ne tire encore à coup sûr.

**Performance**, `stress_test.tscn` en fenêtré, 300 ennemis demandés (~230 simulés),
combat automatique, 240 images de chauffe puis 900 mesurées ; base = la même copie sans
l'application dans `Hurtbox`, alternées : **modifié 6,26 et 5,57 ms, base 5,37 et
6,21 ms**. Aucun écart qui sorte du bruit d'un lancement à l'autre.
