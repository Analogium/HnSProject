# Hack'n'slash top-down — jalon 7

Suite de `hack-n-slash-jalon-1.md`, qui reste la référence sur l'architecture et
les conventions, et des jalons 2 à 6. Ce document ne redit pas ce qui y est déjà
écrit, et `docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Décidé le 10 septembre 2026.** Le jalon 6 a donné des compétences, et chacune
porte ses nombres dans son `.tres`. Mais **rien ne peut les toucher de
l'extérieur** : un objet ne sait modifier que les champs de `CharacterStats`, et
« nombre de projectiles » n'en est pas un. Le jour où l'arbre de talents
arrivera, il n'aura aucune prise — il ne pourra que redonner des dégâts et de la
vitesse, c'est-à-dire refaire ce que les affixes font déjà.

Il manque la prise elle-même : **un mot-clé porté par la compétence, sur lequel
un modificateur peut mordre.**

---

## 1. Périmètre du jalon 7

**Dedans :**

- **Les mots-clés** : une liste fermée, portée par chaque compétence, en partie
  déclarée et en partie déduite
- **Les statistiques de compétence** : nombre de projectiles, vitesse de
  projectile, dispersion, coût, cadence, dégâts — résolues à chaque lancer
- **Le modificateur ciblé** : « +1 projectile », « +10 % de vitesse de
  projectile », qui ne s'applique qu'aux compétences portant le mot-clé
- **Une source réelle** : les affixes d'objets gagnent une portée, pour que le
  système ne soit pas du code mort en attendant l'arbre

**Dehors :**

- **L'arbre de talents.** Il est la raison de ce jalon, il n'en fait pas partie.
  Ce qu'on construit ici est la prise sur laquelle il se branchera ; le dessiner
  maintenant, ce serait décider de sa forme avant d'avoir vu la prise tenir.
- **Les mots-clés sur les objets.** `ItemBase.tags` existe déjà et sert au
  filtrage des affixes. Les deux vocabulaires se ressemblent et ne se mélangent
  pas : l'un dit ce qu'un objet **est**, l'autre ce qu'une compétence **fait**.
- **Les modificateurs conditionnels** (« +20 % de dégâts si vous avez tué
  récemment »). Une autre mécanique, et elle demande un état dans le temps.

---

## 2. Le principe : un mot-clé est une prise, pas une catégorie

La tentation est de traiter les mots-clés comme un rangement — « les sorts de
projectile », « les sorts de zone » — et d'en faire un champ d'affichage. Ce
n'est pas à ça qu'ils servent.

**Un mot-clé n'existe que parce que quelque chose mord dessus.** Sa seule raison
d'être est qu'un modificateur puisse dire « ceci s'applique aux compétences qui
le portent ». Un mot-clé que rien ne vise est un mot inutile, et il faut le
retirer plutôt que le garder « au cas où » : la liste doit rester assez courte
pour qu'on la connaisse par cœur en la lisant.

C'est aussi pourquoi la liste est **fermée**. Une chaîne libre dans un `.tres`
donnerait un `projectiles` au pluriel qui ne serait jamais visé par le
modificateur écrit sur `projectile`, et **rien ne le dirait** — le sort marcherait,
simplement il ne recevrait pas son bonus. C'est la faute la plus coûteuse du
jalon parce qu'elle est silencieuse.

---

## 3. Déclaré et déduit

Une compétence porte déjà deux choses qui sont des mots-clés en puissance : sa
`nature` (foudre, froid…) et sa `cadence` (arme ou incantation).

**Elles ne se redéclarent pas.** Un `.tres` qui écrirait à la fois
`nature = LIGHTNING` et `tags = ["foudre"]` porterait deux vérités sur la même
chose, et la première correction en oublierait une. `Competence.mots_cles()`
rend donc l'union de trois sources :

- les mots-clés **déclarés**, ceux que rien d'autre ne sait : `projectile`,
  `zone`, `melee` ;
- le mot-clé de la **nature**, déduit de `DamageType` ;
- `attaque` ou `sort`, déduits de la **cadence**.

C'est un écart assumé avec `ItemBase.tags`, où la famille est déclarée à la main
dans la liste et vérifiée par un test. La raison de l'écart : là-bas le filtre
des affixes lit une liste plate et la famille devait y figurer ; ici,
`mots_cles()` est une fonction, la déduction ne coûte rien, et ce qui n'est pas
écrit ne peut pas diverger.

---

## 4. Les statistiques de compétence ne sont pas des statistiques de personnage

`CharacterStats` décrit un corps : ses PV, son armure, sa vitesse. « Nombre de
projectiles » n'y a pas sa place — ce n'est pas une propriété du personnage, mais
d'un geste. Deux compétences lancées par le même personnage n'en ont pas le même
nombre, et un champ unique sur la fiche ne saurait pas les distinguer.

D'où une seconde structure, `StatsDeCompetence`, qui est **le résultat d'un
lancer** et non un état conservé : dégâts, projectiles, dispersion, vitesse de
projectile, coût en mana, intervalle. Elle naît à chaque appel et meurt avec lui.

Elle absorbe au passage un défaut du jalon 6 : la vitesse d'un tir est
aujourd'hui un `@export` de la **scène** du projectile. Deux compétences qui
partagent `player_bolt.tscn` ont donc forcément la même vitesse, et aucun
modificateur ne peut y toucher.

---

## 5. La résolution, et son ordre

`Competence.resoudre(points, stats, mods) -> StatsDeCompetence` part des valeurs
de la fiche, puis applique les modificateurs dont le mot-clé est porté.

**Les plats d'abord, les pourcentages ensuite**, exactement comme
`StatMod.apply_all` et pour la même raison : sinon un « +1 projectile » appliqué
après un « +50 % » ne vaut pas le même « +1 » appliqué avant, et deux objets
identiques donneraient deux résultats selon l'ordre d'équipement.

**Le nombre de projectiles s'arrondit à la fin, jamais en cours de route.** Un
`+50 %` sur trois projectiles donne 4,5 : arrondir à chaque étape ferait dépendre
le résultat de l'ordre des modificateurs.

---

## 6. D'où viennent les modificateurs

Le porteur est le joueur : `Player.mods_de_competence`, reconstruite d'un bloc
dans `recompute_stats()`, comme la fiche l'est déjà. Un seul endroit reconstruit,
un seul endroit à ne pas oublier.

Sa source, dans ce jalon, est **l'affixe d'objet** : `ItemAffix` gagne un champ
de portée. Un affixe sans portée agit sur la fiche comme aujourd'hui ; un affixe
avec portée devient un modificateur ciblé. C'est ce qui empêche ce jalon d'être
du code mort en attendant l'arbre — et l'arbre, plus tard, versera dans la même
liste sans que rien d'autre ne bouge.

**Conséquence assumée : un « +1 projectile » touche aussi le tir de base**, qui
porte le mot-clé `projectile`. C'est le comportement de PoE et il est voulu — un
modificateur qui épargnerait les compétences de départ demanderait une exception
écrite quelque part, et cette exception serait la première chose qu'on oublierait
en ajoutant un sort.

---

## 7. Ordre de construction

Chaque étape se valide avec `tests/run.sh` avant la suivante.

- [ ] **1. Les mots-clés.** La liste fermée, le champ déclaré sur `Competence`,
      la déduction depuis `nature` et `cadence`, et `mots_cles()`. Aucun effet en
      jeu. Tests : chaque mot-clé déclaré dans un `.tres` appartient à la liste —
      c'est le test qui attrape la faute de frappe silencieuse ; une compétence de
      foudre porte `foudre` sans l'avoir écrit ; un tir porte `projectile` et un
      coup d'épée non.
- [ ] **2. Les statistiques de compétence.** `StatsDeCompetence`,
      `ModDeCompetence`, et `resoudre()`. Toujours aucun effet : le joueur ne
      l'appelle pas encore. Tests : sans modificateur, la résolution rend
      **exactement** les nombres de la fiche — c'est le test qui garantit qu'on
      n'a rien changé au jeu ; les plats passent avant les pourcentages ; un
      modificateur dont le mot-clé n'est pas porté ne fait rien.
- [ ] **3. Le lancer passe par la résolution.** `Player._tirer` et `_swing`
      lisent `StatsDeCompetence` au lieu de la fiche, la vitesse de projectile
      quitte la scène pour la compétence. Tests : les quatre sorts de foudre
      partent avec exactement les mêmes nombres qu'avant ; un tir lancé avec un
      `+1 projectile` en sort deux.
- [ ] **4. L'affixe porté.** La portée sur `ItemAffix`, la reconstruction de la
      liste dans `recompute_stats()`, et deux affixes réels — un `+1 projectile`
      et une vitesse de projectile. Régénérer `docs/CATALOGUE.md`. Tests : un
      objet porté ajoute son projectile et le retirer le reprend ; un affixe
      porté n'écrit **rien** sur `CharacterStats` — c'est le test qui attrape la
      confusion entre les deux familles de modificateurs.
- [ ] **5. L'affichage.** L'infobulle d'une case de manuel montre les mots-clés
      et les nombres **résolus**, pas ceux de la fiche. Tests : la fiche affichée
      passe par la même fonction que le lancer.

---

## 8. Ce qui peut mal tourner

**La faute de frappe silencieuse.** Un `projectiles` au pluriel dans un `.tres`,
et le sort ne reçoit jamais son bonus sans qu'aucune erreur ne sorte. C'est la
raison d'être de la liste fermée et du test de l'étape 1.

**La confusion des deux familles de modificateurs.** Un affixe porté qui
écrirait quand même sur `CharacterStats` donnerait le bonus **deux fois**, et
seulement pour certaines compétences. Le test de l'étape 4 le vise directement.

**Le vocabulaire qui se dédouble.** `ItemBase.tags` et les mots-clés de
compétence se ressemblent assez pour qu'on soit tenté de les fusionner. Ils
répondent à deux questions différentes — ce qu'un objet est, ce qu'une compétence
fait — et les réunir donnerait une liste où « bottes » et « projectile »
cohabitent sans qu'on sache ce qui vise quoi.

**La nova.** Sa dispersion vaut le tour complet, et la répartition divise l'écart
par le nombre de traits plutôt que par les intervalles. Un « +1 projectile »
change donc l'espacement de la couronne, ce qui est correct — mais un
« +50 % de dispersion » sur un cercle déjà fermé ne veut rien dire. La dispersion
se **borne** au tour complet.

**L'équilibrage.** « +1 projectile » est le modificateur le plus fort du genre :
sur une salve de trois, c'est un tiers de dégâts en plus. Il est ici pour prouver
la mécanique, pas pour être bien réglé, et c'est le premier endroit où revenir
quand le jeu paraîtra trop facile.

**Ce que la sauvegarde retient : rien de neuf.** Les mots-clés vivent dans les
`.tres` partagés et les modificateurs se recalculent depuis l'équipement. Le
format ne bouge pas — c'est l'arbre de talents, plus tard, qui aura des points
alloués à écrire.
