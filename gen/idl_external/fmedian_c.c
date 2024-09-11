#include <stdio.h>
#include INCLUDE

/*****************************************************************************/
/** ****    ****    ****    ****    ****    ****    ****    ****    ****    **/
/*****************************************************************************/
void f_median_c(argc, argv)
     int argc;			/* The number of arguments */
     void *argv[];		/* The arguments */
{
  float *in, *out, missing, *workspace;
  LONG ndim1, ndim2, n_width1, n_width2;

  /*  Convert the IDL input parameters into C parameters.  */

  in = (float *) argv[0];
  out = (float *) argv[1];
  ndim1 = *(LONG *) argv[2];
  ndim2 = *(LONG *) argv[3];
  n_width1 = *(LONG *) argv[4];
  n_width2 = *(LONG *) argv[5];
  missing = *(float *) argv[6];
  workspace = (float *) argv[7];

  /*  Call the C routine F_MEDIAN.  */

  f_median(in,out,ndim1,ndim2,n_width1,n_width2,missing,workspace);
  return;
}


/*****************************************************************************/
/** ****    ****    ****    ****    ****    ****    ****    ****    ****    **/
/*****************************************************************************/
void d_median_c(argc, argv)
     int argc;			/* The number of arguments */
     void *argv[];		/* The arguments */
{
  double *in, *out, missing, *workspace;
  LONG ndim1, ndim2, n_width1, n_width2;

  /*  Convert the IDL input parameters into C parameters.  */

  in = (double *) argv[0];
  out = (double *) argv[1];
  ndim1 = *(LONG *) argv[2];
  ndim2 = *(LONG *) argv[3];
  n_width1 = *(LONG *) argv[4];
  n_width2 = *(LONG *) argv[5];
  missing = *(double *) argv[6];
  workspace = (double *) argv[7];

  /*  Call the C routine F_MEDIAN.  */

  d_median(in,out,ndim1,ndim2,n_width1,n_width2,missing,workspace);
  return;
}


/*****************************************************************************/
/** ****    ****    ****    ****    ****    ****    ****    ****    ****    **/
/*****************************************************************************/
void l_median_c(argc, argv)
     int argc;			/* The number of arguments */
     void *argv[];		/* The arguments */
{
  LONG *in, *out, missing, *workspace;
  LONG ndim1, ndim2, n_width1, n_width2;

  /*  Convert the IDL input parameters into C parameters.  */

  in = (LONG *) argv[0];
  out = (LONG *) argv[1];
  ndim1 = *(LONG *) argv[2];
  ndim2 = *(LONG *) argv[3];
  n_width1 = *(LONG *) argv[4];
  n_width2 = *(LONG *) argv[5];
  missing = *(LONG *) argv[6];
  workspace = (LONG *) argv[7];

  /*  Call the C routine F_MEDIAN.  */

  l_median(in,out,ndim1,ndim2,n_width1,n_width2,missing,workspace);
  return;
}


