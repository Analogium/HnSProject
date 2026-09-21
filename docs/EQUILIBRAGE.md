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
| Sous-équipé | 🟩 1,29 · 23,2 s | 🟨 0,65 · 6,55 s | 🟥 0,94 · 3,84 s | 🟥 1,50 · 3,59 s | 🟨 3,35 · 4,62 s | 🟥 16,9 · 8,16 s | 🟥 101 · 5,86 s |
| Équipé | 🟩 1,26 · 18,3 s | 🟨 0,59 · 7,10 s | 🟨 0,85 · 6,81 s | 🟨 1,35 · 5,84 s | 🟨 3,33 · 5,40 s | 🟥 18,1 · 9,12 s | 🟥 119 · 4,89 s |
| Sur-équipé | 🟩 0,98 · 237 s | 🟦 0,49 · 42,5 s | 🟩 0,76 · 22,0 s | 🟨 1,37 · 8,54 s | 🟥 3,34 · 3,83 s | 🟥 15,6 · 8,92 s | 🟥 110 · 5,62 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,50 | 0,99 | 4,68 |
| Débutant | 10 | 1 | Éclair vif | 2,27 | 1,51 | 4,54 | 0,83 | 1,66 | 2,20 |
| Débutant | 20 | 1 | Éclair vif | 4,01 | 2,68 | 8,03 | 1,47 | 2,93 | 1,39 |
| Débutant | 40 | 1 | Éclair vif | 12,6 | 8,40 | 25,2 | 4,60 | 9,20 | 0,80 |
| Débutant | 60 | 1 | Éclair vif | 39,8 | 26,5 | 79,6 | 14,5 | 29,1 | 0,56 |
| Débutant | 90 | 1 | Éclair vif | 226 | 151 | 452 | 82,6 | 165 | 0,39 |
| Débutant | 120 | 1 | Éclair vif | 1310 | 873 | 2620 | 479 | 957 | 0,30 |
| Nu | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,50 | 0,99 | 4,68 |
| Nu | 10 | 13 | Chaîne d'éclairs | 0,67 | 0,45 | 1,34 | 0,13 | 0,26 | 2,20 |
| Nu | 20 | 19 | Chaîne d'éclairs | 0,98 | 0,65 | 1,96 | 0,19 | 0,38 | 1,62 |
| Nu | 40 | 34 | Éclair vif | 1,65 | 1,10 | 3,29 | 0,24 | 0,47 | 1,21 |
| Nu | 60 | 53 | Éclair vif | 4,00 | 2,67 | 8,00 | 0,57 | 1,15 | 1,05 |
| Nu | 90 | 100 | Éclair vif | 22,7 | 15,2 | 45,5 | 3,25 | 6,51 | 2,20 |
| Nu | 120 | 100 | Éclair vif | 132 | 87,8 | 263 | 18,9 | 37,7 | 1,68 |
| Sous-équipé | 1 | 1 | Éclair vif | 1,29 | 0,86 | 2,58 | 0,46 | 0,93 | 23,2 |
| Sous-équipé | 10 | 13 | Chaîne d'éclairs | 0,65 | 0,43 | 1,30 | 0,12 | 0,25 | 6,55 |
| Sous-équipé | 20 | 19 | Chaîne d'éclairs | 0,94 | 0,63 | 1,88 | 0,17 | 0,35 | 3,84 |
| Sous-équipé | 40 | 34 | Éclair vif | 1,50 | 1,00 | 3,01 | 0,21 | 0,41 | 3,59 |
| Sous-équipé | 60 | 53 | Éclair vif | 3,35 | 2,23 | 6,70 | 0,40 | 0,80 | 4,62 |
| Sous-équipé | 90 | 100 | Éclair vif | 16,9 | 11,3 | 33,8 | 1,81 | 3,63 | 8,16 |
| Sous-équipé | 120 | 100 | Éclair vif | 101 | 67,1 | 201 | 9,62 | 19,2 | 5,86 |
| Équipé | 1 | 1 | Éclair vif | 1,26 | 0,84 | 2,52 | 0,46 | 0,91 | 18,3 |
| Équipé | 10 | 13 | Chaîne d'éclairs | 0,59 | 0,40 | 1,19 | 0,10 | 0,21 | 7,10 |
| Équipé | 20 | 19 | Chaîne d'éclairs | 0,85 | 0,57 | 1,70 | 0,15 | 0,30 | 6,81 |
| Équipé | 40 | 34 | Éclair vif | 1,35 | 0,90 | 2,70 | 0,16 | 0,32 | 5,84 |
| Équipé | 60 | 53 | Éclair vif | 3,33 | 2,22 | 6,66 | 0,39 | 0,78 | 5,40 |
| Équipé | 90 | 100 | Éclair vif | 18,1 | 12,1 | 36,3 | 2,12 | 4,24 | 9,12 |
| Équipé | 120 | 100 | Éclair vif | 119 | 79,6 | 239 | 14,7 | 29,3 | 4,89 |
| Sur-équipé | 1 | 1 | Éclair vif | 0,98 | 0,66 | 1,97 | 0,33 | 0,66 | 237 |
| Sur-équipé | 10 | 13 | Chaîne d'éclairs | 0,49 | 0,33 | 0,99 | 0,09 | 0,17 | 42,5 |
| Sur-équipé | 20 | 19 | Chaîne d'éclairs | 0,76 | 0,50 | 1,51 | 0,12 | 0,25 | 22,0 |
| Sur-équipé | 40 | 34 | Éclair vif | 1,37 | 0,92 | 2,75 | 0,14 | 0,28 | 8,54 |
| Sur-équipé | 60 | 53 | Éclair vif | 3,34 | 2,23 | 6,68 | 0,39 | 0,79 | 3,83 |
| Sur-équipé | 90 | 100 | Éclair vif | 15,6 | 10,4 | 31,1 | 1,88 | 3,76 | 8,92 |
| Sur-équipé | 120 | 100 | Éclair vif | 110 | 73,3 | 220 | 12,1 | 24,2 | 5,62 |

</details>

## Mêlée — Manuel du chevalier, Colosse

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,05 · 4,68 s | 🟥 2,23 · 2,20 s | 🟥 4,83 · 1,39 s | 🟥 20,0 · 0,80 s | 🟥 75,6 · 0,56 s | 🟥 506 · 0,39 s | 🟥 3166 · 0,30 s |
| Nu | 🟨 1,05 · 4,68 s | 🟨 0,44 · 4,44 s | 🟨 0,81 · 6,32 s | 🟨 1,88 · 6,05 s | 🟨 3,55 · 5,59 s | 🟥 19,5 · 4,04 s | 🟥 106 · 2,97 s |
| Sous-équipé | 🟩 1,00 · 20,7 s | 🟦 0,43 · 12,3 s | 🟩 0,77 · 16,2 s | 🟩 1,76 · 24,8 s | 🟩 2,54 · 28,9 s | 🟥 14,7 · 20,6 s | 🟥 69,4 · 13,8 s |
| Équipé | 🟩 1,10 · 19,6 s | 🟦 0,40 · 12,3 s | 🟩 0,76 · 26,6 s | 🟩 1,39 · 46,4 s | 🟩 2,32 · 37,5 s | 🟥 15,6 · 21,5 s | 🟥 58,4 · 13,2 s |
| Sur-équipé | 🟩 0,79 · ∞ s | 🟦 0,34 · 113 s | 🟩 0,54 · 82,0 s | 🟩 1,41 · 36,6 s | 🟨 3,05 · 37,3 s | 🟥 13,6 · 27,4 s | 🟥 75,2 · 13,2 s |

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
| Sous-équipé | 1 | 1 | Frappe lourde | 1,00 | 0,67 | 2,00 | 0,43 | 0,86 | 20,7 |
| Sous-équipé | 10 | 13 | Frappe lourde | 0,43 | 0,28 | 0,85 | 0,13 | 0,25 | 12,3 |
| Sous-équipé | 20 | 19 | Frappe lourde | 0,77 | 0,51 | 1,53 | 0,23 | 0,46 | 16,2 |
| Sous-équipé | 40 | 34 | Frappe lourde | 1,76 | 1,17 | 3,51 | 0,61 | 1,21 | 24,8 |
| Sous-équipé | 60 | 53 | Frappe lourde | 2,54 | 1,69 | 5,08 | 0,53 | 1,06 | 28,9 |
| Sous-équipé | 90 | 100 | Frappe lourde | 14,7 | 9,79 | 29,4 | 4,11 | 8,23 | 20,6 |
| Sous-équipé | 120 | 100 | Frappe lourde | 69,4 | 46,3 | 139 | 16,2 | 32,4 | 13,8 |
| Équipé | 1 | 1 | Frappe lourde | 1,10 | 0,73 | 2,19 | 0,40 | 0,81 | 19,6 |
| Équipé | 10 | 13 | Frappe lourde | 0,40 | 0,27 | 0,80 | 0,10 | 0,21 | 12,3 |
| Équipé | 20 | 19 | Frappe lourde | 0,76 | 0,51 | 1,52 | 0,23 | 0,47 | 26,6 |
| Équipé | 40 | 34 | Frappe lourde | 1,39 | 0,93 | 2,78 | 0,42 | 0,84 | 46,4 |
| Équipé | 60 | 53 | Frappe lourde | 2,32 | 1,55 | 4,64 | 0,63 | 1,26 | 37,5 |
| Équipé | 90 | 100 | Frappe lourde | 15,6 | 10,4 | 31,1 | 4,44 | 8,88 | 21,5 |
| Équipé | 120 | 100 | Frappe lourde | 58,4 | 38,9 | 117 | 13,7 | 27,5 | 13,2 |
| Sur-équipé | 1 | 1 | Frappe lourde | 0,79 | 0,53 | 1,58 | 0,32 | 0,63 | ∞ |
| Sur-équipé | 10 | 13 | Frappe lourde | 0,34 | 0,23 | 0,68 | 0,07 | 0,15 | 113 |
| Sur-équipé | 20 | 19 | Frappe lourde | 0,54 | 0,36 | 1,09 | 0,11 | 0,22 | 82,0 |
| Sur-équipé | 40 | 34 | Frappe lourde | 1,41 | 0,94 | 2,83 | 0,35 | 0,69 | 36,6 |
| Sur-équipé | 60 | 53 | Frappe lourde | 3,05 | 2,04 | 6,11 | 0,74 | 1,48 | 37,3 |
| Sur-équipé | 90 | 100 | Frappe lourde | 13,6 | 9,10 | 27,3 | 3,26 | 6,53 | 27,4 |
| Sur-équipé | 120 | 100 | Frappe lourde | 75,2 | 50,1 | 150 | 18,6 | 37,1 | 13,2 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
