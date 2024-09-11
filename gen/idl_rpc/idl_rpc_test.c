/*
 *  rpctest.c
 *
 *  $Id: idl_rpc_test.c,v 1.4 1997/01/29 23:28:17 kirk Exp $
 *  
 *
 *
  Copyright (c) 1988-1997, Research Systems Inc.  All rights reserved.
  This software includes information which is proprietary to and a
  trade secret of Research Systems, Inc.  It is not to be disclosed
  to anyone outside of this organization. Reproduction by any means
  whatsoever is  prohibited without express written permission.
 */



/*
 * Purpose:
 * 	This file contains routines that test the idl rpc client
 *	API.
 */

#include "idl_rpc.h"

/*
 * Static variable used to signal that the memory callback is called
 */
static int iCBFlag=0;

/*
 * Prototypes
 */
IDL_ARRAY_FREE_CB RPCArrCBTest(UCHAR *pData);
int RPCVarTest(void);
int RPCStringTest(void);
int RPCScalarTest(CLIENT *pClient);
int RPCGetArrayTest(CLIENT *pClient);
int RPCSetArrayTest(CLIENT *pClient);
int RPCMemoryTest(CLIENT *pClient);
int RPCExeTest(CLIENT *pClient);
void RPCFlushOutput(CLIENT *pClient);

/****************************************************************************
 *   main
 *
 *   PURPOSE:
 *        This is the main program for the idl_rpc_test IDL rpc client program.
 *        This program accepts the following command line arguments.
 *
 *            % idl_rpc_test <server_id> 
 *            % idl_rpc_test <hostname>
 *            % idl_rpc_test <server_id> <hostname>
 *
 *        Where  the server_id is the rpc id for the rpc server and the
 *        hostname is the name of the host that is running the rpc server.
 */
int main(c,v)
    int	c;
    char **v;
{
   CLIENT	*pClient;
   char		cmdbuffer[ IDL_RPC_MAX_STRLEN ];
   IDL_LONG	server_id	 = 0;
   char		* hostname	= NULL;
   int  	result,i;
   IDL_VPTR   	vTmp;
   float        *pData;

/* 
 * Process the command line arguments. If there are two arguments
 * then the first must be the server ID and the second must be the
 * server ID.
 */
   switch(c){
   case 3:
     sscanf( v[1], "0x%x", &server_id );
     hostname = v[2];
     break;     
   case 2:	
     if( !strncmp( v[1], "0x", 2 ) ) 
       sscanf( v[1], "0x%x", &server_id );
     else hostname = v[1];
     break;
   default:
     break; 
   }
/*
 * Register the client, check for errors
 */      
   if( (pClient = IDL_RPCInit( server_id, hostname)) ==NULL){
     printf("Can't register with server on \"%s\"\n",
	       hostname ? hostname : "localhost");
     exit(1);
   }
/*
 * Reset the timeout to 2 minutes
 */
   if(!IDL_RPCTimeout(120)){
       printf("Unable to set timeout\n");
       exit(1);
   }
/*
 * Now should be connected to server. Perform Variable tests
 */
   fprintf(stdout, "Variable Tests\t\t");
   if(RPCVarTest() != 0){	/* Had an error */
      fprintf(stderr, "FAILED\n");
      IDL_RPCCleanup(pClient, 0);
      exit(1);
   }
   fprintf(stdout, "PASSED\n");
   fprintf(stdout, "String Tests\t\t");
   if(RPCStringTest() != 0){
      fprintf(stderr, "FAILED\n");
      IDL_RPCCleanup(pClient, 0);
      exit(1);
   }
   fprintf(stdout, "PASSED\n");
/*
 * Now to perform tests with scalar variables
 */
   fprintf(stdout, "Scalar Tests\t\t");
   if(RPCScalarTest(pClient) != 0){  /* Had an error */
      fprintf(stderr, "FAILED\n");
      IDL_RPCCleanup(pClient, 0);  
      exit(1);
   } 
   fprintf(stdout, "PASSED\n");
/*
 * Now array tests
 */
   fprintf(stdout, "Get Array Tests\t\t");
   if(RPCGetArrayTest(pClient) != 0){   /* Had an error */
      fprintf(stderr, "FAILED\n");
      IDL_RPCCleanup(pClient, 0);
      exit(1);
   } 
   fprintf(stdout, "PASSED\n");
   fprintf(stdout, "Set Array Tests\t\t");
   if(RPCSetArrayTest(pClient) != 0){   /* Had an error */
      fprintf(stderr, "FAILED\n");
      IDL_RPCCleanup(pClient, 0);
      exit(1);
   } 
   fprintf(stdout, "PASSED\n");
/*
 * Check for server memory leaks
 */
   fprintf(stdout, "Server Memory Tests\t");
   if(RPCMemoryTest(pClient) != 0){
      fprintf(stderr, "FAILED\n");
      IDL_RPCCleanup(pClient, 0);
      exit(1);
   }
   fprintf(stdout, "\tPASSED\n");
/* 
 * Finally, Output Redirection and execute command tests 
 */
   if(RPCExeTest(pClient) != 0){
      fprintf(stderr, "FAILED\n");
      IDL_RPCCleanup(pClient, 0);
      exit(1);
   } 
   fprintf(stdout, "IDL Execute String\tPASSED\n");
/*
 * If we are at this point all of the data and interaction tests worked.
 * Now test the different options of IDL Cleanup. First dissconnect
 * the client and leave the server running.
 */
   fprintf(stdout, "IDL_RPCCleanup Tests\t");
   if(IDL_RPCCleanup(pClient, 0) != 1){
      fprintf(stderr, "FAILED\n");
      fprintf(stderr, "Error disconnecting client\n");
      exit(1);
   }
/*
 * Now reconnect to the server and then disconnect, killing the server
 */
   if( (pClient = IDL_RPCInit( server_id, hostname)) == NULL)
   {
     fprintf(stderr, "Can't register with server on \"%s\"\n",
	       hostname ? hostname : "localhost");
     fprintf(stderr, 
	"Possible error with IDL_RPCCleanup when disconnecting client\n");
     exit(1);
   }
/*
 * Now to kill the server and the client
 */
   if(IDL_RPCCleanup(pClient, 1) != 1){
      fprintf(stderr, "Error killing server and disconnecting client\n");
      exit(1);
   }
   fprintf(stdout, "PASSED\n");
/*
 * If we got this far, all tests passed. Indicate this and exit
 */
   printf("\nAll RPC tests\t\tPASSED\n");
   exit(0);
}
/**********************************************************************
 */
IDL_ARRAY_FREE_CB RPCArrCBTest(UCHAR *pData)
{
   iCBFlag = 0;
   free(pData);
}
/***********************************************************************
 * RPCVarTest()
 *
 * Purpose:
 * 	This function is used to test the behavior of the IDL
 *	RPC client variable manipulation API. Basically this
 *	routine will create and destroy local variables making
 *	sure that flags and memory are handled correctly.
 */
int RPCVarTest(void)
{
   IDL_VPTR     pVar1;
   IDL_VPTR	pVar2;
   IDL_VARIABLE Var1_s;
   UCHAR         *pData1, *pData2;
   char         *pStr;

   IDL_LONG     lDim[2] = {10,10};

   bzero((char*)&Var1_s, sizeof(IDL_VARIABLE)); /* clear stack crap */

/*
 * Create and destroy a simple variable
 */
   if( (pVar1 = IDL_RPCGettmp()) == (IDL_VPTR)NULL){
       fprintf(stderr, "IDL_RPCGettmp: Error allocating variable\n");
       return 1;
   }
/*
 * Make sure that the flags section is marked as IDL_V_TEMP and that
 * the type is 0.
 */
   if( !(pVar1->flags & IDL_V_TEMP)){
      fprintf(stderr, "IDL_RPCGettmp: IDL_V_TEMP flag not set.\n");
      return 1;
   }
   if(pVar1->type){
      fprintf(stderr, "IDL_RPCGettmp: type field not set to null.\n");
      return 1;
   }
   if( pVar1->flags & ~IDL_V_TEMP){
     fprintf(stderr, "IDL_RPCGettmp: flags field incorrect\n");
     return 1;
   }
/*
 * Gettmp pass it's simple tests, now to deltmp the variable. Not
 * Much you can test except that the OS doesnt give you an error.
 */
   IDL_RPCDeltmp(pVar1);   
/*
 * Create an array.
 */
   if( (pData1 = (UCHAR*)IDL_RPCMakeArray(IDL_TYP_LONG, 2, lDim, 0, 
				  &pVar1)) == (UCHAR*)NULL) {
   /*
    *  Had an error in creating the array
    */
       fprintf(stderr, "IDL_RPCMakeArray: Null value returned\n");
       return 1;
    }
/*
 * Create a temporary variable and copy the array data to it. Then
 * test to make sure the variable copied correctly.
 */
   if( (pVar2 = IDL_RPCGettmp()) == NULL){
      IDL_RPCDeltmp(pVar1);
      fprintf(stderr, "IDL_RPCGettmp: Error getting variable\n");
      return 1;
   }
/*
 * Do a var copy on the array and make sure that the correct behavoir
 * occurs.
 */
   IDL_RPCVarCopy(pVar1, pVar2);

/*
 * Check the source variable. It should be an undefined variable with
 * the TEMP flag set.
 */
   if(pVar1->type != (UCHAR)0){
      fprintf(stderr, "IDL_RPCVarCopy: source variable type incorrect\n");
      return 1;
   }
   if(!(pVar1->flags & IDL_V_TEMP)){
      fprintf(stderr, "IDL_RPCVarCopy: source temp flag not preserved\n");
      return 1;
   }
   if( pVar1->flags & ~IDL_V_TEMP){
       fprintf(stderr, "IDL_RPCVarCopy: source flags incorrect\n");
       return 1;
   }
   if(IDL_RPCVarIsArray(pVar1)){    /* source should be undefined */
      fprintf(stderr, "IDL_RPCVarCopy: source variable not zeroed\n");
      return 1;
   }
/* 
 * Now for the dest. variable
 */
   if(!IDL_RPCVarIsArray(pVar2)){ /* dest should now be an array */
     fprintf(stderr, "IDL_RPCVarCopy: Array was not copied correctly\n");
     return 1;
   }
   if(IDL_RPCGetArrayData(pVar2) != pData1){
      fprintf(stderr, "IDL_RPCVarCopy: Array Data block not moved\n");
      return 1;
   }
   if(IDL_RPCGetArrayNumDims(pVar2) != 2){
      fprintf(stderr, "IDL_RPCVarCopy: Dest. array dims incorrect.\n");
      return 1;
   }
   IDL_RPCDeltmp(pVar1);  /* free up variable */
/*
 * Now copy the information over to a static variable. This will be 
 * used to verify var copy will allocate space for data when the source
 * variable is not marked *temp*.
 */ 
   IDL_RPCVarCopy(pVar2, &Var1_s);
/*
 * pVar2 should now be *undefined*. Check this.
 */
   if(pVar2->type != (UCHAR)NULL || !(pVar2->flags & IDL_V_TEMP)){
      fprintf(stderr, "IDL_RPCVarCopy: error with copy to static var.\n");
      return 1;
   }
   IDL_RPCVarCopy( &Var1_s, pVar2); /* should allocate new memory */

   if(!IDL_RPCVarIsArray(&Var1_s)){
      fprintf(stderr, "IDL_RPCVarCopy: error with copy to static var.\n");
      return 1;
   }
   if(IDL_RPCGetArrayData(pVar2) == IDL_RPCGetArrayData(&Var1_s)){
   /*
    * The data pointers should be different. Signal an error
    */
      fprintf(stderr, "IDL_RPCVarCopy: static copy, data was moved\n");
      return 1;
   }
/*
 * Make sure that the dest variable didnt get the tmp bit set
 */
   if(Var1_s.flags & IDL_V_TEMP){
      fprintf(stderr, "IDL_RPCVarCopy: static variable had TEMP bit set\n");
      return 1;
   }
/* 
 * Now free the array and all variables that are in use
 */
   IDL_RPCDeltmp(pVar2);
   IDL_RPCDeltmp(&Var1_s);

/* 
 * Now for the last test, Lets import an array.
 */
   pData1 = (UCHAR*)malloc((unsigned)sizeof(IDL_LONG)*100);
   if(!pData1){
      perror("malloc");
      return 1;
   }
   pVar1 = IDL_RPCImportArray(2, lDim, IDL_TYP_LONG, pData1, 
			      (IDL_ARRAY_FREE_CB)RPCArrCBTest);
   if(!pVar1){
      fprintf(stderr, "IDL_RPCImportArray: error detected\n");
      free(pData1);
      return 1;
   }
/*
 * Do a quick array check
 */
   if( !IDL_RPCVarIsArray(pVar1)){
      fprintf(stderr, "IDL_RPCImportArray: Array flag not set\n");
      free(pData1);
      return 1;
   }
   if( IDL_RPCGetArrayNumDims(pVar1) != 2){
      fprintf(stderr, "IDL_RPCImportArray: n dims incorrect\n");
      free(pData1);
      return 1;
   }
   if( IDL_RPCGetArrayData(pVar1) != pData1){
      fprintf(stderr, "IDL_RPCImportArray: Data pointer incorrect.\n");
      free(pData1);
      return 1;
   }
/*
 * Now free the data. This should call the callback func.
 */
   iCBFlag =1;  /* should be set to 0 by the callback function */
   IDL_RPCDeltmp(pVar1);
   if(iCBFlag){
      fprintf(stderr, "IDL_RPCDeltmp: Error in calling memory callback.\n");
      return 1;
   }
  
   return 0;
}			         
/*************************************************************************
 * RPCStringTest()
 *
 * Purpose:
 *	This routine test the string functions which are part of the 
 * 	API.
 */
int RPCStringTest(void)
{
   IDL_STRING  IDLStr_s;
   IDL_ALLTYPES  Scalar_s;
   char     * pCStr;

   bzero((char*)&IDLStr_s, sizeof(IDL_STRING));
/*
 * Store the value of a string in the alltypes union
 */
   IDL_RPCStrStore(&IDLStr_s, "testing");

   if(IDLStr_s.slen != 7){
      fprintf(stderr, "IDL_RPCStrStore: String Length incorrect.\n");
      return 1;
   }
   pCStr = IDLStr_s.s;   /* get the pointer to the string */
/* 
 * Dup the string and make sure the poniters change
 */
   IDL_RPCStrDup( &IDLStr_s, 1L);
   if(IDLStr_s.s == pCStr){
      fprintf(stderr, "IDL_RPCStrDup: string not duplicated.\n");
      return 1;
   }
/*
 * Delete the string and make sure the struct is cleared.
 */
   IDL_RPCStrDelete(&IDLStr_s, 1L);
   if(IDLStr_s.slen != 0 || IDLStr_s.stype != 0){
      fprintf(stderr, "IDL_RPCStrDelete: String sturct not cleared.\n");
      return 1;
   }
/*
 * And now for ensure length
 */
   IDL_RPCStrEnsureLength(&IDLStr_s, 23);
   if(IDLStr_s.slen != 23){
      fprintf(stderr, "IDL_RPCStrEnsureLength: slen not set correctly.\n");
      return 1;
   }
   IDL_RPCStrDelete(&IDLStr_s, 1L);
/*
 * Thats it for the string test
 */

   return 0;
}
/***************************************************************************
 * RpcScalarTest() 
 * 
 * Used to test the scalar ops available via IDL rpc's
 */
int RPCScalarTest(CLIENT *client)
{
   IDL_VPTR   vPtr, vTmp;
   IDL_ALLTYPES type_s;
   IDL_RPC_LINE_S sLine;
   int status;

   vPtr = IDL_RPCGettmp();  
/*
 * Set the values of the scalar and send to the RPC server
 */
   type_s.c = (UCHAR)1;
   IDL_RPCStoreScalar(vPtr, IDL_TYP_BYTE, &type_s);
   if(!IDL_RPCSetMainVariable(client, "V_BYTE", vPtr)){
      fprintf(stderr, "error setting variable in server: byte");
      IDL_RPCDeltmp(vPtr);
      return 1;
   }

   vTmp = IDL_RPCGetMainVariable(client, "V_BYTE");
   if(vTmp->type != IDL_TYP_BYTE || vTmp->value.c != (UCHAR)1){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting variable\n");
       return 1;
   }
   IDL_RPCDeltmp(vTmp);

   type_s.i = 2;
   IDL_RPCStoreScalar(vPtr, IDL_TYP_INT, &type_s);
   if(!IDL_RPCSetMainVariable(client, "V_INT", vPtr)){
      fprintf(stderr, "error setting variable in server: int");
      IDL_RPCDeltmp(vPtr);
      return 1;
   }
   vTmp = IDL_RPCGetMainVariable(client, "V_INT");
   if(vTmp->type != IDL_TYP_INT || vTmp->value.i != 2){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting variable\n");
       return 1;
   }
   IDL_RPCDeltmp(vTmp);

   type_s.l = 3L;
   IDL_RPCStoreScalar(vPtr, IDL_TYP_LONG, &type_s);
   if(!IDL_RPCSetMainVariable(client, "V_LONG", vPtr)){
      fprintf(stderr,"error setting variable in server: long");
      IDL_RPCDeltmp(vPtr);
      return 1;
   }
   vTmp = IDL_RPCGetMainVariable(client, "V_LONG");
   if(vTmp->type != IDL_TYP_LONG || vTmp->value.l != 3L){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting variable\n");
       return 1;
   }
   IDL_RPCDeltmp(vTmp);

   type_s.f = 4.0f;
   IDL_RPCStoreScalar(vPtr, IDL_TYP_FLOAT, &type_s);
   if(!IDL_RPCSetMainVariable(client, "V_FLOAT", vPtr)){
      fprintf(stderr,"error setting variable in server: float");
      IDL_RPCDeltmp(vPtr);
      return 1;
   }
   vTmp = IDL_RPCGetMainVariable(client, "V_FLOAT");
   if(vTmp->type != IDL_TYP_FLOAT || vTmp->value.f != 4.0f){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting variable\n");
       return 1;
   }
   IDL_RPCDeltmp(vTmp);

   type_s.d = 5.0;
   IDL_RPCStoreScalar(vPtr, IDL_TYP_DOUBLE, &type_s);
   if(!IDL_RPCSetMainVariable(client, "V_DOUBLE", vPtr)){
      fprintf(stderr,"error setting variable in server: double");
      IDL_RPCDeltmp(vPtr);
      return 1;
   }

   vTmp = IDL_RPCGetMainVariable(client, "V_DOUBLE");
   if(vTmp->type != IDL_TYP_DOUBLE || vTmp->value.d != 5.0){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting variable\n");
       return 1;
   }

   IDL_RPCDeltmp(vTmp);
   type_s.cmp.r = 6.0f;
   type_s.cmp.i = 7.0f;
   IDL_RPCStoreScalar(vPtr, IDL_TYP_COMPLEX, &type_s);
   if(!IDL_RPCSetMainVariable(client, "V_COMPLEX", vPtr)){
      fprintf(stderr,"error setting variable in server: complex");
      IDL_RPCDeltmp(vPtr);
      return 1;
   }
   vTmp = IDL_RPCGetMainVariable(client, "V_COMPLEX");
   if(vTmp->type != IDL_TYP_COMPLEX || vTmp->value.cmp.r != 6.0f ||
	vTmp->value.cmp.i != 7.0f){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting variable\n");
       return 1;
   }
   IDL_RPCDeltmp(vTmp);

   type_s.dcmp.r = 8.0;
   type_s.dcmp.i = 9.0;
   IDL_RPCStoreScalar(vPtr, IDL_TYP_DCOMPLEX, &type_s);
   if(!IDL_RPCSetMainVariable(client, "V_DCOMPLEX", vPtr)){
      printf("error setting variable in server: double complex");
      IDL_RPCDeltmp(vPtr);
      return 1;
   }
   vTmp = IDL_RPCGetMainVariable(client, "V_DCOMPLEX");
   if(vTmp->type != IDL_TYP_DCOMPLEX || vTmp->value.dcmp.r != 8.0 ||
	vTmp->value.dcmp.i != 9.0){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting variable\n");
       return 1;
   }
   IDL_RPCDeltmp(vTmp);

   IDL_RPCStrStore(&type_s.str, "TEN");	/* test string functions also */
   IDL_RPCStoreScalar(vPtr, IDL_TYP_STRING, &type_s); /* copies string */
   IDL_RPCStrDelete(&type_s.str, 1L);
   if(!IDL_RPCSetMainVariable(client, "V_STRING", vPtr)){
      fprintf(stderr,"error setting variable in server: string ");
      IDL_RPCDeltmp(vPtr);
      return 1;
   }
   vTmp = IDL_RPCGetMainVariable(client, "V_STRING");
   if(vTmp->type != IDL_TYP_STRING || strcmp(vPtr->value.str.s, 
		vTmp->value.str.s)){
       fprintf(stderr, "IDL_RPCGetMainVariable: Error getting variable\n");
       return 1;
   }
   IDL_RPCDeltmp(vTmp);
   IDL_RPCDeltmp(vPtr);

   if(IDL_RPCExecuteStr(client, "HELP")){
      fprintf(stderr, "IDL_RPCExecuteStr: Error executing string \n");
      return 1;
   }
   return 0;
}
/***************************************************************************
 * RPCGetArrayTest()
 *
 * Used to test the passing of Array data back and fourth from IDL
 * to the server.
 */
int RPCGetArrayTest(CLIENT *pClient)
{
  IDL_VPTR  pVtmp;
  UCHAR    *pByte;
  int      *pInt;
  IDL_LONG *pLong;
  float    *pFloat;
  double   *pDouble;
  IDL_COMPLEX *pComplex;
  IDL_DCOMPLEX *pDComplex;
  IDL_STRING *pString;
    
  if(IDL_RPCExecuteStr(pClient, "VA_BYTE=bindgen(15)")){
      fprintf(stderr,"Error executing Command String\n");
      return 1;
   }
   pVtmp = IDL_RPCGetMainVariable(pClient, "VA_BYTE");
   if(IDL_RPCGetVarType(pVtmp) != IDL_TYP_BYTE || !IDL_RPCVarIsArray(pVtmp) ||
      IDL_RPCGetArrayNumElts(pVtmp) != 15){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting byte array\n");
      return 1;
   }
   IDL_RPCDeltmp(pVtmp);

   if(IDL_RPCExecuteStr(pClient, "VA_INT=indgen(31)")){
      fprintf(stderr,"Error executing command string\n");
      return 1;
   }
   pVtmp = IDL_RPCGetMainVariable(pClient, "VA_INT");
   if(IDL_RPCGetVarType(pVtmp) != IDL_TYP_INT || !IDL_RPCVarIsArray(pVtmp) ||
      IDL_RPCGetArrayNumElts(pVtmp) != 31){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting int array\n");
      return 1;
   }
   IDL_RPCDeltmp(pVtmp);

   if(IDL_RPCExecuteStr(pClient, "VA_LONG=lindgen(30)")){
      fprintf(stderr,"Error executing command string\n");
      return 1;
   }
   pVtmp = IDL_RPCGetMainVariable(pClient, "VA_LONG");
   if(IDL_RPCGetVarType(pVtmp) != IDL_TYP_LONG || !IDL_RPCVarIsArray(pVtmp) ||
      IDL_RPCGetArrayNumElts(pVtmp) != 30){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting long array\n");
      return 1;
   }
   IDL_RPCDeltmp(pVtmp);

   if(IDL_RPCExecuteStr(pClient, "VA_FLOAT=findgen(31)")){
      fprintf(stderr,"Error executing command string\n");
      return 1;
   }
   pVtmp = IDL_RPCGetMainVariable(pClient, "VA_FLOAT");
   if(IDL_RPCGetVarType(pVtmp) != IDL_TYP_FLOAT || !IDL_RPCVarIsArray(pVtmp) ||
      IDL_RPCGetArrayNumElts(pVtmp) != 31){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting float array\n");
      return 1;
   }
   IDL_RPCDeltmp(pVtmp);

   if(IDL_RPCExecuteStr(pClient, "VA_DOUBLE=dindgen(30)")){
      fprintf(stderr,"Error executing command string\n");
      return 1;
   }
   pVtmp = IDL_RPCGetMainVariable(pClient, "VA_DOUBLE");
   if(IDL_RPCGetVarType(pVtmp) != IDL_TYP_DOUBLE || !IDL_RPCVarIsArray(pVtmp) ||
      IDL_RPCGetArrayNumElts(pVtmp) != 30){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting double array\n");
      return 1;
   }
   IDL_RPCDeltmp(pVtmp);

   if(IDL_RPCExecuteStr(pClient, "VA_COMPLEX=cindgen(21)")){
      fprintf(stderr,"Error executing command string\n");
      return 1;
   }
   pVtmp = IDL_RPCGetMainVariable(pClient, "VA_COMPLEX");
   if(IDL_RPCGetVarType(pVtmp) != IDL_TYP_COMPLEX || !IDL_RPCVarIsArray(pVtmp) ||
      IDL_RPCGetArrayNumElts(pVtmp) != 21){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting complex array\n");
      return 1;
   }
   IDL_RPCDeltmp(pVtmp);

   if(IDL_RPCExecuteStr(pClient, "VA_DCOMPLEX=dcindgen(7)")){
      fprintf(stderr,"Error executing command string\n");
      return 1;
   }
   pVtmp = IDL_RPCGetMainVariable(pClient, "VA_DCOMPLEX");
   if(IDL_RPCGetVarType(pVtmp) != IDL_TYP_DCOMPLEX || !IDL_RPCVarIsArray(pVtmp) ||
      IDL_RPCGetArrayNumElts(pVtmp) != 7){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting dcomplex array\n");
      return 1;
   }
   IDL_RPCDeltmp(pVtmp);

   if(IDL_RPCExecuteStr(pClient, "VA_STRING=sindgen(32)")){
      fprintf(stderr,"Error executing command string\n");
      return 1;
   }
   pVtmp = IDL_RPCGetMainVariable(pClient, "VA_STRING");
   if(IDL_RPCGetVarType(pVtmp) != IDL_TYP_STRING || !IDL_RPCVarIsArray(pVtmp) ||
      IDL_RPCGetArrayNumElts(pVtmp) != 32){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting string array\n");
      return 1;
   }
   IDL_RPCDeltmp(pVtmp);
   if(IDL_RPCExecuteStr(pClient, "HELP")){
      fprintf(stderr, "IDL_RPCExecuteStr: Error executing help command\n");
      return 1;
   }
   return 0;
}
/****************************************************************************
 * RpcSetArray()
 *
 * Used to test the array setting ability of the routines.
 */
int RPCSetArrayTest(CLIENT *pClient)
{

   IDL_VPTR  pVptr;
   UCHAR    *pByte;
   short    *pInt;
   IDL_LONG *pLong;
   float    *pFloat;
   double   *pDouble;
   IDL_COMPLEX *pComplex;
   IDL_DCOMPLEX *pDComplex;
   IDL_STRING *pString;

   IDL_LONG     l_dim1 = 100;
   IDL_LONG     l_dim2[2] = {10,9}; 
   int          i,j;

/*
 * Start with Main Level. Send over an byte array
 */
   pByte = (UCHAR*)IDL_RPCMakeArray(IDL_TYP_BYTE, 1, &l_dim1, 
				    IDL_BARR_INI_ZERO, &pVptr);
   for(i=0;i<l_dim1;i++)
     pByte[i]=(UCHAR)i;

   if(!IDL_RPCSetMainVariable(pClient, "SET_BYTE", pVptr)){
     fprintf(stderr,"error setting output variable\n");
     return 1;
   }
   IDL_RPCDeltmp(pVptr);
   pVptr = IDL_RPCGetMainVariable(pClient, "SET_BYTE");
   if(!pVptr){
      fprintf(stderr, "IDL_RPCGetVariable: Error getting variable SET_BYTE.\n");
      return 1;
    }
/*
 * Does result look sane?
 */
   if(IDL_RPCGetVarType(pVptr) != IDL_TYP_BYTE || !IDL_RPCVarIsArray(pVptr) ||
      IDL_RPCGetArrayNumElts(pVptr) != l_dim1){
      fprintf(stderr, "Return Byte variable attributes wrong.\n");
      return 1;
   }
   IDL_RPCDeltmp(pVptr);

   pInt = (short*)IDL_RPCMakeArray(IDL_TYP_INT, 1, &l_dim1, 
				    IDL_BARR_INI_ZERO, &pVptr);
   for(i=0;i<l_dim1;i++)
      pInt[i]=(short)i;
   if(!IDL_RPCSetMainVariable(pClient, "SET_INT", pVptr)){
     fprintf(stderr, "error setting output variable\n");
     return 1;
   }
   IDL_RPCDeltmp(pVptr);
   pVptr = IDL_RPCGetMainVariable(pClient, "SET_INT");
   if(!pVptr){
      fprintf(stderr, "IDL_RPCGetVariable: Error getting variable SET_INT.\n");
      return 1;
    }
/*
 * Does result look sane?
 */
   if(IDL_RPCGetVarType(pVptr) != IDL_TYP_INT || !IDL_RPCVarIsArray(pVptr) ||
      IDL_RPCGetArrayNumElts(pVptr) != l_dim1){
      fprintf(stderr, "Return int variable attributes wrong.\n");
      return 1;
   }
   IDL_RPCDeltmp(pVptr);

   pLong = (IDL_LONG*)IDL_RPCMakeArray(IDL_TYP_LONG, 2, l_dim2, 
				    IDL_BARR_INI_ZERO, &pVptr);
   if(!IDL_RPCSetMainVariable(pClient, "SET_LONG", pVptr)){
     fprintf(stderr,"error setting output variable\n");
     return 1;
   }
   IDL_RPCDeltmp(pVptr);
   pVptr = IDL_RPCGetMainVariable(pClient, "SET_LONG");
   if(!pVptr){
      fprintf(stderr, "IDL_RPCGetVariable: Error getting variable SET_LONG.\n");
      return 1;
    }
/*
 * Does result look sane?
 */
   if(IDL_RPCGetVarType(pVptr) != IDL_TYP_LONG || !IDL_RPCVarIsArray(pVptr) ||
      IDL_RPCGetArrayNumElts(pVptr) != l_dim2[0]*l_dim2[1]){
      fprintf(stderr, "Return long variable attributes wrong.\n");
      return 1;
   }
   IDL_RPCDeltmp(pVptr);

   pFloat = (float*)IDL_RPCMakeArray(IDL_TYP_FLOAT, 1, &l_dim1, 
				    IDL_BARR_INI_ZERO, &pVptr);
   for(i=0;i<l_dim1;i++)
      pFloat[i]=(float)i;
   if(!IDL_RPCSetMainVariable(pClient, "SET_FLOAT", pVptr)) {
     fprintf(stderr, "error setting output variable\n");
     return 1;
   }
   IDL_RPCDeltmp(pVptr);
   pVptr = IDL_RPCGetMainVariable(pClient, "SET_FLOAT");
   if(!pVptr){
      fprintf(stderr, "IDL_RPCGetVariable: Error getting variable SET_FLOAT.\n");
      return 1;
    }
/*
 * Does result look sane?
 */
   if(IDL_RPCGetVarType(pVptr) != IDL_TYP_FLOAT || !IDL_RPCVarIsArray(pVptr) ||
      IDL_RPCGetArrayNumElts(pVptr) != l_dim1){
      fprintf(stderr, "Return float variable attributes wrong.\n");
      return 1;
   }
   IDL_RPCDeltmp(pVptr);
/*
 * Now with the current program Level. Send over an byte array
 */
   pByte = (UCHAR*)IDL_RPCMakeArray(IDL_TYP_BYTE, 1, &l_dim1, 
				    IDL_BARR_INI_ZERO, &pVptr);
   for(i=0;i<l_dim1;i++)
     pByte[i]=(UCHAR)i;

   if(!IDL_RPCSetVariable(pClient, "SET_BYTE", pVptr)){
     fprintf(stderr,"error setting output variable\n");
     return 1;
   }
   IDL_RPCDeltmp(pVptr);
   pVptr = IDL_RPCGetVariable(pClient, "SET_BYTE");
   if(!pVptr){
      fprintf(stderr, "IDL_RPCGetVariable: Error getting variable SET_BYTE.\n");
      return 1;
    }
/*
 * Does result look sane?
 */
   if(IDL_RPCGetVarType(pVptr) != IDL_TYP_BYTE || !IDL_RPCVarIsArray(pVptr) ||
      IDL_RPCGetArrayNumElts(pVptr) != l_dim1){
      fprintf(stderr, "Return byte variable attributes wrong.\n");
      return 1;
   }
   IDL_RPCDeltmp(pVptr);

   pInt = (short*)IDL_RPCMakeArray(IDL_TYP_INT, 1, &l_dim1, 
				    IDL_BARR_INI_ZERO, &pVptr);
   for(i=0;i<l_dim1;i++)
      pInt[i]=(short)i;
   if(!IDL_RPCSetVariable(pClient, "SET_INT", pVptr)){
     fprintf(stderr, "error setting output variable\n");
     return 1;
   }
   IDL_RPCDeltmp(pVptr);
   pVptr = IDL_RPCGetVariable(pClient, "SET_INT");
   if(!pVptr){
      fprintf(stderr, "IDL_RPCGetVariable: Error getting variable SET_INT.\n");
      return 1;
    }
/*
 * Does result look sane?
 */
   if(IDL_RPCGetVarType(pVptr) != IDL_TYP_INT || !IDL_RPCVarIsArray(pVptr) ||
      IDL_RPCGetArrayNumElts(pVptr) != l_dim1){
      fprintf(stderr, "Return int variable attributes wrong.\n");
      return 1;
   }
   IDL_RPCDeltmp(pVptr);

   pLong = (IDL_LONG*)IDL_RPCMakeArray(IDL_TYP_LONG, 2, l_dim2, 
				    IDL_BARR_INI_ZERO, &pVptr);
   if(!IDL_RPCSetVariable(pClient, "SET_LONG", pVptr)){
     fprintf(stderr,"error setting output variable\n");
     return 1;
   }
   IDL_RPCDeltmp(pVptr);
   pVptr = IDL_RPCGetVariable(pClient, "SET_LONG");
   if(!pVptr){
      fprintf(stderr, "IDL_RPCGetVariable: Error getting variable SET_LONG.\n");
      return 1;
    }
/*
 * Does result look sane?
 */
   if(IDL_RPCGetVarType(pVptr) != IDL_TYP_LONG || !IDL_RPCVarIsArray(pVptr) ||
      IDL_RPCGetArrayNumElts(pVptr) != l_dim2[0]*l_dim2[1]){
      fprintf(stderr, "Return long variable attributes wrong.\n");
      return 1;
   }
   IDL_RPCDeltmp(pVptr);

   pFloat = (float*)IDL_RPCMakeArray(IDL_TYP_FLOAT, 1, &l_dim1, 
				    IDL_BARR_INI_ZERO, &pVptr);
   for(i=0;i<l_dim1;i++)
      pFloat[i]=(float)i;
   if(!IDL_RPCSetVariable(pClient, "SET_FLOAT", pVptr)) {
     fprintf(stderr, "error setting output variable\n");
     return 1;
   }
   IDL_RPCDeltmp(pVptr);
   pVptr = IDL_RPCGetVariable(pClient, "SET_FLOAT");
   if(!pVptr){
      fprintf(stderr, "IDL_RPCGetVariable: Error getting variable SET_FLOAT.\n");
      return 1;
    }
/*
 * Does result look sane?
 */
   if(IDL_RPCGetVarType(pVptr) != IDL_TYP_FLOAT || !IDL_RPCVarIsArray(pVptr) ||
      IDL_RPCGetArrayNumElts(pVptr) != l_dim1){
      fprintf(stderr, "Return float variable attributes wrong.\n");
      return 1;
   }
   IDL_RPCDeltmp(pVptr);

   if(IDL_RPCExecuteStr(pClient, "HELP, SET_BYTE, SET_INT, SET_LONG, set_float")){
      fprintf(stderr, "IDL_RPCExecuteStr: Error executing help command\n");
      return 1;
   }
   return 0; 
}
/***************************************************************************
 * RPCMemoryTest()
 *
 * Purpose:
 *	This routine sends an array to the server repeatedly and 
 * 	checks for any memory leaks on the server side.
 */
int RPCMemoryTest(CLIENT *pClient)
{
   char 	*pData;
   IDL_VPTR	 pVar, pVarMem;
   long		 lMem0;
   int		 i, iRet=0;    		
   IDL_LONG      lDim=100;
/*
 * Start by building an array variable
 */
   pData = IDL_RPCMakeArray(IDL_TYP_FLOAT, 1, &lDim, 
			    IDL_BARR_INI_ZERO, &pVar);
   if(!pData){
      fprintf(stderr, "IDL_RPCMakeArray: Error allocating memory\n");
      return 1;
   }
/* 
 * Send the variable to the server so that it is initially set.
 */
   if(!IDL_RPCSetMainVariable(pClient, "F_MEM", pVar)){
      fprintf(stderr, "IDL_RPCSetMainVariable: Error setting array\n");
      IDL_RPCDeltmp(pVar);
      return 1;
   }
/*
 * Get the start memory value
 */
   if(IDL_RPCExecuteStr(pClient, "mem0=(memory())(0)")){
      fprintf(stderr, "IDL_RPCExecuteStr: Error setting memory variable\n");
      IDL_RPCDeltmp(pVar);
      return 1;
   }
   pVarMem = IDL_RPCGetMainVariable(pClient, "MEM0");
   if(!pVarMem){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting mem0\n");
      IDL_RPCDeltmp(pVar);
      return 1;
   }
   lMem0 = IDL_RPCGetVarLong(pVarMem);
   IDL_RPCDeltmp(pVarMem);
   (void)IDL_RPCExecuteStr(pClient, "help, /mem");
/*
 * Now to loop thru and set the variable on the server side.
 */
   for(i=0;i<1000; i++){
      if(!IDL_RPCSetMainVariable(pClient, "F_MEM", pVar)){
	 fprintf(stderr, "IDL_RPCSetMainVariable: Error setting F_MEM\n");
	 IDL_RPCDeltmp(pVar);
	 return 1;
      }
      if( !(i %10)){		/* A "working" indicator */
        fprintf(stdout,".");
        fflush(stdout);
      }
   } 
   (void)IDL_RPCExecuteStr(pClient, "help, /mem");
/*
 * Now get the resulting memory level.
 */
   if(IDL_RPCExecuteStr(pClient, "mem0=(memory())(0)")){
      fprintf(stderr, "IDL_RPCExecuteStr: Error setting memory variable\n");
      IDL_RPCDeltmp(pVar);
      return 1;
   }
   pVarMem = IDL_RPCGetMainVariable(pClient, "MEM0");
   if(!pVarMem){
      fprintf(stderr, "IDL_RPCGetMainVariable: Error getting mem0\n");
      IDL_RPCDeltmp(pVar);
      return 1;
   }
   if(lMem0 != IDL_RPCGetVarLong(pVarMem)){
      fprintf(stderr, "Memory Leak detected on the server.\n");
      fprintf(stderr, "\tInitial %d\t Final %d\n", lMem0, 
	      IDL_RPCGetVarLong(pVarMem));
      iRet = 1;
   }
   IDL_RPCDeltmp(pVarMem);
   IDL_RPCDeltmp(pVar);
   return iRet;
}
/***************************************************************************
 * RPCExeTest()
 *
 * Used to test the execute command string functionality.
 */
int RPCExeTest( CLIENT *pClient)
{

   int     iResult;
   char    sBuffer[512];

/*
 * Start by setting up command line trapping
 */
   if(!IDL_RPCOutputCapture(pClient, 100)){
      fprintf(stderr, "IDL_RPCOutputCapture: Error setting up buffer\n");
      return 1;
   }
/*
 * Start up a command processing loop
 */
   fprintf(stdout, "\nEnter IDL Commands,  ^D or a null line to exit\n\n");
   for(;;){
      printf("RMTIDL> ");
      sBuffer[0] = '\0';
      gets(sBuffer);
      if(sBuffer[0] == (char)NULL)
         break;   /* user whats to exit */
      iResult=IDL_RPCExecuteStr( pClient, sBuffer);
      RPCFlushOutput(pClient);
      
   /*
    * Now flush the output buffer
    */
   }
   printf("\n");
   if(!IDL_RPCOutputCapture(pClient, 0)){
      fprintf(stderr, "IDL_RPCOutputCapture: Error disabling output capture.\n");
      return 1;
   }
   return 0;
}
/***************************************************************************
 * RpcFlushOutput()
 *
 * Test routine that empties out the output queue on the server
 */
void RPCFlushOutput(CLIENT *pClient)
{
   IDL_RPC_LINE_S sLine;
   char           outbuffer[IDL_RPC_MAX_STRLEN];

   sLine.buf = outbuffer;

   while(IDL_RPCOutputGetStr(pClient, &sLine, 0)){
      printf("%s%c", sLine.buf, (sLine.flags & IDL_TOUT_F_NLPOST ?
				     '\n' : '\0'));
   } /* thats it */
 }



