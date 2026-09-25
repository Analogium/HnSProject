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
| Sous-équipé | 🟩 1,34 · 24,6 s | 🟨 0,66 · 6,34 s | 🟥 0,97 · 3,74 s | 🟥 1,59 · 3,75 s | 🟨 3,64 · 4,26 s | 🟥 14,2 · 6,99 s | 🟥 103 · 5,73 s |
| Équipé | 🟩 1,35 · 21,5 s | 🟨 0,58 · 7,63 s | 🟨 0,86 · 6,42 s | 🟨 1,27 · 5,84 s | 🟨 3,87 · 5,40 s | 🟥 16,3 · 8,64 s | 🟥 110 · 5,24 s |
| Sur-équipé | 🟩 0,87 · ∞ s | 🟩 0,52 · 36,3 s | 🟩 0,75 · 18,9 s | 🟩 1,37 · 10,0 s | 🟨 3,34 · 4,68 s | 🟥 19,0 · 7,44 s | 🟥 110 · 4,57 s |

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
| Sous-équipé | 1 | 1 | Éclair vif | 1,34 | 0,89 | 2,68 | 0,48 | 0,95 | 24,6 |
| Sous-équipé | 10 | 13 | Chaîne d'éclairs | 0,66 | 0,44 | 1,32 | 0,13 | 0,25 | 6,34 |
| Sous-équipé | 20 | 19 | Chaîne d'éclairs | 0,97 | 0,65 | 1,94 | 0,19 | 0,37 | 3,74 |
| Sous-équipé | 40 | 34 | Éclair vif | 1,59 | 1,06 | 3,17 | 0,22 | 0,44 | 3,75 |
| Sous-équipé | 60 | 53 | Éclair vif | 3,64 | 2,43 | 7,28 | 0,48 | 0,97 | 4,26 |
| Sous-équipé | 90 | 100 | Éclair vif | 14,2 | 9,45 | 28,4 | 1,54 | 3,08 | 6,99 |
| Sous-équipé | 120 | 100 | Éclair vif | 103 | 68,6 | 206 | 12,4 | 24,8 | 5,73 |
| Équipé | 1 | 1 | Éclair vif | 1,35 | 0,90 | 2,70 | 0,48 | 0,95 | 21,5 |
| Équipé | 10 | 13 | Chaîne d'éclairs | 0,58 | 0,39 | 1,16 | 0,11 | 0,22 | 7,63 |
| Équipé | 20 | 19 | Chaîne d'éclairs | 0,86 | 0,57 | 1,71 | 0,15 | 0,30 | 6,42 |
| Équipé | 40 | 34 | Éclair vif | 1,27 | 0,85 | 2,54 | 0,16 | 0,32 | 5,84 |
| Équipé | 60 | 53 | Éclair vif | 3,87 | 2,58 | 7,73 | 0,47 | 0,95 | 5,40 |
| Équipé | 90 | 100 | Éclair vif | 16,3 | 10,9 | 32,6 | 1,96 | 3,92 | 8,64 |
| Équipé | 120 | 100 | Éclair vif | 110 | 73,3 | 220 | 11,5 | 23,0 | 5,24 |
| Sur-équipé | 1 | 1 | Éclair vif | 0,87 | 0,58 | 1,74 | 0,29 | 0,58 | ∞ |
| Sur-équipé | 10 | 13 | Chaîne d'éclairs | 0,52 | 0,34 | 1,03 | 0,09 | 0,17 | 36,3 |
| Sur-équipé | 20 | 19 | Chaîne d'éclairs | 0,75 | 0,50 | 1,51 | 0,11 | 0,22 | 18,9 |
| Sur-équipé | 40 | 34 | Éclair vif | 1,37 | 0,92 | 2,75 | 0,16 | 0,33 | 10,0 |
| Sur-équipé | 60 | 53 | Éclair vif | 3,34 | 2,23 | 6,68 | 0,39 | 0,79 | 4,68 |
| Sur-équipé | 90 | 100 | Éclair vif | 19,0 | 12,6 | 37,9 | 2,27 | 4,53 | 7,44 |
| Sur-équipé | 120 | 100 | Éclair vif | 110 | 73,3 | 220 | 11,8 | 23,5 | 4,57 |

</details>

## Mêlée — Manuel du chevalier, Colosse

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,05 · 4,68 s | 🟥 2,23 · 2,20 s | 🟥 4,83 · 1,39 s | 🟥 20,0 · 0,80 s | 🟥 75,6 · 0,56 s | 🟥 506 · 0,39 s | 🟥 3166 · 0,30 s |
| Nu | 🟨 1,05 · 4,68 s | 🟨 0,44 · 4,44 s | 🟨 0,81 · 6,32 s | 🟨 1,88 · 6,05 s | 🟨 3,55 · 5,59 s | 🟥 19,5 · 4,04 s | 🟥 106 · 2,97 s |
| Sous-équipé | 🟩 1,00 · 18,5 s | 🟦 0,43 · 12,3 s | 🟩 0,76 · 15,7 s | 🟩 1,71 · 23,3 s | 🟩 2,90 · 26,4 s | 🟥 15,5 · 19,7 s | 🟥 67,8 · 15,1 s |
| Équipé | 🟩 1,08 · 17,3 s | 🟦 0,42 · 13,2 s | 🟩 0,76 · 25,9 s | 🟩 1,44 · 67,0 s | 🟩 2,47 · 39,7 s | 🟥 12,2 · 24,9 s | 🟥 62,1 · 12,0 s |
| Sur-équipé | 🟩 0,74 · ∞ s | 🟦 0,36 · 196 s | 🟩 0,56 · 76,5 s | 🟩 1,50 · 39,8 s | 🟩 2,78 · 35,0 s | 🟥 14,1 · 23,7 s | 🟥 76,8 · 11,8 s |

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
| Sous-équipé | 1 | 1 | Frappe lourde | 1,00 | 0,67 | 2,00 | 0,43 | 0,86 | 18,5 |
| Sous-équipé | 10 | 13 | Frappe lourde | 0,43 | 0,28 | 0,85 | 0,12 | 0,23 | 12,3 |
| Sous-équipé | 20 | 19 | Frappe lourde | 0,76 | 0,51 | 1,53 | 0,24 | 0,48 | 15,7 |
| Sous-équipé | 40 | 34 | Frappe lourde | 1,71 | 1,14 | 3,42 | 0,57 | 1,15 | 23,3 |
| Sous-équipé | 60 | 53 | Frappe lourde | 2,90 | 1,93 | 5,80 | 0,82 | 1,64 | 26,4 |
| Sous-équipé | 90 | 100 | Frappe lourde | 15,5 | 10,4 | 31,1 | 4,44 | 8,87 | 19,7 |
| Sous-équipé | 120 | 100 | Frappe lourde | 67,8 | 45,2 | 136 | 19,1 | 38,1 | 15,1 |
| Équipé | 1 | 1 | Frappe lourde | 1,08 | 0,72 | 2,15 | 0,41 | 0,81 | 17,3 |
| Équipé | 10 | 13 | Frappe lourde | 0,42 | 0,28 | 0,84 | 0,11 | 0,23 | 13,2 |
| Équipé | 20 | 19 | Frappe lourde | 0,76 | 0,51 | 1,52 | 0,23 | 0,47 | 25,9 |
| Équipé | 40 | 34 | Frappe lourde | 1,44 | 0,96 | 2,87 | 0,44 | 0,88 | 67,0 |
| Équipé | 60 | 53 | Frappe lourde | 2,47 | 1,65 | 4,94 | 0,58 | 1,16 | 39,7 |
| Équipé | 90 | 100 | Frappe lourde | 12,2 | 8,11 | 24,3 | 2,72 | 5,44 | 24,9 |
| Équipé | 120 | 100 | Frappe lourde | 62,1 | 41,4 | 124 | 15,9 | 31,8 | 12,0 |
| Sur-équipé | 1 | 1 | Frappe lourde | 0,74 | 0,49 | 1,48 | 0,30 | 0,59 | ∞ |
| Sur-équipé | 10 | 13 | Frappe lourde | 0,36 | 0,24 | 0,72 | 0,11 | 0,21 | 196 |
| Sur-équipé | 20 | 19 | Frappe lourde | 0,56 | 0,37 | 1,11 | 0,12 | 0,24 | 76,5 |
| Sur-équipé | 40 | 34 | Frappe lourde | 1,50 | 1,00 | 3,01 | 0,39 | 0,78 | 39,8 |
| Sur-équipé | 60 | 53 | Frappe lourde | 2,78 | 1,85 | 5,56 | 0,65 | 1,30 | 35,0 |
| Sur-équipé | 90 | 100 | Frappe lourde | 14,1 | 9,37 | 28,1 | 3,54 | 7,09 | 23,7 |
| Sur-équipé | 120 | 100 | Frappe lourde | 76,8 | 51,2 | 154 | 19,3 | 38,6 | 11,8 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
