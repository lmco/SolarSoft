# Zarro (ADNET) - last updated 8/9/17
# Start Python server to execute IDL commands via Python-IDL bridge
# Example:

# >>> import server
# >>> server.start()


def start(thread=True,**kwargs):

# Start Python-IDL bridge server in thread mode 

    import threading
  
    if thread:
        try:
            t=threading.Thread(target=startup,kwargs=kwargs)
            t.start()
        except:
            print("Failed to start Python thread server.")
            return None
    else:
        startup(**kwargs)

#######################################################################

def startup(**kwargs):
  
    import socket,select,tempfile,os,sys,json
    import tools,config,bridge
    if sys.platform != 'win32': 
        base=os.nice(1)-1
        new=os.nice(base+9)

# Create a TCP/IP socket

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    ip=""
    if 'ip' in kwargs: ip=kwargs['ip']
    port=10000
    if 'port' in kwargs: port=kwargs['port']
    config.stop_server=False

# Bind the socket to the port

    server_address = (ip,port)
    try:
        server_socket.bind(server_address)
    except socket.error as msg:
        print('Bind failed. Error Code : ' + str(msg[0]) + ' Message ' + msg[1])
        print('Could not start server. Check if already running on port: '+str(port))
        return None

# Listen for incoming connections

    IDL=bridge.startup()
    print('Starting Python-IDL server on %s port %s' % server_address)
    server_socket.listen(10)
    CONNECTION_LIST = []             # list of socket clients
    RECV_BUFFER = 4096      
    CONNECTION_LIST.append(server_socket)

    while 1:
        if config.stop_server and config.port == port:
          #  server_socket.shutdown(socket.SHUT_RDWR)
            server_socket.close()
            config.stop_server=False
            print("Stopping server on port: "+str(port))
            IDL.run(".reset")
            return
      
# Wait for a connection

        read_sockets,write_sockets,error_sockets = select.select(CONNECTION_LIST,[],[])
        
        for sock in read_sockets:
            if sock == server_socket:
                sockfd, addr = server_socket.accept()
                CONNECTION_LIST.append(sockfd)
                print "Client (%s, %s) connected:" % addr
            else:	
                try:
                    data=tools.recv_data(sock)
                    if data: 
                        if type(data) == str: 
                            print(data)
                            tdict=json.loads(data)
                            if 'action' in tdict:
                                action=str(tdict['action'])

# Save uploaded file to temporary directory
                           
                                if action == 'upload':
                                    filename=os.path.basename(str(tdict['filename']))
                                    filename=tools.expand_name(filename)
                                    dsize=long(str(tdict['size'])) 
                                    outdir=tools.get_temp_dir()
                                    result,error = tools.rdwrt(sock,filename,dsize,outdir=outdir,RECV_BUFFER=RECV_BUFFER)
                                    tdict={'action':'upload','filename':result,'error':error}
                                    sdict=json.dumps(tdict)
                                    tools.send_data(sock,sdict)

# Send file to client

                                elif action == 'download':
                                    filename=str(tdict['filename'])
                                    filename=tools.expand_name(filename)
                                    if os.path.isfile(filename):
                                        dsize=os.path.getsize(filename)
                                        tdict={'action':'download','filename':filename,'size':dsize,'error':''}
                                        sdict=json.dumps(tdict)
                                        tools.send_data(sock,sdict)
                                        with open(filename,'rb') as file:
                                            sdata=file.read()
                                            print("Server sending file: "+filename)
                                            print "# of bytes: ",str(dsize)
                                            sock.sendall(sdata)
                                    else:
                                        tdict={'action':'download','filename':filename,'size':0L,'error':'File not found.'}
                                        sdict=json.dumps(tdict)
                                        tools.send_data(sock,sdict)     
# Execute IDL command  
                           
                                elif action == 'execute':							
                                    cmd=str(tdict['command'])
                                    is_function=str(tdict['is_function'])
                                    result=''
                                    error=''		
                                    edata=tools.recv_data(sock)
                                    edict=json.loads(edata)    
                                    IDL.run('retall ; message,/reset ; catch,/cancel')
                                    IDL.result=result
                                    IDL.err=error
                                    IDL.extra_keywords=''
                                    try:
                                        if edict: 
                                            IDL.extra_keywords=edict
                                            IDL.run("extra=hash2struct(extra_keywords)",stdout=True)
                                            IDL.run("help,extra",stdout=True)
                                            if is_function == "1":
                                                cmd=cmd.replace( ')' , ',_extra=extra)' )
                                            else:
                                                cmd=cmd+',_extra=extra'
                                        print("Executing: "+cmd)
                                        IDL.run(cmd,stdout=True)           
                                    except IDLError as e:
                                        print('Caught IDL error: ' + str(e))
                                        error=str(e)
                                    else:
                                        if type(IDL.result) == str: result=IDL.result
                                        if type(IDL.err) == str: error=IDL.err
                                    tdict={'action':'execute','result':result,'error':error}
                                    sdict=json.dumps(tdict)
                                    tools.send_data(sock,sdict)

                                else: print("No client action specified.")
                            else: print("Unsupported client action.")
                        else: print("Unrecognized client data input.")
                    
                except Exception as e: 
                    print e
                    print "Unexpected error:", sys.exc_info()[0]
                    print "Client (%s, %s) disconnected:" % addr
                    sock.close()
                    CONNECTION_LIST.remove(sock)
                    continue
         
    server_socket.close()

##################################################################################################
# stop Python-IDL server

def stop(port=10000):
    import config
    config.stop_server=True
    config.port=port

##################################################################################################
	
if __name__ == "__main__":
    start(thread=0)
	    
			
