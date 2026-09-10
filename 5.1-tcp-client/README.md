# Algorithmes des réseaux - Client TCP

Complétez le programme `client` pour envoyer le message `hello world` avec un socket TCP.

## Commande d'exécution

Le programme admet en argument l'adresse IP et le numéro de port de l'hôte distant à contacter :

```sh
./client <ip_dest> <port_dest>
```

## Objectifs

- Comprendre la phase d'initialisation et de terminaison d'une connexion TCP.
- Transmettre un message texte en TCP.

## Marche à suivre

Complétez une structure d'adresse correspondant à l'hôte distant avec la fonction `getaddrinfo()` puis créez un socket TCP avec la primitive `socket()`.
Votre programme doit être agnostique de la version du protocole IP utilisée.

💡 Pensez à la gestion des erreurs sur la fonction `getaddrinfo()` et la primitive `socket()`.

En TCP, avant de pouvoir transmettre un message, le client doit d'abord établir une connexion avec le serveur.
Cette étape consiste à réaliser la poignée de main de TCP (SYN, SYN/ACK, ACK), au cours duquel les deux extrémités échangent les informations nécessaires : numéros de séquence initiaux, options, etc.
La primitive `connect()` permet au client d'initier cette connexion vers le serveur identifié par son adresse IP et port (correctement renseignés dans une structure d'adresse) :

```c
int connect (int socket, const struct sockaddr *address, socklen_t address_len)
```

Lorsque la connexion est établie (la primitive `connect()` n'a pas rencontrée d'erreur), l'envoi de message se fait via la primitive :

```c
ssize_t send (int socket, const void *buffer, size_t length, int flags)
```

Sans option (`flags = 0`), cette primitive est équivalente à :

```c
ssize_t write (int fildes, const void *buf, size_t nbyte)
```

que vous pouvez utiliser si vous êtes nostalgique de l'UE programmation système !

💡 Utilisez la macro `CK()` sur cette primitive pour gérer les erreurs.

Après l'émission du message, vous pouvez mettre fin à la connexion via un appel à la primitive `close()`.

## Tests du programme

Testez votre programme en exécutant `netcat` (commande `nc`) dans un autre terminal pour écouter en TCP sur l'adresse et le port que vous spécifiez :

- Pour IPv4 :

```sh
nc -4l 127.0.0.1 port_number
```

- Pour IPv6 :

```sh
nc -6l ::1 port_number
```

Dans un second terminal, exécutez votre programme et vérifiez que le message `hello world` est bien affiché par `netcat` sur la sortie standard.
Consultez les messages échangés avec un analyseur réseau (`wireshark, tshark, tcpdump`).

## Questions

1. Que se passe-t-il si on omet l'appel à `connect()`
2. Est-il possible d'utiliser la primitive `connect()` avec un socket UDP ? En quoi son comportement diffère-t-il de celui observé avec un socket TCP ?
3. L'appel à `close()` termine complètement la connexion avec le serveur. Est-il possible de ne fermer qu'un côté (soit l'écriture, soit la lecture) ? Si oui avec quelle primitive ?

## Validation

Votre programme doit obligatoirement passer tous les tests sur GitLab avant de passer à l'exercice suivant.
Pour ce faire, vous devez `commit/push` votre fichier source sur le dépôt GitLab, ce qui déclenchera automatiquement le pipeline de compilation et de tests.
