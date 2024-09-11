/* If the widths given for the median filter are out of range, then return the
   original array unmodified.  */

if ((((n_width1 > n_width2) ? n_width1 : n_width2) < 2) ^ (ndim1 < 1)) {
  for (i=0; i < (ndim1 * ndim2); ++i) out[i] = in[i];
}
else
{

/* Calculate the half width points. */

  nw1 = (n_width1 - 1) / 2;
  nw2 = (n_width2 - 1) / 2;

/* Find the range of points to use in performing the median filter.  Be
   careful not to exceed the limits of the input array. */

  for (j=0; j < ndim2; ++j) {
    j1 = j - nw2;
    if (j1 < 0) j1 = 0;
    j2 = j + n_width2 - nw2 - 1;
    if (j2 > (ndim2-1)) j2 = ndim2 - 1;
    for (i=0; i < ndim1; ++i) {
      i1 = i - nw1;
      if (i1 < 0) i1 = 0;
      i2 = i + n_width1 - nw1 - 1;
      if (i2 > (ndim1-1)) i2 = ndim1 - 1;

      /* Store the points in the box found above into WORKSPACE for sorting. */

      k = 0;
      for (jj=j1; jj<=j2; ++jj) {
	for (ii=i1; ii<=i2; ++ii) {
	  if (in[ii+ndim1*jj] != missing) {
	    workspace[k] = in[ii+ndim1*jj];
	    ++k;
	  }
	}
      }
      n_sort = k;
      mid = n_sort/2;

      /* If there are no points, then flag pixel as missing. */

      if (n_sort == 0)
	out[i+ndim1*j] = missing;

      /* If there are only one or two points, then simply do the average. */

      else if (n_sort <= 2) {
	out[i+ndim1*j] = 0;
	for (k=0; k<n_sort; ++k) out[i+ndim1*j] += workspace[k];
	out[i+ndim1*j] = out[i+ndim1*j] / n_sort;
      }

      /* Otherwise, sort the points in ascending order, and find the
	 midpoint. */

      else {
	switch (ktype) {
	case 3: 
	  l_qsrt_k(workspace,mid,n_sort);
	  break;
	case 4:
	  f_qsrt_k(workspace,mid,n_sort);
	  break;
	case 5: 
	  d_qsrt_k(workspace,mid,n_sort);
	  break;
	}
	out[i+ndim1*j] = workspace[mid];
      }
    }
  }
}
