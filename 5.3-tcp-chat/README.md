# Algorithmes des réseaux - Chat multi-utilisateur avec TCP

Dans ce TP vous allez vous familiariser avec la création, la gestion et la communication via un serveur TCP capable de gérer plusieurs clients simultanément.
Vous allez développer un programme `client` et un programme `serveur`.
Ce dernier devra gérer plusieurs connexions clientes de manière concurrente en utilisant la primitive `poll()` (plutôt que l'emploi de processus parallèles).

## Commande d'exécution

Le programme `server` admet en argument le numéro de port local :

```sh
./server <port_local>
```

Le programme `client` admet en argument l'adresse IP (version 4 ou 6) et le port du serveur.
Les données envoyées sont lues depuis l'entrée standard, et les données reçues sont écrites sur la sortie standard :

```sh
./client <ip_serveur> <port_serveur>
```

## Objectifs
- Créer et gérer des sockets TCP.
- Gérer de façon concurrente des descripteurs via la primitive `poll()`.
- Diffuser des messages à plusieurs clients.
- Comprendre le fonctionnement du protocole TCP avec et sans l'algorithme de _Nagle_.

## Marche à suivre

## Programme client

Reprenez le code source `client.c` de l'exercice 5.1.

La primitive `poll()` sert à surveiller simultanément plusieurs descripteurs (sockets, fichiers, tubes, etc.) afin de savoir lesquels sont prêts pour une opération d’entrée/sortie (lecture, écriture, erreurs, etc.) sans bloquer inutilement.

```c
int poll(struct pollfd *fds, nfds_t nfds, int timeout)
```

Le premier argument liste les descripteurs à observer associés aux événements que l'on souhaite détecter sous la forme de structures `struct pollfd` :

```c
struct pollfd {
    int   fd;         /* descripteur */
    short events;     /* événements qu'on souhaite détecter */
    short revents;    /* événements effectivement survenus (complété par le noyau) */
};
```

Consultez le manuel utilisateur pour découvrir les différents événements possibles.

Le paramètre `nfds` correspond au nombre d'entrées valides dans le tableau.
Enfin, `timeout` permet d'imposer une limite temporelle (en millisecondes) avant que `poll()` ne retourne.
Deux valeurs permettent de forcer un comportement spécifique :

- `-1` signifie attendre indéfiniment qu'un événement attendu se produise ;
- `0` signifie « tester immédiatement ».

Modifiez le  programme `client` pour qu'il écoute simultanément sur l'entrée standard et sur le socket connecté au serveur en utilisant la primitive `poll()`.
Lorsque des données sont disponibles sur l'entrée standard, elles doivent être envoyées au serveur via le socket.
De même, si des données sont reçues sur le socket, elles doivent être affichées sur la sortie standard.
Pour vous aider, vous pouvez vous inspirer du programme `medium` des exercices 3 et 4.

Le programme `client` doit se terminer lorsque l'entrée standard est fermée ou lorsque le serveur ferme la connexion.

💡 `poll()` a un comportement différent si le descripteur sur lequel on attend en lecture est un tube.
Dans le cas de la fermeture d'un tube, `poll()` retourne l'événement `POLLHUP` pour ce descripteur (et non `POLLIN` comme pour un socket ou un descripteur de fichier).
En outre, les tubes sont utilisés dans le script de test.

## Programme serveur

Reprenez le code source `server.c` de l'exercice 5.2.
Supprimez les affichages des informations sur les connexions clientes lors de leur arrivée.

Le serveur doit utiliser la primitive `poll()` pour écouter sur l'entrée standard et sur le socket acceptant les connexions entrantes.
Lorsqu'un nouveau client se connecte, ajoutez le socket créé par `accept()` à la liste des descripteurs surveillés par `poll()`.
Si un client se déconnecte, retirez le socket correspondant de cette liste.

Lorsque le serveur reçoit un message sur l'entrée standard, il doit le diffuser à tous les clients connectés.
De même, lorsque le serveur reçoit un message d'un client, il doit le diffuser à tous les autres clients et l'afficher sur la sortie standard.
Le serveur se termine après la déconnexion du dernier client.

Le serveur doit gérer un maximum de `MAX` (déjà défini) clients simultanés.
Si cette limite est atteinte, les nouvelles connexions doivent échouer avec un message d'erreur affiché sur la sortie d'erreur du client concerné (le serveur ne doit pas se terminer pour autant).
Les clients refusés doivent se terminer en erreur (code de retour du programme == 1).

## Test des programmes

- Test en environnement multi-client : exécutez le serveur dans un terminal et au moins deux clients dans deux autres terminaux. Assurez-vous que les messages envoyés par un client sont bien reçus par les autres clients connectés.

- Test de transmission de fichier ; vous testerez ici la capacité d'un client à transmettre un fichier au serveur :

    - pour le serveur :

    ```sh
    ./serveur-tcp port_local > titi
    ```

    - pour le client :

    ```sh
    dd if=/dev/random of="toto" bs=8k count=2 2> /dev/null
    ./client-tcp ::1 port_du_serveur < toto
    ```

    - vérifiez que les fichiers `toto` et `titi` sont identiques :

    ```sh
    cmp toto titi
    ```

## Analyse du mode flux de TCP

Contrairement à UDP, en plus de l'établissement préalable de la connexion, TCP est un protocole en **mode flux**.
Cela signifie que, via un socket TCP, l'envoi de données et leur segmentation (découpage en segments) sont gérés par un algorithme sous-jacent à TCP, et non par l'application :

- un appel à `send` ne provoque pas nécessairement l'émission directe d'un segment.
- un appel à `recv` peut retourner des données agrégées provenant de plusieurs segments.

En pratique, l'émission des segments TCP est en effet gérée par l'algorithme de [Nagle](https://www.ietf.org/rfc/rfc0896.txt).
Pour le mettre en évidence, modifiez la taille du tampon du client pour forcer TCP à envoyer des petits segments :
```c
#define BUFSIZE 2
```

Répétez le test de transmission de fichier et analysez le trafic réseau avec `tshark` ou `tcpdump` pour observer comment les données sont segmentées et envoyées.

```sh
tshark -i lo -f "tcp and ip6"
```

Combien de segments sont envoyés pour transmettre l'intégralité du fichier ?
Ont-ils tous la même taille ?
Combien de fois la primitive `read/recv` est-elle appelée pour reconstituer l'intégralité du fichier (vous pouvez préfixer le programme serveur par la commande `strace`) ?
Combien d'octets sont récupérés à chaque appel ?

Désactivez l'algorithme de _Nagle_ sur le client en utilisant la primitive `setsockopt()` avec l'option `TCP_NODELAY` :

```c
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen)
```

Utilisez `IPPROTO_TCP` pour le paramètre `level`.  

Répétez l'analyse du trafic avec `tshark` après avoir désactivé l'algorithme de _Nagle_ et comparez les résultats avec ceux obtenus précédemment.
Le comportement du serveur a-t-il changé ?
Quelle version de la transmission est la plus efficace et pourquoi ?

## Validation

Votre programme doit obligatoirement passer tous les tests sur GitLab avant de passer à l'exercice suivant.
Pour ce faire, utilisez les actions `commit` et `push` sur vos fichiers sources sur le dépôt GitLab, ce qui déclenchera le pipeline de compilation et de tests.
