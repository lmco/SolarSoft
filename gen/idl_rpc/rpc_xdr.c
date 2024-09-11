/* 
 * rpc_xdr.c - 
 * This file contains routines required to perform XDR opts on 
 * the non-standard structures passed used with the IDL rpc service.
 */
 
/*
  Copyright (c) 1996-1997, Research Systems Inc.  All rights reserved.
  This software includes information which is proprietary to and a
  trade secret of Research Systems, Inc.  It is not to be disclosed
  to anyone outside of this organization. Reproduction by any means
  whatsoever is  prohibited without express written permission.
  */

static char rcsid[] = "$Id: rpc_xdr.c,v 1.31 1997/01/18 08:23:00 ali Exp $";


#include "idl_rpc.h"
#include "rpc_xdr.h"

/*
 * Determine what array and string functions we should use. If we 
 * are on the server side, use the function available via callable
 * IDL, otherwise use the client side functions.
 */

#ifndef IDL_RPC_CLIENT

#define    IDL_RPC_MAKE_ARRAY           IDL_MakeTempArray
#define    IDL_RPC_STR_ENSURE           IDL_StrEnsureLength
#define    IDL_RPC_VAR_COPY             IDL_VarCopy
#define    IDL_RPC_GET_TMP              IDL_Gettmp
#else

/*
 * Routines available on the client side 
 */

#define    IDL_RPC_MAKE_ARRAY           IDL_RPCMakeArray
#define    IDL_RPC_STR_ENSURE           IDL_RPCStrEnsureLength
#define    IDL_RPC_VAR_COPY             IDL_RPCVarCopy
#define    IDL_RPC_GET_TMP              IDL_RPCGettmp
#endif

/*
 * Declare the xdr routines.
 *
 ***************************************************
 * IDL_RPC_xdr_mips_double()
 *
 * Declare XDR for doubles on mips machines. This is required because
 * DecStation 3100 and other mips machines trash XDR doubles. This routine
 * uses xdr_long() to output the double properly. This works because the
 * mips uses ieee math, the XDR standard.
 */

#if defined(mips) || defined(AUX)
publish bool_t IDL_RPC_xdr_mips_double( XDR *xdrs, double *p)
{
#ifdef ultrix			/* Little Endian */
  return(XDR_LONG(xdrs, ((IDL_LONG *) p) + 1) &&
	 XDR_LONG(xdrs, (IDL_LONG *) p));
#else				/* Big endian */
  return(XDR_LONG(xdrs, (IDL_LONG *) p)
	 && XDR_LONG(xdrs, ((IDL_LONG *) p + 1)));
#endif
}
#endif

/*************************************************************
 *  IDL_RPC_xdr_complex
 *      This routine is used to perform xdr ops on an IDL complex
 */
publish bool_t IDL_RPC_xdr_complex( xdrsp, p )
    XDR         * xdrsp;
    IDL_COMPLEX     * p;
{
    return(XDR_FLOAT(xdrsp, (XDR_FLOAT_TYPE *) &(p->r))
	   && XDR_FLOAT(xdrsp, (XDR_FLOAT_TYPE *) &(p->i)));
}
/*************************************************************
 *  IDL_RPC_xdr_dcomplex
 *      This routine is used to perform xdr ops on an IDL double complex
 */
publish bool_t IDL_RPC_xdr_dcomplex(XDR *xdrs, IDL_DCOMPLEX *p)
{
  return(XDR_DOUBLE(xdrs, &(p->r)) && XDR_DOUBLE(xdrs, &(p->i)));
}

/*************************************************************
 * IDL_RPC_xdr_string
 *      This routine is used to perform xdr ops on an IDL string struct
 */
publish bool_t IDL_RPC_xdr_string( XDR *xdrs, IDL_STRING *pStr)
{
   bool_t  statust;
   short length = pStr->slen;

/*
 * First read/write the length
 */
   if(!xdr_short(xdrs, (short*)&length))
       return FALSE;
/*
 * If we are reading the string, make sure that it is long enough
 */
   if(xdrs->x_op == XDR_DECODE){
      pStr->slen = 0;
      pStr->stype= 0;
      IDL_RPC_STR_ENSURE(pStr, length);
      if(length && pStr->s == NULL)
	 return FALSE;		/* had an error */
   }
/*
 * Read/write the string, but only if it is non-null
 */
   
   return(length ? xdr_string(xdrs, &pStr->s, length) : TRUE);
}

/*************************************************************
 * IDL_RPC_xdr_array
 *
 *   This function performs xdr ops on an IDL array structure.
 *
 */
static bool_t IDL_RPC_xdr_array(XDR *xdrsp, IDL_VPTR pVar)
{
   xdrproc_t   xdr_data_func;	/* function used for array data */
   char       *pData;		/* pointer to array data area   */
   char       *pDim;		/* pointer to dimension array */
   u_int       dimMax = IDL_MAX_ARRAY_DIM;
   int         status;		/* status flag for xdr ops */
   IDL_ARRAY  *pTmpArr;		/* temporary array struct  */
   IDL_ARRAY   sArr;
   IDL_VPTR   vTmp;
/*
 * If we are ecoding, copy over the data contained in the pTmpArr
 * array field. 
 */
   if(xdrsp->x_op != XDR_DECODE){
     if(pVar->flags & IDL_V_ARR) /* is this an array */
        pTmpArr = pVar->value.arr;
     else
        return FALSE;		/* not an array */
   }else 
     pTmpArr = &sArr;
/*
 * read/write the fields that make up the array descriptor. This includes
 * all except the data section.
 */
   pDim = (char *)pTmpArr->dim;
   status = XDR_LONG(xdrsp, IDL_LONGA(pTmpArr->elt_len)) &&
	    XDR_LONG(xdrsp, IDL_LONGA(pTmpArr->arr_len)) &&
	    XDR_LONG(xdrsp, IDL_LONGA(pTmpArr->n_elts)) &&
	    xdr_u_char(xdrsp, IDL_UCHARA(pTmpArr->n_dim)) &&
	    xdr_u_char(xdrsp, IDL_UCHARA(pTmpArr->flags)) &&
	    xdr_short(xdrsp, IDL_SHORTA(pTmpArr->file_unit)) &&
	    xdr_array(xdrsp, &pDim, &dimMax, (u_int)dimMax,
		     sizeof(IDL_LONG), (xdrproc_t)XDR_LONG);
   if( status == 0)
      return FALSE;
/*
 * Determine what xdr function will be required to read/write the data 
 */
   switch( pVar->type ){
   case IDL_TYP_BYTE:       
      xdr_data_func   =  (xdrproc_t)xdr_u_char; 
      break;
   case IDL_TYP_INT:  
      xdr_data_func   =  (xdrproc_t)xdr_short;  
      break;
   case IDL_TYP_LONG:
      xdr_data_func   =  (xdrproc_t)XDR_LONG;
      break;
   case IDL_TYP_FLOAT:
      xdr_data_func   =  (xdrproc_t)XDR_FLOAT;  
      break;
   case IDL_TYP_DOUBLE:   
      xdr_data_func   =  (xdrproc_t)XDR_DOUBLE; 
      break;
   case IDL_TYP_COMPLEX:    
      xdr_data_func   =  (xdrproc_t)IDL_RPC_xdr_complex; 
      break;
   case IDL_TYP_STRING:     
      xdr_data_func   =  (xdrproc_t)IDL_RPC_xdr_string; 
      break;
   case IDL_TYP_DCOMPLEX:   
      xdr_data_func   =  (xdrproc_t)IDL_RPC_xdr_dcomplex; 
      break;
   default:
      return FALSE;		/* An Error Condition */
   }
/*
 * If we are decoding, we will need to get an array of the 
 * desired size and type.
 */
   if(xdrsp->x_op == XDR_DECODE){
      pData = IDL_RPC_MAKE_ARRAY(pVar->type, pTmpArr->n_dim, (IDL_LONG*)pDim, 
				IDL_BARR_INI_ZERO, &vTmp);
   /*
    * Move this array over to the input variable. Will free up any
    * data that needs to be freed.
    */ 
      IDL_RPC_VAR_COPY(vTmp, pVar);  
        				
    }else 
      pData = (char*)pVar->value.arr->data;
/*
 *  Now to Xdr the data
 */
    return xdr_array(xdrsp, &pData, (u_int*)&pTmpArr->n_elts,
		      pTmpArr->n_elts, pTmpArr->elt_len, xdr_data_func);
}
/*************************************************************
 * IDL_RPC_xdr_vptr()
 *
 * Used to perform xdr ops on an IDL_VPTR
 */
bool_t IDL_RPC_xdr_vptr(XDR *xdrs, IDL_VPTR *pVar)
{
  bool_t status;
  IDL_VPTR  ptmpVar;
  UCHAR     flags;

  if(xdrs->x_op == XDR_DECODE){
     *pVar = IDL_RPC_GET_TMP();	/* Need a variable */
  }else {
    /* client uses the tmp flags */
     flags = ~IDL_V_DYNAMIC & (~IDL_V_TEMP & (*pVar)->flags);	
  }
  ptmpVar = *pVar;

  status = xdr_u_char(xdrs, &ptmpVar->type);
  status = (status && xdr_u_char(xdrs, &flags));

  if(xdrs->x_op == XDR_DECODE)
     ptmpVar->flags |= flags;  /* preserve the old flags */

  if(status == FALSE)
     return status;
/*
 * Do we have an array?
 */
   if(ptmpVar->flags & IDL_V_ARR)
      return IDL_RPC_xdr_array(xdrs, ptmpVar);
/*
 * Must have a scalar, Determine the type and xdr
 */
   switch(ptmpVar->type){
   case IDL_TYP_UNDEF:
      status = TRUE;
      break;
   case IDL_TYP_BYTE:
      status = xdr_u_char(xdrs, &ptmpVar->value.c);
      break;
   case IDL_TYP_INT:
      status = xdr_short(xdrs, &ptmpVar->value.i);
      break;
   case IDL_TYP_LONG:
      status = XDR_LONG(xdrs, &ptmpVar->value.l);
      break;
   case IDL_TYP_FLOAT:
      status = XDR_FLOAT(xdrs, &ptmpVar->value.f);
      break;
   case IDL_TYP_DOUBLE:
      status = XDR_DOUBLE(xdrs, &ptmpVar->value.d);
      break;
   case IDL_TYP_COMPLEX:
      status = IDL_RPC_xdr_complex(xdrs, &ptmpVar->value.cmp);
      break;
   case IDL_TYP_STRING:
      status = IDL_RPC_xdr_string(xdrs, &ptmpVar->value.str);
   /*
    * Make sure that the dynamic flag is set 
    */
      if(ptmpVar->value.str.stype)
         ptmpVar->flags |= IDL_V_DYNAMIC;
      break;
   case IDL_TYP_DCOMPLEX:
      status = IDL_RPC_xdr_dcomplex(xdrs, &ptmpVar->value.dcmp);
      break;
   default: status = FALSE;
   }
   return status;
}
/*************************************************************
 * IDL_RPC_xdr_variable()
 *
 * Used to perform xdr ops on an RPC variable structure. This 
 * structure contains the variable name and an IDL_VPTR.
 */
bool_t IDL_RPC_xdr_variable(XDR *xdrs, IDL_RPC_VARIABLE *pVar)
{
   unsigned int maxElem = MAXIDLEN +1;
   return(xdr_wrapstring(xdrs, &pVar->name) &&
	  IDL_RPC_xdr_vptr(xdrs, &pVar->pVariable));
}
/*************************************************************
 * IDL_RPC_xdr_line_s()
 * 
 * This function is used to perform XDR ops on a structure 
 * of type IDL_RPC_LINE_S. This structure is used to pass 
 * idl output lines between the rpc server and client.
 */

bool_t IDL_RPC_xdr_line_s(XDR *xdrs, IDL_RPC_LINE_S *pLine)
{
   return (xdr_int(xdrs, &pLine->flags) &&
	    xdr_wrapstring(xdrs, &pLine->buf));
}
  


