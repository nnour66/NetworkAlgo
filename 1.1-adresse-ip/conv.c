#include <netdb.h>
#include <stdio.h>
#include <stdnoreturn.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include <limits.h>

noreturn void usage(const char *prog)
{
    fprintf(stderr, "usage: %s ip_addr\n", prog);
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

uint32_t convip(const char *ip)
{
    (void) ip; /* à supprimer */

    uint32_t addr = 0;

    /* TODO à compléter */

    return addr;
}

void dump_uint32(uint32_t val) {
    uint8_t *octets = (uint8_t *)&val;
    for (int i = 0; i < 4; i++) {
        printf("octet[%d] = 0x%02X | ", i, octets[i]);
    }
    printf("\n");
}

int main(int argc, char *argv[])
{
    if(argc != 2)
        usage(argv[0]);

    uint32_t addr = convip(argv[1]);

    printf("petit-boutiste : ");
    dump_uint32(addr);
    printf("gros-boutiste :  ");
    dump_uint32(htonl(addr));

    return 0;
}
