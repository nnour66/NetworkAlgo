#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <sys/socket.h>
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

noreturn void usage(const char *prog)
{
    fprintf(stderr, "usage: %s port_number timer\n", prog);
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

    /* TODO à compléter */


    long int duration = 0; /* à modifier */

    sleep(duration); /* ne pas supprimer */

    /* TODO fermer le socket */

    return 0;
}
