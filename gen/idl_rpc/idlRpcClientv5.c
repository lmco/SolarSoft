/************************************************************************/
/*									*/
/*	rmtidl.c							*/
/*									*/
/*	Copyright (c) 1992, Research Systems Inc.  All rights reserved.	*/
/*									*/
/*      S.L.Freeland - modified to send one command to the server       */
/*		       and exit (for http script calls)			*/
/*                     (Started from RSI rmtidl.c)			*/
/*									*/
/*	Note: Commands must only one line.				*/
/*	                                                                */
/*      Modified by David Schiff 2 Feb 98 for IDL RPC version 5         */								*/
/************************************************************************/



#include        <stdio.h>
#include        <ctype.h>
#include        idl_rpc.h
#include	<sys/time.h>

/************************************************************************/
/*									*/
/*	main								*/
/*									*/
/*	Usage: idlrpc [server_id] [hostname]				*/
/*									*/
/*	E.g.	idlrpc 0x234567890		-- change server id	*/
/*		idlrpc mymachine		-- use remote host	*/
/*						   'mymachine'		*/
/*		idlrpc 0x12345678 thunder	-- use IDL running on	*/
/*			host 'thunder' with server ID 12345678 (hex)	*/
/*									*/
/************************************************************************/

main(c,v)
    int	c;
    char **v;
{
    CLIENT		* client;
    char		cmdbuffer[ MAX_STRING_LEN ];
    LONG		server_id	 = 0;
    char		* hostname	= NULL;
    char		* status	=NULL;

    /*	The default call to register a client is:			*/
    /*									*/
    /*		register_idl_client(server-id, hostname, timeout)	*/
    /*									*/
    /*	where the default values are:					*/
    /*		Server ID = 0x2010cafe  (IDL_DEFAULT_ID)		*/
    /*		hostname  = "localhost"					*/
    /*		timeout   = 3 seconds					*/
    /*	In this module we allow the user to specify the server ID	*/
    /*	and/or the hostname. register_idl_client(0,NULL,NULL) means	*/
    /*	use defaults for everything					*/
    

    /*	If the user has specified 2 arguments, then the first		*/
    /*	must be the server ID (in hexadecimal) and the second		*/
    /*	argument the hostname						*/
    
    if( c >= 3 ) {
	sscanf( v[1], "0x%x", &server_id );
	hostname = v[2];

	/*	Show the user what he/she chose				*/
	
	printf("Serverid = %x, Host=%s\n", server_id, hostname );

	/*	Tell IDL server we want to be a client			*/

	client	= IDL_RPCInit( server_id, hostname, NULL );
    }

    /*	If there is only one argument, determine if it is a server ID	*/
    /*	or a hostname. Server IDs need to start with '0x'.		*/

    else if( c == 2 ) {
	if( !strncmp( v[1], "0x", 2 ) ) {
	    sscanf( v[1], "0x%x", &server_id );
	}
	else {
	    hostname	= v[1];
	}

	/*	Tell IDL server we want to be a client			*/

	client = IDL_RPCInit( server_id, hostname, NULL );
    }

    /*	If there are no arguments specified. The just use the defaults	*/

    else
	client = IDL_RPCInit( 0, NULL, NULL );

    /*	See if we found the desired server. If not, tell user that we	*/
    /*	failed and why.							*/
    
    if( client == NULL ) {
	printf("Can't register with server on \"%s\"\n",
	       hostname ? hostname : "localhost");
	exit(1);
    }

    /*	Now we are ready to run our remote command line.		*/
    /*	read in lines the user types and send them to our IDL server.	*/
    /*	Quit if user types a null line (or EOF)				*/

	/*	Print error code returned by running the command	*/
	
	IDL_RPCExecuteStr( client, v[3] );

    /*	Done. Kill server, cleanup and exit				*/


    if (!IDL_RPCCleanup(client, 1))
       fprintf(stderr, "IDL_RPCCleanup: failed\n");

    exit(0);
}    


