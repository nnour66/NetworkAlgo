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
 char *ip_copy = strdup(ip);
 if (ip_copy == NULL) {
 perror("strdup");
 exit(EXIT_FAILURE);
 }

 uint32_t addr = 0;
 char *token;
 int i = 0;

 token = strtok(ip_copy, ".");
 while (token != NULL) {
 if (i >= 4) {
 fprintf(stderr, "Erreur : adresse trop longue\n");
 free(ip_copy);
 exit(EXIT_FAILURE);
 }

 long int val = conversion(token);

 if (val < 0 || val > 255) {
 fprintf(stderr, "Erreur : octet hors intervalle [0, 255]\n");
 free(ip_copy);
 exit(EXIT_FAILURE);
 }

 addr |= ((uint32_t)val << ((3 - i) * 8));

 i++;
 token = strtok(NULL, ".");
 }

 if (i != 4) {
 fprintf(stderr, "Erreur : adresse trop courte\n");
 free(ip_copy);
 exit(EXIT_FAILURE);
 }

 free(ip_copy);
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