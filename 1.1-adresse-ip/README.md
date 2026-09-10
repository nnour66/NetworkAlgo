# Algorithmes des réseaux - Conversion adresse IPv4

L'objectif de ce TP est d'écrire une fonction qui convertit une adresse IPv4 donnée sous la forme d'une chaîne de caractères (dans le format décimal pointé) en un entier non signé sur 32 bits.
Le programme affiche cet entier en héxadécimal en petit-boutiste (_little-endian_) et en gros-boutiste (_big_endian_).

## Commande d'exécution

Le programme `conv.c` contient la fonction `convip()` que vous devez compléter ainsi qu'une fonction `main()` afin de tester cette dernière.
Le programme prend en argument l'adresse IP à convertir :

```sh
./conv <A.B.C.D>
```

## Objectifs

- Savoir convertir une adresse IPv4 depuis une chaîne de caractères vers un entier non signé.
- Distinguer le gros-boutisme du petit-boutisme.

## Marche à suivre

Vous devez uniquement compléter la fonction `convip()` disponible dans le fichier `conv.c`.

L'adresse IP donnée en argument doit respecter le format décimal pointé, c'est-à-dire que chaque chiffre est séparé des autres par le caractère « . ».
Pour récupérer chaque chiffre, vous pouvez utiliser la fonction `strtok()` qui permet de récupérer un pointeur vers la chaîne de caractère se trouvant entre deux délimiteurs (ici le caractère « . »).

Exemple : si l'adresse IP fournit est « AAA.BBB.CCC.DDD », le premier appel à `strtok()` permet de récupérer un pointeur vers la chaîne de caractères « AAA », puis le deuxième appel permet de récupérer un pointeur vers la chaîne de caractères « BBB », et ainsi de suite.
Attention la fonction `strtok()` modifie la chaîne originale.

💡 Consultez le manuel de la fonction `strtok()` afin de gérer les erreurs potentielles sur cette fonction.

Lorsque vous avez récupéré un chiffre (sous la forme d'un pointeur vers une chaîne de caractères), vous pouvez le convertir vers un entier à l'aide de la fonction `conversion()` fournie dans le code source.

💡 Vérifez que chaque entier convertit est bien dans l'intervalle $[0, 255]$.

Le chiffre convertit correspond à 8 bits (1 octet) du résultat final.
Il faut maintenant placer ces 8 bits au bon endroit dans les 32 bits finaux.
En informatique, le boutisme désigne l'ordre dans lequel les octets sont placés.
Le gros-boutisme (_big_endian_) place les octets de poids fort dans les premières cases mémoire, donc celles ayant l'adresse la plus petite.
À l'inverse, le petit-boutisme (_little-endian_) place les octets de poids faible dans les premières cases mémoire.

Exemple : soit l'entier écrit en héxadécimal 0x1528 stocké sur 2 octets dont les adresses mémoires sont 2000 et 2001.
Ce nombre sera stocké :
- en gros-boutisme : l'octet 15 dans la case d'adresse 2000 et l'octet 28 dans la case d'adresse 2001.
- en petit-boutisme : l'octet 15 dans la case d'adresse 2001 et l'octet 28 dans la case d'adresse 2000.

Stockez les octets convertis en petit-boutisme, donc les octets de poids faible en premier.

Les données réseaux (adresse IP, port, etc.) destinées à être lues par des équipements intermédiaires (commutateur, routeur, etc.) doivent être au format « réseaux », c'est-à-dire au format gros-boutiste. Pour convertir une valeur dans ce format vous pouvez utiliser les fonctions suivantes :

```c
uint32_t htonl(uint32_t hostlong);  /* host to network long (32 bits)  */
uint16_t htons(uint16_t hostshort); /* host to network short (16 bits) */
```

La conversion inverse est également possible avec les fonctions :

```c
uint32_t ntohl(uint32_t netlong);   /* network to host long (32 bits)  */
uint16_t ntohs(uint16_t netshort);  /* network to host short (16 bits) */
```

La fonction `main()` affiche déjà l'adresse IP convertie en hexadécimal au format petit-boutisme et gros-boutisme.

## Test du programme

Testez votre programme avec les adresses suivantes et vérifiez que vous obtenez les mêmes résultats :

```sh
./conf 0.0.0.0
petit-boutiste : octet[0] = 0x00 | octet[1] = 0x00 | octet[2] = 0x00 | octet[3] = 0x00 | 
gros-boutiste :  octet[0] = 0x00 | octet[1] = 0x00 | octet[2] = 0x00 | octet[3] = 0x00 | 

./conv 127.0.0.1
petit-boutiste : octet[0] = 0x01 | octet[1] = 0x00 | octet[2] = 0x00 | octet[3] = 0x7F | 
gros-boutiste :  octet[0] = 0x7F | octet[1] = 0x00 | octet[2] = 0x00 | octet[3] = 0x01 | 

./conv 130.79.200.1
petit-boutiste : octet[0] = 0x01 | octet[1] = 0xC8 | octet[2] = 0x4F | octet[3] = 0x82 | 
gros-boutiste :  octet[0] = 0x82 | octet[1] = 0x4F | octet[2] = 0xC8 | octet[3] = 0x01 | 
```

### Validation

Votre programme doit réussir tous les tests sur GitLab avant de passer à l'exercice suivant.
Pour cette validation à distance, il faut `commit/push` votre fichier source sur le dépôt, ce qui déclenchera le *pipeline* de compilation et de tests.
