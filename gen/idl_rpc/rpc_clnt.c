/* idl_rpc_client.c - Client side routines for the IDL RPC feature */

/*
  Copyright (c) 1988-1997, Research Systems Inc.  All rights reserved.
  This software includes information which is proprietary to and a
  trade secret of Research Systems, Inc.  It is not to be disclosed
  to anyone outside of this organization. Reproduction by any means
  whatsoever is  prohibited without express written permission.
 */

static char rcsid[] = "$Id: rpc_clnt.c,v 1.5 1997/01/29 21:17:45 kirk Exp $";


/*
 *  Contents:
 *  This file contains routines that are used on the client side
 *  of the IDL RPC routines. This includes all API functions as 
 *  well as API support routines.
 */


/*
 * Header files
 */

#include "idl_rpc.h"
#include "rpc_xdr.h"

#include <sys/time.h>
#include <sys/socket.h>
#include <netdb.h>

/*
 * Declare the global timeout variable and set a default value
 */
static struct timeval   s_rpcTimeOut  = { 60, 0 }; /* default of 60 secs */

/*
 * local functions 
 */
void idl_rpc_delvar(IDL_VPTR pVar);         /* deletes dynamic memory */
void idl_rpc_strup(char * dst, char * src); /* upcases an char string */
int idl_rpc_valid_str(char *s);	            /* syntax check a command line */
/*
 * Declare the rpc buffer size
 */
#define      RPC_BUF_SIZE      (8*1024)

/*********************************************************************
 * IDL_RPCInit()
 *
 * Purpose:
 *    This function is used to perform the connection to the rpc server
 *    and other startup initialization of the rpc client. All idl rpc
 *    clients should call this routine before executing any IDL rpc
 *    operations.
 *
 * entry:
 *    lServerId      - integer ID of the rpc server. 0 => use default
 *    pszHostname    - the hostname of the server. NULL => localhost
 *
 * exit:
 *    Function returns a CLIENT pointer that references the client/server
 *    connection or returns NULL if there was an error.
 */
CLIENT *IDL_RPCInit( long lServerId, char* pszHostname)
{
   int                   iSock = RPC_ANYSOCK;
   struct hostent       *pHostent;
   struct sockaddr_in    ServerAddr;
   CLIENT               *pClient;
/*
 * Check input parameters
 */
   if(lServerId == 0)
      lServerId = IDL_RPC_DEFAULT_ID;
   
   if( (pszHostname == (char*)NULL) || (*pszHostname == '\0'))
       pszHostname = "localhost";
/*
 * Get the host information
 */
   if( (pHostent = gethostbyname(pszHostname)) == (struct hostent*)NULL){
       perror("gethostbyname");
       return (CLIENT*)NULL;
     }
/*
 * Copy the host address into the server address struct
 */
   bcopy(pHostent->h_addr, (caddr_t)&ServerAddr.sin_addr, pHostent->h_length);
   ServerAddr.sin_family      = AF_INET; /* address type */
   ServerAddr.sin_port        = 0;
/*
 * Connect to the client usign TCP/IP
 */
   if( (pClient = (CLIENT*)clnttcp_create(&ServerAddr, lServerId, 
			 IDL_RPC_DEFAULT_VERSION, &iSock,
			 RPC_BUF_SIZE, RPC_BUF_SIZE)) == (CLIENT*)NULL){
       clnt_pcreateerror("clnttcp_create");
   }
   return pClient;		/* return the client struct */
}
/******************************************************************
 * IDL_RPCCleanup()
 *
 * Purpose:
 *    This routine should be called when the user no longer desires to 
 *    use the rpc server. This routine will unregister the client and
 *    if desired by the user, halt the rpc server.      
 *
 * entry:
 *    pClient    - The CLIENT ^ that refs the server/client connection
 *      	   that will be affected.
 *    iKill 	 - If true the RPC server will be killed.
 *
 * exit:
 *	RPC client unregistered and if iKill was set, the server is killed.
 *
 */
int IDL_RPCCleanup( CLIENT *pClient, int iKill)
{
   enum clnt_stat    rpcResult=RPC_SUCCESS;
/*
 * Does the user want to kill the server?
 */
   if(iKill)
      rpcResult = clnt_call(pClient, IDL_RPC_CLEANUP, /* kill server */
			    (xdrproc_t)xdr_void, 0, (xdrproc_t)xdr_void, 0, 
			    s_rpcTimeOut);
   if(pClient != (CLIENT*)NULL)
      clnt_destroy(pClient);

   return (rpcResult == RPC_SUCCESS ? 1 : 0); 
}
/******************************************************************
 * IDL_RPCTimeout()
 *
 * Purpose:
 *    This routine is used to set the value of the rpc timeout being
 *    used in the rpc calls to the server. The timeout value units 
 *    are seconds. Returns 0 on failure.
 *
 * entry:
 *    lTimeOut 	- New timeout value in seconds.
 *
 * exit:
 *    Returns 1 on success, 0 on failure. 
 *    
 */
int IDL_RPCTimeout(long lTimeOut)
{
/*
 * make sure that the timeout value looks "sane".
 */
   if(lTimeOut <= 0)
      return 0;
   s_rpcTimeOut.tv_sec = lTimeOut;
   return 1;
}
/***************************************************************************
 * idl_rpc_valid_str()
 *
 * Purpose:
 *	This function checks to make sure that a string contains
 *	a valid IDL command. Commands the start with $ or contain
 *	"$" that are used for line continuations can cause the IDL 
 * 	server to hang. This function is used to validate command
 *	lines before they are sent to the server.
 *
 * entry:
 * 	s	- command string to check.
 *
 * exit:
 *	0 - command string is ok
 *     -1 - command string is invalid
 */
int idl_rpc_valid_str(char *s)
{
   if(s == (char*)NULL) 
      return 0;			/* valid */
  
   if(*s == '$')
      return -1;			/* invalid */
/*
 * Loop thru and check for a '$'
 */
   while(*++s){
     if( *s == '$'){
     /*
      * if this is preceeded by a alpha or an '_' it should be a
      * variable name, otherwise signal an error.
      */
       if( !isalpha(*(s-1)) &&  *(s-1) != '_' && *(s-1) != '$')
          return -1;
     }
   }  
   return 0;	/* command string is OK */
}
/**********************************************************************
 * IDL_RPCExecuteStr()
 *
 * Purpose:
 * 	This routine is used to send an IDL command string to the rpc
 * 	server. This string should be in the form of a single IDL command line.
 * 	The return value of this function is the value of !ERROR after 
 * 	the completion of the command.
 *
 * entry:
 * 	pClient		- The CLIENT ^ that refs the client/server connection.
 *	pszCommand	- The command line to send to the server
 *
 * exit:
 *	Return Value:
 *		0 	- Command executed ok.
 *		-1	- Invalid command line.
 *		other	- Value of !ERROR in the IDL server.
 *
 */
int IDL_RPCExecuteStr( CLIENT *pClient, char * pszCommand)
{ 
  enum clnt_stat     rpcResult;
  int                iCmdResult;
/* 
 * check for a null command...why send it.
 */
   if(pszCommand == (char*)NULL)
      return 1;			/* null commands are ok */
/* 
 * A command spawn using $ can cause problems and should not be sent
 * to the server. Lets check for this.
 */
   if(idl_rpc_valid_str(pszCommand)){
      fprintf(stderr, "IDL_RPCExecuteStr: %s\n",
	      "Shell command and line continue symbols not allowed");
      return 0;
    }
/* 
 * Send the command string to the server.
 */
   rpcResult = clnt_call(pClient, IDL_RPC_EXE_STR, 
			 (xdrproc_t)xdr_wrapstring, (char*)&pszCommand, 
			 (xdrproc_t)xdr_int, (char*)&iCmdResult,
			 s_rpcTimeOut);
   if(rpcResult != RPC_SUCCESS){
      clnt_perror( pClient, "IDL_RPCExecuteStr");
      iCmdResult = 0;
   }

   return iCmdResult;
}
/*****************************************************************
 * IDL_RPCOutputCapture()
 *
 * Purpose:
 * 	This routine is used to enable and disable the capture of the 
 * 	output lines from IDL on the server side. If the input argument 
 * 	is greater than zero, the capture of output lines is enabled with
 * 	the size of the output queue (in lines) equal to the input parameter.
 * 	If the input parameter is <= zero, the caputure queue is emptied and
 * 	the capture of output lines is disabled.
 *
 * entry:
 * 	pClient		- The CLIENT ^ that refs the client/server connection.
 *	n_lines		- The number of output lines to store. A value <=0 
 *			  disables the storage of output lines.
 * exit:
 *	Return Values:
 *		1 - All is ok
 *		0 - an error occurred.
 */
int IDL_RPCOutputCapture( CLIENT *pClient, int n_lines)
{
   enum clnt_stat     rpcResult;
   int                iResult;
/*
 * Send the number of lines to capture to the server.
 */
   rpcResult = clnt_call(pClient, IDL_RPC_OUT_CAPTURE, 
			 (xdrproc_t)xdr_int, (char*)&n_lines, 
			 (xdrproc_t)xdr_int, (char*)&iResult,
			 s_rpcTimeOut);

   if(rpcResult != RPC_SUCCESS){
      clnt_perror(pClient, "IDL_RPCOutputCapture");
      return 0;
   }
   return 1; /* thats it */
}
/*******************************************************************
 * IDL_RPCSetMainVariable()
 *
 * Purpose:
 *	This function is used to set the value of a variable that 
 *	is at the main level of the IDL RPC server. If the variable
 *	doesnt exist at the main level on the server side, the server
 *	will create it.
 *
 * entry:
 * 	pClient		- The CLIENT ^ that refs the client/server connection.
 *	Name		- The name of the variable to be set.
 *	pVar		- An IDL_VPTR that contains the value that the variable
 *			  should be set to.
 * exit:
 *   Return Values:
 *		0 - ok
 *		1 - Error occurred
 */
int IDL_RPCSetMainVariable( CLIENT *pClient, char *Name, IDL_VPTR pVar)
{
   enum clnt_stat   rpcResult;
   IDL_RPC_VARIABLE rpcVar;	/* struct that holds vptr and Name */
   int              iResult=0;
   char             szBuffer[124];
/*
 * Put the information in the rpc variable structure and send it
 * to the server.
 */
   idl_rpc_strup(szBuffer, Name);	/* upcase name */
   rpcVar.name = szBuffer;
   rpcVar.pVariable = pVar;
/*
 * If the variable is a string that is dynamically allocated, make
 * sure that the V_DYNAMIC flag is set. With out this flag set,
 * there can be problems on the server side.
 */
   if(pVar->type == IDL_TYP_STRING){
      if(pVar->value.str.stype){
         pVar->flags |= IDL_V_DYNAMIC;
      }
   }
/*
 * Send this info to the server.
 */
   rpcResult = clnt_call(pClient, IDL_RPC_SET_MAIN_VAR,
			 (xdrproc_t)IDL_RPC_xdr_variable, (char*)&rpcVar,
			 (xdrproc_t)xdr_void, 0, s_rpcTimeOut);

   if(rpcResult != RPC_SUCCESS){
      clnt_perror(pClient, "IDL_RPCSetMainVariable");
      return 0;
   }
   return 1;
}
/*************************************************************
 * IDL_RPCGetMainVariable()
 *
 * Purpose:
 * 	This function is used to get the value of a variable 
 *	that is located at the main IDL level on the IDL RPC server.
 *	The IDL_VPTR that is returned from this function is dynamically
 *	allocated and should be deallocated using the IDL_RPCDeltmp() 
 *	function when the user is finished with it.
 * 
 * entry: 
 * 	pClient		- The CLIENT ^ that refs the client/server connection.
 *	Name		- The name of the desired variable.
 *
 * exit:
 * 	Return Value:
 *		On success this function returns an IDL_VPTR that points
 *		to an IDL_VARIABLE structure that contains the value of 
 *		the requested variable. On failure this function returns
 *		NULL.
 */
IDL_VPTR IDL_RPCGetMainVariable(CLIENT *pClient, char *Name)
{
   IDL_VPTR pVar;
   IDL_RPC_VARIABLE rpcVar;
   enum clnt_stat   rpcResult;
   char             szBuffer[124];
   char           *pChar;
   idl_rpc_strup(szBuffer, Name);	/* make sure it is uppercase */
   bzero((char*)&rpcVar, sizeof(IDL_RPC_VARIABLE)); /* clear out  */
   pChar = (char*)szBuffer;
/* 
 * Request the variable from the server
 */
   rpcResult = clnt_call(pClient, IDL_RPC_GET_MAIN_VAR,
			 (xdrproc_t)xdr_wrapstring, (char*)&pChar,
			 (xdrproc_t)IDL_RPC_xdr_variable, (char*)&rpcVar,
			 s_rpcTimeOut);
   if(rpcResult != RPC_SUCCESS){
      clnt_perror(pClient, "IDL_RPCGetMainVariable");
      return (IDL_VPTR)NULL;
   }
   return rpcVar.pVariable;	/* return the value */
}
/*******************************************************************
 * IDL_RPCSetVariable()
 *
 * Purpose:
 *	This function is used to set the value of a variable that 
 *	is in the current scope of the IDL RPC server. If the variable
 *	doesnt exist at this level on the server side, the server
 *	will create it.
 *
 * entry:
 * 	pClient		- The CLIENT ^ that refs the client/server connection.
 *	Name		- The name of the variable to be set.
 *	pVar		- An IDL_VPTR that contains the value that the variable
 *			  should be set to.
 * exit:
 *   Return Values:
 *		0 - ok
 *		1 - Error occurred
 */
int IDL_RPCSetVariable( CLIENT *pClient, char *Name, IDL_VPTR pVar)
{
   enum clnt_stat   rpcResult;
   IDL_RPC_VARIABLE rpcVar;
   int              iResult=0;
   char             szBuffer[124];
/*
 * Put the information in the rpc variable structure and send it
 * to the server.
 */
   idl_rpc_strup(szBuffer, Name);
   rpcVar.name = Name;
   rpcVar.pVariable = pVar;

/*
 * If the variable is a string that is dynamically allocated, make
 * sure that the V_DYNAMIC flag is set. With out this flag set,
 * there can be problems on the server side.
 */
   if(pVar->type == IDL_TYP_STRING){
      if(pVar->value.str.stype){
         pVar->flags |= IDL_V_DYNAMIC;
      }
   }
/*
 * Send this info to the server.
 */
   rpcResult = clnt_call(pClient, IDL_RPC_SET_VAR,
			 (xdrproc_t)IDL_RPC_xdr_variable, (char*)&rpcVar,
			 (xdrproc_t)xdr_void, 0, s_rpcTimeOut);

   if(rpcResult != RPC_SUCCESS){
      clnt_perror(pClient, "IDL_RPCSetVariable");
      iResult=0;
   }
   return 1;
}
/*************************************************************
 * IDL_RPCGetVariable()
 *
 * Purpose:
 * 	This function is used to get the value of a variable 
 *	that is located in the current IDL scope on the IDL RPC server.
 *	The IDL_VPTR that is returned from this function is dynamically
 *	allocated and should be deallocated using the IDL_RPCDeltmp() 
 *	function when the user is finished with it.
 * 
 * entry: 
 * 	pClient		- The CLIENT ^ that refs the client/server connection.
 *	Name		- The name of the desired variable.
 *
 * exit:
 * 	Return Value:
 *		On success this function returns an IDL_VPTR that points
 *		to an IDL_VARIABLE structure that contains the value of 
 *		the requested variable. On failure this function returns
 *		NULL.
 */
IDL_VPTR IDL_RPCGetVariable(CLIENT *pClient, char *Name)
{
   IDL_VPTR pVar;
   IDL_RPC_VARIABLE rpcVar;
   enum clnt_stat   rpcResult;
   char             szBuffer[124];
   char            *pChar;
   idl_rpc_strup(szBuffer, Name);	/* make sure it is uppercase */
   pChar = (char*)szBuffer;
   bzero((char*)&rpcVar, sizeof(IDL_RPC_VARIABLE)); /* clear out  */
   rpcResult = clnt_call(pClient, IDL_RPC_GET_VAR,
			 (xdrproc_t)xdr_wrapstring, (char*)&pChar,
			 (xdrproc_t)IDL_RPC_xdr_variable, (char*)&rpcVar,
			 s_rpcTimeOut);
   if(rpcResult != RPC_SUCCESS){
      clnt_perror(pClient, "IDL_RPCGetVariable");
      return (IDL_VPTR)NULL;
   }
   return rpcVar.pVariable;
}   
/*************************************************************
 * IDL_RPCOuputGetStr()
 *
 * Purpose:
 * 	This function is used to get a line from the output queue that
 * 	is being kept on the RPC server. The routine IDL_RPCOutputCapture()
 * 	MUST have been called with a positive arguement before this routine.
 *
 * entry:
 *	pClient		- The CLIENT ^ that refs the client/server connection.
 *	pLine		- A ^ to a valid structure of type pLine. This 
 *			  structure will be filled with the next line
 *			  and information about this line.
 *	first		- If not 0, the value should be popped from the 
 *			  output queue, not dequeued.
 */
int IDL_RPCOutputGetStr(CLIENT *pClient, IDL_RPC_LINE_S *pLine, int first)
{
   enum clnt_stat     rpcResult;
/*
 * Get the line from the server
 */
   rpcResult = clnt_call(pClient, IDL_RPC_OUT_STR, 
			 (xdrproc_t)xdr_int, (char*)&first, 
			 (xdrproc_t)IDL_RPC_xdr_line_s, (char*)pLine,
			 s_rpcTimeOut);
   if(rpcResult != RPC_SUCCESS){
      clnt_perror(pClient, "IDL_RPCOutputGetStr");
      return 0;
   }
/*
 * A flag value of -1 indicates that there are no more values
 * in the ouput queue
 */
   return (pLine->flags == -1 ? 0 : 1);
}
/*************************************************************
 * IDL_RPCVarCopy()
 * 
 * Purpose:
 * 	Used to emulate IDL_VarCopy() on the client side. The value
 * 	of the source variable is copied to the destination variable.
 *	If the source variable has the IDL_V_TMP flag set, any dynamic
 *	part of the source variable is moved to the destination variable
 *	and not copied.
 *	
 *	Any dynamic memory associated with the destination variable
 *	is freed before the copy is performed.
 *
 * entry:
 *	src - ^ to variable to be copied.
 *	dst - ^ to variable that will have info copied to it.
 *
 * exit:
 *	src - not changed
 *	dst - Any original dynamic data has been deallocated and it now
 *	      contains the value that was in src.
 *
 */
void IDL_RPCVarCopy(IDL_VPTR src, IDL_VPTR dst)
{
   int flags;

   flags = dst->flags;		/* save the destination flags */
/*
 * Free up any dynamic memory used by the dst variable 
 */
   idl_rpc_delvar(dst);  
   dst->flags = flags & ~(IDL_V_ARR & IDL_V_DYNAMIC); /* save some flags */
   dst->type = src->type;	/* get the type of the copied var */
/*
 * Is the variable an array?
 */
   if( src->flags & IDL_V_ARR){
   /*
    * Is the source variable a *temporary* variable (or at least
    * marked as such)? If so, just copy the arr pointer to the 
    * src variable.
    */
      if(src->flags & IDL_V_TEMP){
	 dst->value.arr = src->value.arr;
	 src->flags &=  ~(IDL_V_NOT_SCALAR); /* take out array bit */
	 idl_rpc_delvar(src);	/* free any other memory being used */
      }else{			/* need to copy over the data! */
         dst->value.arr = (IDL_ARRAY*)malloc((unsigned)sizeof(IDL_ARRAY));
	 if(!dst->value.arr){
	    perror("malloc");
	    return;
	 }
      /*
       * Copy over the array info.
       */
	 bcopy((char*)src->value.arr,(char*)dst->value.arr, sizeof(IDL_ARRAY));
	 dst->value.arr->data = (UCHAR*)malloc(src->value.arr->arr_len);
	 if(!dst->value.arr->data){
	    perror("malloc");
	    free((char*)dst->value.arr);
	    return;
	 }
      /*
       * Copy over the array info
       */
	 bcopy((char*)src->value.arr->data, (char*)dst->value.arr->data, 
	       src->value.arr->arr_len);
	 dst->flags |= IDL_V_DYNAMIC;
      }
      dst->flags |= IDL_V_ARR;
   }else {			/* a scalar */
   /*
    * just copy over the alltypes union
    */
      bcopy((char*)&dst->value, (char*)&src->value, sizeof(IDL_ALLTYPES));
      dst->flags = dst->flags & ~(IDL_V_NOT_SCALAR);
   }
}
/********************************************************************
 * IDL_RPCDeltmp()
 *
 * Purpose:
 * 	This function emulates the IDL_Deltmp() function. This is used
 * 	to delete any dynamic memory that is allocated to create
 * 	a variable. This function calls idl_rpc_delvar() which keys off
 *	the IDL_V_DYNAMIC flag or if a scalar is a string. 
 *
 *	If the IDL_V_TEMP bit is set, the IDL_VARIABLE will also be 
 *	deallocated.
 *
 * entry:
 *	vTmp  - A variable that will have its memory freed.
 *
 * exit:
 *	vTmp - Any dynamic memory associated with vTmp is freed.
 */
void IDL_RPCDeltmp( IDL_VPTR vTmp)
{
   if(!vTmp)
      return;   
/*
 * Free up any dynamic memory in the variable
 */
   idl_rpc_delvar(vTmp);
/*
 * If the IDL_V_TEMP bit is not set, return. 
 */
   if(!(vTmp->flags & IDL_V_TEMP))
      return;
   free((char*)vTmp);  /* free the IDL_VARIABLE */
}
/*********************************************************************
 * IDL_RPCGettmp()
 *
 * Purpose:
 * 	Used to emulate the IDL function IDL_Gettmp(). Allocates
 * 	memory for an IDL_VARIABLE struct and returns a pointer 
 * 	to this value. The IDL_V_TEMP flag is set to indicate
 * 	that this value will need to be free'd later in the program.
 *
 * entry:
 *	Nothing.
 *
 * exit:
 * 	Return Value:
 *	 	Returns an IDL_VPTR that points to an IDL_VARIABLE 
 *		struct with the IDL_V_TEMP bit set in the flags field.
 *		On an error a NULL is returned.
 */
IDL_VPTR IDL_RPCGettmp(void)
{
   IDL_VPTR vTmp;

   vTmp = (IDL_VPTR)malloc((unsigned)sizeof(IDL_VARIABLE));
   if(!vTmp){
     perror("malloc");
     return (IDL_VPTR)NULL;
   }
   bzero((char*)vTmp, sizeof(IDL_VARIABLE));
   vTmp->flags = IDL_V_TEMP;  /* used to mark the IDL_VARIABLE as dynamic */
   return vTmp;
}
/*********************************************************************
 * IDL_RPCStoreScalar()
 *
 * Purpose:
 *	This function is used to store a scalar value into an 
 *	IDL_VPTR variable. This function emulates the Callable IDL
 *	function IDL_StoreScalar.
 *
 * entry:
 * 	dest 	- The ^ to the IDL_VARIABLE struct where the scalar
 *		  value is stored. Any dynamic memory that is contained
 *		  in dest will be deallocated before the store takes place.
 *	type    - The type of the value to be stored.
 *	value	- A ^ to an IDL_ALLTYPES union that contains the 
 *		  scalar value to store in the destination variable.
 *
 * exit:
 * 	The scalar value is stored in the destination variable.
 */
void IDL_RPCStoreScalar(IDL_VPTR dest, int type, 
			IDL_ALLTYPES *value)
{
   int i;
   IDL_STRING *pStr;
/*
 * Free up any dynamic memory being used by the variable
 */
   if(dest->flags & IDL_V_DYNAMIC)
      idl_rpc_delvar(dest);
   dest->flags=0;
/* 
 * Switch on the variable type and do the store.
 */
   switch(dest->type = type){
   case IDL_TYP_BYTE: 
      dest->value.c = value->c;
      break;
   case IDL_TYP_INT:
      dest->value.i = value->i;
      break;
   case IDL_TYP_LONG:
      dest->value.l = value->l;
      break;
   case IDL_TYP_FLOAT:
      dest->value.f = value->f;
      break;
   case IDL_TYP_DOUBLE:
      dest->value.d = value->d;
      break;
   case IDL_TYP_COMPLEX:
      dest->value.cmp = value->cmp;
      break;
   case IDL_TYP_DCOMPLEX:
      dest->value.dcmp = value->dcmp;
      break;
   case IDL_TYP_STRING:
      dest->value.str = value->str;
      IDL_RPCStrDup( &(dest->value.str), 1L);
      dest->flags = IDL_V_DYNAMIC;	
      break;
   default:
      fprintf(stderr,"IDL_RPCStoreScalar: Unknown Type");
   }
   return;  /* thats it, fairly simple */
}
/**************************************************************
 * IDL_RPCMakeArray()
 *
 * Purpose:
 * 	This function is used to emulate the IDL function 
 * 	IDL_MakeTempArray() on the client side of the IDL RPC system.
 *	This routine accepts parameters that describe the desired array,
 *	and then creates a variable and allocates memory for the array.
 *
 *	The resulting array is marked such that all dynamic memory
 *	will be deallocated by IDL_RPCDeltmp(), IDL_RPCVarCopy()..ect.
 *
 * entry:
 *	type	- The IDL type code of the desired array.
 *	n_dim	- The number of dimensions of the array.
 *	dim	- An array that contains the size of each dimension.
 *	init	- The type of initialization that is performed on the 
 *		  data block. If the value is set to IDL_BARR_INI_ZERO
 *		  the data block is cleared, otherwise no initialization
 *		  is done.
 *	var	- A ^ to an IDL_VPTR. The address of the created variable
 *		  is placed in the location referenced by var.
 *
 * exit:
 *	var 	- referances the IDL_VPTR of the created variable.
 *	Return Value:
 *	    On success the function returns the poniter to the array
 *	    data block. On failure, a NULL is returned.
 *
 */
char * IDL_RPCMakeArray( int type, int n_dim, IDL_LONG dim[], 
			    int init, IDL_VPTR *var)
{
   int      i;
   char    *pData;
   IDL_VPTR vTmp;
/*
 * Get a new IDL_VPTR
 */
   if( (vTmp = IDL_RPCGettmp()) == (IDL_VPTR)NULL)
      return (char *)NULL;
/*
 * Alloc the array struct
 */
   vTmp->value.arr = (IDL_ARRAY*)calloc(1, sizeof(IDL_ARRAY));
   if(!vTmp->value.arr){
      IDL_RPCDeltmp(vTmp);
      perror("calloc");
      return((char*)NULL);
   }
/*
 * Set up the vptr flags.
 */
   vTmp->flags |= IDL_V_ARR | IDL_V_DYNAMIC;
   vTmp->type  = type;

/*
 * Get the element size. Depends on the type. 
 */
   switch(type){
   case IDL_TYP_BYTE:      
     vTmp->value.arr->elt_len = sizeof(UCHAR);
     break;
   case IDL_TYP_INT:
     vTmp->value.arr->elt_len = sizeof(short);
     break;
   case IDL_TYP_LONG:
     vTmp->value.arr->elt_len = sizeof(IDL_LONG);
     break;
   case IDL_TYP_FLOAT:
     vTmp->value.arr->elt_len = sizeof(float);
     break;
   case IDL_TYP_DOUBLE:
     vTmp->value.arr->elt_len = sizeof(double);
     break;
   case IDL_TYP_COMPLEX:
     vTmp->value.arr->elt_len = sizeof(IDL_COMPLEX);
     break;
   case IDL_TYP_DCOMPLEX:
     vTmp->value.arr->elt_len = sizeof(IDL_DCOMPLEX);
     break;
   case IDL_TYP_STRING:
     vTmp->value.arr->elt_len = sizeof(IDL_STRING);
     break;
   default:
     break;
   }
/*
 * Set the rest of the array fields, start with the number of 
 * elements.
 */
   vTmp->value.arr->n_elts = 1;
   for(i=0;i < n_dim; i++){
     vTmp->value.arr->n_elts *= dim[i];
     vTmp->value.arr->dim[i] = dim[i];
   }
   vTmp->value.arr->arr_len = vTmp->value.arr->elt_len *
			      vTmp->value.arr->n_elts;
   vTmp->value.arr->n_dim = n_dim;
 /*
 * Now allocate space for the data
 */
   pData = (char*)malloc(vTmp->value.arr->arr_len);
   if(!pData){
      perror("malloc");
      IDL_RPCDeltmp(vTmp);
      return((char*)NULL);
   }
/*
 * Does the user want to initialize this to zero?
 */
   if(init == IDL_BARR_INI_ZERO)
      bzero(pData, vTmp->value.arr->arr_len);
			
   vTmp->value.arr->data = (UCHAR*)pData;
   *var = vTmp;			/* assign vptr to output */
   
   return pData;
}
/***************************************************************************
 *IDL_RPCImportArray()
 *
 * Purpose:
 *  	This function is used to emulate the IDL function IDL_ImportArray()
 *	on the client side of the IDL RPC system. This routine accepts 
 *	a pointer to a data block that the user whishes to import into an
 *	IDL variable as well as parameters that describe the attributes of 
 *	the data. In addition to this information, the function accepts a
 *	a pointer to a user supplied function that can be used to free 
 *	the memory associated with the imported data.
 *
 *	The resulting array is marked such that all dynamic memory
 *	will be deallocated by IDL_RPCDeltmp(), IDL_RPCVarCopy()..ect. as 
 * 	well as calling a user supplied memory deallocation call back function.
 *
 * 	Note: This function does not support structure def. pointers as
 *	      does IDL_ImportArray(). Structures are not supported by the
 *	      RPC system. 
 *  entry:
 *	n_dim	- The number of dimesions in the array.
 *	dim	- The number of elements of each dimension.
 *	type	- The type of the array.
 *	data	- Pointer to the array block that is being imported.
 *	free_cb - Pointer to a function that should be called 
 *	    	  when freeing the data. If left null free() will be 
 *		  called.
 *
 *  exit:
 *	Return Value:
 *		On success, the function returns an IDL_VPTR that 
 *		references the IDL_VARIABLE the contains the imported
 *		array. On failure, NULL is returned.
 */
IDL_VPTR IDL_RPCImportArray(int n_dim, IDL_LONG dim[], int type, 
			    UCHAR *data, IDL_ARRAY_FREE_CB free_cb)
{
   IDL_VPTR   pVptr;		/* vptr */
   long       n_elements=1;
   long       szElement;
   int        i;

/*
 * Are there any dimensions?
 */
   if(n_dim  <= 0){
      fprintf(stderr, "IDL_RPCImportArray: Invalid Number of dimensions");
      return (IDL_VPTR)NULL;
   }
/*
 * What is the size of an element?
 */
   switch(type){
   case IDL_TYP_INT:        szElement=sizeof(short); break;
   case IDL_TYP_LONG:       szElement=sizeof(IDL_LONG); break;
   case IDL_TYP_FLOAT:      szElement=sizeof(float); break;
   case IDL_TYP_DOUBLE:     szElement=sizeof(double); break;
   case IDL_TYP_COMPLEX:    szElement=sizeof(IDL_COMPLEX); break;
   case IDL_TYP_DCOMPLEX:   szElement=sizeof(IDL_DCOMPLEX); break;
   case IDL_TYP_STRING:     szElement=sizeof(IDL_STRING); break;
   default:
      fprintf(stderr, "IDL_RPCImportArray: Unknown Type\n");
      return (IDL_VPTR)NULL;
   }
/*
 * Get a temporary Variable
 */ 
   pVptr = IDL_RPCGettmp();
/*
 * Alloc an array block
 */
   pVptr->value.arr = (IDL_ARRAY*)calloc(1, sizeof(IDL_ARRAY));
   if(!pVptr->value.arr){
      IDL_RPCDeltmp(pVptr);
      return (IDL_VPTR)NULL;
   }
/*
 * Set-up the correct flags for the variable.
 */
   pVptr->flags |= IDL_V_ARR | IDL_V_DYNAMIC;
   pVptr->type  = type;

   for(i=0; i<n_dim; i++){
      pVptr->value.arr->dim[i] = dim[i];
      n_elements *= dim[i];
   }
   pVptr->value.arr->elt_len = szElement;
   pVptr->value.arr->n_dim = (UCHAR)n_dim;
   pVptr->value.arr->arr_len = szElement*n_elements;
   pVptr->value.arr->n_elts = n_elements;
   pVptr->value.arr->free_cb = free_cb;
   pVptr->value.arr->data = data;
/*
 * That's all
 */
   return pVptr;
}
/***************************************************************************
 * idl_rpc_delvar
 *
 * Purpose:
 * 	This routine is used to free all of the dynamic memory associated
 * 	with a variable. This routine doesnt free the variable. This routine
 * 	should not be called by the user, but is used internally by the rpc
 * 	client side functions
 * entry:
 *	pVar	- A IDL_VPTR to the variable to have dynamic memory freed.
 *
 * exit:
 *	pVar	- All dynamic memory associated with the variable( array 
 *		  and/or strings) is deallocated or a user call-back has been
 *		  called.
 */
void idl_rpc_delvar(IDL_VPTR pVar)
{   
   int i;
   IDL_STRING *pStr;
   int flags=0;

   flags = (IDL_V_TEMP & pVar->flags);
/* 
 * Check for an array.
 */
   if(pVar->flags & IDL_V_ARR){
      if(pVar->flags & IDL_V_DYNAMIC){
      /* 
       * was a Free callback function declared?
       */
         if(pVar->value.arr->free_cb != (IDL_ARRAY_FREE_CB)NULL){
	    pVar->value.arr->free_cb((UCHAR*)pVar->value.arr->data);
         }else{
         /*
          * Have a dynamic array that needs to be free'd. Is this a string 
          * array?
          */
            if(pVar->type == IDL_TYP_STRING){
	       IDL_RPCStrDelete((IDL_STRING*)pVar->value.arr->data, 
			    pVar->value.arr->n_elts);
	    }
	    free(pVar->value.arr->data);
         }
       }
       free(pVar->value.arr); /* the array block is always dynamic */
    }else if(pVar->type == IDL_TYP_STRING){
       if(pVar->value.str.stype)
	  free(pVar->value.str.s);
    }
/*
 *  Now just clear out the variable.
 */
    bzero((char*)pVar, sizeof(IDL_VARIABLE));
    pVar->flags = flags; /* save temp flag. it is used to indicate  */
			 /* that the variable struct is dynamic */
}
/****************
 * String Section.
 ***********************************************************************
 * idl_rpc_strup()
 *
 * Purpose:
 * 	Used to upcase a string.
 *
 * entry:
 *	dst	- The destination of the string variable.
 *	src	- The source string
 *
 * exit: 
 *	dst contains a upcased version of src.
 *
 */
void idl_rpc_strup(char * dst, char * src)
{
  char c;
  do{
    c = *src++;
    if(islower(c)) 
       c = toupper(c);
  }while(*dst++ = c);
}
/****************************************************************************
 * IDL_RPCStrDup()
 *
 * Purpose:
 *	
 * 	This function is used to emulate the Callable IDL function 
 * 	IDL_RPCStrDup(). This function should only be used on the client
 * 	side of the RPC routines.
 *
 * entry:
 *    	str 	- A ^ to an IDL_STRING struct array.
 *	n	- The number of elements in the str.
 *
 * exit:
 *	str contains copies of the string values that where contained
 *	in the IDL_STRING structures.
 *	If an error is detected, the string struct is cleared.
 */
void IDL_RPCStrDup(IDL_STRING *str, IDL_LONG n)
{
   for(;n--; str++){
     if(str->slen && str->stype){ 
        if((str->s = (char*)strdup(str->s))==(char*)NULL)
	   bzero( (char*)str, sizeof(IDL_STRING));
   	else 
  	  str->stype = 1;	/* flag for dynamic */
     }
   }
}
/***************************************************************************
 * IDL_RPCStrDelete()
 *
 * Purpose:
 * 	This routine is used to free any dynamic memory contained in the 
 * 	string descriptors.
 *
 * entry:
 *	str	- A ^ to an IDL_STRING struct array.
 *	n	- The number of elements in str.
 *
 * exit:
 *	All dynamic values in the strings are deallocated and the 
 *	IDL_STRING structs are set to reflect this.
 *
 */
void IDL_RPCStrDelete(IDL_STRING *str, IDL_LONG n)
{
   for(;n--; str++){
   /*
    * Free the string if it is dynamic and has a length
    */
      if(str->slen && str->stype){
	 free(str->s);
	 bzero((char*)str, sizeof(IDL_STRING));
      }
   }
}
/***************************************************************************
 * IDL_RPCStrStore()
 *
 * Purpose:
 * 	This routine is used to store a C string into an IDL String. The
 * 	C string is strdup'd.
 * 
 * entry:
 *	s	- The ^ to a IDL_STRING struct that will get copy of the 
 *		  C string.
 *	fs	- The C string to copy.
 * exit:
 *	s contains a copy of the C string or has been cleared if fs = null.
 */
void IDL_RPCStrStore( IDL_STRING *s, char *fs)
{
  int   len;

  if((len=strlen(fs))){
     s->s = (char*)strdup(fs);
     s->slen = len;
     s->stype=1;
  } else 
     bzero((char*)s, sizeof(IDL_STRING));
}
/***************************************************************************
 * IDL_RPCStrEnsureLength()
 *
 * Purpose:
 * 	Used to ensure that a string is of a certain length.
 *
 * entry:
 *	s	- A ^ to a IDL_STRING struct that will get the string.
 *	n	- The lenght to be allocated.
 *
 * exit:
 *	The string field of the IDL_STRING struct is set to the desired length.
 */
void IDL_RPCStrEnsureLength(IDL_STRING *s, int n)
{
  if(n){			/* make a non-null dynamic string */
    if( ((int)s->slen < n) || !(s->stype)){
       IDL_RPCStrDelete(s, 1L);
       s->s = (char*)malloc((unsigned)sizeof(char)*n+1);
       if(!s->s){
	  bzero((char*)s, sizeof(IDL_STRING));
	  return;
       }
       s->stype=1;
    }
    s->slen = n;
  }else {			/* Want a null string */
    if(s->slen){		
       IDL_RPCStrDelete(s, 1L);
       bzero((char*)s, sizeof(IDL_STRING));
    }
  }
}
/***************************************************************************
 */
void IDL_RPCVarGetData(IDL_VPTR v, IDL_LONG *n, char **pd,
		    int ensure_simple)
/*
 * Given a pointer to a varible, return the number of elements
 * and a pointer to the data area. This routine takes care of the
 * distinction between arrays and scalars.
 *
 * entry:
 *	v - Variable for which data is desired.
 *	n - Address of variable to receive # of elements.
 *	pd - Address of variable to receive pointer to data.
 *	ensure_simple - If TRUE, this routine calls the ENSURE_SIMPLE
 *		macro on the argument v to screen out variables of the
 *		types it prevents. Otherwise, EXCLUDE_FILE is called,
 *		because file variables have no data area to return.
 *
 * exit:
 *	*n - Receives count of elements.
 *	*pd - Receives pointer to data.
 */
{

  if(!v->type)
    return;
  if (ensure_simple) {
    if((v->flags &(IDL_V_FILE|IDL_V_STRUCT))||
       (v->type & (IDL_TYP_OBJREF|IDL_TYP_PTR)))
        return;
  } else {
    if(v->flags & IDL_V_FILE)
       return;
  }
  if (v->flags & IDL_V_ARR) {	/* Array? */
    *n = v->value.arr->n_elts;   /* Return values */
    *pd = (char *) v->value.arr->data;
  } else {
    *n = 1;			/* Scalar, one element */
    *pd = (char *) &v->value;
  }
}



