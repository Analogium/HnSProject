# Hack'n'slash top-down — jalon 50

Suite des jalons 1 à 49. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 13 octobre 2026.** Le **manuel du Vive lame** rempli, comme celui de la
sorcière au jalon 41.

---

## 1. Ce que l'utilisateur a demandé

« Comme pour les précédents jalons avec les manuels, j'aimerais maintenant m'attaquer au
manuel unique du Vive lame en lui ajoutant des compétences. »

Le manuel n'a que les deux cases du jalon 28 — **Frappe vive** et **Soif de sang** — et
aucun arbre : sur vingt points, il n'en dépense que six (CATALOGUE, « Manuels de classe »).

## 2. L'identité

Le chevalier tient ce qui **pèse**, ce qui **ouvre** (le saignement), ce qui **garde** (les
lames autour de soi) et ce qui **porte** (jalon 46, §2). La sorcière tient ce qui se passe
**entre les éléments** (jalon 41, §2). Le Vive lame tient **le tempo du duel** : entrer,
frapper vite, sortir, conclure. Sa matière est ce que les deux autres n'ont pas :

- **la Frénésie** — les charges de la Soif de sang, qu'on gagne en tuant ; aujourd'hui on
  ne fait que les subir, le manuel apprend à les **dépenser** ;
- **le critique** — aucun manuel n'en fait sa règle (la Pesée du chevalier mise à part) ;
- **l'esquive** — `CharacterStats.evasion` existe depuis la dextérité, aucune compétence
  ne s'en sert.

Pas de saignement (le chevalier), pas d'élément, pas d'invocation, pas de lames posées
autour de soi (l'Épée spirale).

| case | ouvre à | ce qu'elle fait | le geste du tempo |
|---|---|---|---|
| Frappe vive *(jalon 28)* | 1 | bond sur l'ennemi le plus proche de la visée, un coup | **entrer** |
| **Rafale** | 2 | trois estocs d'affilée droit devant, dans un seul geste ; chaque estoc a +15 % de chance critique de plus que le précédent | **frapper vite** |
| Soif de sang *(jalon 28)* | 3 | entretenue, gratuite : un tué donne une charge de Frénésie | **s'emballer** |
| **Lames de jet** | 5 | un éventail de trois couteaux vers la visée, une attaque physique à distance ; **un couteau qui critique ne s'arrête pas** : il traverse et continue | **harceler** |
| **Coup de grâce** | 7 | un estoc lourd sur l'ennemi visé qui **consomme toutes les charges de Frénésie** : +25 % de dégâts plus par charge, et **achève** un ennemi sous 10 % de ses PV par charge consommée | **conclure** |
| **Contre-attaque** | 10 | entretenue, draine du mana : +esquive tant qu'elle tient ; **chaque coup esquivé rend un coup d'arme** à l'attaquant, s'il est à portée | **rendre** |

Le combo de base : la Rafale tue, la Soif de sang monte, le Coup de grâce vide les charges
sur le gros ; les Lames de jet tiennent ce qui reste hors de portée.

Sur la première proposition : « remplace Volte par un skill de dégâts et non de mobilité » ;
puis « ça me va, oui fais les arbres avec » — les arbres des six cases dans ce jalon ; sur la
proposition des arbres (§4), « ça me va, je veux un dessin propre pour chacun » : la Rafale,
le Coup de grâce et la riposte ont chacun leur dessin, choisi sur planche.
La **Volte** (saut sans frapper, coup suivant critique) quitte la liste ; les **Lames de
jet**, en réserve, prennent sa case du niveau 5. Le Vive lame a déjà de quoi entrer — la
Frappe vive.

**Les gestes** (jalon 47) : un mouvement neuf n'est plus un coût à éviter — il rend le jeu
plus lisible, à la demande de l'utilisateur. Chaque attaque neuve reçoit le sien, pour le
Vive lame seul (manuel de classe) :

| compétence | geste | ce qu'on voit |
|---|---|---|
| Rafale | `flurry` *(neuf)* | trois estocs secs, le bras qui revient entre chacun |
| Lames de jet | `throw` *(neuf)* | le bras qui lance de côté, de l'épaule |
| Coup de grâce | `finisher` *(neuf)* | l'épée ramenée en arrière, puis l'estoc fendu de tout le corps |
| Contre-attaque | `thrust` *(repris)* | la riposte est un réflexe : l'estoc de la Frappe vive |

Inspirations relevées : dans PoE, la *Blade Flurry*, le *Flicker Strike* et le *Riposte*
du Duelliste ; dans Diablo IV, le *Shadow Step* et la *Twisting Blades* du voleur, le
*Death Blow* ; dans Last Epoch, le *Shift* et la *Lethal Mirage* de la danseuse de lames ;
dans Hero Siege, le samouraï et ses coups qui se relancent ; l'escrime pour les noms.

### En réserve

- **Mirage** — un double qui rejoue les attaques : trop proche du Familier de la sorcière,
  qui rejoue les sorts.

## 3. Les quatre compétences — la proposition

Chiffres de **premier réglage** ; l'équilibrage se fait en dernier (jalon 13, §7). Deux écarts
avec le tableau du §2, dictés par les règles du dépôt :

- **la Rafale ne donne pas de chance critique plate** : hors d'une arme, une chance critique
  n'est jamais plate (`test_no_flat_crit_outside_a_weapon`). L'escalade se fait en accru ;
- **le Coup de grâce achève à 5 % par charge**, pas 10 : à cinq charges, la moitié de la vie
  d'une élite partait d'un seul coup.

### Rafale — `flurry`, niveau 2

Trois estocs droit devant, `RAFALE_GAP` (0,12 s) l'un après l'autre, dans un seul geste
(`attack_time_factor` 1,2). Chacun frappe **le premier ennemi sur sa ligne** — l'estoc de la
Tierce (`Player._thrust()`), sa longueur prise sur le `radius` (48 px) — : c'est un geste de
duel, les Lames de jet tiennent les groupes. Chaque estoc a **+50 % de chance critique
accrue de plus** que le précédent : +0, +50, +100 %. 7 mana. Par point : 10 · 13 · 16 · 20 ·
25 par estoc.

### Lames de jet — `throwing_knives`, niveau 5

Trois couteaux en éventail de 24° vers la visée, 460 px/s, une attaque physique de projectile
(`attack_time_factor` 1,0). **Un couteau qui critique traverse** sa cible et continue, une
fois par critique — un couteau qui ne critique pas s'arrête. Le dessin est neuf : un couteau
qui tournoie (planche, `/dessiner-un-effet`). 8 mana. Par point : 12 · 15 · 19 · 24 · 30 par
couteau.

### Coup de grâce — `coup_de_grace`, niveau 7

Un estoc lourd (`attack_time_factor` 1,4) sur **l'ennemi le plus proche de la visée à 56 px**
— la règle de la Frappe vive, sans le bond ; refusé sans cible, avant tout paiement, pour ne
pas brûler les charges. Il **consomme toutes les charges de Frénésie** : +25 % de dégâts plus
par charge, et **achève** sa cible si elle tombe sous 5 % de ses PV par charge consommée
(25 % à cinq charges). Sans charge, un estoc lourd ordinaire. 10 mana. Par point : 40 · 52 ·
66 · 82 · 100.

### Contre-attaque — `counterattack`, niveau 10

Entretenue, 3 mana/s : tant qu'elle brûle, **Garde** donne +8 esquive par point (le geste
d'une attaque : `cadence` WEAPON, donc ses ripostes sont des attaques — elles nourrissent la
Soif de sang). **Chaque coup esquivé déclenche une riposte** : l'ennemi le plus proche de
l'attaquant à 64 px (`radius`) prend un estoc, sans geste du corps — le fuseau dessiné de la
Tierce part de vous vers lui. Une riposte au plus toutes les 0,25 s : une meute qui rate dix
fois en une image ne doit pas en donner dix. Par point : 14 · 18 · 23 · 29 · 36.

## 4. Les arbres — la proposition

Les règles du jalon 46, §2 : **aucun nom ni aucune ligne** ne revient d'un arbre à l'autre du
manuel, sauf un nœud de dégâts, de rayon et de durée par arbre, et les échanges ; 12 à 13
nœuds, 30 à 34 points pour un pool de 20 ; une à deux suites derrière ce qui change le jeu.
Les soixante-seize noms, tous neufs, ont été vérifiés contre ceux du jeu (`i18n/en.po`) ; quatorze
premiers choix étaient pris (Bond, Sobriété, Enchaînement, Crescendo, Sillage, Acharnement,
Affûtage, Gerbe, Aller-retour, Œil de lynx, Carambolage, Miséricorde, Retenue,
Insaisissable).

Conventions du jalon 42 : « relié à (n) » = points demandés dans le parent, ⇄ marque un
échange, **neuf** = un nombre de `SkillStats` à écrire, 🔗 = interaction avec une autre
compétence, **↳** = suite, accessible par son seul parent.

**Les deux interactions** : la Rafale ravive la Frénésie (Ivresse du sang) ; les Lames de jet
se plantent, et le Coup de grâce les arrache (Lame plantée). Le reste de ce que les arbres
lisent de la Soif de sang — les charges que le Coup de grâce consomme — est la compétence
elle-même.

### Frappe vive — l'entrée *(13 nœuds, 30 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Élancement | 5 | +12 % dégâts plus | — |
| Détente | 3 | +15 % rayon : le bond porte plus loin | — |
| Épargne | 3 | −10 % coût en mana | — |
| Impétuosité *(neuf)* | 3 | +5 % dégâts par point pour chaque 40 px franchis par le bond | Élancement (1) |
| Premier sang *(neuf)* | 2 | contre un ennemi à pleine vie, +25 % dégâts plus par point | Élancement (1) |
| Ouverture *(neuf)* | 3 | la cible frappée prend +6 % par point de vos coups suivants pendant 2 s | Premier sang (1) |
| Coup double *(neuf)* | 2 | un second coup suit le premier, à 30 % par point | Détente (1) |
| **Repli** *(neuf)* | 1 | **après le coup, on rebondit de 60 px en arrière** — frapper et sortir | Détente (2) ou Épargne (2) |
| ↳ Dérobade *(neuf)* | 1 | pendant le repli, intouchable 0,4 s | Repli (1) |
| **Coup sur coup** *(neuf)* | 2 | **un ennemi tué relance la frappe vive** sur le plus proche à portée, gratuite, une fois par point — le *Flicker Strike* | Élancement (2) |
| ↳ Furia *(neuf)* | 2 | chaque relance frappe 15 % plus fort par point que la précédente | Coup sur coup (1) |
| **Fente** *(neuf)* | 1 | **le bond frappe tout ce qu'il traverse**, à 40 % ⇄ +20 % temps du geste | Impétuosité (1) |
| ↳ Coupe-file *(neuf)* | 2 | ce que le bond traverse prend +20 % du coup par point | Fente (1) |

### Rafale — la cadence *(13 nœuds, 31 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Pointe | 5 | +10 % dégâts plus | — |
| Battement | 3 | −8 % temps du geste | — |
| Coup d'œil | 4 | +20 % chance critique accrue | — |
| Fer long | 3 | +15 % rayon : les estocs portent plus loin | — |
| Montée *(neuf)* | 2 | l'escalade d'un estoc à l'autre gagne +25 % de chance critique accrue par point | Coup d'œil (1) |
| Insistance *(neuf)* | 3 | un estoc qui frappe la même cible que le précédent : +8 % dégâts par point | Pointe (1) |
| Pression | 3 | +1 mana par estoc qui touche | Battement (1) |
| Quatrième estoc *(neuf)* | 2 | +1 estoc par point ⇄ +15 % temps du geste | Battement (2) |
| **Botte secrète** *(neuf)* | 1 | **le dernier estoc est critique à coup sûr** | Coup d'œil (2) ou Montée (1) |
| ↳ Coup de Jarnac *(neuf)* | 1 | le dernier estoc porte deux fois plus loin et **traverse tout** | Botte secrète (1) |
| **Éventail** *(neuf)* | 1 | **les estocs partent en éventail**, à gauche, au centre, à droite — un groupe plutôt qu'un duel ⇄ −15 % dégâts plus | Fer long (2) |
| ↳ Rose des vents *(neuf)* | 1 | sous l'Éventail, les estocs se répartissent sur tout le cercle | Éventail (1) |
| Ivresse du sang 🔗 *(neuf)* | 2 | chaque critique de la Rafale ravive les charges de Frénésie, +0,3 s par point | Montée (1) |

### Soif de sang — la frénésie *(12 nœuds, 32 points)*

Les lignes de buff comptent **par charge** (jalon 41, §8), comme celles de Trinité.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Carnage | 5 | par charge, +2 % dégâts d'attaque accrus (buff) | — |
| Ivresse | 4 | par charge, +2 % vitesse (buff) | — |
| Ténacité | 4 | les charges tiennent +0,5 s par point | — |
| Instinct | 3 | par charge, +4 % dégâts critiques (buff) | Carnage (1) |
| Sang chaud | 3 | par charge, +1 PV/s (buff) | Ivresse (1) |
| Moisson *(neuf)* | 3 | chaque charge gagnée rend 1 % des PV max par point | Ivresse (1) |
| Fièvre *(neuf)* | 3 | **un critique d'attaque donne une charge**, à 8 % de chance par point | Instinct (1) |
| Lampée *(neuf)* | 2 | un tué donne deux charges, à 10 % de chance par point | Carnage (1) |
| Sans fond *(neuf)* | 2 | +1 charge au plafond par point ⇄ −0,5 s de tenue | Ténacité (1) |
| **Berserk** *(neuf)* | 1 | +2 charges au plafond, et à pleines charges **+20 % vitesse d'attaque plus** ⇄ par charge, +2 % dégâts subis | Carnage (2) ou Sans fond (1) |
| ↳ Sans quartier *(neuf)* | 1 | sous le Berserk, à pleines charges, **chaque tué éclate** : une onde physique de 40 px, à 30 % du coup qui l'a tué | Berserk (1) |
| **Dernier carré** *(neuf)* | 1 | à l'échéance, **la moitié des charges reste** (arrondie en dessous), et repart pour une tenue | Ténacité (2) |

### Lames de jet — le harcèlement *(13 nœuds, 31 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Aiguisage | 5 | +10 % dégâts plus | — |
| Jet tendu | 3 | +15 % vitesse de projectile | — |
| Poignée | 2 | +1 lame par point ⇄ −10 % dégâts plus | — |
| Perce-armure | 2 | +1 ennemi traversé par point, critique ou non | Jet tendu (1) |
| Lame chercheuse | 3 | les lames s'infléchissent vers un ennemi à 20 px par point | Jet tendu (1) |
| Tir lointain *(neuf)* | 3 | +5 % dégâts par point pour chaque 50 px parcourus | Aiguisage (1) |
| Enfilade *(neuf)* | 3 | une lame qui traverse frappe 15 % plus fort par point chaque ennemi suivant | Perce-armure (1) |
| **Retour de lame** *(neuf)* | 1 | **en bout de course, les lames reviennent vers vous** et frappent encore ce qu'elles croisent | Jet tendu (2) ou Poignée (1) |
| ↳ Récupération *(neuf)* | 2 | chaque lame rattrapée rend 1 mana par point | Retour de lame (1) |
| **Lame plantée** 🔗 *(neuf)* | 1 | **une lame qui s'arrête dans un ennemi y reste plantée** 4 s ; le Coup de grâce les arrache, +20 % de dégâts plus par lame | Aiguisage (2) |
| ↳ Ancrage | 3 | +25 % durée : les lames plantées tiennent plus longtemps | Lame plantée (1) |
| ↳ Hérisson *(neuf)* | 2 | chaque lame plantée fait subir à son porteur +4 % de dégâts par point | Lame plantée (1) |
| Seconde salve *(neuf)* | 1 | une seconde volée part 0,25 s après la première, à 50 % | Poignée (2) |

### Coup de grâce — la conclusion *(13 nœuds, 32 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Estocade | 5 | +12 % dégâts plus | — |
| Renverse | 3 | repousse la cible, +20 par point | — |
| Allonge | 3 | +15 % rayon : la cible se cherche plus loin | — |
| Dague de miséricorde *(neuf)* | 4 | +1 % seuil d'achèvement par point, charges ou non | — |
| Implacable *(neuf)* | 3 | +8 % dégâts plus par charge consommée, par point | Estocade (1) |
| Acculé *(neuf)* | 3 | +10 % dégâts par point contre un ennemi sous la moitié de sa vie | Estocade (1) |
| Défaut de la cuirasse *(neuf)* | 3 | le coup ignore 8 % par point de l'armure de sa cible | Allonge (1) |
| Rançon *(neuf)* | 2 | chaque charge consommée rend 2 mana par point | Implacable (1) |
| Effroi *(neuf)* | 2 | un ennemi achevé ou tué assomme ses voisins à 60 px, 0,3 s par point | Dague de miséricorde (1) |
| **Sang-froid** *(neuf)* | 1 | **le Coup de grâce ne consomme que la moitié des charges** ⇄ −10 % dégâts plus par charge | Implacable (2) |
| ↳ Patience *(neuf)* | 1 | les charges que garde le Sang-froid repartent pour une tenue | Sang-froid (1) |
| **Point final** *(neuf)* | 1 | **à cinq charges consommées, le coup éclate autour de sa cible** : une explosion physique de 40 px, à 50 % | Renverse (2) ou Allonge (2) |
| ↳ Épilogue *(neuf)* | 1 | l'éclat du Point final achève aussi, au seuil du coup | Point final (1) |

### Contre-attaque — la riposte *(12 nœuds, 34 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Contre | 5 | +12 % dégâts plus | — |
| Garde haute | 4 | +6 esquive par point (buff) | — |
| Respiration | 3 | −10 % mana drainé | — |
| Fer tendu | 3 | +15 % rayon : la riposte porte plus loin | — |
| Sangsue | 3 | chaque riposte rend 3 PV par point | Contre (1) |
| Double riposte *(neuf)* | 2 | +1 riposte par esquive par point ⇄ −15 % dégâts plus | Contre (2) |
| Désarmement *(neuf)* | 2 | l'ennemi riposté est assommé 0,3 s par point | Fer tendu (1) |
| Représailles *(neuf)* | 3 | un coup reçu, non esquivé, déclenche aussi une riposte, à 10 % de chance par point | Garde haute (1) |
| Calme | 3 | −2 % dégâts subis par point, tant qu'elle brûle (buff) | Respiration (1) |
| Pas de côté *(neuf)* | 3 | chaque esquive donne +4 esquive par point pendant 3 s, cinq fois au plus | Garde haute (1) |
| **Contretemps** *(neuf)* | 1 | **après une esquive, votre attaque suivante dans les 2 s est critique à coup sûr** — ce qui reste de la Volte | Garde haute (2) ou Pas de côté (1) |
| ↳ Temps d'escrime *(neuf)* | 2 | ce coup sûr frappe 15 % plus fort par point | Contretemps (1) |

## 5. Ce qui serait neuf au moteur

- **`Skill.Shape`** : `FLURRY`, `KNIVES`, `FINISHER`, `RIPOSTE` — à la fin de l'enum.
  `RIPOSTE` entre dans `SUSTAINED_SHAPES` ; `KNIVES` donne `projectile`, les trois autres
  `melee`. Aucune n'entre dans `TRANSFORMABLE` : la Rafale, le Coup de grâce et la riposte
  tiennent une cible, les couteaux un état (la lame plantée).
- **L'esquive dite au joueur** : un signal de `Hurtbox` à l'esquive (invariant 5 : elle reste le
  seul point de passage), que lisent la Contre-attaque et le Contretemps.
- **Dépenser des charges** : `Buff.spend()`, le pendant de `Buff.stack()`.
- **L'achèvement** : le seuil de la Sentence est lu sur le maudit ; celui du Coup de grâce est
  lu sur le coup. `Enemy._execute()` apprend à recevoir l'un ou l'autre.
- **Environ quarante-cinq nombres neufs** dans `SkillStats`, chacun lu à un seul endroit.

## 6. Le dessin, les gestes, les icônes

- **Les gestes** `flurry`, `throw`, `finisher` : `tools/character_forge.py`, pour le Vive lame
  seul, planche de graines choisie par l'utilisateur.
- **Les dessins** (`/dessiner-un-effet`, planche de variantes) : le couteau qui tournoie, l'éclat
  du Point final et la marque de la lame plantée. La Rafale, le Coup de grâce et la riposte
  reprennent le fuseau de l'estoc de la Tierce (`ThrustTrail`) — à confirmer.
- **Les icônes** des quatre compétences et une vignette par nœud (`tools/skill_icons.py`,
  `tools/node_icons.py`).

## 7. Ce que la livraison a changé

- **Les rôles décident des liens.** Un nœud dont tous les parents changent le jeu est une suite
  (`ManualCell.is_suite()`) : relié à la Renverse (`knockback`, un octogone), le Défaut de la
  cuirasse en devenait une. Il se relie à l'Allonge ; le Point final, qui passait sous la
  case de la compétence, à la Renverse ou à l'Allonge.
- **L'Ancrage n'est pas un levier de durée** : une durée sur les Lames de jet se serait lue
  « durée 4 s » sur la fiche, lame plantée ou non. Un nombre à lui, `anchorage`, en secondes.
- **Les lames plantées ont un plafond**, `PLANT_MOST` (5) : sans lui, le Hérisson rendait la
  cible d'un duel vulnérable sans borne — ×125 au banc des arbres. Le Coup de grâce en arrache
  donc au plus cinq.
- **La Rafale escalade en facteur, pas en plat** : chaque estoc multiplie la chance du lancer
  par 1 + `FLURRY_CRIT` × son rang (×1,5, puis ×2), Montée comprise. Une chance plate est
  interdite hors d'une arme ; un « accru » demandait de garder la somme des accrus du lancer,
  que `SkillStats` ne garde pas.
- **La Soif de sang reçoit son lancer à chaque charge** (`Player._stack_on_kill()` passe la
  résolution à `Buff.stack()`) : avant, le plafond et la tenue d'une charge gagnée en tuant
  ignoraient l'arbre — sans effet tant qu'il n'y en avait pas.
- **Trois libellés débordaient** de la fiche de nœud (`test_passive_and_node_sheets_fit_in_both_languages`)
  — « dégâts contre un ennemi à moitié mort », « contre un ennemi intact », « par estoc sur la
  même cible » — : « contre les blessés », « contre les intacts », « par estoc répété ».
- **`tests/run.sh` prend un filtre** : `tests/run.sh integration coup_de_grace` ne lance que
  les tests dont le nom contient le mot (`-gunit_test_name` de GUT). La campagne entière
  prend six minutes ; un test d'intégration seul, quarante secondes.

### Ce qui est neuf au moteur

- **Quatre formes**, `FLURRY`, `KNIVES`, `FINISHER`, `RIPOSTE` (entretenue, un `Buff` qui
  porte la Garde), lues par `Player._flurry()`, `_roll()` sur `ThrowingKnife`,
  `_finish_off()` et `_on_evaded()` / `_riposte()`.
- **Deux signaux** : `Hurtbox.evaded` (le coup esquivé, sans `damaged`) et
  `StatusEffects.critical` (un critique porté, émis par la hurtbox avec `struck`).
- **L'achèvement se lit sur le coup** : `SkillStats.execution`, que `Enemy._on_damaged()`
  traite comme une mort au nom de l'auteur ; la Sentence reste lue sur le maudit.
- **`StatusEffects.open_up()`** : des dégâts subis en plus, pour un temps, dans
  `damage_taken_factor` (l'Ouverture, le Hérisson) ; **`CharacterStats.mitigate(…, armor_kept)`**
  (le Défaut de la cuirasse) ; **`Buff.spend()`** et **`Buff.revive()`**.
- **Deux crochets de `Projectile`** : `_hit_factor()` (ce que le tir ajoute à son coup) et
  `_lodge()` (il reste dans sa cible), en plus de `_keeps_flying()`.
- **Quarante-neuf nombres** dans `SkillStats`, de `IMPETUS` à `FENCING_TIME`, plus
  `execution` ; ARCHITECTURE, « Qu'est-ce qu'un nœud peut allumer ? », dit qui les lit.
- **La fenêtre Alt** lit les mécaniques du Vive lame (`ManualPanel._blade_lines()`) : la
  chance critique de chaque estoc, ce que vaut une charge et le seuil d'achèvement
  maintenant, la lame plantée, la seconde salve, les relances, la riposte ; le bloc de la
  Frénésie, le Berserk, le Dernier carré, la Fièvre et la Lampée.

### Les tests

Vingt-trois tests d'intégration neufs (`test_shapes.gd`, « Les arbres du Vive lame ») : un par
compétence, l'achèvement, et un par mécanique qui change le jeu — Impétuosité, Coup double et
Repli, Fente, Coup sur coup, Botte secrète, Éventail, Quatrième estoc, Ivresse du sang, Berserk,
Dernier carré, Moisson, Sang-froid, Point final, Lame plantée et Coup de grâce, Retour de lame,
Seconde salve, Contretemps avec Double riposte et Pas de côté, Ouverture. **1 522 tests passent.**

## 8. Le dessin — choisi sur planche

Planches de variantes (`Bureau\hns-captures-vivelame\`, 1 à 6), puis captures réelles en
fenêtré (`Bureau\hns-captures-vivelame-jeu\`, 20 et 21 les montages).

| geste | choisi | ce qu'on voit |
|---|---|---|
| Rafale | 2, le peigne | chaque estoc, fuseau fin, sur sa rangée ; les précédents se dissolvent sous le nouveau |
| Coup de grâce | 3, la croix gravée | un fuseau lourd sans étoile, puis deux entailles en X sur la cible (`GraceMark`) |
| riposte | 1, étincelle puis fuseau | l'étincelle dorée de la parade sur le joueur, puis un fuseau fin |
| couteau | 1, le couteau droit | lame, garde d'or, manche de cuir, pointe en avant (`EffectForge.KNIFE`) |
| Point final | 3, l'étoile de fuseaux | huit fuseaux longs et courts qui jaillissent au rayon (`Slash.burst()`, `FinalBurst`) |
| lame plantée | 1, les manches fichés | les couteaux sortent du haut du corps en éventail, manche dehors (`PlantedKnives`) |

**Vu à la capture** : la scène ne se lisait pas — étiquette de butin, nombres de dégâts,
ennemis collés au joueur ; le scénario les éteint et fige les ennemis (`states.hold()`).
Rien à corriger dans les dessins eux-mêmes.

**Mesuré** (headless, première fabrication ; rien ensuite) : l'étoile du Point final, 0,34 à
0,81 ms le temps au rayon 40, 1,9 ms au pire à 60 — **chaque fuseau ne balaie que son propre
cadre** sur la toile commune, sans quoi huit fuseaux balayaient huit fois la toile ; le
couteau, 0,95 ms au pire cap ; la croix, 0,19 ms ; le fuseau lourd de 56 px, 0,20 ms.

## 9. Les gestes

Trois mouvements neufs, pour la planche du Vive lame seule (`STRIKES` de
`tools/character_forge.py`) : `flurry` (garde, estoc, retrait, deux estocs ; impact au
premier), `throw` (bras armé derrière la tête, lâcher devant, accompagnement ; impact au
lâcher) et `finisher` (l'épée ramenée loin derrière, puis la fente de tout le corps ; impact à
l'estoc). Graines retenues : 777 pour la Rafale et le lancer — en 4242, la vue de dos
portait un visage —, 4242 pour le Coup de grâce, à la fente plus marquée. Vus en jeu, image
par image (`Bureau\hns-captures-vivelame-gestes\`, les montages). Le couteau part à
l'image du lâcher ; la riposte n'a pas de geste du corps, c'est un réflexe.

## 10. Les icônes

Les quatre icônes de compétence par Qwen-Image, palette `physical`, à côté de celles du
chevalier (`Bureau\hns-captures-vivelame-icones\01-competences.png`) : la Rafale en graine
1337 (trois épées qu'on lit comme des armes), les Lames de jet en 777 (l'éventail), le Coup
de grâce et la Contre-attaque en 4242. **L'utilisateur ne veut plus choisir les graines** :
le tirage le plus lisible est pris sans lui demander. La Frappe vive et la Soif de sang,
refaites ensuite à la demande, passent au même style
(`03-competences-toutes.png`) : une rapière en biais et ses traits de vitesse (777), une dague
sur une éclaboussure de sang (777). Refusés en route : un chevalier qui lève l'épée (une fente
demandée sort en personnage), un œil injecté de sang cerclé de gris (on y lit un heaume), trois
griffures rouges (une tache).

Les 76 vignettes de nœuds, même palette, trois graines chacune
(`Bureau\hns-captures-vivelame-icones\02-vignettes-noeuds.png`). Le tirage est choisi sans
l'utilisateur. **Un personnage ou une créature est accepté s'il dit le nœud** (l'utilisateur,
en cours de choix) : l'escrimeur en fente de l'Élancement, le spadassin encapuchonné de la Dérobade,
celui du Contre et de la Garde haute sont restés. Deux sujets refaits : l'Ouverture (la
fissure ne se voyait pas à 32 px ; une cuirasse percée de lumière) et la Sangsue (sortie en
crapaud puis en serpent ; « no eyes, no face » et « segmented » la donnent). Faibles, gardés :
le Coup d'œil (l'étoile ne se voit pas), la Montée (lames parallèles, pas en escalier),
l'Acculé (le cœur n'est pas à moitié vide), le Tir lointain (la longue-vue sans son couteau).
Ressemblances gardées : le Fer long et le Fer tendu (deux lames à plat), la Lampée et le
Sans fond (deux coupes), la Respiration et le Calme (deux gouttes bleues).

## 11. Le banc des arbres

`tools/balance.sh trees only=…` (le manuel entre dans `TREE_MANUALS`). **Un relevé, pas un
réglage** : l'équilibrage se fait en dernier.

| arbre | meilleur au paquet | meilleur au duel |
|---|---|---|
| Frappe vive | ×4,52 | ×5,16 |
| Rafale | ×7,01 | ×8,04 |
| Lames de jet | ×16,0 | ×11,2 |
| Coup de grâce | ×1,87 | ×1,86 |
| Contre-attaque | — | — |

Les Lames de jet sont hautes (cinq couteaux, leur retour et la seconde salve s'empilent) ; le
Coup de grâce bas parce que **le banc ne tient pas la Frénésie** — il frappe sans charge ;
la Contre-attaque vaut zéro, **le banc ne frappe pas le joueur**. Jamais pris : Épargne,
Repli, Dérobade (ne frappent pas) ; Fer long, Pression, Éventail, Rose des vents, Ivresse du
sang ; Récupération, Ancrage, Lame chercheuse ; tout le Coup de grâce hors Estocade, Allonge
et Défaut de la cuirasse.

## 12. La performance

Le banc de combat (`world/stress_test.tscn`, 300 ennemis, attaque tenue, 240 images de
chauffe puis 1 440 mesurées), en A/B par paires alternées, cinq paires : HEAD (jalon 49)
**165 img/s, 5,51 ms de physique** ; le jalon 50 **165 img/s, 5,15 ms**. L'écart est dans le
bruit (4,70 à 6,03 ms d'un lancer à l'autre) : `StatusEffects` et `Hurtbox`, touchés pour
l'ouverture et le critique, ne coûtent rien de mesurable.
