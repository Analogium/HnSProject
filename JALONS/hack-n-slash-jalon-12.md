# Hack'n'slash top-down — jalon 12

Suite des jalons 1 à 11. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Décidé le 15 septembre 2026.** Jusqu'ici, la nature d'un coup ne décidait que de
la défense qui s'y oppose et de la couleur de sa gerbe. Un sort de feu et un sort
de foudre aux mêmes nombres se jouaient pareil. Ce jalon donne à chaque nature
**ce qu'elle laisse derrière elle** : un état, posé sur ce qu'il touche.

---

## 1. Périmètre

**Dedans :**

- **Six états**, un par nature, le physique compris :

  | État | Nature | Ce qu'il fait | Durée |
  |---|---|---|---|
  | Embrasement (*Ignite*) | feu | brûle, sur sa durée, le feu que le coup a porté | 4 s |
  | Engourdissement (*Numbed*) | foudre | +10 % de dégâts reçus | 4 s |
  | Gel (*Chill*) | froid | −25 % de vitesse d'action : marche, attaque, incantation | 2 s |
  | Pourriture (*Rot*) | nécrotique | brûle 40 % du nécrotique reçu, et en rend la moitié à celui qui l'a posée | 4 s |
  | Bénédiction (*Blessed*) | sacré | −20 % de dégâts infligés par celui qui la porte | 4 s |
  | Saignement (*Bleed*) | physique | saigne, sur sa durée, la moitié du physique que le coup a porté | 4 s |

- **Sur tout ce qui a une hurtbox et des états** : le joueur comme les ennemis.
  Le joueur en reçoit aujourd'hui des grunts, qui le font saigner, et du caster,
  dont le tir est de froid.
- **Ce qui se voit** : une icône par état au-dessus de la barre de vie, la
  couleur du plus récent sur le corps, l'animation ralentie par le gel, le nom
  de l'état qui s'envole au-dessus du joueur atteint, et le chiffre de ce qui
  brûle.

**Dehors :**

- **Des statistiques d'état.** Chance, durée et force sont des constantes de
  `StatusEffects`. « +10 % de chance d'embraser » ou « durée des états » seraient les
  suivantes naturelles, mais une statistique n'arrive qu'avec un affixe qui la
  vise (voir RECETTES), et ce jalon n'en ajoute aucun.
- **Des résistances aux états.** Une résistance au feu réduit déjà le feu reçu,
  donc la brûlure qui en naît : il n'y a pas de seconde défense.
- **Des ennemis de feu, de foudre, de nécrotique ou de sacré.** Les grunts font
  saigner et le caster transit ; le reste ne vient que du joueur.
- **Le mannequin de l'arène.** Il n'a ni fiche ni vie ; il ne prend pas d'état.
- **La fiche et la page du manuel.** Elles n'annoncent aucune chance d'état.
- **L'équilibrage.** Premiers réglages, tous dans `core/status_effects.gd`.

---

## 2. Comment un état se pose

**Par le coup, dans `Hurtbox.take_damage()`**, qui est déjà le point de passage
unique de tous les coups du jeu. Après l'esquive, la mitigation et le signal : un
coup esquivé n'a rien posé, et c'est ce qui a été **reçu** qui embrase, pas ce qui a
été lancé.

**La chance est de 20 % pour un coup entièrement d'une nature, et se partage
selon les parts** : un coup à moitié de feu embrase une fois sur dix. C'est la
règle du jalon 8 — « un éclair reste un éclair » — appliquée aux états : le froid
qu'un anneau met dans un sort de foudre ne doit pas geler aussi souvent qu'un sort
de froid.

**Plus la part des PV max qu'elle retire**, ajoutée et non multipliée. Un coup de
feu qui ôte 30 % de la vie d'un grunt embrase une fois sur deux, un coup qui
l'emporte entière pose à coup sûr, et un petit coup sur une cible de trois mille PV
garde ses 20 %. Les PV **max** et non restants : le même coup a la même chance sur
un ennemi frais ou blessé. Comptée sur ce qui a passé les défenses, comme le reste.

**Un tirage de `Game.rng` par nature présente dans le coup, quel que soit le
résultat** (invariant 3). Le physique compris, depuis le saignement : chaque coup
de grunt et d'épée consomme un tirage de plus, et le butin tiré ensuite en est
décalé — ce que le butin n'a jamais promis de ne pas être.

**La brûlure ne pose rien.** Ni celle d'un embrasement, ni celle d'Immolation :
ce ne sont pas des coups, et un embrasement qui en reposerait un autre ne
s'éteindrait jamais.

### Quand un état de la même sorte est déjà là

- **Ce qui brûle — embrasement, pourriture, saignement — garde le plus fort.**
  Un nouvel embrasement plus faible que celui qui court est ignoré ; plus fort ou
  égal, il le remplace et repart pour sa durée entière. Sans ça, une pluie de petites braises
  éteindrait la grosse.
- **Les trois autres ont une force fixe**, et un nouveau coup leur rend leur durée.

**Tous les états se portent à la fois** : un corps peut être embrasé, pourrissant
et saignant, et perdre les trois brûlures ensemble. Ce qui ne se cumule pas, ce
sont deux états **de la même sorte** : un corps porte au plus un embrasement.

---

## 3. L'auteur d'un coup

La bénédiction affaiblit **celui qui la porte**, et la pourriture soigne **celui
qui l'a posée** : pour l'une comme pour l'autre, un coup doit savoir d'où il vient.

**`DamageInfo.author`** porte les états de qui a frappé, ou rien. C'est la seule
chose que la hurtbox apprend de l'attaquant — pas son nœud, pas sa fiche.

| Qui frappe | D'où vient l'auteur |
|---|---|
| Le coup d'arc du joueur | `Player._on_hitbox_area_entered()` |
| Un tir, joueur ou caster | `Projectile.setup()`, par `Etats.de(source)` |
| L'explosion d'une boule de feu | la boule, qui la pose |
| Chaîne, nuage, aura, serpent, épée | passé à leur naissance, puis à `Targets.strike()` |
| Le coup d'un grunt | `Grunt.tick()` |

**La pourriture tient son auteur par une référence faible.** Un joueur et un
ennemi qui se pourrissent l'un l'autre formeraient sinon deux `RefCounted` qui se
tiennent en vie, et ne seraient jamais libérés.

**Un tir garde l'auteur de sa naissance** : celui d'un caster tué en vol frappe
encore, et sa bénédiction avec.

---

## 4. Où chaque état agit

`StatusEffects` ne touche à rien : il dit des facteurs et rend ce qui brûle. Chaque état
s'applique **là où vit déjà la règle qu'il modifie** :

| État | Où |
|---|---|
| Bénédiction | `Hurtbox.take_damage()`, **avant** l'armure : le coup béni est un coup plus petit, et l'armure protège mieux des petits coups |
| Engourdissement | `Hurtbox._mitigate()`, **après** les défenses et avant le plancher ; et sur tout ce qui brûle, Immolation comprise — il dit « dégâts reçus » |
| Gel | `Enemy.movement_speed()` et `_cool_down()` pour les ennemis ; la marche et la recharge des cinq cases dans `Player._physics_process()` ; `ActorSprite.speed_scale` pour l'animation |
| Embrasement, pourriture, saignement | `StatusEffects.advance()` rend la perte ; `Enemy.suffer_states()` — appelée par l'`EnemyManager` avec la régénération — et `Player._suffer_states()` l'ôtent par `_set_health()` |
| Soin de la pourriture | le signal `StatusEffects.heal` de l'auteur, que son porteur branche sur sa vie |

**Une mort par brûlure est une victoire** : l'embrasement vient d'un coup, et
l'ennemi qu'il achève rapporte son expérience et son butin.

**Un ennemi hors de portée de simulation ne brûle pas**, comme il ne se régénère
pas : ses états l'attendent.

**Un corps qui meurt perd ses états, et un joueur relevé aussi** : un corps tombé
encaisse encore, et ce qu'il reçoit entre sa mort et sa résurrection ne doit pas le
suivre.

---

## 5. Ce qui se voit

- **Les icônes.** Une par état au-dessus de la barre de vie, un masque de 7×7
  cerné de noir — flamme, éclair, flocon, crâne, croix, goutte —, dans la couleur
  de sa nature. **Sauf le saignement**, rouge sang : le blanc chaud du physique,
  posé sur un corps, se lirait comme le flash d'un coup reçu. La forme porte plus
  que la couleur, embrasement et saignement étant deux rouges. Elles tiennent la
  barre visible même à pleine vie : un ennemi remonté à fond reste transi, et
  c'est justement ce qu'on regarde. Les noms d'affixes sont remontés de quatre
  pixels pour leur laisser la place.
- **La teinte.** La couleur du plus récent des états, mêlée au corps selon sa
  luminosité : le contour noir reste noir. **C'est l'inverse de la règle des
  affixes**, qui pose un liseré pour ne pas voler sa couleur à l'archétype, et
  c'est voulu : un affixe est une identité, un état dure quelques secondes et doit
  se lire d'un coup d'œil dans un paquet.
- **Le nom de l'état, au-dessus du joueur seulement**, à l'apparition et pas au
  rafraîchissement. Sur soixante-dix ennemis, les mots couvriraient l'écran, et
  leurs icônes le disent déjà.
- **Le chiffre de ce qui brûle**, par paquets d'une demi-seconde comme la brûlure
  d'Immolation : rouge sur le joueur, blanc sur un ennemi, chacun derrière la case
  de son côté dans les options. La dernière demi-seconde d'un embrasement est
  montrée à sa fin, et ne disparaît pas de l'écran.

---

## 6. Arbitrages

**« États » dans le code, « effets » dans la demande.** Dans ce dépôt, un effet
est ce qui se dessine : le joueur a un `_effects_parent()`, et les tests un
nœud `_effects`. Une classe `Effects` à côté aurait donné deux sens au même mot.

**La bénédiction réduit les dégâts infligés par son porteur**, pas ceux qu'il
reçoit. C'est la lecture de « réduit les dégâts de 20 % de la personne qui possède
cet état », et c'est ce qui en fait un état qu'on pose sur un ennemi — les quatre
autres le sont aussi.

**Les états ne sont pas sauvegardés.** Un personnage rechargé transi serait puni
d'avoir quitté le jeu, et le format de sauvegarde ne bouge pas.

**`StatusEffects` ne nomme ni `DamageInfo` ni `Hurtbox`**, qui le nomment tous deux. Il
reçoit des parts et un auteur, jamais un coup : c'est ce qui le garde hors d'un
cycle de dépendances.

**Deux paquets d'affichage chez le joueur, et non un.** La brûlure d'Immolation et
celle des états n'avancent pas sur la même horloge : partagé, un paquet compterait
deux fois l'image où les deux brûlent.

**La conversion prend toutes les natures du coup**, et non plus la seule nature de
la compétence comme au jalon 10. Un sort de foudre avec un ajout de froid, converti
à 100 % en feu, gardait son froid et pouvait donc geler : « tout converti » doit
vouloir dire une seule nature, donc un seul état possible. À 50 %, chaque nature,
ajouts compris, garde la moitié de ce qu'elle portait. Une conversion entière
emporte aussi ce qu'une précédente avait converti ailleurs. C'est la forme que
prendra un « convertit 50 % de tous les dégâts » d'un arbre de passifs, qui n'aura
qu'à appeler `apply_conversion()`. Rien ne change pour le contenu actuel : ses nœuds
convertissent des compétences sans ajout d'une autre nature.

---

## 7. Ce qui refusera un oubli

- `tests/unit/test_status_effects.gd` — les tables couvrent chaque nature une fois, chaque
  état a sa couleur et son icône, tous se portent ensemble, un tirage par nature
  présente, la chance partagée selon les parts et accrue par
  la part des PV retirée, les
  facteurs, la durée et son rafraîchissement, le plus fort qui l'emporte, la
  pourriture qui soigne, les pourritures croisées qui ne fuient pas, les paquets
  d'affichage.
- `tests/integration/test_status_effects_in_game.gd` — la hurtbox (engourdissement,
  bénédiction avant l'armure, pose, saignement d'un coup physique), l'ennemi qui
  meurt de sa brûlure et rapporte, le gel sur la marche, la recharge et
  l'animation, le soin, les icônes et la teinte, l'annonce au-dessus du joueur,
  l'engourdissement sur Immolation, le tir d'un joueur béni, la mort qui vide, le
  coup converti qui ne pose que ce qu'il porte.
- `tests/unit/test_talents.gd` — la conversion qui emporte les ajouts de toutes les
  natures, l'entière qui emporte la précédente.
- `tests/integration/test_shapes.gd : test_the_chain_strikes_on_behalf_of_its_caster`.
- `tests/unit/test_translations.gd` relève `StatusEffects.NAMES`.
