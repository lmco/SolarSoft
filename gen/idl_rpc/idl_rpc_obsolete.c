/*
 *  $Id: idl_rpc_obsolete.c,v 1.2 1997/01/29 23:24:33 kirk Exp $
 */
/*
  Copyright (c) 1992-1997, Research Systems Inc.  All rights reserved.
  This software includes information which is proprietary to and a
  trade secret of Research Systems, Inc.  It is not to be disclosed
  to anyone outside of this organization. Reproduction by any means
  whatsoever is  prohibited without express written permission.
  */

/*
 * This file contains routines that are used to emulate the obsolete 
 * method of calling IDL rpc's.
 *
 * Note: All of the old rpc functionality is available to the user
 *       except the ability to place the rpc server into *interactive*
 *       mode. 
 */

#include <string.h>

#include "idl_rpc.h"
#include "idl_rpc_obsolete.h"


/***************************************************************************
 * free_idl_var()
 * 
 * Purpose:
 *    	This routine will free all dynamic memory associated with
 *    	a variable.
 */
void free_idl_var(varinfo_t * var)
{
   if(var->Variable == (IDL_VPTR)NULL || var->Length != 0)
      return;
/*
 * If length equals 0, then this should be a dynamic variable
 */
   IDL_RPCDeltmp(var->Variable); /* will free all memory */
   var->Variable = (IDL_VPTR)NULL;
}
/***************************************************************************
 * get_idl_variable()
 *
 * Purpose:
 * 	This function is used to retrieve the value of the variable name
 * 	given. The routine also provides the ability to have the value 
 * 	returned converted to a desired type.
 */
int get_idl_variable(CLIENT *client, char *name, varinfo_t *var,
		     int typecode)
{
    int  status;		/* holds return status values */
    char *funcName;		/* the name of the conversion name */
    char buffer[248];		/* string buffer for commands */

/*
 *  Check the input parameters
 */
    if(name == (char*)NULL || var == (varinfo_t*)NULL)
       return -1;
/*
 *  If there is no conversion desired, just get the variable
 */
    if(typecode <= 0){
       var->Variable = IDL_RPCGetMainVariable(client, name);
       if(var->Variable == (IDL_VPTR)NULL){
          return 0;
       }
    }else{			/* perform conversion */
    /*
     * what is the function name needed for the conversion?
     */       
       switch(typecode){
       case IDL_TYP_BYTE:
	 funcName="byte";
	 break;
       case IDL_TYP_INT:
	 funcName="fix";
	 break;
       case IDL_TYP_LONG:
	 funcName="long";
	 break;
       case IDL_TYP_FLOAT:
	 funcName="float";
	 break;
       case IDL_TYP_DOUBLE:
	 funcName="double";
	 break;
       case IDL_TYP_STRING:
	 funcName="string";
	 break;
       case IDL_TYP_COMPLEX:
	 funcName="complex";
	 break;
       case IDL_TYP_DCOMPLEX:
	 funcName="dcomplex";
	 break;
       default:
	 funcName="long";
	 break;
       }
    /* 
     * build a command line to do the conversion
     */
       sprintf(buffer, "if(n_elements(%s) gt 0)then %s=%s(%s)", 
	       name, IDL_RPC_CON_VAR, funcName, name);
       status = IDL_RPCExecuteStr(client, buffer); /* perform conversion */
       if(status != 0){
	 return 0;
       }
       var->Variable = IDL_RPCGetMainVariable(client, IDL_RPC_CON_VAR);
       if(var->Variable == (IDL_VPTR)NULL){
          return 0;
       }
    }
    strncpy(var->Name, name, MAXIDLEN);	/* copy in the name  */
/* 
 *  Set the conversion varialbe to 0
 */
    sprintf(buffer, "%s = 0", IDL_RPC_CON_VAR);
    status = IDL_RPCExecuteStr(client, buffer);

    return 1;
}
/***************************************************************************
 * kill_server()
 *
 * This function is used to kill the IDL server
 */
int kill_server(CLIENT *client)
{
    return IDL_RPCCleanup(client, 1);	/* pretty easy */
}
/***************************************************************************
 * register_idl_client()
 *
 * Used to register with the IDL server.
 */
CLIENT * register_idl_client(IDL_LONG server_id, char* hostname, 
			     struct timeval* timeout)
{
  CLIENT *pClient;

/*
 * Initialize the IDL RPC session
 */   
    pClient = IDL_RPCInit(server_id, hostname);

/*
 * If we have a client struct and the time value looks sane, set the 
 * timeout.
 */ 
   if(pClient != (CLIENT*)NULL && timeout->tv_sec > 0) 
      (void)IDL_RPCTimeout( timeout->tv_sec);

   return pClient;
}
/***************************************************************************
 * send_idl_command()
 *
 * Used to send a command string to IDL
 */
int send_idl_command(CLIENT *client, char *command)
{
   if(command == (char*)NULL || *command == (char)NULL)
      return 0;

   return (IDL_RPCExecuteStr(client, command) == 0 ? 1 : -1); 
}
/***************************************************************************
 * set_idl_timeout()
 *
 * Sets the rpc timeout. Only the second value is used.
 */
int set_idl_timout( struct timeval * timeout)
{
   return IDL_RPCTimeout(timeout->tv_sec); /* only use seconds with new API */
}
/***************************************************************************
 * set_idl_variable()
 *
 * Used to set a variable at the main level of IDL.
 */
int set_idl_variable(CLIENT *client, varinfo_t * var)
{
/*
 * Just call IDL_RPCSetMainVariable
 */
  return (IDL_RPCSetMainVariable(client, var->Name, var->Variable) 
	  == 0 ? 1 : 0 ); 
}
/***************************************************************************
 * unregister_idl_client()
 *
 * Unregisters the IDL client, but doesnt kill the RPC server
 */
void unregister_idl_client(CLIENT *client)
{
   IDL_RPCCleanup(client, 0);
}
/***************************************************************************
 * Now for the "helper" functions
 *
 */
int v_make_byte( varinfo_t *var, char *name, unsigned int c)
{
   IDL_ALLTYPES   type_s;

/*
 * Fill in the varinfo_t struct
 */
   strncpy( var->Name, name, MAXIDLEN );
   var->Name[ MAXIDLEN ] = 0;

/*
 * Get a temporary variable if we need it
 */
   if(var->Variable == (IDL_VPTR)NULL){
      var->Variable = IDL_RPCGettmp();
      if(var->Variable == (IDL_VPTR)NULL)
	 return 0;
   }
/*
 * Store the scalar using the client side API.
 */
   type_s.c  = (UCHAR)c;	
   IDL_RPCStoreScalar( var->Variable, IDL_TYP_BYTE, type_s);
   return 1;
}
/***************************************************************************
 * v_make_int()
 *
 */
int v_make_int( varinfo_t *var, char *name, int value)
{
   IDL_ALLTYPES   type_s;

/*
 * fill in the varinfo_t struct
 */
   strncpy( var->Name, name, MAXIDLEN );
   var->Name[ MAXIDLEN ] = 0;
/*
 * Get a vptr if we need one.
 */
   if(var->Variable == (IDL_VPTR)NULL){
      var->Variable = IDL_RPCGettmp();
      if(var->Variable == (IDL_VPTR)NULL)
	 return 0;
   }
/*
 * Store the value.
 */
   type_s.i  = value;
   IDL_RPCStoreScalar( var->Variable, IDL_TYP_INT, type_s);
   return 1;
}
/***************************************************************************
 * v_make_long()
 *
 */
int v_make_long( varinfo_t *var, char *name, IDL_LONG value)
{
   IDL_ALLTYPES   type_s;

/*
 * fill in the varinfo_t struct
 */
   strncpy( var->Name, name, MAXIDLEN );
   var->Name[ MAXIDLEN ] = 0;
/*
 * get a vptr if we need one
 */
   if(var->Variable == (IDL_VPTR)NULL){
      var->Variable = IDL_RPCGettmp();
      if(var->Variable == (IDL_VPTR)NULL)
	 return 0;
   }
/*
 * Store the value.
 */
   type_s.l  = value;
   IDL_RPCStoreScalar( var->Variable, IDL_TYP_LONG, type_s);
   return 1;
}
/***************************************************************************
 * v_make_float()
 *
 */
int v_make_float( varinfo_t *var, char *name, double value)
{
   IDL_ALLTYPES   type_s;

/*
 * fill in the varinfo_t struct.
 */
   strncpy( var->Name, name, MAXIDLEN );
   var->Name[ MAXIDLEN ] = 0;
/*
 * Get a vptr if needed 
 */
   if(var->Variable == (IDL_VPTR)NULL){
      var->Variable = IDL_RPCGettmp();
      if(var->Variable == (IDL_VPTR)NULL)
	 return 0;
   }
/*
 * Store the value in the variable
 */
   type_s.f  = value;
   IDL_RPCStoreScalar( var->Variable, IDL_TYP_FLOAT, type_s);
   return 1;
}
/***************************************************************************
 * v_make_double()
 *
 */
int v_make_double( varinfo_t *var, char *name, double value)
{
   IDL_ALLTYPES   type_s;

/*
 * fill in the varinfo_t struct
 */
   strncpy( var->Name, name, MAXIDLEN );
   var->Name[ MAXIDLEN ] = 0;
/*
 * Get a variable if needed 
 */
   if(var->Variable == (IDL_VPTR)NULL){
      var->Variable = IDL_RPCGettmp();
      if(var->Variable == (IDL_VPTR)NULL)
	 return 0;
   }
/*
 * Store the scalar
 */
   type_s.d  = value;
   IDL_RPCStoreScalar( var->Variable, IDL_TYP_DOUBLE, type_s);
   return 1;
}
/***************************************************************************
 * v_make_complex()
 *
 */
int v_make_complex( varinfo_t *var, char *name, double r, double i)
{
   IDL_ALLTYPES   type_s;

/*
 * Fill in the varinfo_t struct
 */
   strncpy( var->Name, name, MAXIDLEN );
   var->Name[ MAXIDLEN ] = 0;
/*
 * get a vptr if needed
 */
   if(var->Variable == (IDL_VPTR)NULL){
      var->Variable = IDL_RPCGettmp();
      if(var->Variable == (IDL_VPTR)NULL)
	 return 0;
   }
/* 
 * Store the value
 */
   type_s.cmp.r  = (float)r;
   type_s.cmp.i  = (float)i;
   IDL_RPCStoreScalar( var->Variable, IDL_TYP_COMPLEX, type_s);
   return 1;
}
/***************************************************************************
 * v_make_dcomplex()
 *
 */
int v_make_dcomplex( varinfo_t *var, char *name, double r, double i)
{
   IDL_ALLTYPES   type_s;

/* 
 * Fill in the varinfo_t struct
 */
   strncpy( var->Name, name, MAXIDLEN );
   var->Name[ MAXIDLEN ] = 0;
/*
 * Get a vptr if we need it
 */
   if(var->Variable == (IDL_VPTR)NULL){
      var->Variable = IDL_RPCGettmp();
      if(var->Variable == (IDL_VPTR)NULL)
	 return 0;
   }
/*
 * Store the values in the vptr
 */
   type_s.dcmp.r = r;
   type_s.dcmp.i = i;
   IDL_RPCStoreScalar( var->Variable, IDL_TYP_DCOMPLEX, type_s);
   return 1;
}
/***************************************************************************
 * v_make_string()
 *
 */
int v_make_string( varinfo_t *var, char *name, char * value)
{
   IDL_ALLTYPES   type_s;

/*
 * Fill in the varinfo_t struct
 */
   strncpy( var->Name, name, MAXIDLEN );
   var->Name[ MAXIDLEN ] = 0;
/* 
 * Get a vptr if needed
 */
   if(var->Variable == (IDL_VPTR)NULL){
      var->Variable = IDL_RPCGettmp();
      if(var->Variable == (IDL_VPTR)NULL)
	 return 0;
   }
/*
 * Get an IDL string and then store the value in the vptr
 */
   IDL_RPCStrStore(&type_s.str, value);
   IDL_RPCStoreScalar( var->Variable, IDL_TYP_STRING, type_s);
   IDL_RPCStrDelete(&type_s.str, 1L);
   return 1;
}
/***************************************************************************
 * v_fill_array()
 *
 * Purpose:
 *    	This routine is used to create an array and optionally import
 *      the users data. 
 */
int v_fill_array(varinfo_t *var, char *name, int type, 
		 int n_dim, IDL_LONG dims[], UCHAR *value, IDL_LONG length)
{
   IDL_VPTR vTmp;
   char    *pData;

/*
 * Delete the old variable
 */
   free_idl_var(var);
   bzero((char*)var, sizeof(varinfo_t)); /* zero out the struct */
   strncpy( var->Name, name, MAXIDLEN );
/*
 * Should we import an array or create one?
 */
   if(value != (UCHAR*)NULL)
      vTmp = IDL_RPCImportArray( n_dim, dims, type, value, 0);
   else
      pData = IDL_RPCMakeArray(type, n_dim, dims, IDL_BARR_INI_ZERO,
			       &vTmp);
   if(vTmp == (IDL_VPTR)NULL)
      return 0;  
   var->Variable = vTmp;
   return 1;
}
      
         


