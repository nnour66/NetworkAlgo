# Algorithmes des réseaux - Serveur TCP

L'objectif de ce TP est de vous familiariser avec la création et la gestion d'un serveur TCP.
Vous allez compléter un programme `server` capable de recevoir un message texte via un socket TCP.

## Commande d'exécution

Le programme doit être exécuté avec le numéro de port local en argument :

```sh
./server <port_local>
```

## Exemple de sortie attendue

Lorsque le programme reçoit un message, la sortie doit être sous la forme suivante :

```sh
./server 10001
::ffff:127.0.0.1 1234 a envoyé : hello world
```

Dans cet exemple :

- `hello world` est le message reçu.
- `::ffff:127.0.0.1` est l'adresse IP de l'expéditeur.
- `1234` est le port source utilisé par l'expéditeur.

## Objectifs

- Créer un socket TCP.
- Comprendre le modèle client/serveur.
- Recevoir un message en TCP.

## Marche à suivre

Créez un socket TCP avec la primitive `socket()` qui supporte à la fois IPv4 et IPv6 (double pile).

Le protocole TCP met un temps non négligeable pour fermer un socket afin d'être sûr que tous les segments appartenant à la connexion qui vient de se terminer ne puissent pas être acceptés à tort par une nouvelle connexion avec le même quadruplet (adresse source, port source, adresse destination, port destination).
Cela permet également de s'assurer que l'hôte distant a bien terminé la connexion (cf. CM et l'exercice 1 du TD4).
Cependant, ce mécanisme ralentit significativement les tests qui utilisent le même quadruplet à plusieurs reprises. 
Pour éviter cette attente, activez l'option `SO_REUSEADDR` sur le socket :

```c
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);
```

Consultez la page de manuel (`man 7 socket`) pour plus de détails sur cette primitive.

Ensuite, complétez une structure d'adresse correspondant à l'hôte local, votre serveur, avec `getaddrinfo()`, puis liez le socket avec cette structure d'adresse avec la primitive `bind()`.

💡 N'oubliez pas de gérer les erreurs possibles sur les fonctions et primitives utilisées.

Le socket que vous venez de configurer ne sera utilisé que pour accepter les connexions entrantes (donc recevoir les _messages de contrôle_ *SYN* de TCP). Aucune _donnée utile_ ne sera échangée sur ce socket. 

Une telle configuration (écoute passive en attente de connexion entrante active) est réalisée avec la primitive :

```c
int listen(int socket, int backlog);
```

Acceptez une connexion entrante avec `accept()`, qui retourne un nouveau socket dédié à cette connexion  avec le client :

```c
int accept(int socket, struct sockaddr *restrict address, socklen_t *restrict address_len);
```

En cas de succès, vous disposerez désormais de deux sockets :

- Le socket initial, utilisé pour accepter de nouvelles connexions (multi-clients).
- Le socket retourné par `accept()`, utilisé pour communiquer exclusivement avec le client connecté.

Enfin, utilisez la primitive `recv()` pour lire le message envoyé par le client sur le socket retourné par `accept()` :

```c
ssize_t recv (int socket, void *buffer, size_t length, int flags)
```

Obtenez les informations sur le client (adresse IP et port) à partir de la structure passée à `accept()` (utilisez une structure `struct sockaddr_storage`).

Convertissez ces informations en chaînes de caractères avec `getnameinfo()` pour les afficher.

Finalement, fermez les deux sockets via la primitive `close()`.

💡 N'oubliez pas de gérer les erreurs possibles sur les fonctions et primitives utilisées.

## Tests du programme

Exécutez votre programme dans un terminal.

Dans un autre terminal, utilisez `netcat` (commande `nc`) pour envoyer un message au serveur :

- Pour IPv4 :

```sh
printf "hello world" | nc -4 127.0.0.1 port_serveur -p port_local_netcat
```

- Pour IPv6 :

```sh
printf "hello world" | nc -6 ::1 port_server -p port_local_netcat
```

Vérifiez que les informations affichées par votre programme sont exactes.

Analysez le trafic réseau échangé avec un outil comme `tshark` ou `tcpdump`, par exemple :

```sh
tshark -i lo -f "tcp and ip6"
```

Identifiez la phase de connexion, l'envoi des données et la phase de fermeture. 
Quelles sont les options utilisées ?
Quels sont les numéros de séquence choisis initialement ? Ajoutez l'option `-V` pour consulter les entêtes complètes.

## Analyse de l'état TCP

Ouvrez un nouveau terminal et surveillez l'état de la connexion TCP avec `netstat` :

```sh
watch -n 1 netstat -tna
```

Exécutez votre programme dans un autre terminal et observez l'état de la connexion.

Copiez votre programme de l'exercice 5.1 dans le répertoire courant.
Modifiez ce programme pour inclure `sleep(10)` entre la connexion et l'envoi du message, puis après l'envoi.
Observez comment l'état TCP évolue.

## Questions

1. Quel socket est utilisé pour envoyer le message SYN/ACK lors de la phase de connexion ?
2. Quelle est l'utilité du second argument de la primitive `listen()` ?
3. Que se passe-t-il lorsqu'on utilise la primitive `accept()` sur un socket qui n'est pas en mode écoute ?
4. En UDP (mode paquet), supposons qu'un émetteur envoie un datagramme de 1024 octets alors que le récepteur ne lit que les 1000 premiers octets avec `recvfrom()`. Que se passe-t-il pour les 24 octets restants ? Observe-t-on le même comportement avec TCP ? Pourquoi ?

## Validation

Votre programme doit obligatoirement passer tous les tests sur GitLab avant de passer à l'exercice suivant.
Pour ce faire, utilisez les actions `commit` et `push` sur vos fichiers sources sur le dépôt GitLab, ce qui déclenchera le pipeline de compilation et de tests.
