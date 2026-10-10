# Hack'n'slash top-down — jalon 47

Suite des jalons 1 à 46. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 10 octobre 2026.** Le **geste** des attaques : le personnage anime chaque
attaque, et c'est ce geste, à la vitesse d'attaque, qui règle la cadence. Les sorts
suivront dans un jalon à eux.

---

## 1. Ce que l'utilisateur a demandé

« Jusqu'ici il n'y avait pas d'animation pour ces skills de la part du personnage […]
Il faudrait que cela change pour chaque skill d'attaque présent et à venir, je voudrais le
faire maintenant car j'en ai très peu. » Et : « la vitesse d'animation de chaque skill
d'attaque sera ce qui va définir la vitesse d'action, ainsi la vitesse d'attaque aura enfin
un sens comparé au cooldown ».

Sur la première analyse : **d'accord pour un multiplicateur de temps par compétence** ;
le reste « au mieux », et l'ordre proposé — la mécanique d'abord sur les images actuelles,
les gestes dessinés ensuite.

## 2. D'où l'on part

**Les règles y sont déjà, le corps ne les montre pas.**

- **La cadence suit déjà la vitesse d'attaque.** `Skill.use_time()` vaut
  `attack_time / attack_speed` à la cadence `WEAPON` (0,45 s de base), la case attend
  `Skill.interval()`, le plus long du geste et de la recharge, et une attaque faite pour
  les dégâts n'a pas de recharge (jalon 22, jalon 28).
- **L'image ne suit rien.** `ActorSprite.attack()` joue les 3 images du coup à **11 img/s
  fixes** (`SpriteForge`, `_add_anim`), environ 0,27 s quelle que soit la vitesse : au
  repos avant que la case revienne à la vitesse de base, coupée et relancée au-delà de 2.
- **Le coup part à l'appui.** `Player._swing()` ouvre la hitbox tout de suite, pour
  `swing_duration` (0,12 s fixes) par coup ; la vague part à l'appui, la frappe vive
  téléporte à l'appui.
- **Un seul geste pour toutes les attaques** — la frappe lourde, la croix, la vague jouent
  le même coup d'épée.
- **Rien n'occupe le corps.** Une recharge par case : deux attaques sur deux cases se lancent
  dans la même image, et alterner deux cases **double** la cadence.

Les attaques concernées (cadence `WEAPON`) : Attaque (`ARC`), Frappe lourde (`STRIKE`),
Coup en croix (`CROSS`), Frappe vive (`LUNGE`), Vague tranchante (`WAVE`, `BOOMERANG` sous
le Ressac), Épée spirale (`ORBIT`), Brise-sol (`SLAM`, transformation), Ruée tranchante
(`DASH`, `LEAP`), Cyclone (entretenu), Soif de sang (`BUFF`).

## 3. La règle du jalon

1. **`use_time` reste le seul chiffre ; l'animation s'étire dessus.** Vitesse de lecture =
   durée native du geste / `use_time`. Jamais l'inverse : la règle ne vit pas dans un PNG.
2. **Le coup tombe à l'impact**, une fraction du geste propre à sa famille, plus à l'appui.
   Ce qui part du coup — la vague, l'épée de la ronde, le bond de la frappe vive — part
   avec lui.
3. **Un geste à la fois.** Tant que le corps est dans un geste, aucune autre case ne part.
   C'est ce qui donne son sens à « vitesse d'action » : sans ça, deux cases alternées
   doublent la cadence et le geste n'est qu'un dessin.
4. **Un facteur de temps par compétence**, `Skill.attack_time_factor` (1 par défaut) :
   `use_time = attack_interval() × facteur`. Le « 110 % du temps d'attaque » de PoE. Il
   se lit sur la fiche du manuel.

## 4. Ce qui est décidé (laissé « au mieux »)

- **Se déplacer pendant le geste** : le ralenti actuel (`ATTACK_MOVE_MULT`, 0,4) tenu
  **tout le geste**, sans annulation. Figer change la sensation d'un jeu qui se joue en
  bougeant (Hero Siege laisse marcher) ; annuler en bougeant ferait perdre des coups sans
  que la vitesse d'attaque se lise mieux.
- **L'impact par famille**, une table dans le code et pas un champ par compétence :
  balayage 0,40, frappe de haut 0,55, estoc 0,30. Les coups multiples de la croix se
  répartissent entre l'impact et la fin ; l'estoc de la Tierce garde son écart après eux.
- **L'horloge du geste est en temps de jeu** : un gel d'impact fige le geste et le coup
  ensemble. Les minuteries de `_swing()` qui ignorent l'échelle de temps, et qui
  décaleraient le coup par rapport à l'image, passent sur l'horloge du geste.
- **La hitbox reste ouverte `swing_duration`** à chaque impact : elle mesure la fenêtre où
  un ennemi peut entrer dans l'arc, pas la longueur du geste.
- **Hors règle 2**, gardés tels quels : la ruée et le bond (le corps est le coup), le
  Cyclone (l'allumage seul ; sa cadence est son `period`), la Soif de sang (un buff). Ils
  occupent quand même le corps le temps de leur geste (règle 3).
- **Les ennemis** ne changent pas dans ce jalon : `Enemy` a sa propre cadence
  (`_attack_cd`).

## 5. Le découpage

**A. La mécanique, sur les images actuelles.** Horloge du geste chez le joueur (une durée,
un temps écoulé, l'impact), `ActorSprite.attack()` qui reçoit sa durée, `_swing()` et les
formes de la règle 2 qui attendent l'impact, le verrou de la règle 3, le facteur à 1
partout. À tester en jeu en changeant la vitesse d'attaque d'une arme.

**B. Les facteurs.** Proposés, à valider (question 2). L'équilibrage se fait en dernier
(jalon 13, §7) : `tests/run.sh balance` relevé avant → après, sans rien corriger en
passant.

| compétence | facteur | pourquoi |
|---|---|---|
| Attaque | 1,00 | la référence |
| Frappe lourde | 1,30 | ce qui **pèse** (jalon 39, §2) |
| Coup en croix | 1,15 | deux coups dans un geste |
| Frappe vive | 0,80 | le bond vif |
| Vague tranchante | 1,10 | elle porte au loin |
| Épée spirale | 1,00 | une épée posée, pas un coup |

**C. Les gestes dessinés.** Trois familles, choisies sur planche (`/dessiner-un-effet`) puis
générées par `tools/character_forge.py` pour la Vive lame et la sorcière, trois vues :
**balayage** (Attaque, croix, vague), **frappe de haut** (Frappe lourde, Brise-sol),
**estoc** (Frappe vive, Tierce). 4 à 5 images plutôt que 3, sans quoi le geste étiré à
vitesse de base tombe à moins de 7 img/s. L'image d'impact est un repère de la planche
(`anims.<geste>.impact` dans le `.json`), qui remplace alors la table de l'étape A. Une
attaque future choisit sa famille.

**D. La doc.** ARCHITECTURE (la ligne de la cadence, le personnage joueur), RECETTES (une
attaque nouvelle choisit sa famille et son facteur), le guide du jeu : la vitesse d'attaque
accélère le geste, et un geste à la fois.

**Les tests** : le geste suit la vitesse d'attaque et le facteur ; le coup n'est pas porté
avant l'impact ; une seconde case ne part pas pendant un geste ; le gel fige le geste. Les
tests de forme qui frappent dans l'image de l'appui attendront l'impact : c'est leur
timing qui change, pas leurs chiffres.

### Les questions

1. **Un geste à la fois — les sorts aussi, dès ce jalon ?** Proposé : **oui**, tout ce qui
   anime le corps l'occupe, sorts compris, au temps qu'ils ont déjà (`cast_time` /
   `cast_speed`). Sinon une attaque et un sort sur deux cases se lancent dans la même image
   jusqu'au jalon des sorts. Ce qui change pour la sorcière : plus de boule de feu et de
   nova dans la même image.
2. **Les facteurs** du tableau de l'étape B : d'accord, ou d'autres valeurs ?

## 6. Les réponses

L'utilisateur, sur les deux questions : « j'accepte ».

- **un geste à la fois, sorts compris**, dès ce jalon, au temps qu'ils ont déjà ;
- **les facteurs** du tableau de l'étape B.

## 7. La mécanique et les facteurs — livrés (étapes A et B)

### Ce qui est neuf au moteur

- **`Skill.attack_time_factor`** : `use_time` d'une attaque vaut `attack_interval()` fois le
  facteur. Posé dans les `.tres` du tableau de l'étape B ; le catalogue l'écrit en « % du
  temps de l'arme », la fiche le montre déjà par le temps d'attaque.
- **`Skill.IMPACT`** : la part du geste où tombe le coup, par forme. Une forme absente pose
  à l'appui.
- **`Player.Gesture`** : la durée qui reste, l'impact, le `_pose()` à porter.
  `cast_slot()` le crée et refuse tout lancer tant qu'il court ; `_tick_gesture()` le
  décompte dans `_physics_process()` au rythme des recharges (`states.speed_factor`), donc
  figé par un gel d'impact comme les cases. La mort l'abandonne, coup compris.
- **`ActorSprite.attack(spell, duration)`** : `speed_scale` réglé pour que le geste dure
  `use_time`, remis à 1 à la fin.
- **La frappe vive choisit sa cible à l'impact** : celle de l'appui a pu tomber, et la
  garder dans le `bind` passerait un objet libéré à `_pose()` (invariant 4). L'appui ne
  fait plus que refuser un lancer sans personne à portée.

### Les écarts avec la proposition

- **La ruée et le bond ne prennent pas le corps.** Leur temps de geste n'espace que leur
  case : le Choc d'arrivée (+500 %) en fait une recharge, l'Enchaînement (+40 %) un prix.
  Pris par le verrou, le Choc d'arrivée aurait figé le personnage 2,7 s.
- **Les sorts étirent aussi leur lancer** sur leur geste. Sans ça le corps restait pris
  1,6 s après un lancer de 0,27 s (le Nuage d'orage), ce qui se lit comme un bug. Leur
  pose, elle, reste à l'appui jusqu'au jalon des sorts.
- **Les fenêtres de la hitbox restent en temps réel** (`swing_duration`, 0,12 s par coup,
  à la suite à partir de l'impact) : c'était voulu — un gel ne les étire pas — et elles
  tiennent dans le geste à vitesse de base. Au-delà d'une vitesse d'attaque de 2 environ,
  la croix finit son second coup après la fin du geste.

### Ce qui change au jeu

- Deux cases ne partent plus dans la même image, sorts compris : la sorcière ne lance plus
  le Nuage d'orage (1,6 s) puis une boule dans la foulée. Les nœuds qui allongent le geste
  d'un sort (Pluie de météorites, Ramification, Anathème…) coûtent donc le corps, plus
  seulement la case.
- Le coup part après un temps d'armé : 0,18 s pour l'Attaque à vitesse de base, 0,32 s pour
  la Frappe lourde.

### Les tests

`test_an_attack_takes_its_share_of_the_weapon_time` et `test_only_attacks_wait_for_an_impact`
(unitaires) ; `test_an_attack_lands_at_its_impact_not_on_the_press`,
`test_a_second_slot_waits_for_the_gesture`, `test_the_body_plays_the_gesture_over_its_length`
(intégration). Les tests des formes lancent par `tests/gestures.gd`, qui joue le geste
d'un trait : ils vérifient ce que le coup pose, pas quand. Aucune valeur attendue n'a
bougé.

### Le banc

`tests/run.sh balance` avant (worktree de `HEAD`) et après : **les mêmes vingt échecs, aux
mêmes chiffres**. Ses verdicts comptent les coups par ennemi et la survie, pas le temps du
geste : un facteur n'y entre pas. Il se lit dans les secondes de `docs/EQUILIBRAGE.md`.
`docs/EQUILIBRAGE.md` régénéré : les coups ne bougent pas, les secondes de la Frappe lourde
(meilleure compétence du banc) montent de 29 % — 0,41 → 0,53 s contre un grunt, débutant en
zone 1 ; 2,48 → 3,19 s, équipé en zone 90. Le facteur 1,3, et rien d'autre.

### Ce qui reste au jalon

- **Jouer** : la sensation de l'armé, le ralenti tenu tout le geste, la sorcière sous le
  verrou. Aucun test ne pilote le clavier ni ne voit l'animation.
- **L'étape C**, les gestes dessinés (balayage, frappe de haut, estoc), sur planche.
- **L'étape D** est faite pour A et B : ARCHITECTURE, RECETTES, l'article « Le geste » du
  guide, l'aide du temps d'attaque.

## 8. Le facteur sur la fiche

L'utilisateur : « il faut que l'on voie la vitesse d'attaque appliquée de chaque skill, par
exemple le 130 %, en plus de l'actuel résultat ». La fiche du manuel porte une ligne
**« temps de l'arme »** sous le temps d'attaque, pour toute attaque : 130 % sous 0,56 s pour
la Frappe lourde, 115 % sous 0,50 s pour le Coup en croix. Un sort n'en a pas
(`test_an_attack_sheet_shows_its_share_of_the_weapon_time`). Vu sur capture réelle, en
fenêtré : la fiche tient dans son cadre.


## 9. Les visages, avant les gestes

L'utilisateur : « leurs visages, sur certaines directions, sortent un peu de leurs crânes ;
il faudrait refaire ça avant d'aller plus loin ». **La cause** : le visage est une retouche
à la main, posée **après** le contour, et sa grille est dessinée pour 45 px quand les deux
classes sont passées à 34 — seule sa place suivait (`reshape_point()`). Une tête générée un
pixel plus étroite, ou décalée, le laissait dépasser, sans contour : la joue droite de la
Vive lame de face, le nez et la bouche de la sorcière de profil.

**La correction**, dans `tools/character_forge.py` : `put_patches()` cale la première
retouche d'une vue — le visage — sur le crâne de **chaque image** (`fit_dx()` : centrée de
face, contre le bord avant de profil, mesurée aux seules rangées des yeux, car plus haut
mèches et bord du chapeau débordent), et `patch()` n'écrit que dans la silhouette, contour
compris. Deux essais refusés à la planche : le clipping seul (de profil, la sorcière perdait
tout son visage, la Vive lame un œil), puis le calage sur toutes les rangées (le visage de la
sorcière reculait dans les cheveux). Planche avant/après : `Bureau\hns-captures-visages\`.
Retenue telle quelle ; le bas du visage de la sorcière de profil est un peu rogné.

## 10. Les gestes dessinés — livrés (étape C)

**Choisis sur pièce** : la graine 4242 pour les trois gestes et les deux classes
(`Bureau\hns-gestes\`). La 777 de la sorcière perdait son chapeau de dos.

- **L'outil** : `STRIKES` dans `character_forge.py`, cinq temps par geste — armé, élan,
  coup, suite, retour — avec le buste qui penche, se tasse et se fend. Vérifié d'abord en
  squelettes, lame tracée : la lame pendait vers le bas au retour puis sautait au repos ; la
  dernière image prend donc la lame du repos (`REST_BLADE`).
- **La planche** porte `blades` (la lame de chaque image, le long de l'avant-bras) et
  `impact` ; **`Skill.IMPACT` disparaît** au profit de `Skill.GESTURE` (forme → geste), et
  `ActorSprite.impact_of()` lit l'impact sur la planche : 2/5 pour le balayage, 3/5 pour la
  frappe de haut, 1/5 pour l'estoc. `DEFAULT_IMPACT` (0,4) pour les grilles.
- **La forge** enregistre tout geste de la planche ; le coup et le lancer **toujours**,
  réduits à la pose s'ils manquent — les ennemis en planche n'ont pas les deux.
- **Mesuré** hors jeu (headless, meilleur de trois) : 87 images par personnage et par arme
  en 9,6 ms (Vive lame), 9,1 ms (sorcière), contre 42 avant le jalon.

**Vu en jeu, en fenêtré** (`Bureau\hns-captures-gestes-swiftblade\` et `-witch\`) : la
frappe lourde lève l'épée derrière la tête pendant cinq captures puis l'abat, l'arc d'effet
au même instant ; le coup en croix part en arrière à l'horizontale, monte, traverse au
premier coup. **L'estoc n'a pas été capturé** : la frappe vive a été refusée, faute d'ennemi
à portée.

**Les tests** : `test_each_attack_gesture_is_on_each_class_sheet` (chaque geste sur chaque
planche, une lame par image, l'impact ni à la première ni à la dernière image),
`test_an_attack_plays_its_gesture_and_reads_its_impact`, et les gestes ajoutés à
`test_every_animation_of_a_sheet_moves`. 1431 sur 1431.

### Ce qui reste au jalon

- **Jouer** : l'estoc en jeu, la sensation d'ensemble.
- L'ancien coup d'épée (`attack`) ne sert plus au joueur que pour une forme sans geste ;
  il reste pour les ennemis en planche.
