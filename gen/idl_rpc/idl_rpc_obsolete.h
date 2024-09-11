/*
 *	$Id: idl_rpc_obsolete.h,v 1.2 1997/01/29 23:24:49 kirk Exp $
 */

/*
  Copyright (c) 1992-1997, Research Systems Inc.  All rights reserved.
  This software includes information which is proprietary to and a
  trade secret of Research Systems, Inc.  It is not to be disclosed
  to anyone outside of this organization. Reproduction by any means
  whatsoever is  prohibited without express written permission.
  */

/*
 * If we are a client, define name lenght macros
 */

#ifndef MAXIDLEN
#define MAXIDLEN     128
#endif

/*              Biggest string we can XDR                       */

#define         MAX_STRING_LEN          512

/*              Version/portmapper id                           */

#define         IDL_DEFAULT_ID          0x2010CAFE
#define         IDL_DEFAULT_VERSION     1

/*              Server requests available                       */

#define         OLDGET_VARIABLE         1
#define         OLDSET_VARIABLE         2
#define         RUN_COMMAND             3
#define         FORCED_EXIT             4
#define		RUN_INTERACTIVE		5
#define         GET_VARIABLE            8
#define         SET_VARIABLE            9

/*      Data Extraction Macros                                  */

#define         VarIsArray(v)           ((v)->Variable->flags & IDL_V_ARR)
#define         GetVarType(v)           ((v)->Variable->type)
#define         GetVarByte(v)           ((v)->Variable->value.c)
#define         GetVarInt(v)            ((v)->Variable->value.i)
#define         GetVarLong(v)           ((v)->Variable->value.l)
#define         GetVarFloat(v)          ((v)->Variable->value.f)
#define         GetVarDouble(v)         ((v)->Variable->value.d)
#define         GetVarComplex(v)        ((v)->Variable->value.cmp)
#define         GetVarDComplex(v)        ((v)->Variable->value.dcmp)
#define         GetVarString(v)         STRING_STR((v)->Variable->value.str)

#define         GetArrayData(v)         (v)->Variable->value.arr->data
#define         GetArrayNumDims(v)      (v)->Variable->value.arr->n_dim
#define         GetArrayDimensions(v)   (v)->Variable->value.arr->dim


/* 
 * Define a variable name that can be used to variable type conversions
 */

#define IDL_RPC_CON_VAR "_THIS$VARIABLE$IS$FOR$RPC$VARIABLE$CONVERSION$ONLY_"

/*      XDR structure used to transfer a variable                       */

typedef struct _VARINFO {

    char        Name[MAXIDLEN+1];	/* Variable name in IDL         */
    IDL_VPTR        Variable;		/* IDL internal definition      */
    IDL_LONG        Length;	/* Array length (0 for dynamic, */
					/* sizeof(data) for statics     */
} varinfo_t;

/************************************************************************/
/*      IDL RPC interface routines                                      */
/************************************************************************/

publish  CLIENT *register_idl_client IDL_ARG_PROTO((IDL_LONG server_id,
						   char *hostname,
						   struct timeval *timeout));
publish  void unregister_idl_client IDL_ARG_PROTO((CLIENT *client));
publish  int  kill_server IDL_ARG_PROTO((CLIENT *client));
publish  int  set_idl_timeout IDL_ARG_PROTO((struct timeval *timeout));
publish  int  send_idl_command IDL_ARG_PROTO((CLIENT* client, char* cmd));
publish  void free_idl_var IDL_ARG_PROTO((varinfo_t* var ));
publish  int  set_idl_variable IDL_ARG_PROTO((CLIENT* client, varinfo_t* var));
publish  int  get_idl_variable IDL_ARG_PROTO((CLIENT* client,
					     char* name,
					     varinfo_t* var,
					     int typecode));

/************************************************************************/
/*      Helper function declarations                                    */
/************************************************************************/

publish  int     v_make_byte IDL_ARG_PROTO((varinfo_t* var,
					   char* name,
					   unsigned int c));
publish  int     v_make_int IDL_ARG_PROTO((varinfo_t* var,
					  char* name,
					  int i));
publish  int     v_make_long IDL_ARG_PROTO((varinfo_t* var,
					   char* name,
					   IDL_LONG l));
publish  int     v_make_float IDL_ARG_PROTO((varinfo_t* var,
					    char* name,
					    double f));
publish  int     v_make_double IDL_ARG_PROTO((varinfo_t* var,
					     char* name,
					     double d));
publish  int     v_make_complex IDL_ARG_PROTO((varinfo_t* var,
					      char* name,
					      double real, double imag));
publish  int     v_make_dcomplex IDL_ARG_PROTO((varinfo_t* var,
					      char* name,
					      double real, double imag));
publish  int     v_make_string IDL_ARG_PROTO((varinfo_t* var,
					     char* name,
					     char* s));
publish  int     v_fill_array IDL_ARG_PROTO((varinfo_t* var,
					    char* name, int type,
					    int ndims, IDL_LONG dims[],
					    UCHAR* data,IDL_LONG data_length));






