/*
 * $Id: example.c,v 1.1 1997/01/29 23:25:54 kirk Exp $
 */
/*
  Copyright (c) 1988-1997, Research Systems Inc.  All rights reserved.
  This software includes information which is proprietary to and a
  trade secret of Research Systems, Inc.  It is not to be disclosed
  to anyone outside of this organization. Reproduction by any means
  whatsoever is  prohibited without express written permission.
 */

#include "idl_rpc.h"

int main()
{
   CLIENT *pClient;
   char    cmdBuffer[512];
   int     result;

/*
 * Connect to the server.
 */
   if((pClient = IDL_RPCInit(0, (char*)NULL)) == (CLIENT*)NULL){
      fprintf(stderr, "Can't register with IDL server\n");
      exit(1);
   }
/*
 * Start a loop that will read commands and then send them to idl.
 */
   for(;;){
     printf("RMTIDL>");
     cmdBuffer[0]='\0';
     gets(cmdBuffer);
     if( cmdBuffer[0] == '\n' || cmdBuffer[0] == '\0')
        break;
     result = IDL_RPCExecuteStr(pClient, cmdBuffer);
   }
/*
 * Now disconnect from the server and kill it.
 */
   if(!IDL_RPCCleanup(pClient, 1))
     fprintf(stderr, "IDL_RPCCleanup: failed\n");
   exit(0);
}
