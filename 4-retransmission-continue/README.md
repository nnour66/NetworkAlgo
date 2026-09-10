# Algorithmes des Réseaux - Retransmission Continue

Ce TP a pour objectif de vous faire implémenter les mécanismes d'anticipation à l'émission (_pipelining_) et de retransmission continue (e.g., _Go-Back-N_) vus en cours et en TD, en utilisant des sockets UDP.
En plus de l'émetteur et du récepteur habituels, un troisième programme, le `medium`, simulera une liaison avec pertes pour tester la fiabilité de votre implémentation.

## Objectifs

- Implémenter l'anticipation à l'émission afin d'améliorer l'efficacité de la transmission sur une liaison sujette à des pertes.
- Mettre en œuvre un mécanisme de retransmission continue pour garantir l'intégrité des données en cas de perte.

## Marche à Suivre

Il est recommandé de réutiliser et d'adapter le code développé à l'exercice précédent.
Seul l'émetteur nécessite des modifications conséquentes.
Le récepteur ne nécessite que des adaptations mineures : la fenêtre de réception reste de taille 1 et le modèle de perte inchangé.

### Fenêtre d'émission (glissante)

L'émetteur utilise une fenêtre d'émission de taille `WNDSIZE` (définie dans `common.h`)
Ce mécanisme lui permet d'envoyer jusqu'à `WNDSIZE` messages avant d'exiger la réception d'un accusé de réception.
Chaque accusé de réception, en acquittant de nouvelles données, libère de la place dans la fenêtre d'émission permettant l'envoi de nouvelles données.
Les accusés de réception sont désormais cumulatifs : recevoir l'accusé de réception numéro $X$ signifie que tous les messages numérotés jusqu'à $X-1$ ont bien été reçus, et que le récepteur attend désormais le message numéroté $X$ (cela ne veut pas dire que l'émetteur va envoyer $X$ en recevant cet accusé).

Exemple : Si la taille de la fenêtre est de 4, l'émetteur peut envoyer les messages 0 à 3.
Après réception d'un accusé de réception avec le numéro 3, l'émetteur sait que les messages 0 à 2 ont été reçus et qu'il peut décaler la fenêtre pour envoyer les messages 4, 5 et 6.

La gestion des accusés de réception doit prendre en compte une numérotation modulo $N$ (défini dans `common.h`) des numéros de séquence.
À vous de définir l'ensemble des variables et structures nécessaires au bon fonctionnement de ce modèle de retransmission.
Pour simplifier l'exercice, vous pouvez utiliser des variables globales.

### Gestion des pertes

Comme dans l'exercice précédent, les pertes de messages (les données) sont gérées à l'aide d'un temporisateur.
En cas d'expiration du temporisateur, tous les messages stockés dans la fenêtre d'émission seront retransmis.

Exemple : si la fenêtre d'émission contient les messages 3, 4, 5 et 6 et que le temporisateur expire, l'émetteur doit retransmettre ces quatre messages dans l'ordre initial. La fenêtre d'émission joue donc un rôle essentiel : elle conserve une copie des messages non encore acquittés, afin de pouvoir les retransmettre en cas de perte ou de dépassement du délai d’attente.

Implémentez cela simplement, i.e. de la même manière que dans l'exercice précédent : si après un délai pré-défini assez large (par exemple 2 secondes), l'émetteur est toujours bloqué sur une lecture d'accusé de réception, alors il retransmet l'ensemble des données en attente (même si des accusés de réception arrivent en //). 

## Test des programmes

Il vous faut trois terminaux (un par programme) pour tester vos programmes avec les commandes suivantes :

- Définissez les variables d'environnement pour les ports de communication :

```sh
export RECEIV_PORT= # port de votre choix 
export MEDIUM_PORT= # port de votre choix 
```

- Lancez le récepteur dans le premier terminal :

```sh
./gbn-receiver > titi
```

- Lancez le médium dans le second terminal (ici $P = 0,3$) :

```sh
./medium 0.3
```

- Enfin, lancez les commandes suivantes dans un troisième terminal :

```sh
dd if=/dev/random of="toto" bs=8k count=2 2> /dev/null
./gbn-sender < toto
```

À la fin de l'exécution du programme `gbn-sender`, quittez les programmes `medium` et `gbn-receiver`, puis vérifiez que les fichiers `toto` et `titi` sont identiques :

```sh
cmp toto titi
```

## Questions

1. Comparez le temps d'exécution du programme `gbn-sender` avec celui de l'exercice précédent (via la commande `time`) pour une même taille de fichier et un même taux d'erreur. Que pouvez-vous en déduire ?
2. Que se passe-t-il si la taille de la fenêtre d'émission est égale à 1 ?
3. Quelle est la taille minimale de l'espace de numérotation (modulo) en fonction de la taille des fenêtres d'émission et de réception ?

## Validation

Votre programme doit réussir tous les tests sur GitLab avant de passer à l'exercice suivant.
Pour cette validation à distance, il faut `commit/push` votre fichier source sur le dépôt, ce qui déclenchera le *pipeline* de compilation et de tests.
