/* rpc_tout.c -
 * 	This file contains routines that are used to maintain the
 * 	server Tout information. This includes the establishment of 
 * 	a linked list that maintains a list of output lines along with
 * 	the flags for the lines. For information on these flags, 
 * 	consult the IDL ADG.
 */

/*  
  Copyright (c) 1988-1997, Research Systems Inc.  All rights reserved.
  This software includes information which is proprietary to and a
  trade secret of Research Systems, Inc.  It is not to be disclosed
  to anyone outside of this organization. Reproduction by any means
  whatsoever is  prohibited without express written permission.
 */

static char rcsid[] = "$Id: rpc_tout.c,v 1.2 1997/01/18 08:23:00 ali Exp $";


#include "idl_rpc.h"

/*
 * Declare types for the output list. This is a simple link list of 
 * output strings.
 */

typedef struct rpc_tout_node {	/* node of the list */
   struct rpc_tout_node   * next;
   struct rpc_tout_node   * prev;
   char  *data;
}RPC_TOUT_NODE;

static struct rpc_tout_head {	/* head of the list. */
   int      max_lines;
   int      n_lines;
   struct rpc_tout_node  *head;
   struct rpc_tout_node  *tail;
}   lHead = {100, 0, 0, 0};
      

/*************************************************************
 * IDL_RPCOutListInit()
 *
 * Purpose:
 * 	Initailizes the head of the list for the list
 *
 * Parameters:
 *	maxLines - the maximum number of lines used in the list.
 */
void IDL_RPCOutListInit( int maxLines )
{
   lHead.max_lines = (maxLines <= 0 ? 200 : maxLines);
   lHead.head = NULL;
   lHead.tail = NULL;
}
/************************************************************
 * IDL_RPCOutListDequeue()
 *
 * Purpose:
 * 	This routine is used to remove the end item from the 
 * 	Output list.
 */
char *IDL_RPCOutListDequeue(void)
{
   char * pData;
   RPC_TOUT_NODE *pNode;

/*
 * are there any items in the list?
 */
   if(lHead.n_lines == 0)
      return (char*)NULL;
/*
 * Get the end data and move up the prev pointer.
 */
   pData = lHead.tail->data;
   pNode = lHead.tail;
   lHead.tail = (--lHead.n_lines == 0 ? NULL : pNode->prev);
   free((char*)pNode);		/* free node */
   return pData;
}
/************************************************************
 * IDL_RPCOutListPop()
 *
 * Purpose:
 * 	This routine is used to pop the first element of the top 
 * 	of the output list.
 */
char *IDL_RPCOutListPop(void)
{
   char  *pData;
   RPC_TOUT_NODE  *pNode;

   if(lHead.n_lines == 0)
      return (char*)NULL; /* no need to continue */
/*
 * Pop the list.
 */
   pData = lHead.head->data;
   pNode = lHead.head;
   lHead.head = pNode->next;
   if(--lHead.n_lines == 0)
      lHead.tail = NULL;
   else 
      lHead.head->prev = NULL;
   free((char*)pNode);
   return pData;
}
/************************************************************
 * IDL_RPCOutListAdd()
 * 
 * Purpose:
 * 	This function is used to add one node of data to the list
 */
char * IDL_RPCOutListAdd( char *pData )
{
   RPC_TOUT_NODE *pNode;
   char * pOldData = (char*)NULL;
/*
 * Alloc a new node
 */
   pNode = (RPC_TOUT_NODE*)malloc((unsigned)sizeof(RPC_TOUT_NODE));
   if(!pNode){
      perror("malloc");
      return (char*)NULL;
   }
/*
 * Have we reached the limit of the buffer?
 */
   if(lHead.n_lines == lHead.max_lines)
      pOldData = IDL_RPCOutListDequeue(); /* remove last node */
   pNode->data = pData;
   pNode->next = lHead.head;
   lHead.head = pNode;
   if(lHead.n_lines > 0)
      pNode->next->prev = pNode;
   else 
      lHead.tail = pNode;
   lHead.n_lines++;

   return pOldData; 
}
/*************************************************************
 * IDL_RPCToutFunc()
 * 
 * Purpose:
 * 	This function is used to capture the output from IDL. This 
 * 	function is used via the functions IDL_ToutPush() & IDL_ToutPop().
 */
IDL_TOUT_OUTF IDL_RPCToutFunc( int flags, char *buf, int n)
{

   char              szBuffer[IDL_RPC_MAX_STRLEN];
   IDL_RPC_LINE_S   *pOldData;
   IDL_RPC_LINE_S   *psLine;
   
/*
 * Create a new line struct 
 */
   psLine = (IDL_RPC_LINE_S*)malloc((unsigned)sizeof(IDL_RPC_LINE_S));
   if(!psLine){
      perror("malloc");
      return;
   }
/*
 * Copy over the string. Make sure that the length of the buffer is 
 * not exceeded.
 */
   n = (n < IDL_RPC_MAX_STRLEN-1 ? n : IDL_RPC_MAX_STRLEN-1);
   bcopy(buf, (char*)szBuffer, n);
   szBuffer[n] = '\0';		/* null terminate string */
	 
   psLine->buf = (char*)strdup(szBuffer); /* duplicate the string. */
   psLine->flags = flags;

/*
 * Add the new line to the buffer
 */   
   pOldData = (IDL_RPC_LINE_S*)IDL_RPCOutListAdd((char*)psLine);

   if(pOldData != (IDL_RPC_LINE_S*)NULL){
   /*
    * The line buffer is full so a data element was dequeued
    */
      free(pOldData->buf);
      free((char*)pOldData);
   }
} /* IDL_RPCToutFunc */
/*************************************************************
 * IDL_RPCOutLIstCnt()
 *
 * Purpose:
 * 	Used to get the number of lines currently in the list.
 *
 */
int IDL_RPCOutListCnt(void)
{
   return lHead.n_lines;
}






