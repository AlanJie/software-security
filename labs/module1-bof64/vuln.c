#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void win(void) {
    puts("FLAG{control_flow_hijacked}");
    exit(0);
}

void vulnerable(void) {
    char buf[16];
    printf("input> ");
    fflush(stdout);
    ssize_t n = read(0, buf, 256);
    if (n > 0) buf[n < 256 ? n : 255] = '\0';
    printf("you said: %s\n", buf);
}

int main(void) {
    vulnerable();
    puts("bye");
    return 0;
}
