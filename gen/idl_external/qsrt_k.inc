
c
c Quicksort-based k'th element finder (for calculating median)
c Based on http://www.mathcs.carleton.edu/courses/course_resources/
c                cs227_w96/swanjorg/algorithms.html
c

c      FUNCTION F_QSRT_K(A,K,N)
c      IMPLICIT REAL*4 (A)
c      REAL*4 F_QSRT

      DIMENSION A(N)
      INTEGER*4 K,N
      INTEGER*4 I,J,L,R,II

      L = 1
      R = N

 333  CONTINUE

      
      IF ( R .GT. L ) THEN 
         
         AV = A(R)
         I = L - 1
         J = R
         DO WHILE ( .TRUE. )
         
            I = I + 1
            DO WHILE ( A(I) .LT. AV .AND. I .LT. J)
               I = I + 1
            END DO

            J = J - 1
            DO WHILE ( A(J) .GT. AV .AND. J .GT. I)
               J = J - 1
            END DO

            IF ( I .GE. J ) GO TO 666
C
C SWAP(A,I,J)
C     
            ATEMP = A(I)
            A(I) = A(J)
            A(J) = ATEMP

         END DO
C
C SWAP(A,I,R)
C
 666     ATEMP = A(I)
         A(I) = A(R)
         A(R) = ATEMP

C Terminate if appropriate

         IF ( I .EQ. K ) THEN 
C           F_QSRT_K = A(I)
            RETURN
         ENDIF
         
C Select the correct interval

         IF ( K .LT. I ) THEN 
            R = I-1
         ELSE 
            L = I+1
         ENDIF
         
         GO TO 333

      ELSE 

C
C  R == L   ==>  F_QSRT_K == A(R)
C

         RETURN

      ENDIF
      
      END


            

