# Algorithmes des réseaux - Expéditeur UDP

L'objectif de ce TP est de compléter le programme `usender.c` pour envoyer le message texte `hello world` via le protocole UDP à un hôte distant spécifié.

## Commande d'exécution

Le programme prend en argument l'adresse IP et le numéro de port de l'hôte distant à contacter, ainsi que la durée d'attente après l'envoi avant de se terminer :

```sh
./usender <ip_addr> <port_number> <duration>
```

## Objectifs

- Transmettre un message texte avec le protocol **UDP**.
- Comprendre la gestion des sockets par le système.

## Marche à suivre

Créez un socket IPv4 et UDP à l'aide de la primitive `socket` :

```c
int socket(int domain, int type, int protocol)
```

💡 Utilisez la macro `CHK` pour gérer les erreurs sur cette primitive.

Complétez une structure d'adresse `struct sockaddr_in` utilisée pour les communication IPv4 avec les paramètres du destinataire.
Pour rappel, cette structure contient les champs suivants :

```c
struct sockaddr_in {
    sa_family_t     sin_family; /* AF_INET */
    in_port_t       sin_port;   /* Numéro de port */
    struct in_addr  sin_addr;   /* Adresse IPv4 */
};

struct in_addr {
    in_addr_t s_addr;
};

typedef uint32_t in_addr_t;
typedef uint16_t in_port_t;
```

Vous utiliserez votre fonction `convip()` de l'exercice 1.1 pour convertir l'adresse IP du destinataire dans le bon format.
Il faudra également convertir le numéro de port.
Assurez-vous d'utiliser le format « gros-boutiste » lorsque vous renseignez la structure `struct sockaddr_in` avec l'adresse IP et le port.

Envoyez le message *hello world* via le socket que vous avez créé en utilisant la primitive `sendto()` :

```c
ssize_t sendto(int socket, const void *buffer, size_t length, int flags, const struct sockaddr *dest_addr, socklen_t dest_len)
```

Vous noterez que, pour rester compatible avec toutes les familles de socket (IPv4, IPv6, UNIX, etc.), cette primitive attend en cinquième argument un pointeur vers la structure générique `struct sockaddr`.
Le dernier argument permet d'indiquer la taille réelle de la structure pointée.

💡 Utilisez la macro `CHK` pour gérer les erreurs sur cette primitive.

## Test du programme

Testez votre programme en exécutant `netcat` (avec la commande `nc`) dans un autre terminal pour écouter en UDP sur l'adresse et le port que vous spécifiez :

```sh
nc -4ul 127.0.0.1 port_number
```

Ensuite, lancez votre programme dans un autre terminal et vérifiez que le message *hello world* est bien affiché par `netcat` sur la sortie standard.
Consultez les messages échangés avec un analyseur réseau (`wireshark, tshark, tcpdump`).

## Questions

1. Que se passe-t-il si vous envoyez un message vers une adresse IP et un port qui ne sont associés à aucun socket ?
2. Quels adresse IP et port ont été choisis pour le socket expéditeur ? Qui a fait ce choix ?
3. Peut-on utiliser la primitive `bind()` sur un socket qui ne fait qu'émettre ?

## Validation

Votre programme doit réussir tous les tests sur GitLab avant de passer à l'exercice suivant.
Pour cette validation à distance, il faut `commit/push` votre fichier source sur le dépôt, ce qui déclenchera le *pipeline* de compilation et de tests.
