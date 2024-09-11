#include <stdio.h>
#include INCLUDE

/*
Quicksort-based (partitioning) k'th element finder (for calculating 
e.g., median)
Based on http://www.mathcs.carleton.edu/courses/course_resources/
               cs227_w96/swanjorg/algorithms.html

INPUTS:
   A - Array with data (N elements)
   K - The number of the element to be found
   N - The number of elements in A
*/

/* LONG version */

void l_qsrt_k(a,k,n)
     long k,n;
     LONG a[];
{
     long i,j,l,r,test;
     long av,atemp;

#include "qsrt_k_c.inc"

  return;
}

/* REAL*4 version */

void f_qsrt_k(a,k,n)
     long k,n;
     float a[];

{
     long i,j,l,r,test;
     float av,atemp;

#include "qsrt_k_c.inc"

  return;
}
     
/* REAL*8 version */

void d_qsrt_k(a,k,n)
     long k,n;
     double a[];

{
     long i,j,l,r,test;
     double av,atemp;

#include "qsrt_k_c.inc"

  return;
}
