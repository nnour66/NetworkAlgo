# Algorithmes des réseaux - Récepteur UDP

L'objectif de ce TP est de compléter le programme `ureceiver.c` pour réceptionner un message texte via le protocole UDP.
Le message reçu ainsi que les informations de l'expéditeur (adresse IP et port) seront affichés sur la sortie standard.

## Commande d'exécution

Le programme prend en argument le numéro de port local et la durée d'attente :

```sh
./ureceiver <port_number> <duration>
```

## Exemple de sortie attendue

Lorsque le programme reçoit un message, la sortie doit être de la forme suivante :

```sh
./ureceiver 10001 2
127.0.0.1 1234 a envoyé : hello world
```

Ici, `hello world` est le message reçu, et `127.0.0.1` et `1234` sont respectivement l'adresse IP et le port de l'expéditeur du message.

## Objectifs

- Réceptionner un message texte en UDP.
- Convertir une structure d'adresse en chaîne de caractères.

## Marche à suivre

Le socket est déjà créé et un temporisateur est ajouté au socket via le code fourni.
Ne le modifiez pas.

Complétez une structure d'adresse `struct sockaddr_in` avec les informations locale : le port est celui passé en argument et vous pouvez utiliser la constante `INADDR_ANY` pour l'adresse IP.

Liez le socket avec la structure d'adresse à l'aide de la primitive `bind` :

```c
int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
```

N'oubliez pas de passer un pointeur vers la structure générique `struct sockaddr`.

💡 Utilisez la macro `CHK` pour gérer les erreurs sur cette primitive.

Placez-vous en attente de réception d'un message à l'aide de la primitive :

```c
ssize_t recvfrom(int socket, void *restrict buffer, size_t length, int flags, struct sockaddr *restrict address, socklen_t *restrict address_len)
```

- Le paramètre `buffer` contiendra les octets reçus en cas de succès de réception.
- Les paramètres `address` et `address_len` seront automatiquement complétés par le système avec les informations de l'expéditeur. Prévoyez de la place pour stocker une structure d'adresse de type `sockaddr_in`.
- Pour rester indépendante des types de socket, cette primitive utilise également l'astuce de passer par un pointeur vers la structure générique `struct sockaddr`. Attention, le pointeur `address_len` doit pointer sur la taille réelle de la structure passée en 5e argument, même si ce dernier est ensuite écrasé par la primitive.

💡 Utilisez la macro `CHK` pour gérer les erreurs sur cette primitive.

Convertissez l'adresse IP et le port de l'expéditeur en chaînes de caractères avec la fonction :

```c
int getnameinfo(const struct sockaddr *sa, socklen_t salen, char *host, socklen_t hostlen, char *serv, socklen_t servlen, int flags);
```

Les deux premiers arguments correspondent à la structure d'adresse complétée par la primitive `recvfrom()`.
Les deux arguments suivants indiquent respectivement l'emplacement mémoire où écrire l'adresse IP convertie en chaîne de caractères et la taille maximale allouée pour cette chaîne.
Les deux arguments suivants sont similaires mais concernent le numéro de port.
Les tailles maximale de ces chaînes doivent être positionnées respectivement à `NI_MAXHOST` (pour l'adresse IP) et `NI_MAXSERV` pour le numéro de port.
Enfin, les flags à utiliser sont `NI_NUMERICHOST` et `NI_NUMERICSERV`.

💡 Utilisez la macro `CHKA` pour gérer les erreurs sur cette fonction.

## Test du programme

Testez votre programme avec le programme réalisé dans l'exercice précédent ou en utilisant `netcat` (`nc`en pratique) dans un autre terminal.

- Lancez votre programme dans un terminal.
- Exécutez les commandes suivantes dans un second terminal pour envoyer le message « hello world » en UDP :

```sh
echo "hello world" | nc -4u -w1 127.0.0.1 port_du_prog -p port_local_pour_netcat
```

- Vérifiez que l'adresse IP et le port affichés par votre programme sont conformes à ceux utilisés par l'expéditeur.
- Consultez les messages échangés avec un analyseur réseau (`wireshark`, `tshark`, `tcpdump`).

## Questions

1. Quel est l'utilité des flags `NI_NUMERICHOST` et `NI_NUMERICSERV` dans la fonction `getnameinfo()` ?
2. Que se passe-t-il si le temporisateur expire avant la réception de données ?
3. Pourquoi la primitive `recvfrom()` prend-elle un pointeur vers `socklen_t` en dernier argument ? Que se passe-t-il si cette valeur est incorrecte ?

## Validation

Votre programme doit réussir tous les tests sur GitLab avant de passer à l'exercice suivant.
Pour cette validation à distance, il faut `commit/push` votre fichier source sur le dépôt, ce qui déclenchera le *pipeline* de compilation et de tests.
