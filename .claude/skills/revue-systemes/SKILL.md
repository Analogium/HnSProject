---
name: revue-systemes
description: Passe de revue et de nettoyage sur le code du projet Godot — traquer la logique écrite deux fois, les constantes en double, le code inutilement malin et les API mortes, puis valider en headless avant de livrer. À invoquer quand l'utilisateur demande un contrôle du code ou des systèmes, une chasse à la redondance, ou une optimisation « dans la limite de la compréhension ».
---

# Revue des systèmes

L'objectif n'est **pas** de réduire le nombre de lignes. C'est de ramener chaque
règle du jeu à **un seul endroit où on l'écrit**. Une passe réussie peut très bien
ajouter autant de lignes qu'elle en retire : le gain est qu'un changement futur se
fait à un endroit au lieu de quatre, et qu'on ne peut plus en oublier un.

Le second objectif, aussi important : **rester compréhensible**. Une abstraction
qui économise trois lignes mais oblige à sauter dans deux fichiers pour suivre une
mort d'ennemi est une régression, pas une amélioration. Ce n'est pas une passe de
« design patterns », c'est une passe de bon sens.

Le but est donc d'avoir un code clean et compréhensible, avec des design patterns intelligents et des bonnes pratiques.

## 1. Cadrer

Demander (ou déduire) le périmètre : tout le dépôt, ou seulement les systèmes
récemment touchés. Par défaut, tout ce qui n'est pas dans `.godot/`.

```bash
find . -name "*.gd" -not -path "./.godot/*" | xargs wc -l | sort -n
```

Lire **tous** les fichiers du périmètre avant de proposer quoi que ce soit. Une
redondance ne se voit que quand on a les deux copies en tête ; on ne peut pas la
trouver par grep seul, parce que les deux copies sont rarement écrites pareil.

## 2. La grille de détection

Ce sont les catégories qui ont réellement produit des trouvailles sur ce projet.
Les passer une par une, sur le code entier, pas seulement sur le dernier diff.

**La même séquence écrite à plusieurs endroits.** Le cas typique : deux lignes qui
vont toujours ensemble, recopiées à la main partout. Ici, `health = …` suivi de
`health_bar.set_health(...)` était écrit huit fois — il suffisait d'en oublier une
pour que la barre mente. Cherche les paires collées :

```bash
grep -rn -A2 "health = " --include="*.gd" .
grep -rn "instantiate()" --include="*.gd" .   # naissances d'entités
grep -rn "add_child" --include="*.gd" .
```

**Une constante définie plusieurs fois.** La taille d'une tuile valait 32 dans
quatre fichiers. Repérer les nombres nus répétés :

```bash
grep -rnoE "\b(1[6-9]|2[0-9]|3[0-9]|48|64|96|128)\b" --include="*.gd" . \
  | awk -F: '{print $NF}' | sort | uniq -c | sort -rn | head -20
```

Un nombre qui apparaît partout n'est pas forcément une constante à extraire — `2`
ou `0.5` sont du calcul. Ce qui compte, c'est le nombre qui **signifie** quelque
chose (une taille de case, une portée, un coût) et qui devra changer partout en
même temps.

**Une formule recopiée.** La conversion case → pixels avec son demi-décalage était
réécrite trois fois. Chercher les expressions arithmétiques qui se ressemblent.

**Deux implémentations du même mécanisme.** Le grunt et le caster tenaient chacun
leur propre décompte de recharge d'attaque, à l'identique. Quand deux classes
sœurs font la même chose, la logique descend dans la classe parente.

**Du code inutilement malin.** Le symptôme : une expression dont on ne comprend
l'intention qu'après réflexion. Exemple trouvé ici :
`couleur * Color(1, 1, 1, 3.0)` pour forcer l'alpha — un rustinage d'un contour
trop pâle, là où retirer le contour suffisait. Autre symptôme : des tableaux
indexés à la main (`n[9]`, `n[6]`) là où une petite classe (`n.half`, `n.text`) se
relit sans compter les colonnes. Garder le tableau packé **seulement** là où le
volume le justifie et où c'est mesuré (les particules, oui ; quelques dizaines de
libellés, non).

**Des branches qui font la même chose.** Deux `continue` et le même dessin dans
deux branches distinctes : un seul chemin suffisait.

**Des API mortes.** Fonctions publiques que personne n'appelle. Vérifier avant de
supprimer :

```bash
grep -rn "^func \|^static func \|^const \|^signal " --include="*.gd" . \
  | sed -E 's/.*(func|const|signal) ([A-Za-z_0-9]+).*/\2/' | sort -u \
  | while read n; do
      c=$(grep -rc "\b$n\b" --include="*.gd" . | awk -F: '{s+=$2} END {print s}')
      [ "${c:-0}" -le 1 ] && echo "mort ? $n"
      true
    done
```

Attention aux faux positifs : les callbacks Godot (`_ready`, `_process`,
`_on_*` connectés dans une `.tscn`), et tout ce qui est appelé depuis une scène ou
un `.tres`. Grepper aussi dans `*.tscn` avant de conclure.

**Des commentaires qui mentent.** Un commentaire qui annonce une étape future déjà
faite, ou un chiffre de performance écrit avant d'être mesuré, désoriente plus
qu'il n'aide. Les relire en même temps que le code qu'ils décrivent.

**Des valeurs par défaut qui contredisent une décision de design.** Vérifier que
les `@export` et les constantes correspondent à ce que le document de jalon dit.

## 3. L'arbitrage : ce qu'il ne faut PAS factoriser

C'est la moitié du travail, et c'est celle qu'on rate. Avant chaque extraction,
répondre :

1. **Combien de lignes sont réellement partagées ?** Pas « les deux classes se
   ressemblent » — compter. Trois lignes communes ne paient pas une hiérarchie.
2. **Combien d'appelants ?** Deux appelants de deux lignes chacun ne paient pas une
   classe utilitaire globale. À partir de trois, la question se repose.
3. **Les cas divergent-ils déjà ?** Si les deux copies ont des différences réelles
   (ici : la mort du joueur émet un signal et attend un rechargement, celle de
   l'ennemi se libère), les unifier crée un paramètre `bool` qui rend les deux
   chemins plus durs à lire qu'avant.
4. **Est-ce que ça déplace le « où ça se passe » hors de vue ?** Si suivre le code
   demande un saut de fichier de plus pour un gain nul, refuser.

Les refus se **notent** et se justifient dans le rapport final. Un « je n'ai pas
fait X, voici pourquoi » vaut mieux qu'un silence : sans ça, la même question
revient à la revue suivante.

## 4. Corriger

- Une correction = un point de vérité unique créé. Ne pas mélanger avec une
  correction de comportement : si un bug apparaît pendant la revue, le corriger,
  mais l'annoncer séparément.
- Garder le style du fichier : ce projet commente le **pourquoi**, pas le quoi.
  Une fonction extraite mérite un commentaire qui dit ce qu'elle remplaçait
  (« quatre appelants écrivaient les quatre mêmes lignes »).
- Respecter les doctrines du projet, qui sont des invariants et non des
  préférences :
  - **base partagée / instance** : ne jamais écrire dans un `.tres` du disque
    (`ItemBase` vs `Item`, `base_stats` vs `stats`, `duplicate()` avant mutation) ;
  - **déterminisme** : un tirage lié à la zone passe par son RNG local, jamais par
    `Game.rng`, dont l'état dépend de tout ce qui a été tiré avant ;
  - **rappels de physique** : jamais d'`add_child` d'une `Area2D` depuis un signal
    de collision (`call_deferred` + `set_deferred`), et toujours
    `is_instance_valid()` **avant** un cast `as` sur une référence conservée ;
  - **pilote unique** : les ennemis n'ont pas de `_physics_process`, l'EnemyManager
    les tick ; le retour visuel des coups est dessiné par un seul nœud.

## 5. Valider — obligatoire avant d'annoncer quoi que ce soit

Le code qui compile n'est pas du code vérifié. La recette complète est dans la
mémoire `godot-headless-validation` ; le minimum pour une passe de revue :

1. **Copie fraîche** du projet sous `/mnt/c/.../AppData/Local/Temp/hns-<horodatage>`
   (ne jamais toucher le cache `.godot/` du vrai projet).
2. `--headless --path <chemin Windows> --import` → doit sortir **zéro** erreur de
   parsing. Toujours en premier : sans import, les `class_name` ne sont pas
   enregistrés et tout échoue en « Could not find type X ».
3. Une scène de test écrite pour l'occasion, lancée en
   `--headless --quit-after <images> res://test_all.tscn`, qui **rejoue les
   invariants touchés par la passe**. Ce qui a été vérifié la dernière fois, à
   reprendre comme base : modèle du sac, aller-retour case ↔ pixels, filtre des
   affixes par type d'objet, plats avant pourcentages, peuplement et vidage de
   zone, dégâts et équipement, distance de bouche des projectiles, gain
   d'expérience, glisser-déposer à la souris réelle, **zone de graine fixe
   identique sur trois lancements**, planches de sprites inchangées au pixel près,
   `.tres` du disque intacts.
4. Un test d'endurance de quelques centaines d'images de physique en combat dense :
   c'est lui qui débusque les fautes de rappel de physique, invisibles autrement.
5. Si la passe touche au dessin : lancer **sans** `--headless` et sauver le
   framebuffer (`await RenderingServer.frame_post_draw` puis `save_png`), recadrer
   et agrandir en NEAREST avec PIL avant de juger.
6. Si la passe touche à une boucle chaude : remesurer avec `world/stress_test.tscn`
   en fenêtré et comparer au tableau de la mémoire `hns-perf-reference`. Chauffer
   ~240 images avant de relever, et alterner l'ordre des conditions.

Puis **nettoyer** : supprimer le dossier temporaire et le
`AppData/Roaming/Godot/app_userdata/<projet>/` laissé par les exécutions.

**Ne jamais arrêter un processus Godot par nom d'image** — ça tue l'éditeur ouvert
de l'utilisateur. Cibler par PID sur la ligne de commande `Temp/hns-`, comme décrit
dans la mémoire `ne-pas-tuer-godot-utilisateur`. Mieux : que les scripts de test se
terminent seuls.

## 6. Le rapport

En français, court, sans tableau de métriques inventé. Quatre sections :

1. **Ce qui était vraiment redondant** — pour chaque point : ce qui était écrit N
   fois, *pourquoi c'était dangereux* (« il suffisait d'en oublier une pour que la
   barre mente »), et ce que ça devient. Le danger concret, pas l'esthétique.
2. **Ce que j'ai supprimé comme mort ou inutilement malin** — nommer les choses,
   assumer celles qu'on avait écrites soi-même.
3. **Ce que j'ai décidé de ne pas faire** — les refus de l'étape 3 avec leur
   raison, et le seuil qui les ferait basculer (« si un troisième appelant
   arrive, ça changera »).
4. **Le bilan honnête** — le vrai delta de lignes, y compris quand il est nul ou
   positif, avec la phrase qui remet le gain à sa place ; puis le résultat de la
   validation (nombre de points verts, tests de cadence et d'endurance) ; puis
   l'état du dépôt (fichiers modifiés, non commités).

Ne pas commiter sans que l'utilisateur le demande.
