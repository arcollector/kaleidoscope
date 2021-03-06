#include <stdio.h>

/* putchard - putchar that takes a double and returns 0 */
extern double putchard(double X) {
  putchar((char) X);
  fflush(stdout);
  return 0;
}

/* printd - printf that takes a double prints it as "%f\n", return 0 */
extern double printd(double X) {
  printf("%f\n", X);
  return 0;
}
