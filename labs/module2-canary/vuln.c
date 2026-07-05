#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void win(void) {
    puts("FLAG{canary_bypassed}");
    exit(0);
}

void vulnerable(void) {
    char buf[100];

    printf("leak> ");
    fflush(stdout);
    fgets(buf, sizeof(buf), stdin);
    printf(buf);
    fflush(stdout);

    printf("overflow> ");
    fflush(stdout);
    read(0, buf, 256);
    puts("done");
}

int main(void) {
    vulnerable();
    return 0;
}
