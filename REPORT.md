# Génération de configurations pour le jeu de la Vie

## Ce qu'on a fait

Le travail s'est fait dans deux fichiers principaux :

- **`test/cram/symbolic/configuration_gen.t/constraints.wat`** : contient les primitives du jeu de la Vie réécrites en WebAssembly (`step`, `is_alive`, `count_alive_neighbours`, etc.), un mécanisme d'initialisation de la grille avec des cellules symboliques, et 17 contraintes qui modélisent différentes propriétés à vérifier au tour suivant.

- **`scripts/to_life.ml`** : un script OCaml qui prend la sortie d'Owi (le bloc `model { ... }` qu'il imprime quand il trouve une configuration valide) et la convertit en fichier `.life`, le format compris par le simulateur graphique de l'autre partie du projet.

Un wrapper bash (`scripts/gen_life.sh`) automatise tout le pipeline.

## Comment ça marche concrètement

Le principe général est le même pour toutes les contraintes :

1. On initialise la grille en remplissant chaque cellule avec un symbole indépendant.
2. On applique un `step` du jeu de la Vie sur cette grille symbolique.
3. On exprime la contrainte sous forme d'une expression booléenne sur la grille après step.
4. Si la contrainte est satisfaite, on déclenche `unreachable`. Owi explore tous les chemins symboliques, trouve une assignation des symboles qui mène à cet `unreachable`, et la renvoie sous forme de modèle.

Pour générer une configuration et la visualiser :

```bash
chmod +x scripts/gen_life.sh
./scripts/gen_life.sh > ./scripts/solution.life
# tape le numéro de la contrainte voulu quand demandé
```

Puis on charge `./scripts/solution.life` dans l'interface graphique pour vérifier visuellement que la propriété est bien satisfaite au tour suivant.

## Les contraintes implémentées

Toutes les contraintes proposées dans le `README.md`

## Points subtils de cette partie du projet

### Les `if` symboliques tuent les performances

C'est le piège principal de toute la démarche. Au départ, le code était écrit naïvement avec des `if` qui branchaient sur le contenu des cellules. Sur une grille 2×3 ça passait, mais sur une 5×5 mon ordi crashait.

L'explication : chaque `if` dont la condition dépend d'une valeur symbolique force Owi à dupliquer le chemin d'exécution pour explorer les deux branches. Avec 25 symboles passant dans plusieurs `if` (dans `step` puis dans la contrainte), on se retrouve avec des millions de chemins.

La solution : réécrire sans `if` symboliques, avec des expressions booléennes pures (`i32.and`, `i32.or`). Owi construit alors une seule grosse formule au lieu de forker l'exécution, et le solveur SMT derrière est conçu pour gérer ça efficacement. Pareil pour les `return` dans les boucles, remplacés par des agrégations `AND`/`OR` sur toute la grille.

Résultat : le programme tourne maintenant en quelques secondes.

### Le buffer double dans `print_initial_grid`

Le `step` fait un `swap_buffers` à la fin pour basculer entre "current" et "next". Du coup, après une étape, ce qu'on voit comme "la grille actuelle" est en fait le résultat du calcul, et l'état initial est dans l'autre buffer. `print_initial_grid` doit faire un `swap_buffers` avant d'afficher pour retrouver l'état initial.

### Le format de sortie d'Owi

Owi imprime un bloc `model { ... }` quand il trouve une configuration valide, c'est lui qui contient les valeurs concrètes des symboles. Il génère aussi un fichier XML au format SoSy-Lab, mais on a fini par parser le bloc texte avec une regex OCaml parce que le XML s'est révélé compliqué à exploiter (voir section suivante).

## Difficultés rencontrées et ce qui n'a pas marché

### Le testcase XML

Owi génère un fichier XML à chaque exécution réussie, dans `test/cram/symbolic/configuration_gen.t/test-suite/testcase-1.xml`.

En pratique, c'est pénible car le fichier n'est pas régénéré si la contrainte n'est pas satisfaite, donc on risque de lire un ancien résultat sans s'en rendre compte. Après plusieurs essaies, on a choisi de parsing le bloc `model { ... }` directement dans la sortie standard. Beaucoup plus prévisible.

### On a dû mettre toute la grille en symbolique, même là où ce n'était pas nécessaire

Pour certaines contraintes (1, 2, 6, 7), il aurait suffi de symboliser une petite zone : le voisinage 3×3 autour de la cellule cible pour 1 et 2, un rectangle autour de la ligne/colonne pour 6 et 7. C'est ce que on avait fait au départ, avec des fonctions dédiées (`init_neighbors_as_symbols`, mode "rectangle" de `init_rectangle_as_symbols`).

Le problème est apparu au moment de générer le `.life`. Le script `to_life.ml` doit savoir où placer chaque symbole dans la grille. Avec une init globale, c'est trivial : le symbole `i*w + j` correspond à la cellule `(i, j)`. Mais avec une init partielle, il faut connaître la zone symbolisée et passer ces coordonnées au script, ce qui duplique des infos déjà présentes dans le `.wat` et devient fragile.

On a donc choisi de symboliser systématiquement toute la grille.

**Important** : on a laissé dans le `.wat` les fonctions `init_neighbors_as_symbols` et le mode "rectangle" de `init_rectangle_as_symbols`, même si elles ne sont plus appelées. C'est volontaire : on voulait montrer qu'on avait bien compris qu'il était possible de ne symboliser qu'une sous-partie de la grille, et que on avait su écrire les bonnes abstractions pour ça.

## Comment exécuter le programme

### Prérequis

Aucun paquet opam supplémentaire n'a été nécessaire au-delà de ce qui était déjà dans le projet.

### Génération d'une configuration

Depuis la racine du projet :

```bash
./scripts/gen_life.sh > ./scripts/solution.life
```

Le script affiche `Entrez le numéro de la contrainte :` taper un numéro entre 1 et 17, puis Entrée. Le fichier `solution.life` produit peut ensuite être chargé dans le simulateur graphique pour vérifier visuellement la propriété.

Si la contrainte est insatisfiable, le script affiche un message clair et n'écrit pas de fichier.

### Si on veut tester manuellement sans le wrapper

```bash
dune exec -- ono symbolic test/cram/symbolic/configuration_gen.t/constraints.wat 2>&1 \
  | ocaml -I +str str.cma scripts/to_life.ml 5 5 \
  > ./scripts/solution.life
```

### Ajuster les paramètres des contraintes

Certaines contraintes ont des paramètres définis comme globales dans `constraints.wat` :
- `TARGET_I`, `TARGET_J` pour les contraintes 1 et 2 (la cellule cible)
- `TARGET_I_2`, `TARGET_J_2` pour les contraintes 6 et 7 (le deuxième point de la ligne/colonne)
- `NUMBER_OF_ALIVE_CELLS` pour la contrainte 8
- `DIAGONAL_LENGTH` pour la contrainte 17

Pour les modifier, éditer directement les `(global ...)` en début du fichier.

### Ajuster la taille de la grille

Pareil : changer les valeurs de `$w` et `$h` au début de `constraints.wat`. Le script `gen_life.sh` lit automatiquement ces valeurs avec un `grep`, donc rien d'autre à toucher.
