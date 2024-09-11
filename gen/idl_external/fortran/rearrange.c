/*+
 * Project     : SOHO - CDS
 * 
 * Name        : c_rearrange, s_rearrange, l_rearrange, d_rearrange
 * 
 * Purpose     : CALL_EXTERNAL software to rearrange array dimensions.
 * 
 * Explanation : These routines support the IDL procedure REARRANGE.PRO, to
 *		 rearrange the dimensions in an array.  The concept is similar
 *		 to TRANSPOSE, but generalized to N dimensions.
 * 
 * Use         : Called using CALL_EXTERNAL by the IDL procedure REARRANGE.  In
 *		 VMS, these routines are called directly.  In Unix, the
 *		 intermediate routines *_rearrange_c are called instead.
 *
 *		 TEST1 = CALL_EXTERNAL(FILENAME, 'c_rearrange', IN, OUT, $
 *			DIM, FIX(DIM_ORDER), FIX(N_ELEMENTS(DIM_ORDER), $
 *			VALUE=[0b,0b,0b,0b,1b])
 * 
 *		 The actual routine called depends on the data type of the
 *		 input array.
 * 
 *			IDL data type	Routine
 * 
 *			Byte		c_rearrange
 *			Integer		s_rearrange
 *			Long		l_rearrange
 *			Float		l_rearrange
 *			Double		d_rearrange
 *			Complex		c_rearrange
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
 * Calls       : None.
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
#include <stdlib.h>
#include INCLUDE

/*****************************************************************************/
/*   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   */
/*****************************************************************************/
void c_rearrange(in,out,dim,dim_order,n_dim)
     BYTE in[];		/* The input array */
     BYTE out[];	/* The output array */
     LONG dim[];	/* The dimensions of the input array */
     SHORT dim_order[];	/* The order to rearrange the dimensions in */
     SHORT n_dim;	/* The number of dimensions */
{
  long n_elem;		/* Number of elements of in and out */
  long i;		/* Loop index */
  long j;		/* Dimension index */
  long ind[8];		/* Indices as a function of dimension */
  long delta1[8];	/* Amount to step forward as a function of dimension */
  long delta2[8];	/* Amount to step back as a function of dimension */
  long idim[8];		/* Reordered input dimension sizes */
  short done;		/* Boolean */

/* Calculate the number of elements in the array, and initialize the index,
   delta, and reordered dimension arrays. */

  n_elem = 1;
  for (i=0; i<n_dim; ++i)
    {
      n_elem *= dim[i];
      ind[i] = 0;
      delta1[i] = 1;
      delta2[i] = 1;
      idim[i] = dim[abs(dim_order[i])-1];
    }

/* Calculate how much each output dimension should be multiplied by to map into
   the input array.  The index into the input array is stepped by these factors
   depending on which dimension is being incremented. */

  for (i=0; i<n_dim; ++i)
    {
      if (abs(dim_order[i]) != 1)
	for (j=0; j<abs(dim_order[i])-1; ++j) delta1[i] *= dim[j];
      delta2[i] = delta1[i] * idim[i];
    }

/* Calculate the initial index in the input array, and determine what sign the
   delta arrays should have. */

      for (j=0; j<n_dim; ++j)
	if (dim_order[j] < 0)
	  {
	    in += delta1[j]*(idim[j] - 1);
	    delta1[j] = -delta1[j];
	    delta2[j] = -delta2[j];
	  }

/* Step through each element in the output array, and increment the indices for
   the dimensions. */

  for (i=0; i<n_elem; ++i)
    {
      if (i != 0)
	{

/* Increment the individual indices for the output array, starting with the
   first one.  Increment the output index by the appropriate amount. */

	  j = 0;
	  done = 0;
	  do
	    {
	      ++ind[j];
	      in += delta1[j];

/* If the index is exceeded, then step back to the beginning of that index, in
   both the input and output arrays, and go on to the next dimension index.
   Keep doing this until a dimension is reached that can be incremented without
   overflowing. */

	      if (ind[j] >= idim[j])
		{
		  ind[j] = 0;
		  in -= delta2[j];
		  ++j;
		}
	      else
		done = 1;
	    }
	  while (done == 0);
	}

/* Map the input array into the output array. */

      *out++ = *in;
    }
}

/*****************************************************************************/
/*   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   */
/*****************************************************************************/
void s_rearrange(in,out,dim,dim_order,n_dim)
     SHORT in[];	/* The input array */
     SHORT out[];	/* The output array */
     LONG dim[];	/* The dimensions of the input array */
     SHORT dim_order[];	/* The order to rearrange the dimensions in */
     SHORT n_dim;	/* The number of dimensions */
{
  long n_elem;		/* Number of elements of in and out */
  long i;		/* Loop index */
  long j;		/* Dimension index */
  long ind[8];		/* Indices as a function of dimension */
  long delta1[8];	/* Amount to step forward as a function of dimension */
  long delta2[8];	/* Amount to step back as a function of dimension */
  long idim[8];		/* Reordered input dimension sizes */
  short done;		/* Boolean */

/* Calculate the number of elements in the array, and initialize the index,
   delta, and reordered dimension arrays. */

  n_elem = 1;
  for (i=0; i<n_dim; ++i)
    {
      n_elem *= dim[i];
      ind[i] = 0;
      delta1[i] = 1;
      delta2[i] = 1;
      idim[i] = dim[abs(dim_order[i])-1];
    }

/* Calculate how much each output dimension should be multiplied by to map into
   the input array.  The index into the input array is stepped by these factors
   depending on which dimension is being incremented. */

  for (i=0; i<n_dim; ++i)
    {
      if (abs(dim_order[i]) != 1)
	for (j=0; j<abs(dim_order[i])-1; ++j) delta1[i] *= dim[j];
      delta2[i] = delta1[i] * idim[i];
    }

/* Calculate the initial index in the input array, and determine what sign the
   delta arrays should have. */

      for (j=0; j<n_dim; ++j)
	if (dim_order[j] < 0)
	  {
	    in += delta1[j]*(idim[j] - 1);
	    delta1[j] = -delta1[j];
	    delta2[j] = -delta2[j];
	  }

/* Step through each element in the output array, and increment the indices for
   the dimensions. */

  for (i=0; i<n_elem; ++i)
    {
      if (i != 0)
	{

/* Increment the individual indices for the output array, starting with the
   first one.  Increment the output index by the appropriate amount. */

	  j = 0;
	  done = 0;
	  do
	    {
	      ++ind[j];
	      in += delta1[j];

/* If the index is exceeded, then step back to the beginning of that index, in
   both the input and output arrays, and go on to the next dimension index.
   Keep doing this until a dimension is reached that can be incremented without
   overflowing. */

	      if (ind[j] >= idim[j])
		{
		  ind[j] = 0;
		  in -= delta2[j];
		  ++j;
		}
	      else
		done = 1;
	    }
	  while (done == 0);
	}

/* Map the input array into the output array. */

      *out++ = *in;
    }
}

/*****************************************************************************/
/*   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   */
/*****************************************************************************/
void l_rearrange(in,out,dim,dim_order,n_dim)
     LONG in[];		/* The input array */
     LONG out[];	/* The output array */
     LONG dim[];	/* The dimensions of the input array */
     SHORT dim_order[];	/* The order to rearrange the dimensions in */
     SHORT n_dim;	/* The number of dimensions */
{
  long n_elem;		/* Number of elements of in and out */
  long i;		/* Loop index */
  long j;		/* Dimension index */
  long ind[8];		/* Indices as a function of dimension */
  long delta1[8];	/* Amount to step forward as a function of dimension */
  long delta2[8];	/* Amount to step back as a function of dimension */
  long idim[8];		/* Reordered input dimension sizes */
  short done;		/* Boolean */

/* Calculate the number of elements in the array, and initialize the index,
   delta, and reordered dimension arrays. */

  n_elem = 1;
  for (i=0; i<n_dim; ++i)
    {
      n_elem *= dim[i];
      ind[i] = 0;
      delta1[i] = 1;
      delta2[i] = 1;
      idim[i] = dim[abs(dim_order[i])-1];
    }

/* Calculate how much each output dimension should be multiplied by to map into
   the input array.  The index into the input array is stepped by these factors
   depending on which dimension is being incremented. */

  for (i=0; i<n_dim; ++i)
    {
      if (abs(dim_order[i]) != 1)
	for (j=0; j<abs(dim_order[i])-1; ++j) delta1[i] *= dim[j];
      delta2[i] = delta1[i] * idim[i];
    }

/* Calculate the initial index in the input array, and determine what sign the
   delta arrays should have. */

      for (j=0; j<n_dim; ++j)
	if (dim_order[j] < 0)
	  {
	    in += delta1[j]*(idim[j] - 1);
	    delta1[j] = -delta1[j];
	    delta2[j] = -delta2[j];
	  }

/* Step through each element in the output array, and increment the indices for
   the dimensions. */

  for (i=0; i<n_elem; ++i)
    {
      if (i != 0)
	{

/* Increment the individual indices for the output array, starting with the
   first one.  Increment the output index by the appropriate amount. */

	  j = 0;
	  done = 0;
	  do
	    {
	      ++ind[j];
	      in += delta1[j];

/* If the index is exceeded, then step back to the beginning of that index, in
   both the input and output arrays, and go on to the next dimension index.
   Keep doing this until a dimension is reached that can be incremented without
   overflowing. */

	      if (ind[j] >= idim[j])
		{
		  ind[j] = 0;
		  in -= delta2[j];
		  ++j;
		}
	      else
		done = 1;
	    }
	  while (done == 0);
	}

/* Map the input array into the output array. */

      *out++ = *in;
    }
}

/*****************************************************************************/
/*   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   */
/*****************************************************************************/
void d_rearrange(in,out,dim,dim_order,n_dim)
     DOUBLE in[];	/* The input array */
     DOUBLE out[];	/* The output array */
     LONG dim[];	/* The dimensions of the input array */
     SHORT dim_order[];	/* The order to rearrange the dimensions in */
     SHORT n_dim;	/* The number of dimensions */
{
  long n_elem;		/* Number of elements of in and out */
  long i;		/* Loop index */
  long j;		/* Dimension index */
  long ind[8];		/* Indices as a function of dimension */
  long delta1[8];	/* Amount to step forward as a function of dimension */
  long delta2[8];	/* Amount to step back as a function of dimension */
  long idim[8];		/* Reordered input dimension sizes */
  short done;		/* Boolean */

/* Calculate the number of elements in the array, and initialize the index,
   delta, and reordered dimension arrays. */

  n_elem = 1;
  for (i=0; i<n_dim; ++i)
    {
      n_elem *= dim[i];
      ind[i] = 0;
      delta1[i] = 1;
      delta2[i] = 1;
      idim[i] = dim[abs(dim_order[i])-1];
    }

/* Calculate how much each output dimension should be multiplied by to map into
   the input array.  The index into the input array is stepped by these factors
   depending on which dimension is being incremented. */

  for (i=0; i<n_dim; ++i)
    {
      if (abs(dim_order[i]) != 1)
	for (j=0; j<abs(dim_order[i])-1; ++j) delta1[i] *= dim[j];
      delta2[i] = delta1[i] * idim[i];
    }

/* Calculate the initial index in the input array, and determine what sign the
   delta arrays should have. */

      for (j=0; j<n_dim; ++j)
	if (dim_order[j] < 0)
	  {
	    in += delta1[j]*(idim[j] - 1);
	    delta1[j] = -delta1[j];
	    delta2[j] = -delta2[j];
	  }

/* Step through each element in the output array, and increment the indices for
   the dimensions. */

  for (i=0; i<n_elem; ++i)
    {
      if (i != 0)
	{

/* Increment the individual indices for the output array, starting with the
   first one.  Increment the output index by the appropriate amount. */

	  j = 0;
	  done = 0;
	  do
	    {
	      ++ind[j];
	      in += delta1[j];

/* If the index is exceeded, then step back to the beginning of that index, in
   both the input and output arrays, and go on to the next dimension index.
   Keep doing this until a dimension is reached that can be incremented without
   overflowing. */

	      if (ind[j] >= idim[j])
		{
		  ind[j] = 0;
		  in -= delta2[j];
		  ++j;
		}
	      else
		done = 1;
	    }
	  while (done == 0);
	}

/* Map the input array into the output array. */

      *out++ = *in;
    }
}
