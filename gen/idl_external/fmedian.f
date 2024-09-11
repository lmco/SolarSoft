C******************************************************************************
C  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
C******************************************************************************
	SUBROUTINE F_MEDIAN(R_IN,OUT,NDIM1,NDIM2,N_WIDTH1,N_WIDTH2,
	1                   R_MISSING,A_SORT)
C
C  This subroutine performs a median filter on a one or two dimensional
C  array.  The variables in the call list are:
C
C		R_IN	 = Input array.
C		OUT	 = Output array.
C		NDIM1	 = First dimension of R_IN and OUT.
C		NDIM2	 = Second dimension of R_IN and OUT.  If the
C				arrays are one dimensional, then use
C				the value NDIM2 = 1.
C		N_WIDTH1 = Width of the median filter in the first
C				dimension of R_IN.
C		N_WIDTH2 = Width of the median filter in the second
C				dimension, ignored if NDIM2 = 1.
C
C               R_MISSING = Value signifying missing data.
C               A_SORT    = Working space array, size (N_WIDTH1*N_WIDTH2)
C
C  Note that the median filter will decrease in size near the edges of the
C  input array.
C
C 
        PARAMETER (KTYPE=4)
        INCLUDE 'fmedian.inc'
C
	RETURN
	END
C******************************************************************************
C  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
C******************************************************************************
	SUBROUTINE L_MEDIAN(R_IN,OUT,NDIM1,NDIM2,N_WIDTH1,N_WIDTH2,
	1                   R_MISSING,A_SORT)
C
C  This is the INTEGER*4 version of MEDIAN.
C
	IMPLICIT INTEGER*4 (A-H,O-Z)
        PARAMETER (KTYPE=3)
        INCLUDE 'fmedian.inc'
C
	RETURN
	END
C******************************************************************************
C  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
C******************************************************************************
	SUBROUTINE D_MEDIAN(R_IN,OUT,NDIM1,NDIM2,N_WIDTH1,N_WIDTH2,
	1                   R_MISSING,A_SORT)
C
C  This is the double precision version of MEDIAN.
C
	IMPLICIT DOUBLE PRECISION (A-H,O-Z)
        PARAMETER (KTYPE=5)
        INCLUDE 'fmedian.inc'
C
	RETURN
	END

C******************************************************************************
C  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
C******************************************************************************
C
C A utility routine to pick the k'th (sorted) element of an array,
C based on the quicksort algorithm.
C 
	INCLUDE 'qsrt_k.f'
