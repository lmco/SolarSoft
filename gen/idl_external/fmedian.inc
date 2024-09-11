	DIMENSION R_IN(NDIM1,NDIM2),OUT(NDIM1,NDIM2),A_SORT(N_WIDTH1*N_WIDTH2)
C
C  If the widths given for the median filter are out of range, then return the
C  original array unmodified.
C  Range tests changed: .LE. to .LT., 
C                       NDIM1 minimum value changed from 2 to 1
C
	IF (MAX(N_WIDTH1,N_WIDTH2) .LT. 2 .OR. NDIM1 .LT. 1 ) THEN
		DO J = 1,NDIM2
			DO I = 1,NDIM1
				OUT(I,J) = R_IN(I,J)
			ENDDO
		ENDDO
		RETURN
	ENDIF
C
C  Calculate the half width points.
C
	NW1 = (N_WIDTH1 - 1) / 2
	NW2 = (N_WIDTH2 - 1) / 2
C
C  Find the range of points to use in performing the median filter.  Be
C  careful not to exceed the limits of the input array.
C
	DO J = 1,NDIM2
	   J1 = MAX(J-NW2,1)
	   J2 = MIN(J+N_WIDTH2-NW2-1,NDIM2)
	   DO I = 1,NDIM1
	      I1 = MAX(I-NW1,1)
	      I2 = MIN(I+N_WIDTH1-NW1-1,NDIM1)
C       
C       Store the points in the box found above into A_SORT for sorting.
C       
	      K = 0
	      DO JJ = J1,J2
		 DO II = I1,I2
		    IF (R_IN(II,JJ) .NE. R_MISSING) THEN 
		       K = K + 1
		       A_SORT(K) = R_IN(II,JJ)
		    ENDIF
		 ENDDO
	      ENDDO
	      N_SORT = K
C       
C       MID = (N_SORT+1)/2 Changed SVHH
C       
	      MID = N_SORT/2 + 1
	      
C       
C       If there are no points, then flag pixel as missing.
C       
	      IF (N_SORT .EQ. 0) THEN
		 OUT(I,J) = R_MISSING
C       
C       If there are only one or two points, then simply do the average.
C       
	      ELSE IF (N_SORT .LE. 2) THEN
		 OUT(I,J) = 0
		 DO K = 1,N_SORT
		    OUT(I,J) = OUT(I,J) + A_SORT(K) / N_SORT
		 ENDDO
C       
C       Otherwise, sort the points in ascending order, and find the midpoint.
C       
	      ELSE
C       
C       If there are very few points, don't bother with the QSORT
C       
		 IF (N_SORT .LT. 10) THEN
		    DO K = N_SORT,MID,-1
		       A_MAX = A_SORT(K)
		       M = K
		       DO L = 1,K-1
			  IF (A_SORT(L) .GT. A_MAX) THEN
			     A_MAX = A_SORT(L)
			     M = L
			  ENDIF
		       ENDDO
		       IF (M .NE. K) THEN
			  A_SORT(M) = A_SORT(K)
			  A_SORT(K) = A_MAX
		       ENDIF
		    ENDDO
		 ELSE IF (KTYPE .EQ. 3) THEN
		    CALL L_QSRT_K(A_SORT,MID,N_SORT)
		 ELSE IF (KTYPE .EQ. 4) THEN
		    CALL F_QSRT_K(A_SORT,MID,N_SORT)
		 ELSE IF (KTYPE .EQ. 5) THEN
		    CALL D_QSRT_K(A_SORT,MID,N_SORT)
		 ENDIF
		 
		 OUT(I,J) = A_SORT(MID)
	      ENDIF
	   ENDDO
	ENDDO
	


