# Algorithmes des Réseaux - Envoyer et Attendre

Dans cet exercice, le récepteur n'est pas toujours prêt à recevoir car le traitement de données reçues prend un temps non négligeable.
Si l'expéditeur envoie de nouvelles données alors que le récepteur n'est pas prêt à les réceptionner, il y a risque de pertes.
L'objectif de ce TP est d'implémenter le modèle de communication *envoyer et attendre* présenté en cours et en TD, en utilisant un socket UDP, afin de s'adapter aux capacités de traitement du récepteur : il s'agit de réaliser un __contrôle de flux__.

## Objectifs

- Transmettre de grandes quantités de données via UDP.
- Implémenter l'algorithme « envoyer et attendre » à l'aide des sockets.

## Commande d'exécution

Pour simplifier l'exécution des programmes, les adresses IP seront toutes fixées à l'adresse de boucle locale IPv6 (`::1`).
Le port de communication de l'émetteur est laissé à la discretion du système d'exploitation.
Le port de communication du récepteur est spécififé dans la variable d'environnement suivante :

```sh
RECEIV_PORT    # port du récepteur
```

En conséquence, le programme `sw-sender` ne prend pas d'argument.
Les données transmises sont celles lues sur l'entrée standard :

```sh
./sw-sender
```

Le programme `sw-receiver` prend en argument la durée (en sec.) pour le temporisateur.
Cela permet au programme de se terminer si aucune donnée n'est réceptionnée durant ce laps de temps.
Les données reçues sont écrites sur la sortie standard :

```sh
./sw-receiver <duration>
```

## Marche à suivre

### Programme récepteur

Dans le programme `sw-receiver`, commencez par créer un socket IPv6 / UDP.

Ensuite, ajustez la taille du tampon de réception du socket afin de provoquer des pertes en l'absence d'un mécanisme de contrôle de flux.
Ce tampon stocke les messages UDP reçus et non encore traités par un appel à `recvfrom()`.
Si des nouvelles données arrivent alors que le tampon est plein, ces dernières sont définitivement perdues.
Fixez sa taille à `BUFSIZE` octets (i.e. exactement la taille de vos tampons d'échange) en utilisant la primitive suivante :

```c
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen)
```

Utilisez la constante `SO_RCVBUF` pour `optname`.
Référez-vous au manuel des sockets (`man 7 socket`) pour plus de détails sur l'utilisation de cette primitive.

💡 La constante `BUFSIZE` est déjà définie dans le fichier `common.h`.

💡 Utilisez la macro `CHK()` pour gérer les erreurs sur cette primitive.

Complétez une structure d'adresse `struct sockaddr_in6` avec les paramètres locaux :
- l'adresse IPv6 locale est l'adresse de boucle locale (variable globale `in6addr_any`) ;
- le numéro de port local est récupéré depuis la variable d'environnement `RECEIV_PORT` et stocké dans la variable `local_port_str` sous la forme d'une chaîne de caractères. Vous pouvez le convertir en entier à l'aide de la fonction `conversion()` déjà définie dans le fichier `common.h`.

Liez maintenant le socket avec cette structure d'adresse via la primitive `bind()`.

💡 Utilisez la macro `CHK()` pour gérer les erreurs sur cette primitive.

Enfin, écrivez la boucle de réception :
1. Appelez la fonction `process_data()` (déjà présente dans le code) après chaque réception de données sur le socket pour simuler le temps de traitement ;
2. Affichez les données reçues et traitées sur la sortie standard ;
3. Envoyez un message vide à l'expéditeur pour lui signaler que vous êtes à nouveau « prêt à recevoir ».

💡 N'oubliez pas de gérer les erreurs possibles sur les fonctions `recvfrom()`, `sendto()` et `write()`.

### Programme émetteur

Créez un socket IPv6 / UDP puis complétez une structure `struct sockaddr_in6` avec les paramètres du récepteur.

Enfin, écrivez la boucle d'émission :
- envoyez sur le socket les données lues depuis l'entrée standard ;
- attendez la réception d'un message sur le socket avant l'envoi des données suivantes.

💡 N'oubliez pas de gérer les erreurs possibles sur les fonctions `read()`, sendto()` et `recvfrom()`.

## Test des programmes

- Définissez les variables d'environnement pour le port de communication du récepteur :

```sh
export RECEIV_PORT= # port de votre choix
```

- Lancez le programme `sw-receiver` dans un terminal avec une valeur élevée pour le temporisateur :

```sh
./sw-receiver 20 > titi
```

- Exécutez les commandes suivantes dans un second terminal :

```sh
dd if=/dev/random of="toto" bs=8k count=1 2> /dev/null
./sw-sender < toto
```

Lorsque les programmes sont terminés, vérifiez que les fichiers `toto` et `titi` sont identiques à l'aide de la commande :

```sh
cmp toto titi
```

Consultez les messages échangés avec un analyseur réseau (`wireshark, tshark, tcpdump`).

## Questions

1. Que se passerait-il si l'émetteur n'attendait pas la confirmation du récepteur avant d'envoyer le prochain message ?
2. Que se passe-t-il si l'on supprime l'appel à `setsockopt()` dans le récepteur ?
3. Quelle est la différence entre la taille du tampon définie par `BUFSIZE` et la taille du buffer du socket réglée par `SO_RCVBUF` ?

## Validation

Votre programme doit réussir tous les tests sur GitLab avant de passer à l'exercice suivant.
Pour cette validation à distance, il faut `commit/push` votre fichier source sur le dépôt, ce qui déclenchera le *pipeline* de compilation et de tests.
