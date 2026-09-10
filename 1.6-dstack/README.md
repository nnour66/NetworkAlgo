# Algorithmes des réseaux - Double pile IPv4/IPv6

L'objectif de ce TP est de mettre en œuvre des sockets IPv4/IPv6 (double pile) pour permettre des communications IPv4 ou IPv6.
Pour ce faire, il faut compléter les programmes `usender64.c` et `ureceiver64.c`.
Le message reçu ainsi que les informations de l'expéditeur (adresse IP et port) seront affichés sur la sortie standard par le programme `ureceiver64.c`.
Il s'agit des versions double pile de l'exercice précédent.

## Commande d'exécution

Le programme `usender64.c` prend en argument l'adresse IP (IPv4 ou IPv6) et le numéro de port de l'hôte distant :

```sh
./usender64 <ip_dest> <port_dest>
```

Le programme `ureceiver64.c` prend en argument le numéro de port local ainsi que la durée (en sec.) pour le temporisateur :

```sh
./ureceiver64 <port_local> <duration> 
```

## Exemple de sortie attendue

Lorsque le programme `ureceiver64.c` reçoit un message via IPv6, la sortie doit être de la forme suivante :

```sh
./ureceiver64 10001 2
::1 1234 a envoyé : hello world
```

Ici, `hello world` est le message reçu, et `::1` et `1234` sont respectivement l'adresse IPv6 et le port de l'expéditeur du message.

Lorsque le programme `ureceiver64.c` reçoit un message via IPv4, la sortie doit être de la forme suivante :

```sh
./ureceiver64 10001 2
::ffff:130.79.91.1 1234 - hello world
```

Ici, `hello world` est le message reçu, et `130.79.91.1` et `1234` sont respectivement l'adresse IPv4 et le port de l'expéditeur du message.

## Objectifs

- Créer des sockets double pile IPv4/IPv6.
- Mettre en œuvre des communications IP agnostiques de la version du protocole.
- Utiliser la structure d'adresse générique `struct sockaddr_storage`.
- Utiliser des fonctions modernes (`getaddrinfo()`).

## Marche à suivre

Reprenez vos deux exercices précedents.
Dans le récepteur, après avoir créé le socket IPv6, autorisez les communications IPv4 sur ce dernier via le code :

```c
int value = 0;
setsockopt(sockfd, IPPROTO_IPV6, IPV6_V6ONLY, &value, sizeof value);
```

💡 Utilisez la macro CHK pour gérer les erreurs sur cette primitive.

Lors de l'appel à la primitive `recvfrom()`, les informations de l'expéditeur sont stockées soit dans une structure `struct sockaddr_in` en IPv4, soit dans une structure `struct sockaddr_in6` en IPv6.
Ici, comme on ne connait pas à l'avance le protocole utilisé pour joindre le récepteur, on peut utiliser une structure spéciale qui est capable de stocker tout type de structures d'adresse.
Cette structure est `struct sockaddr_storage`.

Utilisez une structure de ce type pour stocker les informations de l'expéditeur et faire ensuite la conversion de l'adresse IP et du port vers des chaînes de caractères.

Le reste du code du récepteur ne change pas.

Concernant l'expéditeur, il faut en premier lieu convertir l'adresse et le port fournis en arguments dans les bons formats.
Pour ce faire, vous devez utiliser la fonction :

```c
int getaddrinfo(const char *restrict node,
                const char *restrict service,
                const struct addrinfo *restrict hints,
                struct addrinfo **restrict res);
```

Cette fonction est complémentaire à la fonction `getnameinfo()`.
La fonction `getaddrinfo()` permet de convertir une adresse IP, un nom de machine, un numéro de port, ou un nom de service exprimés sous la forme d'une chaîne de caractères dans une structure d'adresse adéquate.
Les arguments sont les suivants :
- `node` est une adresse IP (IPv4 ou IPv6) ou un nom de machine (e.g. google.fr) ;
- `service` est un numéro de port ou un nom de service (e.g. http) ;
- `hints` permet de filtrer les résultats si plusieurs correspondances existent ;
- `res` est une liste chaînée de structure `struct addrinfo` pour chaque correspondance trouvée. 

La structure `struct addrinfo` comporte les paramètres suivants :

```c
struct addrinfo {
    int              ai_flags;
    int              ai_family;
    int              ai_socktype;
    int              ai_protocol;
    socklen_t        ai_addrlen;
    struct sockaddr *ai_addr;
    char            *ai_canonname;
    struct addrinfo *ai_next;
};
```
Il est donc possible de filtrer les résultsts en fonction de la famille de socket, le protocole de transport, etc.
En retour, la fonction `getaddrinfo` complète une liste chaînée de structure `struct addrinfo` ou chaque maillon correspond à une correspondance.
Dans chaque maillon, le pointeur `ai_addr` contient l'adresse IP et le numéro de port au bon format.

Il est donc possible de créer un socket et d'envoyer des données en utilisant les informations contenues dans l'un des maillon.
Par exemple :

```c
int socket;
struct addrinfo *res;
getaddrinfo(..., NULL, &res);

if (res != NULL) {
    socket = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    sendto(sockfd, "hello", 5, 0, res->ai_addr, res->ai_addrlen);
}
```

La fonction `getaddrinfo()` alloue de la mémoire dynamiquement pour la liste chaînée `res`.
Il faudra donc libérer cette mémoire dès que possible via la fonction :

```c
void freeaddrinfo(struct addrinfo *ai);
```
💡 Consultez le manuel de la fonction `getaddrinfo()` pour effectuer une simple conversion des arguments passés au programme.

💡 Consultez le manuel de la fonction `getaddrinfo()` pour gérer les erreurs potentielles sur cette fonction..

Le reste du code de l'émetteur ne change pas.

## Test des programmes

Testez votre programme avec le programme réalisé dans l'exercice précédent ou en utilisant `netcat` (`nc`en pratique) dans un autre terminal.

- Lancez votre programme `ureceiver64.c` dans un terminal avec une durée suffisamment grande.
- Lancez votre programme `usender64.c` dans un autre terminal.
- Vérifiez que l'adresse IPv6 et le port affichés par votre programme sont conformes à ceux utilisés par l'expéditeur.
- Consultez les messages échangés avec un analyseur réseau (`wireshark`, `tshark`, `tcpdump`).
- Visualisez les sockets à l'aide de la commande `ss`.

## Questions

1. Sans flag particulier, comment la fonction `getaddrinfo()` effectue la résolution de l'adresse / nom ou du port / service ?
2. Quelle est l'utilité de la structure `struct sockaddr_storage` ?
3. À quoi correspond le format d'adresse `::ffff:a.b.c.d` retourné par le récepteur en cas de communication IPv4 ?

## Validation

Votre programme doit réussir tous les tests sur GitLab avant de passer à l'exercice suivant.
Pour cette validation à distance, il faut `commit/push` votre fichier source sur le dépôt, ce qui déclenchera le *pipeline* de compilation et de tests.
