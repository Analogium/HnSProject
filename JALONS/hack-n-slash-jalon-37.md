# Hack'n'slash top-down — jalon 37

Suite des jalons 1 à 36. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 3 octobre 2026.** L'équilibrage des arbres du feu, de la foudre et du froid.

---

## 1. Ce que l'utilisateur a demandé

« Fais l'équilibrage » — précisé : **les arbres des trois manuels repris** (jalons 34 à
36), dont les chiffres étaient de premier réglage. L'équilibrage global du jalon 13
(ennemis contre joueur, les couloirs) reste à la fin, comme décidé le 17 septembre.

## 2. Le banc des arbres

Le banc du jalon 13 ne voit aucun nœud : il joue deux personnages fixes, sur des
moyennes calculées. Un arbre change **ce que fait** un sort — perforer, rebondir, poser
un sol, faire exploser les tués — et cela ne se calcule pas : ça se joue.

`tools/balance.sh trees` écrit `docs/ARBRES.md`. `BenchTrees` lance chaque compétence
de dégâts sans relâche, par `Player.cast_slot()`, sur des cibles immobiles (des
`Hurtbox` à la fiche d'un grunt de zone 20, mitigation comprise) :

- **le paquet** : des vagues de neuf cibles, la suivante une demi-seconde après la
  mort de la précédente — la vitesse de nettoyage ;
- **le duel** : une cible qui ne meurt pas ;
- au contact (45 px) ou au point visé (140 px), la meilleure des deux ; le joueur vise
  la cible vivante la plus proche ;
- 12 s comptées après 6 s de chauffe, avec la réserve d'un vrai personnage — le Sort
  « Équipé » de zone 40 du jalon 13, 380 mana et 11,3/s : sans réserve à payer, les
  nuages s'empilaient sans fin.

**Les builds sont cherchés, pas écrits** : à chaque pas, le nœud — avec le chemin le
moins cher qui l'ouvre — qui rend le plus par point dans la scène visée, jusqu'aux 20
points ou jusqu'à ce que plus rien ne rende. Une transformation ou une conversion est
prise d'abord, puis la recherche reprend. Des builds écrits à la main auraient porté
mes préjugés, et se seraient périmés au premier nœud changé.

**Ce qu'il ne voit pas** : ralentir, aspirer, survivre, se déplacer. Les buffs
(Ignition, Électricité statique, Tombeau de glace) ne se mesurent pas seuls.

**Deux pièges payés en chemin** : des cibles qui renaissaient seules, sur l'instant,
mouraient sous l'explosion du voisin et explosaient à leur tour — une réaction en
chaîne qui débordait la file de messages de Godot et le faisait tomber ; et un joueur
qui visait droit devant ne finissait jamais une vague.

## 3. Ce que le premier rapport a montré, et les décisions

**Les sols s'empilaient sans limite.** Chaque plaque frappait pour son compte ; le
Serpent en pose une tous les 12 px de reptation et en empilait des dizaines sous une
cible immobile : ×19 en duel, la Boule de feu ×10 par Braises dispersées, et 16 minutes
de banc pour le Serpent seul. **Décidé par l'utilisateur le 3 octobre : un sol ne
cumule pas** — une cible déjà frappée par un sol de la même compétence dans la période
en cours ne l'est pas une seconde fois (`DashTrail._first_ground_on()`). Deux
compétences différentes se cumulent toujours. Le couloir d'une ruée n'est pas un sol.

**La puissance des manuels diffère** — le froid nettement derrière, par les dégâts de
base de ses compétences plus que par ses arbres. **Décidé : les arbres seulement** ;
l'écart entre manuels revient à l'équilibrage global.

## 4. Les critères

Sur le rapport du banc, compétence par compétence :

- **une transformation vaut son chemin** : son meilleur build rend entre **×0,85 et
  ×1,15** du meilleur build sans elle, dans la scène pour laquelle elle est faite, et
  **pas plus de ×1,15** dans l'autre — un choix, pas une promotion ;
- **une conversion est neutre** : même fourchette dans les deux scènes — elle change la
  matière, pas la puissance ;
- **un nœud de dégâts sert quelque part** : pris par au moins un des builds cherchés.
  Ce que le banc ne mesure pas (ralentir, aspirer, survivre, se déplacer) n'y est pas
  soumis.

## 5. Les réglages

En deux passes, chacune vérifiée au banc sur les compétences touchées. Ratios : le
meilleur build avec la transformation ou la conversion, sur le meilleur build sans,
dans la même scène.

| nœud | avant (paquet · duel) | réglage | après (paquet · duel) |
|---|---|---|---|
| Météore | ×1,20 · ×2,30 | « plus » +150 → **+25 %**, rayon +100 → **+200 %** | ×1,00 · ×1,15 |
| Bond | ×0,30 · ~0 | « plus » +150 → **+1 000 %** — la ruée n'a que 10 de base | ×1,01 · ×1,15 |
| Flamme noire | ×1,40 · ×1,07 | +15 → **−5 %** | ×0,92 · ×0,88 |
| Orbe statique | ×0,91 · ×1,48 | intervalle des frappes 0,25 → **0,33 s** | ×0,85 · ×1,16 |
| Toile d'arcs | ×0,72 · ×0,80 | −20 → **+5 %** | ×0,98 · ×1,04 |
| Orage portatif | ×1,06 · ×1,62 | durée +100 → **+25 %**, rayon −25 → **−15 %** | ×0,88 · ×1,17 |
| Grêle | ×1,24 · ×1,04 | son +15 % **retiré** : la conversion seule | ×0,96 · ×0,91 |
| Sillon de glace | ×1,63 · ×1,64 | **−40 %** de dégâts, en plus du rayon | ×1,01 · ×0,98 |
| Onde de givre | ×1,20 · ×0,57 | −20 → **−30 %** | ×1,08 · (paquet) |
| Implosion | ×0,43 · ×0,80 | l'éclatement final vaut **4 impulsions** (`IMPLOSION_BURST`) | ×0,97 · ×1,05 |

Restés dans la fourchette sans réglage : Givre (Boule de feu), Venin, Trait de glace.

**Le bruit du banc est d'environ ±0,1** sur ces ratios : le Venin, qu'aucun réglage n'a
touché, est passé de ×1,16 à ×0,93 au paquet d'un passage à l'autre — la recherche
gloutonne n'y suit pas le même chemin. L'Orbe statique (×1,16) et l'Orage portatif
(×1,17) en duel sont donc gardés tels quels. Les chiffres « après » sont ceux du banc
complet final (`docs/ARBRES.md`). Les descriptions qui citaient « bien plus fort »,
« un peu moins fort » ou « deux fois plus large » suivent.

**Le banc ne voit pas l'Aspiration** : ses cibles sont des hurtbox nues que rien ne
déplace. L'Implosion, qui ramasse un paquet avant d'éclater, est donc réglée sur son
éclatement seul ; l'Aspiration et Froid mordant, jamais pris, sont des nœuds de contrôle.

**Nœuds jamais pris** : Persistance, Foulée, Réflexes, Insaisissable et Sans répit de la
Ruée d'orage — mobilité et buff, hors du banc ; Aspiration et Froid mordant du Désastre.
Aucun nœud de dégâts n'est laissé de côté.

## 5 bis. Le banc en 3 min 30 au lieu de 36

Demandé par l'utilisateur : le banc complet prenait 36 min, dont 20 pour le Serpent seul.

- **Un monde caché** (`visible = false`) : rien ne se dessine, et le Serpent ne rastérise
  plus son corps quand il n'est pas visible (`is_visible_in_tree()`, vrai en jeu aussi).
  Son passage nu : 2,8 → 0,6 s.
- **Un cache des builds joués** : la graine est fixe, un même build rend le même chiffre.
- **Onze processus en parallèle** (`PARTS`, 8 cœurs, 16 fils) : chacun prend une
  compétence sur onze et écrit sa section dans `user://arbres/`, que `tools/balance.sh`
  rassemble dans l'ordre. Le plus long, le Serpent, fixe la durée : 3 min.

Les chiffres sont les mêmes au chiffre près, sauf le Serpent : son ondulation se tire de
son identifiant d'instance, qui change dès qu'une simulation de moins a tourné avant lui.
C'est la même source que le bruit du Venin (§5).

## 6. Le déroulé

**Fait** : le banc, la règle des sols, les deux passes de réglage, le banc complet
final ; ARCHITECTURE, RECETTES et CLAUDE.md. **Reste** : l'équilibrage global du jalon
13, en dernier, et l'écart de puissance entre manuels qu'il porte (§3).
