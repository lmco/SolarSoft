/************************************************************************

  idlRpcClient.c							

  David Schiff
  3 February 1998
  Based on idl_rpc.c by S.L.Freeland - send one command to idl server and exit 
  
  Usage: idlRpcClient [server id in hexadecimal] [hostname-optional] "command string"

  Example: idlRpcClient 0x2010CAFE "PRINT, 'Hello World'"

  The server id is NOT optional
  IDL command must be in double quotes.
  Multiline IDL commands are not permitted.

************************************************************************/


#include        <stdio.h>
#include        <ctype.h>
#include        "idl_rpc.h"
#include	<sys/time.h>


#define USAGE 1
#define INIT 2
#define EXECUTE 3
#define CLEANUP 4
#define KEEP_SERVER_RUNNING 0

/*
const int USAGE = 1;
const int INIT = 2;
const int EXECUTE = 3;
const int CLEANUP = 4;
*/

main(int argc, char *argv[])
{
    CLIENT *client;
    long server;
    int retval;
    char *command, *hostname = NULL;
    void leave(int code);

    void parseCommandLine(int argc, char ** argv, long* server, 
                         char **hostname, char **command);
    
    parseCommandLine(argc, argv, &server, &hostname, &command);

    if ( !(client = IDL_RPCInit(server, hostname)))
       leave(INIT);

    /*
      I was getting execute errors for good commands, and server
       showed correct output, return -55 Syntax Error.
       Same error for garbage commands.

    if ( !IDL_RPCExecuteStr( client, command ) )
       leave(EXECUTE);
    */

    IDL_RPCExecuteStr( client, command );

    if (!IDL_RPCCleanup(client, KEEP_SERVER_RUNNING))
       leave(CLEANUP);

    exit(0);

} /* end main */


void parseCommandLine(int argc, char *argv[], long *server, 
                     char**hostname, char **command)
{
    char *ptr;
    void leave(int code);

    if ( argc < 3 || argc > 4)  leave(USAGE);

    /* server id is mandatory */
    *server = strtol(argv[1], &ptr, 16 );

    if (*ptr != '\0') leave(USAGE);

    if ( argc == 3)  *command = argv[2];

    else 
    {
       *hostname = argv[2];
       *command = argv[3];
    }
}



void leave(int code)
{
   char *message;

   switch (code)
   {
      case USAGE: message = "Usage: idlRpcClient <serverid> [hostname-optional]\
 <command in quotes>.\n Example: idlRpcClient 0x2010CAFE \"PRINT, 'Hello'\""; break;

      case INIT: message = "Could not connect to IDL RPC server.\n"; break;

      case EXECUTE: message = "Server could not execute the given command.\n"; break;

      case CLEANUP: message = "Error trying to free connection resources.\n"; break;

   }

   fprintf(stderr, "IDL RPC error: %s\n", message);

   exit(1);
}
                        
