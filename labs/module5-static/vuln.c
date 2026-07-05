#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void process(void) {
    char *p = malloc(8);
    char buf[4];
    strcpy(buf, "hello");
    printf("%s\n", buf);
}

int compute(void) {
    int *a = malloc(sizeof(int) * 4);
    a[0] = 1;
    free(a);
    return a[0];
}

int main(void) {
    process();
    return compute();
}
