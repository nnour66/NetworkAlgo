# Algorithmes des réseaux - Transmission IPv6

L'objectif de ce TP est de compléter les programmes `usender6.c` et `ureceiver6.c` pour transmettre un message texte via le protocole UDP en IPv6.
Le message reçu ainsi que les informations de l'expéditeur (adresse IP et port) seront affichés sur la sortie standard par le programme `ureceiver6.c`.
Il s'agit des versions IPv6 des deux exercices précédents.

## Commande d'exécution

Le programme `usender6.c` prend en argument le numéro de port distant :

```sh
./usender6 <port_dest> 
```

Le programme `ureceiver6.c` prend en argument le numéro de port local ainsi que la durée (en sec.) pour le temporisateur :

```sh
./ureceiver6 <port_local> <duration> 
```

## Exemple de sortie attendue

Lorsque le programme `ureceiver6.c` reçoit un message, la sortie doit être de la forme suivante :

```sh
./ureceiver6 10001 2
::1 1234 a envoyé : hello world
```

Ici, `hello world` est le message reçu, et `::1` et `1234` sont respectivement l'adresse IPv6 et le port de l'expéditeur du message.

## Objectifs

- Créer des sockets IPv6.
- Configurez une structure d'adresse IPv6.
- Transmettre un message via des sockets IPv6.
- Convertir une structure d'adresse IPv6 en chaînes de caractères.

## Marche à suivre

Reprenez vos deux exercices précedents et modifiez le type de socket utilisé, puis complétez une structure d'adresse `struct sockaddr_in6`.
Pour rappel, cette structure contient les champs suivants :

```c
struct sockaddr_in6 {
    sa_family_t     sin6_family;   /* AF_INET6 */
    in_port_t       sin6_port;     /* port number */
    uint32_t        sin6_flowinfo; /* IPv6 flow information */
    struct in6_addr sin6_addr;     /* IPv6 address */
    uint32_t        sin6_scope_id; /* Scope ID (new in Linux 2.4) */
};

struct in6_addr {
    unsigned char s6_addr[16];     /* IPv6 address */
};
```

Dans le programme `usender6.c`, vous utiliserez la variable `in6addr_loopback` pour l'adresse IPv6 du destinataire.
Dans le programme `ureceiver6.c`, vous utiliserez la variable `in6addr_any` pour l'adresse IPv6 locale.
Le port doit être complété de façon similaire aux exercices précédents.
Les autres champs de la structure doivent être mis à zéro.

## Test des programmes

Testez votre programme avec le programme réalisé dans l'exercice précédent ou en utilisant `netcat` (`nc`en pratique) dans un autre terminal.

- Lancez votre programme `ureceiver6.c` dans un terminal avec une durée suffisamment grande.
- Lancez votre programme `usender6.c` dans un autre terminal.
- Vérifiez que l'adresse IPv6 et le port affichés par votre programme sont conformes à ceux utilisés par l'expéditeur.
- Consultez les messages échangés avec un analyseur réseau (`wireshark`, `tshark`, `tcpdump`).
- Visualisez les sockets à l'aide de la commande `ss`.

## Questions

1. Quelle est la différence entre l'utilisation de sockets IPv4 et IPv6 ?
2. Quelle est l'utilité des champs `sin6_flowinfo` et `sin6_scope_id` de la structure `struct sockaddr_in6` ?
3. À quelles valeurs correspondent les variables `in6addr_loopback` et `in6addr_any` ?

## Validation

Votre programme doit réussir tous les tests sur GitLab avant de passer à l'exercice suivant.
Pour cette validation à distance, il faut `commit/push` votre fichier source sur le dépôt, ce qui déclenchera le *pipeline* de compilation et de tests.
