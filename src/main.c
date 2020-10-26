#include <stdio.h>

int cFib(int n) {
  if (n <= 1) {
    return 1;
  } else {
    return cFib(n - 1) + cFib(n - 2);
  }
}
