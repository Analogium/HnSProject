# Hack'n'slash top-down — jalon 28

Suite des jalons 1 à 27. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 26 septembre 2026.** Le jalon du **manuel de classe** : jusqu'ici une
classe ne changeait que le corps dessiné et l'arme de départ. Chacune porte
désormais un manuel qui n'appartient qu'à elle.

---

## 1. Ce que l'utilisateur a demandé

- **Un quatrième emplacement** dans l'onglet des manuels, occupé d'office par le
  « Manuel du [classe] » : unique par classe, toujours là, **impossible à retirer**.
- **Pour l'instant une compétence et un buff** par manuel, en rapport avec la classe.
  Le surplus de points qui en découle est accepté.

| Manuel | Compétence | Buff |
|---|---|---|
| **de la sorcière** | **Projectile élémentaire** : un trait qui alterne feu, glace, foudre à chaque lancer, de la couleur de son élément, avec une forte chance de poser son état | **Amplification des sorts** : +20 % de dégâts aux sorts, 10 s |
| **du Vive lame** | **Frappe vive** : on se jette sur l'ennemi le plus proche et on le frappe ; refusée sans ennemi à portée ; à plusieurs, la souris choisit | **Soif de sang** (entretenue, gratuite) : chaque ennemi tué par une attaque donne une charge de **Frénésie** — +5 % de vitesse d'attaque par charge, 5 au plus, 3 s, rafraîchies à chaque charge |

## 2. Le système

- **L'emplacement.** `Rack.SLOT_COUNT` passe à 4, et `Rack.CLASS_SLOT` (le dernier)
  échappe à `put()` et `remove()` : seul `Rack.seat()` y écrit. C'est ce qui le rend
  inamovible partout à la fois — page (le clic droit n'y range rien), sac,
  sauvegarde trafiquée. `free_slot()` ne le propose jamais.
- **Le manuel est un objet comme les autres**, une base `resources/items/manual_<classe>.tres`
  et un archétype `resources/manuals/<classe>.tres` : toute la mécanique des manuels
  (points, expérience au râtelier, fiche, arbre) le sert sans une ligne de plus. Mais
  **hors d'`ItemCatalog.ALL`** : il ne tombe pas, l'établi ne le propose pas.
  `Character.CLASSES[classe]["manual"]` est le seul lien classe → manuel, et
  `Character.class_manual_bases()` la seule liste, que lisent les tests et le catalogue.
- **La sauvegarde passe en v9.** `rack` garde ses trois entrées ; le manuel de classe
  s'écrit à part, **par son seul état** (`class_manual` : expérience et points), sa
  base se déduisant de la classe. Une v1 à v8 reçoit un manuel neuf.
  `Character.create_new()` et `from_dict()` le posent tous deux par `_seat_class_manual()`.
- **Une nature qui tourne** : `Skill.nature_cycle`, et `resolve(…, turn)` qui y prend la
  nature du lancer — ses dégâts, **ses mots-clés** (un affixe de froid ne mord que le
  tir de glace), donc sa couleur par `dominant_nature()`. Le tour est compté par le
  joueur (`Player._turns`), jamais sauvegardé ; la page du manuel montre le prochain.
  La couleur du tir ne demandait rien : `Projectile` dessine déjà par nature.
- **La frappe vive** est une forme neuve, `LUNGE`, à la fin de `Skill.Shape`. La cible :
  parmi les ennemis dans `radius`, celle **la plus proche de la visée** — une règle qui
  couvre les deux cas de la demande. Le refus est le huitième de `cast_slot()`, avant
  tout paiement. On atterrit à `LUNGE_REACH` de la cible par l'atterrissage de la ruée
  (murs traversés), et on la frappe **elle seule** par `Targets.strike()` : un arc
  aurait pris ses voisines.
- **Un buff lancé** : une durée et aucun prix à la seconde (`Skill.is_cast_buff()`). Il
  n'est pas entretenu : relancé, il repart à zéro au lieu de s'éteindre. Le Tombeau de
  glace a une durée mais se paie à la seconde : il reste entretenu, comme avant.
- **Les charges** : `Skill.stacks_max` et `stack_duration`, portées par le nœud `Buff`.
  Les lignes du buff comptent `points × charges` fois — une ligne est linéaire en points.
  Le bandeau écrit le compte sur l'icône, et le voile y suit la durée des charges.
- **La mort d'un ennemi** se dit à son auteur par un signal neuf, `StatusEffects.slew`,
  avec les mots-clés du coup. Émis par l'ennemi, qui seul sait qu'il meurt ; la hurtbox
  ne le sait pas. Ce qui brûle ne l'émet pas : un état tue sans lancer.

## 3. Ce qui a été tranché sans l'utilisateur

À revoir sur pièce ; aucun n'engage la suite.

- **Les noms** : « Frappe vive » (Quick Strike), « Soif de sang » pour le buff
  entretenu — la demande ne le nommait pas — dont le buff à charges s'appelle
  « Frénésie », « Sorts amplifiés » pour le buff de l'Amplification.
- **« Amplifie » est pris au mot** : les 20 % sont un « plus » (`more`), le terme
  « amplifiés » du jeu, et non un accru. C'est la seule ligne de buff qui l'est ; les
  passifs de manuel restent accrus (jalon 14).
- **Un point par buff** (`declared_points_max` 1) : les nombres demandés sont ceux d'un
  point. Les tables de dégâts suivent leurs voisines (cinq points). Six destinations
  pour vingt points gagnés : `test_no_manual_fills_up_entirely` exempte les manuels de
  classe tant que la demande l'accepte.
- **Les chiffres** : Projectile élémentaire 18 → 44, 7 mana, 0,45 s, +200 % de chance
  d'état (20 → 60 % sur un coup d'une seule nature) ; Amplification 20 mana, 0,3 s, une
  recharge égale à sa durée (10 s) ; Frappe vive 24 → 58, 6 mana, portée 130, **sans
  recharge** ; Soif de sang 0,6 s d'anti-rebond. La règle, donnée par l'utilisateur
  après coup : une attaque faite pour les dégâts n'a pas de recharge, sa cadence est la
  vitesse d'attaque ; un buff, un debuff ou une malédiction en a toujours une ; la Ruée
  tranchante, utilitaire, garde la sienne. La Malédiction putride, qui n'en avait pas,
  reçoit la durée de sa malédiction (5 s). `test_attacks_ride_the_attack_speed_and_buffs_wait`
  tient la règle. Buffs ouverts au niveau 3 du livre, compétences au 1.
- **Nature des buffs**, qui ne décide que de leur dessin : l'Amplification est de
  foudre (le violet de la sorcière), la Soif de sang physique.
- **Les dessins réemployés** : les deux buffs prennent le halo de leur nature. Le reste
  est passé par la planche (§4).
- **Une zone sans personnage** (arène, tests) n'a pas de manuel de classe : son
  emplacement reste vide.

## 4. Ce qui s'est choisi sur planche

Planches et captures sur le Bureau : `hns-captures-jalon28-icones`,
`hns-captures-jalon28-frappe-vive` et `hns-captures-jalon28-manuel-classe` (1 à 7).

- **Les icônes**, par `tools/skill_icons.py` et `tools/item_icons.py` : deux sujets par
  icône, trois graines, à côté d'icônes déjà en jeu. Retenus : quatre orbes feu et glace
  (Projectile élémentaire, 4242) et un cercle runique (Amplification, 4242) sur le violet
  de la sorcière ; une épée plantée dans une cible rouge (Frappe vive, 4242) et une face
  de démon qui saigne (Soif de sang, 4242) sur l'ardoise du physique ; un tome coiffé
  d'un chapeau de sorcière (4242) et un tome rouge à l'épée (1337).
- **Deux séries ratées pour la Frappe vive** : le guerrier qui se rue double l'icône de
  la Ruée tranchante, l'épée verticale celle de la Frappe lourde. SDXL redresse toute
  épée qu'on lui demande en diagonale ; c'est la **cible** qui a fait la différence.
  Le second sujet de la sorcière (un orbe élémentaire sur la couverture) sortait en
  sphère, pas en livre : la formule de famille des manuels tient encore.
- **Le geste de la Frappe vive** : six partis pris en cinq temps — fil et croissant,
  lames rémanentes, traits de vitesse, estoc, croix sans trajet, fil et entaille.
  Retenu : **fil et entaille**, un fil d'acier d'un pixel pour le trajet et une entaille
  chaude en travers de la cible, le fil parti avant l'entaille (`LungeTrail`).
- **À la capture**, rien à reprendre sur le geste. La fiche écrivait « rayon » pour ce
  qui est une portée : elle écrit « portée » pour une frappe vive.
- **Le tir du Projectile élémentaire**, demandé ensuite (« il faudrait un bon
  visuel ») : il reprenait les glyphes tracés du feu et du froid et le dard de la
  foudre, trois dessins sans parenté. Six partis pris, chacun dans les trois
  éléments — matières existantes, comète, éclat à facettes, une forme par élément,
  orbe à grains d'or, tête suivie d'une traînée de matière. Deux remplacés avant de
  montrer : un feu follet qui sortait en têtard, une tresse d'or qui noyait l'élément.
  Retenu : **la comète**, une seule silhouette dont la couleur dit l'élément
  (`fx/comet.gd`, forme `COMET`). À la capture, rien à reprendre ; mesuré 0,24 ms par
  fabrication, une fois par teinte, cap et forme.
- **Mesuré** au banc headless, la naissance d'une `LungeTrail` — deux entailles à
  l'angle exact et six crans de dissolution : 0,62 ms en moyenne au pire cas (130 px en
  diagonale), 0,45 à l'horizontale, 0,27 à 40 px.

## 5. La fenêtre des déclenchements

Demandée ensuite : la touche des détails tenue sur une compétence de la page ouvre une
seconde fenêtre, qui liste **tout ce que le lancer peut poser ou déclencher, avec sa
vraie chance** — ce qu'y ajoutent l'équipement, l'arbre et le lancer compris.

- **Une seule touche** : `item_details`, celle de l'infobulle du sac, rebindable ; son
  libellé devient « Détails (maintenu) ». Son identifiant ne change pas : il est dans
  les réglages sauvegardés.
- **Les chances sont celles du coup**, pas une copie : `StatusEffects.chance()` sur la
  part de chaque nature dans un coup moyen (`SkillStats.distribution()`), donc un pic
  de glace sous une baguette de feu ajouté annonce « Embrasé 16 % » et son « Transi »
  tombe à 4 %. La pourriture des à-coups passe par `tick_rot_chance()`, sortie de
  `_rot_from()` pour que le tirage et la page lisent la même règle.
- **Ce que la fenêtre ne peut pas savoir** : la part des PV de la cible que retire le
  coup, qui ajoute sa chance en jeu. La fenêtre calcule sur une cible saine et le dit
  en tête.
- **Sa place** : de l'autre côté du panneau que la fiche — à gauche, puisque la fiche
  prend la droite. Entre les deux côtés, il n'y a pas la place de deux fiches.
- **À la capture** : le critique sortait à 0 % — `SkillStats.crit_chance` est déjà une
  fraction, divisée une seconde fois. Le sous-titre a pris sa majuscule.

## 6. L'équilibrage

Pas touché — il vient en dernier (jalon 13, §7). Le banc ne pose pas de manuel de
classe : `docs/EQUILIBRAGE.md` ne bouge pas, et les couloirs non plus.
