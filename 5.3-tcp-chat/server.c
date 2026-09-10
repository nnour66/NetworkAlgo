#include "common.h"

#define MAX 2

noreturn void usage(const char *msg)
{
    fprintf(stderr, "usage: %s <port_local>\n", msg);
    exit(EXIT_FAILURE);
}

int main(int argc, char *argv[])
{
    if (argc != 2)
        usage(argv[0]);

    /* TODO à compléter... */

    return 0;
}
