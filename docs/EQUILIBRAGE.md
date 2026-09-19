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
| Nu | 🟨 1,36 · 4,68 s | 🟥 0,67 · 2,20 s | 🟥 0,98 · 1,62 s | 🟥 1,65 · 1,21 s | 🟥 4,00 · 1,05 s | 🟥 22,7 · 2,20 s | 🟥 132 · 1,68 s |
| Sous-équipé | 🟩 1,33 · 13,4 s | 🟨 0,63 · 5,15 s | 🟥 0,97 · 3,22 s | 🟥 1,51 · 2,77 s | 🟥 3,80 · 3,24 s | 🟥 18,5 · 7,51 s | 🟥 108 · 4,20 s |
| Équipé | 🟩 1,34 · 12,2 s | 🟨 0,59 · 5,61 s | 🟨 0,94 · 5,04 s | 🟨 1,33 · 6,56 s | 🟨 3,66 · 6,74 s | 🟥 19,8 · 6,24 s | 🟥 113 · 5,18 s |
| Sur-équipé | 🟩 0,88 · 35,7 s | 🟦 0,38 · 11,4 s | 🟩 0,77 · 14,5 s | 🟨 1,38 · 5,30 s | 🟨 3,35 · 5,70 s | 🟥 14,6 · 6,61 s | 🟥 94,8 · 5,33 s |

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
| Nu | 10 | 13 | Chaîne d'éclairs | 0,67 | 0,45 | 1,34 | 0,10 | 0,21 | 2,20 |
| Nu | 20 | 19 | Chaîne d'éclairs | 0,98 | 0,65 | 1,96 | 0,14 | 0,28 | 1,62 |
| Nu | 40 | 34 | Éclair vif | 1,65 | 1,10 | 3,29 | 0,16 | 0,31 | 1,21 |
| Nu | 60 | 53 | Éclair vif | 4,00 | 2,67 | 8,00 | 0,34 | 0,68 | 1,05 |
| Nu | 90 | 100 | Éclair vif | 22,7 | 15,2 | 45,5 | 1,87 | 3,74 | 2,20 |
| Nu | 120 | 100 | Éclair vif | 132 | 87,8 | 263 | 10,8 | 21,7 | 1,68 |
| Sous-équipé | 1 | 1 | Éclair vif | 1,33 | 0,89 | 2,66 | 0,45 | 0,90 | 13,4 |
| Sous-équipé | 10 | 13 | Chaîne d'éclairs | 0,63 | 0,42 | 1,27 | 0,10 | 0,19 | 5,15 |
| Sous-équipé | 20 | 19 | Chaîne d'éclairs | 0,97 | 0,64 | 1,93 | 0,13 | 0,27 | 3,22 |
| Sous-équipé | 40 | 34 | Éclair vif | 1,51 | 1,01 | 3,02 | 0,14 | 0,28 | 2,77 |
| Sous-équipé | 60 | 53 | Éclair vif | 3,80 | 2,53 | 7,60 | 0,27 | 0,54 | 3,24 |
| Sous-équipé | 90 | 100 | Éclair vif | 18,5 | 12,3 | 37,0 | 1,23 | 2,45 | 7,51 |
| Sous-équipé | 120 | 100 | Éclair vif | 108 | 72,3 | 217 | 7,68 | 15,4 | 4,20 |
| Équipé | 1 | 1 | Éclair vif | 1,34 | 0,90 | 2,69 | 0,46 | 0,93 | 12,2 |
| Équipé | 10 | 13 | Chaîne d'éclairs | 0,59 | 0,39 | 1,17 | 0,09 | 0,18 | 5,61 |
| Équipé | 20 | 19 | Chaîne d'éclairs | 0,94 | 0,63 | 1,89 | 0,12 | 0,25 | 5,04 |
| Équipé | 40 | 34 | Éclair vif | 1,33 | 0,89 | 2,67 | 0,10 | 0,20 | 6,56 |
| Équipé | 60 | 53 | Éclair vif | 3,66 | 2,44 | 7,32 | 0,25 | 0,51 | 6,74 |
| Équipé | 90 | 100 | Éclair vif | 19,8 | 13,2 | 39,6 | 1,39 | 2,79 | 6,24 |
| Équipé | 120 | 100 | Éclair vif | 113 | 75,4 | 226 | 7,95 | 15,9 | 5,18 |
| Sur-équipé | 1 | 1 | Éclair vif | 0,88 | 0,59 | 1,76 | 0,29 | 0,57 | 35,7 |
| Sur-équipé | 10 | 13 | Chaîne d'éclairs | 0,38 | 0,25 | 0,76 | 0,04 | 0,09 | 11,4 |
| Sur-équipé | 20 | 19 | Chaîne d'éclairs | 0,77 | 0,51 | 1,53 | 0,09 | 0,18 | 14,5 |
| Sur-équipé | 40 | 34 | Éclair vif | 1,38 | 0,92 | 2,76 | 0,11 | 0,23 | 5,30 |
| Sur-équipé | 60 | 53 | Éclair vif | 3,35 | 2,23 | 6,69 | 0,24 | 0,48 | 5,70 |
| Sur-équipé | 90 | 100 | Éclair vif | 14,6 | 9,75 | 29,2 | 1,00 | 2,00 | 6,61 |
| Sur-équipé | 120 | 100 | Éclair vif | 94,8 | 63,2 | 190 | 6,71 | 13,4 | 5,33 |

</details>

## Mêlée — Manuel du chevalier, Colosse

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,05 · 4,68 s | 🟥 2,23 · 2,20 s | 🟥 4,83 · 1,39 s | 🟥 20,0 · 0,80 s | 🟥 75,6 · 0,56 s | 🟥 506 · 0,39 s | 🟥 3166 · 0,30 s |
| Nu | 🟨 1,05 · 4,68 s | 🟨 0,44 · 4,44 s | 🟨 0,81 · 6,32 s | 🟨 1,88 · 6,05 s | 🟨 3,55 · 5,59 s | 🟥 19,5 · 4,04 s | 🟥 106 · 2,97 s |
| Sous-équipé | 🟩 1,03 · 12,1 s | 🟨 0,41 · 9,77 s | 🟩 0,76 · 11,7 s | 🟩 1,72 · 15,0 s | 🟨 3,01 · 15,9 s | 🟥 14,4 · 19,2 s | 🟥 66,2 · 10,3 s |
| Équipé | 🟩 1,17 · 12,9 s | 🟨 0,41 · 9,13 s | 🟩 0,78 · 18,8 s | 🟩 1,40 · 24,7 s | 🟩 2,56 · 22,9 s | 🟥 13,4 · 18,2 s | 🟥 58,9 · 9,05 s |
| Sur-équipé | 🟩 0,79 · 541 s | 🟦 0,33 · 39,8 s | 🟩 0,60 · 47,8 s | 🟩 1,43 · 31,5 s | 🟨 3,06 · 32,0 s | 🟥 14,1 · 17,5 s | 🟥 78,7 · 14,0 s |

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
| Sous-équipé | 1 | 1 | Frappe lourde | 1,03 | 0,69 | 2,06 | 0,35 | 0,69 | 12,1 |
| Sous-équipé | 10 | 13 | Frappe lourde | 0,41 | 0,28 | 0,83 | 0,11 | 0,22 | 9,77 |
| Sous-équipé | 20 | 19 | Frappe lourde | 0,76 | 0,50 | 1,51 | 0,21 | 0,41 | 11,7 |
| Sous-équipé | 40 | 34 | Frappe lourde | 1,72 | 1,15 | 3,44 | 0,50 | 1,00 | 15,0 |
| Sous-équipé | 60 | 53 | Frappe lourde | 3,01 | 2,00 | 6,01 | 0,69 | 1,38 | 15,9 |
| Sous-équipé | 90 | 100 | Frappe lourde | 14,4 | 9,60 | 28,8 | 3,18 | 6,36 | 19,2 |
| Sous-équipé | 120 | 100 | Frappe lourde | 66,2 | 44,1 | 132 | 15,2 | 30,3 | 10,3 |
| Équipé | 1 | 1 | Frappe lourde | 1,17 | 0,78 | 2,34 | 0,43 | 0,86 | 12,9 |
| Équipé | 10 | 13 | Frappe lourde | 0,41 | 0,27 | 0,81 | 0,11 | 0,22 | 9,13 |
| Équipé | 20 | 19 | Frappe lourde | 0,78 | 0,52 | 1,57 | 0,19 | 0,39 | 18,8 |
| Équipé | 40 | 34 | Frappe lourde | 1,40 | 0,94 | 2,81 | 0,36 | 0,72 | 24,7 |
| Équipé | 60 | 53 | Frappe lourde | 2,56 | 1,71 | 5,12 | 0,40 | 0,81 | 22,9 |
| Équipé | 90 | 100 | Frappe lourde | 13,4 | 8,94 | 26,8 | 2,86 | 5,72 | 18,2 |
| Équipé | 120 | 100 | Frappe lourde | 58,9 | 39,2 | 118 | 11,6 | 23,3 | 9,05 |
| Sur-équipé | 1 | 1 | Frappe lourde | 0,79 | 0,53 | 1,59 | 0,24 | 0,49 | 541 |
| Sur-équipé | 10 | 13 | Frappe lourde | 0,33 | 0,22 | 0,67 | 0,06 | 0,13 | 39,8 |
| Sur-équipé | 20 | 19 | Frappe lourde | 0,60 | 0,40 | 1,19 | 0,13 | 0,26 | 47,8 |
| Sur-équipé | 40 | 34 | Frappe lourde | 1,43 | 0,95 | 2,85 | 0,35 | 0,70 | 31,5 |
| Sur-équipé | 60 | 53 | Frappe lourde | 3,06 | 2,04 | 6,13 | 0,48 | 0,97 | 32,0 |
| Sur-équipé | 90 | 100 | Frappe lourde | 14,1 | 9,39 | 28,2 | 2,93 | 5,86 | 17,5 |
| Sur-équipé | 120 | 100 | Frappe lourde | 78,7 | 52,5 | 157 | 16,8 | 33,5 | 14,0 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
