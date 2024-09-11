/*+
 * Project     : SOHO - CDS
 * 
 * Name        : c_rearrange_c, s_rearrange_c, l_rearrange_c, d_rearrange_c
 * 
 * Purpose     : Unix interface between IDL and rearrange C routines.
 * 
 * Explanation : These routines provide the interface between CALL_EXTERNAL in
 *		 IDL and the various rearrange routines written in C.  In VMS
 *		 these routines are not needed, and the rearrange routines can
 *		 be called directly.
 * 
 * Use         : Called using CALL_EXTERNAL by the IDL procedure REARRANGE.
 *
 *		 TEST1 = CALL_EXTERNAL(FILENAME, 'c_rearrange_c', IN, OUT, $
 *			DIM, FIX(DIM_ORDER), FIX(N_ELEMENTS(DIM_ORDER))
 * 
 *		 The actual routine called depends on the data type of the
 *		 input array.
 * 
 *			IDL data type	Routine
 * 
 *			Byte		c_rearrange_c
 *			Integer		s_rearrange_c
 *			Long		l_rearrange_c
 *			Float		l_rearrange_c
 *			Double		d_rearrange_c
 *			Complex		c_rearrange_c
 *
 *		 The important point is that the number of bytes must match,
 *		 not that the data types match completely.
 * 
 * Inputs      : in	   = Input array, of one of the above types.
 *		 dim	   = Long integer array containing the dimensions of
 *			     the in array.
 *		 dim_order = Short integer array containing the order to
 *			     rearrange the dimensions into.  Each dimension is
 *			     specified by a number from 1 to N.  If any
 *			     dimension is negative, then the order of the
 *			     elements is reversed in that dimension.
 *		 n_dim	   = The number of dimensions
 * 
 * Outputs     : out	   = Output array.  Must have the correct data type and
 *			     dimensions, depending on the in array.
 * 
 * Calls       : c_rearrange, s_rearrange, l_rearrange, d_rearrange
 * 
 * Restrictions: None.
 * 
 * Side effects: None.
 * 
 * Category    : Utilities, Array.
 * 
 * Prev. Hist. : William Thompson, GSFC, 14 July 1993
 *			This was an earlier version, written as part of the
 *			SERTS library
 * 
 * Written     : William Thompson, GSFC, 14 July 1993
 * 
 * Modified    : Version 1, William Thompson, GSFC, 24 August 1994
 *			Ported to OSF/1.
 *			Incorporated into CDS library.
 * 
 * Version     : Version 1, 24 August 1994
-*/

#include <stdio.h>
#include INCLUDE

/*****************************************************************************/
/** ****    ****    ****    ****    ****    ****    ****    ****    ****    **/
/*****************************************************************************/
void c_rearrange_c(argc, argv)
     int argc;			/* The number of arguments */
     void *argv[];		/* The arguments */
{
  BYTE *in, *out;
  LONG *dim;
  SHORT *dim_order, n_dim;

  /*  Convert the IDL input parameters into C parameters.  */

  in        = (BYTE *)   argv[0];
  out       = (BYTE *)   argv[1];
  dim       = (LONG *)    argv[2];
  dim_order = (SHORT *)  argv[3];
  n_dim     = *(SHORT *) argv[4];

  /*  Call the C routine c_rearrange.  */

  c_rearrange(in,out,dim,dim_order,n_dim);
  return;
}

/*****************************************************************************/
/** ****    ****    ****    ****    ****    ****    ****    ****    ****    **/
/*****************************************************************************/
void s_rearrange_c(argc, argv)
     int argc;			/* The number of arguments */
     void *argv[];		/* The arguments */
{
  SHORT *in, *out;
  LONG *dim;
  SHORT *dim_order, n_dim;

  /*  Convert the IDL input parameters into C parameters.  */

  in        = (SHORT *)  argv[0];
  out       = (SHORT *)  argv[1];
  dim       = (LONG *)    argv[2];
  dim_order = (SHORT *)  argv[3];
  n_dim     = *(SHORT *) argv[4];

  /*  Call the C routine s_rearrange.  */

  s_rearrange(in,out,dim,dim_order,n_dim);
  return;
}

/*****************************************************************************/
/** ****    ****    ****    ****    ****    ****    ****    ****    ****    **/
/*****************************************************************************/
void l_rearrange_c(argc, argv)
     int argc;			/* The number of arguments */
     void *argv[];		/* The arguments */
{
  LONG *in, *out;
  LONG *dim;
  SHORT *dim_order, n_dim;

  /*  Convert the IDL input parameters into C parameters.  */

  in        = (LONG *)    argv[0];
  out       = (LONG *)    argv[1];
  dim       = (LONG *)    argv[2];
  dim_order = (SHORT *)  argv[3];
  n_dim     = *(SHORT *) argv[4];

  /*  Call the C routine l_rearrange.  */

  l_rearrange(in,out,dim,dim_order,n_dim);
  return;
}

/*****************************************************************************/
/** ****    ****    ****    ****    ****    ****    ****    ****    ****    **/
/*****************************************************************************/
void d_rearrange_c(argc, argv)
     int argc;			/* The number of arguments */
     void *argv[];		/* The arguments */
{
  DOUBLE *in, *out;
  LONG *dim;
  SHORT *dim_order, n_dim;

  /*  Convert the IDL input parameters into C parameters.  */

  in        = (DOUBLE *) argv[0];
  out       = (DOUBLE *) argv[1];
  dim       = (LONG *)    argv[2];
  dim_order = (SHORT *)  argv[3];
  n_dim     = *(SHORT *) argv[4];

  /*  Call the C routine d_rearrange.  */

  d_rearrange(in,out,dim,dim_order,n_dim);
  return;
}
