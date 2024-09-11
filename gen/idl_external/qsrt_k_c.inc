/*
Quicksort-based k'th element finder (for calculating median)
Based on http://www.mathcs.carleton.edu/courses/course_resources/
               cs227_w96/swanjorg/algorithms.html
*/

l = 0;
r = n-1;

while (r > l) {
  av = a[r];
  i = l - 1;
  j = r;

  test = 1;
  while (test) {
    ++i;
    while ((a[i] < av) & (i < j)) ++i;
    --j;
    while ((a[j] > av) & (j > i)) --j;
    if (i < j) {
         
      /* SWAP(A,I,J) */

      atemp = a[i];
      a[i] = a[j];
      a[j] = atemp;
    }
    else test = 0;
  }

  /* SWAP(A,I,R) */

  atemp = a[i];
  a[i] = a[r];
  a[r] = atemp;

  /* Terminate if appropriate */

  if (i == k) return;
         
  /* Select the correct interval */

  if (k < i)
    r = i-1;
  else
    l = i+1;
}
