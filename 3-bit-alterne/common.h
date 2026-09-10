#ifndef COMMON_H
#define COMMON_H

#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <sys/socket.h>
#include <time.h>
#include <unistd.h>
#include <limits.h>
#include <errno.h>
#include <signal.h>

#define CHK(op)								       \
    do {                                                                       \
        if ((op) == -1) {                                                      \
            perror(#op);                                                       \
            exit(1);                                                           \
        }                                                                      \
    } while (0)

#define N 2          // modulo pour numéroter les messages
#define TIMEOUT 2    // durée (en sec.) du temporisateur pour la retransmission (RTO)
#define BUFSIZE 1024 // taille max (en octets) pour les données dans un message

/* format des messages */
struct message {
    uint8_t seq;        // numéro de séquence du message
    char data[BUFSIZE]; // données contenues dans le message
};

static inline long int conversion(char *s)
{
    char *endptr;
    long int v = strtol(s, &endptr, 10);

    if ((v == LONG_MAX || v == LONG_MIN) && errno == ERANGE) {
        perror("strtol: ");
        exit(EXIT_FAILURE);
    }
    if (*endptr != '\0') {
        fprintf(stderr, "strtol: junk in %s\n", s);
        exit(EXIT_FAILURE);
    }

    if (v < 1024 || v > 65535) {
        fprintf(stderr, "port numbers should be in [1024, 65535]\n");
        exit(EXIT_FAILURE);
    }

    return v;
}

#endif // COMMON_H
