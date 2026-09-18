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
| Sous-équipé | 🟩 1,27 · 12,8 s | 🟨 0,64 · 5,04 s | 🟥 0,94 · 3,16 s | 🟥 1,51 · 2,87 s | 🟥 3,93 · 2,59 s | 🟥 19,0 · 7,73 s | 🟥 107 · 4,69 s |
| Équipé | 🟩 1,35 · 12,3 s | 🟨 0,55 · 5,47 s | 🟨 0,94 · 4,87 s | 🟨 1,52 · 5,69 s | 🟨 3,09 · 7,55 s | 🟥 18,0 · 8,12 s | 🟥 110 · 5,68 s |
| Sur-équipé | 🟩 0,88 · 52,6 s | 🟦 0,43 · 12,7 s | 🟨 0,66 · 8,23 s | 🟨 1,62 · 5,36 s | 🟨 3,35 · 5,96 s | 🟥 16,6 · 5,76 s | 🟥 93,5 · 5,33 s |

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
| Sous-équipé | 1 | 1 | Éclair vif | 1,27 | 0,85 | 2,55 | 0,45 | 0,89 | 12,8 |
| Sous-équipé | 10 | 13 | Chaîne d'éclairs | 0,64 | 0,43 | 1,29 | 0,10 | 0,20 | 5,04 |
| Sous-équipé | 20 | 19 | Chaîne d'éclairs | 0,94 | 0,63 | 1,89 | 0,13 | 0,26 | 3,16 |
| Sous-équipé | 40 | 34 | Éclair vif | 1,51 | 1,01 | 3,02 | 0,14 | 0,28 | 2,87 |
| Sous-équipé | 60 | 53 | Éclair vif | 3,93 | 2,62 | 7,85 | 0,29 | 0,59 | 2,59 |
| Sous-équipé | 90 | 100 | Éclair vif | 19,0 | 12,7 | 38,0 | 1,31 | 2,62 | 7,73 |
| Sous-équipé | 120 | 100 | Éclair vif | 107 | 71,5 | 214 | 6,94 | 13,9 | 4,69 |
| Équipé | 1 | 1 | Éclair vif | 1,35 | 0,90 | 2,70 | 0,45 | 0,91 | 12,3 |
| Équipé | 10 | 13 | Chaîne d'éclairs | 0,55 | 0,37 | 1,11 | 0,09 | 0,17 | 5,47 |
| Équipé | 20 | 19 | Chaîne d'éclairs | 0,94 | 0,63 | 1,89 | 0,12 | 0,25 | 4,87 |
| Équipé | 40 | 34 | Éclair vif | 1,52 | 1,01 | 3,03 | 0,14 | 0,27 | 5,69 |
| Équipé | 60 | 53 | Éclair vif | 3,09 | 2,06 | 6,18 | 0,20 | 0,40 | 7,55 |
| Équipé | 90 | 100 | Éclair vif | 18,0 | 12,0 | 36,0 | 1,28 | 2,55 | 8,12 |
| Équipé | 120 | 100 | Éclair vif | 110 | 73,5 | 221 | 7,38 | 14,8 | 5,68 |
| Sur-équipé | 1 | 1 | Éclair vif | 0,88 | 0,59 | 1,76 | 0,29 | 0,57 | 52,6 |
| Sur-équipé | 10 | 13 | Chaîne d'éclairs | 0,43 | 0,29 | 0,86 | 0,06 | 0,12 | 12,7 |
| Sur-équipé | 20 | 19 | Chaîne d'éclairs | 0,66 | 0,44 | 1,33 | 0,08 | 0,16 | 8,23 |
| Sur-équipé | 40 | 34 | Éclair vif | 1,62 | 1,08 | 3,23 | 0,10 | 0,20 | 5,36 |
| Sur-équipé | 60 | 53 | Éclair vif | 3,35 | 2,23 | 6,69 | 0,22 | 0,43 | 5,96 |
| Sur-équipé | 90 | 100 | Éclair vif | 16,6 | 11,0 | 33,1 | 1,11 | 2,22 | 5,76 |
| Sur-équipé | 120 | 100 | Éclair vif | 93,5 | 62,4 | 187 | 5,70 | 11,4 | 5,33 |

</details>

## Mêlée — Manuel du chevalier, Colosse

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,05 · 4,68 s | 🟥 2,23 · 2,20 s | 🟥 4,83 · 1,39 s | 🟥 20,0 · 0,80 s | 🟥 75,6 · 0,56 s | 🟥 506 · 0,39 s | 🟥 3166 · 0,30 s |
| Nu | 🟨 1,05 · 4,68 s | 🟨 0,44 · 4,44 s | 🟨 0,81 · 6,32 s | 🟨 1,88 · 6,05 s | 🟨 3,55 · 5,59 s | 🟥 19,5 · 4,04 s | 🟥 106 · 2,97 s |
| Sous-équipé | 🟩 1,03 · 12,1 s | 🟨 0,42 · 9,98 s | 🟩 0,76 · 11,5 s | 🟩 1,71 · 18,9 s | 🟩 2,92 · 15,5 s | 🟥 14,7 · 16,9 s | 🟥 67,9 · 10,6 s |
| Équipé | 🟩 1,20 · 12,2 s | 🟦 0,40 · 10,5 s | 🟩 0,74 · 16,8 s | 🟩 1,50 · 27,2 s | 🟩 2,32 · 16,7 s | 🟥 13,2 · 14,0 s | 🟥 58,9 · 12,3 s |
| Sur-équipé | 🟩 0,86 · 2344 s | 🟦 0,33 · 37,1 s | 🟩 0,60 · 47,8 s | 🟩 1,43 · 26,0 s | 🟩 2,89 · 36,8 s | 🟥 15,0 · 13,8 s | 🟥 76,5 · 13,4 s |

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
| Sous-équipé | 10 | 13 | Frappe lourde | 0,42 | 0,28 | 0,85 | 0,11 | 0,22 | 9,98 |
| Sous-équipé | 20 | 19 | Frappe lourde | 0,76 | 0,50 | 1,51 | 0,22 | 0,43 | 11,5 |
| Sous-équipé | 40 | 34 | Frappe lourde | 1,71 | 1,14 | 3,43 | 0,49 | 0,97 | 18,9 |
| Sous-équipé | 60 | 53 | Frappe lourde | 2,92 | 1,94 | 5,83 | 0,62 | 1,25 | 15,5 |
| Sous-équipé | 90 | 100 | Frappe lourde | 14,7 | 9,79 | 29,4 | 2,87 | 5,75 | 16,9 |
| Sous-équipé | 120 | 100 | Frappe lourde | 67,9 | 45,3 | 136 | 15,7 | 31,5 | 10,6 |
| Équipé | 1 | 1 | Frappe lourde | 1,20 | 0,80 | 2,39 | 0,41 | 0,82 | 12,2 |
| Équipé | 10 | 13 | Frappe lourde | 0,40 | 0,27 | 0,80 | 0,10 | 0,19 | 10,5 |
| Équipé | 20 | 19 | Frappe lourde | 0,74 | 0,49 | 1,48 | 0,20 | 0,40 | 16,8 |
| Équipé | 40 | 34 | Frappe lourde | 1,50 | 1,00 | 3,01 | 0,33 | 0,66 | 27,2 |
| Équipé | 60 | 53 | Frappe lourde | 2,32 | 1,55 | 4,64 | 0,52 | 1,05 | 16,7 |
| Équipé | 90 | 100 | Frappe lourde | 13,2 | 8,83 | 26,5 | 2,26 | 4,52 | 14,0 |
| Équipé | 120 | 100 | Frappe lourde | 58,9 | 39,2 | 118 | 11,6 | 23,3 | 12,3 |
| Sur-équipé | 1 | 1 | Frappe lourde | 0,86 | 0,57 | 1,72 | 0,28 | 0,57 | 2344 |
| Sur-équipé | 10 | 13 | Frappe lourde | 0,33 | 0,22 | 0,67 | 0,07 | 0,13 | 37,1 |
| Sur-équipé | 20 | 19 | Frappe lourde | 0,60 | 0,40 | 1,20 | 0,12 | 0,24 | 47,8 |
| Sur-équipé | 40 | 34 | Frappe lourde | 1,43 | 0,95 | 2,85 | 0,38 | 0,76 | 26,0 |
| Sur-équipé | 60 | 53 | Frappe lourde | 2,89 | 1,93 | 5,78 | 0,55 | 1,10 | 36,8 |
| Sur-équipé | 90 | 100 | Frappe lourde | 15,0 | 10,0 | 30,1 | 3,33 | 6,67 | 13,8 |
| Sur-équipé | 120 | 100 | Frappe lourde | 76,5 | 51,0 | 153 | 18,4 | 36,7 | 13,4 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
