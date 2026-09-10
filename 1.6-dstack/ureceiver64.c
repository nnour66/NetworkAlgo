#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <limits.h>
#include <errno.h>

#define CHK(op)                                                                \
    do {                                                                       \
        if ((op) == -1) {                                                      \
            perror(#op);                                                       \
            exit(1);                                                           \
        }                                                                      \
    } while (0)

#define BUFSIZE 1024

noreturn void usage(const char *msg)
{
    fprintf(stderr, "usage: %s <port_local> <duration>\n", msg);
    exit(EXIT_FAILURE);
}

long int conversion(char *s)
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

    return v;
}

int main(int argc, char *argv[])
{
    if (argc != 3)
        usage(argv[0]);

    int sockfd = 0;

    /* TODO à compléter */


    long int timeout = 0; /* à modifier */

    /* ajout d'un timer sur la non réception sur le socket - à ne pas toucher */
    struct timeval tv = {timeout, 0};
    CHK(setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv));

    /* tampon pour la réception des données */
    char buffer[BUFSIZE] = {0};

    /* tampons pour la conversion IP / port */
    char s_addr[NI_MAXHOST] = {0}, s_port[NI_MAXSERV] = {0};


    /* affichage final - à ne pas toucher */
    printf("%s %s a envoyé : %s\n", s_addr, s_port, buffer);

    return 0;
}
