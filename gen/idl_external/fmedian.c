/*+
 * This subroutine performs a median filter on a one or two dimensional
 * array.  The variables in the call list are:
 *
 *		R_IN	 = Input array.
 *		OUT	 = Output array.
 *		NDIM1	 = First dimension of R_IN and OUT.
 *		NDIM2	 = Second dimension of R_IN and OUT.  If the
 *				arrays are one dimensional, then use
 *				the value NDIM2 = 1.
 *		N_WIDTH1 = Width of the median filter in the first
 *				dimension of R_IN.
 *		N_WIDTH2 = Width of the median filter in the second
 *				dimension, ignored if NDIM2 = 1.
 *
 *              R_MISSING = Value signifying missing data.
 *              A_SORT    = Working space array, size (N_WIDTH1*N_WIDTH2)
 *
 * Note that the median filter will decrease in size near the edges of the
 * input array.
 *
-*/

#include <stdio.h>
#include INCLUDE

/*****************************************************************************/
/*   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   */
/*****************************************************************************/
void f_median(in,out,ndim1,ndim2,n_width1,n_width2,missing,workspace)
     float in[];
     float out[];
     LONG ndim1;
     LONG ndim2;
     LONG n_width1;
     LONG n_width2;
     float missing;
     float workspace[];
{
  float a_max;
  long ktype;

  long i,j,k,l,m,ii,jj,i1,i2,j1,j2,nw1,nw2,n_sort,mid;

  ktype = 4;

#include "fmedian_c.inc"

  return;
}
/*****************************************************************************/
/*   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   */
/*****************************************************************************/
void l_median(in,out,ndim1,ndim2,n_width1,n_width2,missing,workspace)
     LONG in[];
     LONG out[];
     LONG ndim1;
     LONG ndim2;
     LONG n_width1;
     LONG n_width2;
     LONG missing;
     LONG workspace[];
{
  long a_max;
  long ktype;

  long i,j,k,l,m,ii,jj,i1,i2,j1,j2,nw1,nw2,n_sort,mid;

  ktype = 3;

#include "fmedian_c.inc"

  return;
}
/*****************************************************************************/
/*   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   */
/*****************************************************************************/
void d_median(in,out,ndim1,ndim2,n_width1,n_width2,missing,workspace)
     double in[];
     double out[];
     LONG ndim1;
     LONG ndim2;
     LONG n_width1;
     LONG n_width2;
     double missing;
     double workspace[];
{
  double a_max;
  long ktype;

  long i,j,k,l,m,ii,jj,i1,i2,j1,j2,nw1,nw2,n_sort,mid;

  ktype = 5;

#include "fmedian_c.inc"

  return;
}
