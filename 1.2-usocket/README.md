# Algorithmes des réseaux - Socket UDP

L'objectif de ce TP est de créer un socket UDP et de le visualiser sur le système grâce à la commande `ss` (_socket statistics_).

## Commande d'exécution

Le programme prend en argument le numéro de port pour le socket et la durée d'attente (pour l'appel à `sleep`) avant de se terminer :

```sh
./usocket <port_number> <duration>
```

## Objectifs

- Comprendre la création d'un socket UDP.
- Savoir compléter une structure d'adresse IPv4.
- Associer une adresse à un socket.
- Visualiser un socket ouvert sur le système.

## Marche à suivre

Commencez par convertir le numéro de port passé en argument du programme avec la fonction `conversion()` fournie dans le code source.

Créez ensuite un socket IPv4 et UDP à l'aide de la primitive `socket` :

```c
int socket(int domain, int type, int protocol)
```

💡 Utilisez la macro `CHK` pour gérer les erreurs sur cette primitive.

Complétez une structure d'adresse `struct sockaddr_in` utilisée pour les communication IPv4.
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

Utilisez le port passé en argument du programme que vous avez converti dans l'étape 1 et la constante `INADDR_ANY` pour l'adresse IP.

💡 Les données réseaux (adresse IP, port, etc.) destinées à être lues par des équipements intermédiaires (commutateur, routeur, etc.) doivent être au format « réseaux », c'est-à-dire au format gros-boutiste.
Référez-vous à l'exercice précédent pour convertir le numéro de port dans le format réseau.

Liez le socket avec la structure d'adresse à l'aide de la primitive `bind` :

```c
int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
```

Vous noterez que, pour rester compatible avec toutes les familles de socket (IPv4, IPv6, UNIX, etc.), cette primitive attend en second argument un pointeur vers la structure générique `struct sockaddr`.
Il s'agit d'une sorte de _type commun_ pour les adresses réseau.
Concrètement, cela nécessite un cast explicite depuis une structure plus spécifique comme `struct sockaddr_in *`.

Pour simplifier, vous pouvez voir ce mécanisme comme une forme de _polymorphisme_ en C, similaire à l'usage d'un `void *` pour passer différents types à une même fonction.
Le troisième argument indique la taille réelle de la structure d'adresse pointée par le second argument.

💡 Utilisez la macro `CHK` pour gérer les erreurs sur cette primitive.

## Test du programme

⚠️  Si vous utilisez l'image docker pour tester les numéros valides de port, vous devez ajouter l'option suivante lorsque vous instanciez le conteneur :

```sh
--sysctl net.ipv4.ip_unprivileged_port_start=1024
```

Testez votre programme en exécutant dans un premier terminal la commande :

```sh
watch ss -uap
```

Exécutez votre programme dans un second terminal et vous devriez voir apparaître votre socket dans le premier terminal.

## Questions

1. Quelles sont les valeurs possibles pour le numéro de port ?
2. Que se passe-t-il si vous passez 0 en numéro de port ?
3. Que permet d'afficher la commande `ss` à propos des sockets réseau ?

## Validation

Votre programme doit réussir tous les tests sur GitLab avant de passer à l'exercice suivant.
Pour cette validation à distance, il faut `commit/push` votre fichier source sur le dépôt, ce qui déclenchera le *pipeline* de compilation et de tests.
