
c
c Quicksort-based (partitioning) k'th element finder (for calculating 
c e.g., median)
c Based on http://www.mathcs.carleton.edu/courses/course_resources/
c                cs227_w96/swanjorg/algorithms.html
c
c INPUTS:
c    A - Array with data (N elements)
c    K - The number of the element to be found
c    N - The number of elements in A


C LONG version

      SUBROUTINE L_QSRT_K(A,K,N)
      IMPLICIT INTEGER*4 (A)

      INCLUDE 'qsrt_k.inc'

C REAL*4 version

      SUBROUTINE F_QSRT_K(A,K,N)
      IMPLICIT REAL*4 (A)

      INCLUDE 'qsrt_k.inc'

C REAL*8 version

      SUBROUTINE D_QSRT_K(A,K,N)
      IMPLICIT REAL*8 (A)
      
      INCLUDE 'qsrt_k.inc'


            

