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
| Sous-équipé | 🟩 1,27 · 23,2 s | 🟨 0,66 · 6,46 s | 🟥 0,97 · 3,85 s | 🟥 1,55 · 3,42 s | 🟥 3,35 · 3,91 s | 🟥 17,3 · 7,46 s | 🟥 110 · 4,87 s |
| Équipé | 🟩 1,33 · 20,2 s | 🟨 0,59 · 6,31 s | 🟨 0,84 · 6,76 s | 🟨 1,48 · 6,18 s | 🟨 3,91 · 6,32 s | 🟥 18,6 · 8,91 s | 🟥 113 · 4,84 s |
| Sur-équipé | 🟩 0,99 · ∞ s | 🟩 0,50 · 48,8 s | 🟩 0,69 · 15,5 s | 🟨 1,37 · 8,77 s | 🟨 2,94 · 4,13 s | 🟥 19,0 · 6,67 s | 🟥 110 · 5,82 s |

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
| Sous-équipé | 1 | 1 | Éclair vif | 1,27 | 0,85 | 2,55 | 0,45 | 0,89 | 23,2 |
| Sous-équipé | 10 | 13 | Chaîne d'éclairs | 0,66 | 0,44 | 1,32 | 0,12 | 0,24 | 6,46 |
| Sous-équipé | 20 | 19 | Chaîne d'éclairs | 0,97 | 0,65 | 1,94 | 0,19 | 0,37 | 3,85 |
| Sous-équipé | 40 | 34 | Éclair vif | 1,55 | 1,03 | 3,10 | 0,21 | 0,43 | 3,42 |
| Sous-équipé | 60 | 53 | Éclair vif | 3,35 | 2,23 | 6,70 | 0,41 | 0,82 | 3,91 |
| Sous-équipé | 90 | 100 | Éclair vif | 17,3 | 11,5 | 34,5 | 1,47 | 2,95 | 7,46 |
| Sous-équipé | 120 | 100 | Éclair vif | 110 | 73,4 | 220 | 12,9 | 25,7 | 4,87 |
| Équipé | 1 | 1 | Éclair vif | 1,33 | 0,89 | 2,66 | 0,45 | 0,90 | 20,2 |
| Équipé | 10 | 13 | Chaîne d'éclairs | 0,59 | 0,39 | 1,18 | 0,11 | 0,22 | 6,31 |
| Équipé | 20 | 19 | Chaîne d'éclairs | 0,84 | 0,56 | 1,67 | 0,15 | 0,29 | 6,76 |
| Équipé | 40 | 34 | Éclair vif | 1,48 | 0,99 | 2,97 | 0,17 | 0,34 | 6,18 |
| Équipé | 60 | 53 | Éclair vif | 3,91 | 2,61 | 7,82 | 0,49 | 0,98 | 6,32 |
| Équipé | 90 | 100 | Éclair vif | 18,6 | 12,4 | 37,3 | 2,24 | 4,48 | 8,91 |
| Équipé | 120 | 100 | Éclair vif | 113 | 75,6 | 227 | 13,8 | 27,5 | 4,84 |
| Sur-équipé | 1 | 1 | Éclair vif | 0,99 | 0,66 | 1,97 | 0,17 | 0,33 | ∞ |
| Sur-équipé | 10 | 13 | Chaîne d'éclairs | 0,50 | 0,34 | 1,01 | 0,08 | 0,16 | 48,8 |
| Sur-équipé | 20 | 19 | Chaîne d'éclairs | 0,69 | 0,46 | 1,38 | 0,10 | 0,20 | 15,5 |
| Sur-équipé | 40 | 34 | Éclair vif | 1,37 | 0,92 | 2,75 | 0,17 | 0,33 | 8,77 |
| Sur-équipé | 60 | 53 | Éclair vif | 2,94 | 1,96 | 5,88 | 0,33 | 0,66 | 4,13 |
| Sur-équipé | 90 | 100 | Éclair vif | 19,0 | 12,6 | 37,9 | 2,27 | 4,53 | 6,67 |
| Sur-équipé | 120 | 100 | Éclair vif | 110 | 73,2 | 220 | 13,4 | 26,7 | 5,82 |

</details>

## Mêlée — Manuel du chevalier, Colosse

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,05 · 4,68 s | 🟥 2,23 · 2,20 s | 🟥 4,83 · 1,39 s | 🟥 20,0 · 0,80 s | 🟥 75,6 · 0,56 s | 🟥 506 · 0,39 s | 🟥 3166 · 0,30 s |
| Nu | 🟨 1,05 · 4,68 s | 🟨 0,44 · 4,44 s | 🟨 0,81 · 6,32 s | 🟨 1,88 · 6,05 s | 🟨 3,55 · 5,59 s | 🟥 19,5 · 4,04 s | 🟥 106 · 2,97 s |
| Sous-équipé | 🟩 1,03 · 19,5 s | 🟦 0,41 · 11,8 s | 🟩 0,78 · 15,5 s | 🟩 1,76 · 26,9 s | 🟩 2,97 · 29,0 s | 🟥 14,7 · 20,6 s | 🟥 72,4 · 15,5 s |
| Équipé | 🟩 1,11 · 19,3 s | 🟦 0,40 · 12,4 s | 🟩 0,74 · 27,6 s | 🟩 1,46 · 47,1 s | 🟩 2,69 · 40,9 s | 🟥 11,7 · 21,7 s | 🟥 56,8 · 13,3 s |
| Sur-équipé | 🟩 1,05 · 402 s | 🟦 0,33 · 127 s | 🟩 0,58 · 69,3 s | 🟩 1,38 · 47,5 s | 🟩 2,81 · 33,7 s | 🟥 13,5 · 28,3 s | 🟥 78,1 · 12,5 s |

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
| Sous-équipé | 1 | 1 | Frappe lourde | 1,03 | 0,69 | 2,06 | 0,44 | 0,88 | 19,5 |
| Sous-équipé | 10 | 13 | Frappe lourde | 0,41 | 0,28 | 0,83 | 0,12 | 0,23 | 11,8 |
| Sous-équipé | 20 | 19 | Frappe lourde | 0,78 | 0,52 | 1,56 | 0,24 | 0,48 | 15,5 |
| Sous-équipé | 40 | 34 | Frappe lourde | 1,76 | 1,18 | 3,53 | 0,56 | 1,13 | 26,9 |
| Sous-équipé | 60 | 53 | Frappe lourde | 2,97 | 1,98 | 5,95 | 0,74 | 1,49 | 29,0 |
| Sous-équipé | 90 | 100 | Frappe lourde | 14,7 | 9,79 | 29,4 | 4,11 | 8,23 | 20,6 |
| Sous-équipé | 120 | 100 | Frappe lourde | 72,4 | 48,3 | 145 | 18,2 | 36,4 | 15,5 |
| Équipé | 1 | 1 | Frappe lourde | 1,11 | 0,74 | 2,22 | 0,42 | 0,84 | 19,3 |
| Équipé | 10 | 13 | Frappe lourde | 0,40 | 0,27 | 0,80 | 0,12 | 0,24 | 12,4 |
| Équipé | 20 | 19 | Frappe lourde | 0,74 | 0,50 | 1,49 | 0,21 | 0,42 | 27,6 |
| Équipé | 40 | 34 | Frappe lourde | 1,46 | 0,97 | 2,92 | 0,46 | 0,91 | 47,1 |
| Équipé | 60 | 53 | Frappe lourde | 2,69 | 1,79 | 5,37 | 0,73 | 1,47 | 40,9 |
| Équipé | 90 | 100 | Frappe lourde | 11,7 | 7,77 | 23,3 | 2,82 | 5,65 | 21,7 |
| Équipé | 120 | 100 | Frappe lourde | 56,8 | 37,9 | 114 | 12,6 | 25,2 | 13,3 |
| Sur-équipé | 1 | 1 | Frappe lourde | 1,05 | 0,70 | 2,10 | 0,34 | 0,68 | 402 |
| Sur-équipé | 10 | 13 | Frappe lourde | 0,33 | 0,22 | 0,65 | 0,09 | 0,18 | 127 |
| Sur-équipé | 20 | 19 | Frappe lourde | 0,58 | 0,39 | 1,16 | 0,14 | 0,27 | 69,3 |
| Sur-équipé | 40 | 34 | Frappe lourde | 1,38 | 0,92 | 2,76 | 0,42 | 0,84 | 47,5 |
| Sur-équipé | 60 | 53 | Frappe lourde | 2,81 | 1,88 | 5,63 | 0,69 | 1,38 | 33,7 |
| Sur-équipé | 90 | 100 | Frappe lourde | 13,5 | 9,01 | 27,0 | 3,15 | 6,29 | 28,3 |
| Sur-équipé | 120 | 100 | Frappe lourde | 78,1 | 52,1 | 156 | 21,1 | 42,1 | 12,5 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
