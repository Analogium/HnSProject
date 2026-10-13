# Banc d'équilibrage

<!-- Fichier généré par tools/balance.sh — ne pas éditer à la main. -->

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
| niveau | 1 | 14 | 21 | 36 | 58 | 100 | 100 |

## Sort — Manuel de la foudre, Esprit d'orage

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,36 · 4,68 s | 🟥 2,27 · 2,20 s | 🟥 4,01 · 1,39 s | 🟥 12,6 · 0,80 s | 🟥 39,8 · 0,56 s | 🟥 226 · 0,39 s | 🟥 1310 · 0,30 s |
| Nu | 🟨 1,36 · 4,68 s | 🟥 0,64 · 2,20 s | 🟥 0,77 · 1,62 s | 🟥 1,65 · 1,21 s | 🟥 4,00 · 1,33 s | 🟥 22,7 · 2,20 s | 🟥 132 · 1,68 s |
| Sous-équipé | 🟩 1,35 · 26,0 s | 🟨 0,62 · 6,18 s | 🟥 0,76 · 3,51 s | 🟨 1,61 · 4,37 s | 🟨 3,36 · 5,69 s | 🟥 14,7 · 10,2 s | 🟥 84,6 · 7,17 s |
| Équipé | 🟩 1,31 · 21,7 s | 🟨 0,57 · 5,64 s | 🟨 0,69 · 7,16 s | 🟨 1,30 · 7,77 s | 🟩 2,55 · 12,2 s | 🟥 14,1 · 11,9 s | 🟥 71,2 · 7,99 s |
| Sur-équipé | 🟩 1,08 · ∞ s | 🟩 0,63 · 129 s | 🟦 0,41 · 40,8 s | 🟩 1,04 · 17,0 s | 🟨 3,14 · 11,5 s | 🟥 14,1 · 9,10 s | 🟥 128 · 11,3 s |

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
| Nu | 10 | 14 | Chaîne d'éclairs | 0,64 | 0,43 | 1,29 | 0,07 | 0,15 | 2,20 |
| Nu | 20 | 21 | Éclair vif | 0,77 | 0,51 | 1,53 | 0,11 | 0,21 | 1,62 |
| Nu | 40 | 36 | Éclair vif | 1,65 | 1,10 | 3,29 | 0,19 | 0,38 | 1,21 |
| Nu | 60 | 58 | Éclair vif | 4,00 | 2,67 | 8,00 | 0,46 | 0,92 | 1,33 |
| Nu | 90 | 100 | Éclair vif | 22,7 | 15,2 | 45,5 | 2,60 | 5,21 | 2,20 |
| Nu | 120 | 100 | Éclair vif | 132 | 87,8 | 263 | 15,1 | 30,2 | 1,68 |
| Sous-équipé | 1 | 1 | Éclair vif | 1,35 | 0,90 | 2,70 | 0,46 | 0,93 | 26,0 |
| Sous-équipé | 10 | 14 | Chaîne d'éclairs | 0,62 | 0,41 | 1,24 | 0,07 | 0,14 | 6,18 |
| Sous-équipé | 20 | 21 | Éclair vif | 0,76 | 0,50 | 1,51 | 0,10 | 0,19 | 3,51 |
| Sous-équipé | 40 | 36 | Éclair vif | 1,61 | 1,07 | 3,21 | 0,18 | 0,36 | 4,37 |
| Sous-équipé | 60 | 58 | Éclair vif | 3,36 | 2,24 | 6,72 | 0,33 | 0,65 | 5,69 |
| Sous-équipé | 90 | 100 | Éclair vif | 14,7 | 9,78 | 29,3 | 1,20 | 2,41 | 10,2 |
| Sous-équipé | 120 | 100 | Éclair vif | 84,6 | 56,4 | 169 | 7,99 | 16,0 | 7,17 |
| Équipé | 1 | 1 | Éclair vif | 1,31 | 0,88 | 2,63 | 0,44 | 0,88 | 21,7 |
| Équipé | 10 | 14 | Chaîne d'éclairs | 0,57 | 0,38 | 1,14 | 0,07 | 0,13 | 5,64 |
| Équipé | 20 | 21 | Éclair vif | 0,69 | 0,46 | 1,38 | 0,09 | 0,17 | 7,16 |
| Équipé | 40 | 36 | Éclair vif | 1,30 | 0,87 | 2,60 | 0,14 | 0,27 | 7,77 |
| Équipé | 60 | 58 | Éclair vif | 2,55 | 1,70 | 5,11 | 0,22 | 0,44 | 12,2 |
| Équipé | 90 | 100 | Éclair vif | 14,1 | 9,39 | 28,2 | 1,33 | 2,65 | 11,9 |
| Équipé | 120 | 100 | Éclair vif | 71,2 | 47,5 | 142 | 5,66 | 11,3 | 7,99 |
| Sur-équipé | 1 | 1 | Éclair vif | 1,08 | 0,72 | 2,16 | 0,35 | 0,69 | ∞ |
| Sur-équipé | 10 | 14 | Chaîne d'éclairs | 0,63 | 0,42 | 1,26 | 0,06 | 0,13 | 129 |
| Sur-équipé | 20 | 21 | Éclair vif | 0,41 | 0,27 | 0,82 | 0,03 | 0,07 | 40,8 |
| Sur-équipé | 40 | 36 | Éclair vif | 1,04 | 0,69 | 2,08 | 0,10 | 0,20 | 17,0 |
| Sur-équipé | 60 | 58 | Éclair vif | 3,14 | 2,09 | 6,28 | 0,29 | 0,59 | 11,5 |
| Sur-équipé | 90 | 100 | Éclair vif | 14,1 | 9,42 | 28,3 | 1,14 | 2,29 | 9,10 |
| Sur-équipé | 120 | 100 | Éclair vif | 128 | 85,1 | 255 | 12,3 | 24,7 | 11,3 |

</details>

## Mêlée — Manuel du chevalier, Colosse

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 0,94 · 4,68 s | 🟥 1,94 · 2,20 s | 🟥 4,13 · 1,39 s | 🟥 16,8 · 0,80 s | 🟥 62,7 · 0,56 s | 🟥 415 · 0,39 s | 🟥 2583 · 0,30 s |
| Nu | 🟨 0,94 · 4,68 s | 🟨 0,27 · 4,77 s | 🟨 0,46 · 7,91 s | 🟨 0,97 · 6,86 s | 🟨 2,39 · 6,28 s | 🟥 12,8 · 4,04 s | 🟥 68,2 · 2,97 s |
| Sous-équipé | 🟩 0,84 · 22,7 s | 🟦 0,26 · 11,8 s | 🟦 0,45 · 16,9 s | 🟩 0,85 · 25,3 s | 🟩 1,97 · 41,9 s | 🟨 5,92 · 27,3 s | 🟥 35,6 · 19,5 s |
| Équipé | 🟩 0,97 · 18,6 s | 🟦 0,26 · 13,8 s | 🟦 0,43 · 31,9 s | 🟩 0,76 · 99,6 s | 🟩 1,69 · 47,1 s | 🟨 6,13 · 30,3 s | 🟥 47,8 · 19,8 s |
| Sur-équipé | 🟩 0,72 · ∞ s | 🟦 0,17 · 92,1 s | 🟦 0,30 · 188 s | 🟩 0,64 · 114 s | 🟩 1,84 · 58,9 s | 🟨 6,87 · 26,2 s | 🟥 36,4 · 17,7 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Frappe lourde | 0,94 | 0,62 | 1,87 | 0,53 | 1,05 | 4,68 |
| Débutant | 10 | 1 | Frappe lourde | 1,94 | 1,29 | 3,88 | 1,09 | 2,19 | 2,20 |
| Débutant | 20 | 1 | Frappe lourde | 4,13 | 2,75 | 8,25 | 2,32 | 4,64 | 1,39 |
| Débutant | 40 | 1 | Frappe lourde | 16,8 | 11,2 | 33,5 | 9,43 | 18,9 | 0,80 |
| Débutant | 60 | 1 | Frappe lourde | 62,7 | 41,8 | 125 | 35,3 | 70,5 | 0,56 |
| Débutant | 90 | 1 | Frappe lourde | 415 | 277 | 831 | 234 | 467 | 0,39 |
| Débutant | 120 | 1 | Frappe lourde | 2583 | 1722 | 5165 | 1453 | 2905 | 0,30 |
| Nu | 1 | 1 | Frappe lourde | 0,94 | 0,62 | 1,87 | 0,53 | 1,05 | 4,68 |
| Nu | 10 | 14 | Frappe lourde | 0,27 | 0,18 | 0,53 | 0,15 | 0,30 | 4,77 |
| Nu | 20 | 21 | Frappe lourde | 0,46 | 0,31 | 0,93 | 0,26 | 0,52 | 7,91 |
| Nu | 40 | 36 | Frappe lourde | 0,97 | 0,64 | 1,93 | 0,49 | 0,99 | 6,86 |
| Nu | 60 | 58 | Frappe lourde | 2,39 | 1,59 | 4,78 | 1,15 | 2,29 | 6,28 |
| Nu | 90 | 100 | Frappe lourde | 12,8 | 8,54 | 25,6 | 6,13 | 12,3 | 4,04 |
| Nu | 120 | 100 | Frappe lourde | 68,2 | 45,5 | 136 | 32,7 | 65,4 | 2,97 |
| Sous-équipé | 1 | 1 | Frappe lourde | 0,84 | 0,56 | 1,68 | 0,47 | 0,94 | 22,7 |
| Sous-équipé | 10 | 14 | Frappe lourde | 0,26 | 0,17 | 0,52 | 0,13 | 0,25 | 11,8 |
| Sous-équipé | 20 | 21 | Frappe lourde | 0,45 | 0,30 | 0,90 | 0,25 | 0,49 | 16,9 |
| Sous-équipé | 40 | 36 | Frappe lourde | 0,85 | 0,57 | 1,70 | 0,40 | 0,80 | 25,3 |
| Sous-équipé | 60 | 58 | Frappe lourde | 1,97 | 1,31 | 3,94 | 0,82 | 1,65 | 41,9 |
| Sous-équipé | 90 | 100 | Frappe lourde | 5,92 | 3,94 | 11,8 | 1,99 | 3,99 | 27,3 |
| Sous-équipé | 120 | 100 | Frappe lourde | 35,6 | 23,8 | 71,3 | 12,8 | 25,5 | 19,5 |
| Équipé | 1 | 1 | Frappe lourde | 0,97 | 0,65 | 1,94 | 0,46 | 0,92 | 18,6 |
| Équipé | 10 | 14 | Frappe lourde | 0,26 | 0,17 | 0,52 | 0,12 | 0,25 | 13,8 |
| Équipé | 20 | 21 | Frappe lourde | 0,43 | 0,29 | 0,86 | 0,23 | 0,46 | 31,9 |
| Équipé | 40 | 36 | Frappe lourde | 0,76 | 0,50 | 1,51 | 0,33 | 0,66 | 99,6 |
| Équipé | 60 | 58 | Frappe lourde | 1,69 | 1,13 | 3,38 | 0,61 | 1,22 | 47,1 |
| Équipé | 90 | 100 | Frappe lourde | 6,13 | 4,09 | 12,3 | 1,83 | 3,67 | 30,3 |
| Équipé | 120 | 100 | Frappe lourde | 47,8 | 31,9 | 95,6 | 16,8 | 33,6 | 19,8 |
| Sur-équipé | 1 | 1 | Frappe lourde | 0,72 | 0,48 | 1,43 | 0,35 | 0,69 | ∞ |
| Sur-équipé | 10 | 14 | Frappe lourde | 0,17 | 0,12 | 0,35 | 0,08 | 0,16 | 92,1 |
| Sur-équipé | 20 | 21 | Frappe lourde | 0,30 | 0,20 | 0,59 | 0,13 | 0,25 | 188 |
| Sur-équipé | 40 | 36 | Frappe lourde | 0,64 | 0,43 | 1,28 | 0,25 | 0,51 | 114 |
| Sur-équipé | 60 | 58 | Frappe lourde | 1,84 | 1,22 | 3,67 | 0,59 | 1,18 | 58,9 |
| Sur-équipé | 90 | 100 | Frappe lourde | 6,87 | 4,58 | 13,7 | 2,94 | 5,88 | 26,2 |
| Sur-équipé | 120 | 100 | Frappe lourde | 36,4 | 24,3 | 72,9 | 12,4 | 24,8 | 17,7 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
