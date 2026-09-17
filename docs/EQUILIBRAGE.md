# Banc d'équilibrage

<!-- Fichier généré par tools/equilibrage.sh — ne pas éditer à la main. -->

Ce que chaque profil type rencontre, zone par zone. Les profils sont reconstruits
par les règles du jeu à chaque lancement (`BenchProfiles`), et le calcul passe par
les vraies fonctions (`BenchCalculation`). Le banc montre les écarts ; les réglages
restent une décision — voir `JALONS/hack-n-slash-jalon-13.md`.

| verdict | coups pour tuer un grunt | survie au contact |
|---|---|---|
| 🟦 trivial | moins de 0,50 | plus de 10,0 s |
| 🟩 confortable | 0,50 à 3,00 | plus de 10,0 s |
| 🟨 tendu | 3,00 à 8,00 | 4,00 à 10,0 s |
| 🟥 mur | plus de 8,00 | moins de 4,00 s |

Le verdict est le pire des deux axes. Pour lire les nombres :

- **coups** : avec la compétence de la barre qui en demande le moins, critique en
  moyenne, après les défenses de l'ennemi ;
- **secondes** : par `average_per_second()`, *si tout touche* — les traits d'une
  nova comptent tous sur la même cible — et sans compter la réserve de mana ;
- **survie** : au contact de 3 grunts et 1 caster sans affixe, après armure,
  résistances et esquive, régénération déduite. ∞ : la régénération suffit.

Un profil équipé est tiré 9 fois : coups et survie sont les médianes, chacune
sur son axe ; le détail est celui du tirage médian en coups.

## Niveau attendu

Le niveau atteint en vidant une fois chaque zone de 1 à Z − 1, avec la population
moyenne de l'`EnemySpawner` et le retard de `Enemy.experience_factor()`.

| zone | 1 | 10 | 20 | 40 | 60 | 90 | 120 |
|---|---|---|---|---|---|---|---|
| niveau | 1 | 13 | 19 | 34 | 53 | 100 | 100 |

## Sort — Manuel de la foudre, Esprit d'orage

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,36 · 4,68 s | 🟥 2,27 · 2,20 s | 🟥 4,01 · 1,39 s | 🟥 12,6 · 0,80 s | 🟥 39,8 · 0,56 s | 🟥 226 · 0,39 s | 🟥 1310 · 0,30 s |
| Nu | 🟨 1,36 · 4,68 s | 🟥 0,69 · 2,20 s | 🟥 1,01 · 1,62 s | 🟥 1,95 · 1,21 s | 🟥 4,74 · 1,05 s | 🟥 27,0 · 2,20 s | 🟥 156 · 1,68 s |
| Sous-équipé | 🟩 1,32 · 12,8 s | 🟨 0,69 · 5,04 s | 🟥 0,95 · 3,24 s | 🟥 1,77 · 2,62 s | 🟥 4,66 · 2,81 s | 🟥 22,0 · 7,48 s | 🟥 114 · 4,69 s |
| Équipé | 🟩 1,33 · 12,8 s | 🟨 0,59 · 5,61 s | 🟨 0,99 · 6,21 s | 🟨 1,59 · 5,08 s | 🟨 3,83 · 7,69 s | 🟥 18,4 · 8,66 s | 🟥 127 · 5,76 s |
| Sur-équipé | 🟩 0,88 · 65,4 s | 🟦 0,45 · 10,4 s | 🟩 0,62 · 16,6 s | 🟨 1,92 · 6,10 s | 🟨 3,86 · 4,91 s | 🟥 14,7 · 5,76 s | 🟥 127 · 6,24 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,48 | 0,96 | 4,68 |
| Débutant | 10 | 1 | Éclair vif | 2,27 | 1,51 | 4,54 | 0,80 | 1,59 | 2,20 |
| Débutant | 20 | 1 | Éclair vif | 4,01 | 2,68 | 8,03 | 1,41 | 2,82 | 1,39 |
| Débutant | 40 | 1 | Éclair vif | 12,6 | 8,40 | 25,2 | 4,42 | 8,85 | 0,80 |
| Débutant | 60 | 1 | Éclair vif | 39,8 | 26,5 | 79,6 | 14,0 | 27,9 | 0,56 |
| Débutant | 90 | 1 | Éclair vif | 226 | 151 | 452 | 79,4 | 159 | 0,39 |
| Débutant | 120 | 1 | Éclair vif | 1310 | 873 | 2620 | 460 | 920 | 0,30 |
| Nu | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,48 | 0,96 | 4,68 |
| Nu | 10 | 13 | Chaîne d'éclairs | 0,69 | 0,46 | 1,39 | 0,09 | 0,17 | 2,20 |
| Nu | 20 | 19 | Chaîne d'éclairs | 1,01 | 0,67 | 2,02 | 0,12 | 0,23 | 1,62 |
| Nu | 40 | 34 | Chaîne d'éclairs | 1,95 | 1,30 | 3,91 | 0,17 | 0,34 | 1,21 |
| Nu | 60 | 53 | Chaîne d'éclairs | 4,74 | 3,16 | 9,49 | 0,37 | 0,73 | 1,05 |
| Nu | 90 | 100 | Chaîne d'éclairs | 27,0 | 18,0 | 53,9 | 2,01 | 4,02 | 2,20 |
| Nu | 120 | 100 | Chaîne d'éclairs | 156 | 104 | 313 | 11,7 | 23,3 | 1,68 |
| Sous-équipé | 1 | 1 | Éclair vif | 1,32 | 0,88 | 2,65 | 0,47 | 0,93 | 12,8 |
| Sous-équipé | 10 | 13 | Chaîne d'éclairs | 0,69 | 0,46 | 1,38 | 0,08 | 0,17 | 5,04 |
| Sous-équipé | 20 | 19 | Chaîne d'éclairs | 0,95 | 0,63 | 1,90 | 0,11 | 0,22 | 3,24 |
| Sous-équipé | 40 | 34 | Chaîne d'éclairs | 1,77 | 1,18 | 3,54 | 0,15 | 0,30 | 2,62 |
| Sous-équipé | 60 | 53 | Chaîne d'éclairs | 4,66 | 3,10 | 9,31 | 0,32 | 0,65 | 2,81 |
| Sous-équipé | 90 | 100 | Chaîne d'éclairs | 22,0 | 14,6 | 43,9 | 1,39 | 2,78 | 7,48 |
| Sous-équipé | 120 | 100 | Chaîne d'éclairs | 114 | 75,8 | 227 | 6,32 | 12,6 | 4,69 |
| Équipé | 1 | 1 | Éclair vif | 1,33 | 0,89 | 2,66 | 0,47 | 0,93 | 12,8 |
| Équipé | 10 | 13 | Chaîne d'éclairs | 0,59 | 0,39 | 1,17 | 0,07 | 0,14 | 5,61 |
| Équipé | 20 | 19 | Chaîne d'éclairs | 0,99 | 0,66 | 1,98 | 0,11 | 0,22 | 6,21 |
| Équipé | 40 | 34 | Chaîne d'éclairs | 1,59 | 1,06 | 3,18 | 0,12 | 0,23 | 5,08 |
| Équipé | 60 | 53 | Chaîne d'éclairs | 3,83 | 2,55 | 7,65 | 0,23 | 0,46 | 7,69 |
| Équipé | 90 | 100 | Chaîne d'éclairs | 18,4 | 12,3 | 36,8 | 1,01 | 2,03 | 8,66 |
| Équipé | 120 | 100 | Chaîne d'éclairs | 127 | 84,9 | 255 | 7,65 | 15,3 | 5,76 |
| Sur-équipé | 1 | 1 | Éclair vif | 0,88 | 0,59 | 1,76 | 0,29 | 0,57 | 65,4 |
| Sur-équipé | 10 | 13 | Chaîne d'éclairs | 0,45 | 0,30 | 0,90 | 0,05 | 0,09 | 10,4 |
| Sur-équipé | 20 | 19 | Chaîne d'éclairs | 0,62 | 0,41 | 1,24 | 0,05 | 0,11 | 16,6 |
| Sur-équipé | 40 | 34 | Chaîne d'éclairs | 1,92 | 1,28 | 3,83 | 0,11 | 0,21 | 6,10 |
| Sur-équipé | 60 | 53 | Chaîne d'éclairs | 3,86 | 2,58 | 7,73 | 0,24 | 0,48 | 4,91 |
| Sur-équipé | 90 | 100 | Chaîne d'éclairs | 14,7 | 9,80 | 29,4 | 0,68 | 1,36 | 5,76 |
| Sur-équipé | 120 | 100 | Chaîne d'éclairs | 127 | 84,9 | 255 | 7,60 | 15,2 | 6,24 |

</details>

## Mêlée — Manuel du chevalier, Colosse

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,05 · 4,68 s | 🟥 2,23 · 2,20 s | 🟥 4,83 · 1,39 s | 🟥 20,0 · 0,80 s | 🟥 75,6 · 0,56 s | 🟥 506 · 0,39 s | 🟥 3166 · 0,30 s |
| Nu | 🟨 1,05 · 4,68 s | 🟨 0,44 · 4,44 s | 🟨 0,81 · 6,32 s | 🟨 1,88 · 6,05 s | 🟨 3,55 · 5,59 s | 🟥 19,5 · 4,04 s | 🟥 106 · 2,97 s |
| Sous-équipé | 🟩 1,03 · 12,1 s | 🟨 0,43 · 9,98 s | 🟩 0,76 · 11,7 s | 🟩 1,70 · 19,0 s | 🟩 2,70 · 15,5 s | 🟥 14,7 · 16,9 s | 🟥 65,5 · 10,1 s |
| Équipé | 🟩 1,17 · 13,1 s | 🟨 0,42 · 9,74 s | 🟩 0,76 · 19,2 s | 🟩 1,50 · 28,0 s | 🟩 2,61 · 27,8 s | 🟥 13,1 · 12,1 s | 🟥 75,9 · 11,3 s |
| Sur-équipé | 🟩 0,86 · 1294 s | 🟦 0,33 · 37,6 s | 🟩 0,60 · 54,4 s | 🟩 1,33 · 41,3 s | 🟩 2,47 · 30,1 s | 🟥 14,6 · 13,8 s | 🟥 75,0 · 14,2 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Frappe lourde | 1,05 | 0,70 | 2,10 | 0,45 | 0,91 | 4,68 |
| Débutant | 10 | 1 | Frappe lourde | 2,23 | 1,49 | 4,47 | 0,97 | 1,93 | 2,20 |
| Débutant | 20 | 1 | Frappe lourde | 4,83 | 3,22 | 9,66 | 2,09 | 4,18 | 1,39 |
| Débutant | 40 | 1 | Frappe lourde | 20,0 | 13,3 | 40,0 | 8,66 | 17,3 | 0,80 |
| Débutant | 60 | 1 | Frappe lourde | 75,6 | 50,4 | 151 | 32,7 | 65,5 | 0,56 |
| Débutant | 90 | 1 | Frappe lourde | 506 | 337 | 1012 | 219 | 438 | 0,39 |
| Débutant | 120 | 1 | Frappe lourde | 3166 | 2111 | 6332 | 1370 | 2740 | 0,30 |
| Nu | 1 | 1 | Frappe lourde | 1,05 | 0,70 | 2,10 | 0,45 | 0,91 | 4,68 |
| Nu | 10 | 13 | Frappe lourde | 0,44 | 0,29 | 0,88 | 0,13 | 0,27 | 4,44 |
| Nu | 20 | 19 | Frappe lourde | 0,81 | 0,54 | 1,62 | 0,25 | 0,51 | 6,32 |
| Nu | 40 | 34 | Frappe lourde | 1,88 | 1,25 | 3,75 | 0,66 | 1,32 | 6,05 |
| Nu | 60 | 53 | Frappe lourde | 3,55 | 2,37 | 7,11 | 1,05 | 2,09 | 5,59 |
| Nu | 90 | 100 | Frappe lourde | 19,5 | 13,0 | 38,9 | 5,90 | 11,8 | 4,04 |
| Nu | 120 | 100 | Frappe lourde | 106 | 70,4 | 211 | 32,9 | 65,7 | 2,97 |
| Sous-équipé | 1 | 1 | Frappe lourde | 1,03 | 0,68 | 2,05 | 0,41 | 0,82 | 12,1 |
| Sous-équipé | 10 | 13 | Frappe lourde | 0,43 | 0,28 | 0,85 | 0,12 | 0,24 | 9,98 |
| Sous-équipé | 20 | 19 | Frappe lourde | 0,76 | 0,51 | 1,53 | 0,22 | 0,43 | 11,7 |
| Sous-équipé | 40 | 34 | Frappe lourde | 1,70 | 1,13 | 3,40 | 0,50 | 1,01 | 19,0 |
| Sous-équipé | 60 | 53 | Frappe lourde | 2,70 | 1,80 | 5,39 | 0,58 | 1,15 | 15,5 |
| Sous-équipé | 90 | 100 | Frappe lourde | 14,7 | 9,79 | 29,4 | 2,87 | 5,75 | 16,9 |
| Sous-équipé | 120 | 100 | Frappe lourde | 65,5 | 43,6 | 131 | 15,0 | 30,1 | 10,1 |
| Équipé | 1 | 1 | Frappe lourde | 1,17 | 0,78 | 2,34 | 0,43 | 0,86 | 13,1 |
| Équipé | 10 | 13 | Frappe lourde | 0,42 | 0,28 | 0,84 | 0,12 | 0,23 | 9,74 |
| Équipé | 20 | 19 | Frappe lourde | 0,76 | 0,51 | 1,53 | 0,21 | 0,41 | 19,2 |
| Équipé | 40 | 34 | Frappe lourde | 1,50 | 1,00 | 3,01 | 0,33 | 0,66 | 28,0 |
| Équipé | 60 | 53 | Frappe lourde | 2,61 | 1,74 | 5,22 | 0,51 | 1,03 | 27,8 |
| Équipé | 90 | 100 | Frappe lourde | 13,1 | 8,75 | 26,3 | 2,51 | 5,02 | 12,1 |
| Équipé | 120 | 100 | Frappe lourde | 75,9 | 50,6 | 152 | 17,2 | 34,4 | 11,3 |
| Sur-équipé | 1 | 1 | Frappe lourde | 0,86 | 0,57 | 1,72 | 0,28 | 0,57 | 1294 |
| Sur-équipé | 10 | 13 | Frappe lourde | 0,33 | 0,22 | 0,67 | 0,07 | 0,13 | 37,6 |
| Sur-équipé | 20 | 19 | Frappe lourde | 0,60 | 0,40 | 1,20 | 0,11 | 0,21 | 54,4 |
| Sur-équipé | 40 | 34 | Frappe lourde | 1,33 | 0,89 | 2,67 | 0,27 | 0,54 | 41,3 |
| Sur-équipé | 60 | 53 | Frappe lourde | 2,47 | 1,65 | 4,95 | 0,49 | 0,98 | 30,1 |
| Sur-équipé | 90 | 100 | Frappe lourde | 14,6 | 9,76 | 29,3 | 3,05 | 6,10 | 13,8 |
| Sur-équipé | 120 | 100 | Frappe lourde | 75,0 | 50,0 | 150 | 17,8 | 35,5 | 14,2 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
