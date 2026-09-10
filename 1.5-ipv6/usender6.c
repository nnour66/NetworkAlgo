#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#include <limits.h>

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
    fprintf(stderr, "usage: %s <port_dest>\n", msg);
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
    if (argc != 2)
        usage(argv[0]);

    /* TODO à compléter */

    return 0;
}
