/*
 * rpc_xdr.h
 *
 *	$Id: rpc_xdr.h,v 1.2 1997/01/18 08:23:00 ali Exp $
 */

/*
   Copyright (c) 1990-1997, Research Systems Inc.  All rights reserved.
  This software includes information which is proprietary to and a
  trade secret of Research Systems, Inc.  It is not to be disclosed
  to anyone outside of this organization. Reproduction by any means
  whatsoever is  prohibited without express written permission.
  */


#ifndef _RPC_IDL_XDR_
#define _RPC_IDL_XDR_

/*
 * Nothing here yet
 */


/* Mips Ultrix screws up float and double data */
#if defined(cow) || defined(AUX)
#define XDR_MIPS_HACK
#define XDR_FLOAT xdr_long
typedef long XDR_FLOAT_TYPE;
#define XDR_DOUBLE IDL_RPC_xdr_mips_double
#else
typedef float XDR_FLOAT_TYPE;
#endif


/* Vax Ultrix screws up floating 0.0 */
#if defined(vax) && defined(ultrix)
#define XDR_FLOAT IDL_xdr_vax_ultrix_float
#endif


#ifndef XDR_FLOAT		/* Machines with correct xdr_float() */
#define XDR_FLOAT xdr_float
#endif

#ifndef XDR_DOUBLE		/* Machines with correct xdr_double() */
#define XDR_DOUBLE xdr_double
#endif

/* On 64-bit systems, use xdr_int() instead of xdr_long() */
#ifdef LONG_NOT_32
#define XDR_LONG xdr_int
#else
#define XDR_LONG xdr_long
#endif

bool_t IDL_RPC_xdr_line_s (XDR *xdrs, IDL_RPC_LINE_S *pLine);
bool_t IDL_RPC_xdr_variable(XDR *xdrs, IDL_RPC_VARIABLE *pVar);
bool_t IDL_RPC_xdr_vptr(XDR *xdrs, IDL_VPTR *pVar);
static bool_t IDL_RPC_xdr_array(XDR *xdrsp, IDL_VPTR pVar);
publish bool_t IDL_RPC_xdr_mips_double( XDR *xdrs, double *p);
#endif



