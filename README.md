# Algorithmes des reseaux

Ce dépôt contient une liste d'exercices pratiques pour apprendre à utiliser l'API socket du langage C et ainsi implémenter les algorithmes vus en CM et TD.
Les exercices sont progressifs et doivent être réalisés dans l'ordre.
💡 Certains exercices nécessitent une connectivité IPv6 locale pour fonctionner.

## Compilation

Un ou des squelettes de programme C sont fournis pour chaque exercice.
Pour les compiler, vous pouvez simplement utiliser la commande `make`.

## Tests locaux natifs

Un script de tests est fourni pour chaque exercice.
Vous pouvez lancer les tests avec la commande :

```sh
./test.sh
```

Suivant les exercices, plusieurs tests sont réalisés et un `OK` indique que le test est réussi.
Sinon, un court message vous indique la raison de l'échec, vous permettant de corriger les erreurs dans votre programme.

Vous pouvez lancer un test spécifique en indiquant son numéro :

```sh
./test.sh 1.1
./test.sh 3.2
...
```

L'exécution des tests en local nécessite les outils suivants :

- `valgrind` (cet outil n'existe pas sur OSX, vous pouvez néanmoins utiliser l'image docker, cf. ci-dessous)
- `netcat-openbsd`

## Tests locaux sur docker

Vous pouvez tester vos programmes dans une image `docker` (nécessite d'avoir `docker` installé sur votre système).

L'image `docker` configurée pour les exercices peut être récupérée localement et instanciée dans un conteneur via les commandes :

```sh
# utilisez votre login et mdp du serveur git.unistra.fr
docker login registry.app.unistra.fr

# placez vous à la racine du dossier qui contient ce README !
cd chemin/vers/votre/copie/locale/du/dépôt/git

# instanciez le conteneur
docker run --name algores -e LANG=C.UTF-8 --rm -it -v $PWD:/home/alice registry.app.unistra.fr/montavont/img-docker/algores

# cherchez la définition des options avec --help...
```

Lorsque vous aurez besoin de manipuler plusieurs terminaux, vous pouvez utiliser la commande suivante (une fois le conteneur, nommé ici *algores*, exécuté avec la commande précédente) :

```sh
docker exec -it -e LANG=C.UTF-8 algores bash
```

Vous pouvez aussi ajouter l'option `-u 0` si vous souhaiter vous connectez au conteneur avec les droits administrateur (par exemple pour ajouter des paquets au conteneur).

### Si vous utilisez VS Code

Vous pouvez directement déveloper dans un [Dev Container](https://code.visualstudio.com/docs/devcontainers/containers).
Pour cela il suffit de taper <kbd>Ctrl</kbd> + <kbd>Maj</kbd> + <kbd>P</kbd> (ou <kbd>Cmd</kbd> + <kbd>Maj</kbd> + <kbd>P</kbd> sur MacOs) et d'entrer "Conteneurs de développement: Reconstruire et rouvrir dans le conteneur".

## Tests sur GitLab

Les tests peuvent également être directement exécutés par `gitlab` dans un conteneur `docker` exécuté sur un *runner* de GitLab.
Tout `commit/push` sur l'un des fichiers source provoque sa compilation et l'exécution du script de tests.
Vous pouvez configurer le dépôt GitLab pour être notifié en cas de succès (ou d'échec) des tests.

Sur l'interface de GitLab, il suffit d'aller dans `build/pipeline` pour visualiser le résultat des tests.
