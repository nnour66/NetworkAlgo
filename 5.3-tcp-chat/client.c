#include "common.h"

noreturn void usage(const char *msg)
{
    fprintf(stderr, "usage: %s <ip_dest> <port_dest>\n", msg);
    exit(EXIT_FAILURE);
}

int main(int argc, char *argv[])
{
    if (argc != 3)
        usage(argv[0]);

    /* TODO à compléter... */

    return 0;
}
