#include <stdio.h>

/*****************************************************************************/
/** ****    ****    ****    ****    ****    ****    ****    ****    ****    **/
/*****************************************************************************/
void f_median_c(argc, argv)
     int argc;			/* The number of arguments */
     void *argv[];		/* The arguments */
{
  float *in, *out, *missing, *workspace;
  long *ndim1, *ndim2, *n_width1, *n_width2;

  /*  Convert the IDL input parameters into FORTRAN parameters.  */

  in = (float *) argv[0];
  out = (float *) argv[1];
  ndim1 = (long *) argv[2];
  ndim2 = (long *) argv[3];
  n_width1 = (long *) argv[4];
  n_width2 = (long *) argv[5];
  missing = (float *) argv[6];
  workspace = (float *) argv[7];

  /*  Call the FORTRAN routine F_MEDIAN.  */

  f_median_(in,out,ndim1,ndim2,n_width1,n_width2,missing,workspace);
  return;
}


/*****************************************************************************/
/** ****    ****    ****    ****    ****    ****    ****    ****    ****    **/
/*****************************************************************************/
void d_median_c(argc, argv)
     int argc;			/* The number of arguments */
     void *argv[];		/* The arguments */
{
  double *in, *out, *missing, *workspace;
  long *ndim1, *ndim2, *n_width1, *n_width2;

  /*  Convert the IDL input parameters into FORTRAN parameters.  */

  in = (double *) argv[0];
  out = (double *) argv[1];
  ndim1 = (long *) argv[2];
  ndim2 = (long *) argv[3];
  n_width1 = (long *) argv[4];
  n_width2 = (long *) argv[5];
  missing = (double *) argv[6];
  workspace = (double *) argv[7];

  /*  Call the FORTRAN routine F_MEDIAN.  */

  d_median_(in,out,ndim1,ndim2,n_width1,n_width2,missing,workspace);
  return;
}


/*****************************************************************************/
/** ****    ****    ****    ****    ****    ****    ****    ****    ****    **/
/*****************************************************************************/
void l_median_c(argc, argv)
     int argc;			/* The number of arguments */
     void *argv[];		/* The arguments */
{
  long *in, *out, *missing, *workspace;
  long *ndim1, *ndim2, *n_width1, *n_width2;

  /*  Convert the IDL input parameters into FORTRAN parameters.  */

  in = (long *) argv[0];
  out = (long *) argv[1];
  ndim1 = (long *) argv[2];
  ndim2 = (long *) argv[3];
  n_width1 = (long *) argv[4];
  n_width2 = (long *) argv[5];
  missing = (long *) argv[6];
  workspace = (long *) argv[7];

  /*  Call the FORTRAN routine F_MEDIAN.  */

  l_median_(in,out,ndim1,ndim2,n_width1,n_width2,missing,workspace);
  return;
}


