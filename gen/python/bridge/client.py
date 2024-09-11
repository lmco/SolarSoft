
# Zarro (ADNET) - last updated 8/9/17

def run(*arg,**kwargs):
  
# Send IDL string command to Python server running Python-IDL bridge

# Example:
# import client
# client.run('plot,findgen(100)')     plots IDL findgen array
# client.run(filename,1)              upload file to server

    import socket
    import sys
    import os, time, random, json
    import tools

    ip="localhost"
    port=10000
    timeout=60
    RECV_BUFFER = 4096
    verbose=False
    is_function=0

    if not tools.valid_arg(*arg): return None 
	
    twargs=kwargs.copy()
    if 'ip' in kwargs:
        ip=kwargs['ip']
        del twargs['ip']
		
    if 'port' in kwargs:
        port=kwargs['port']
        del twargs['port']
		
    if 'timeout' in kwargs:
        timeout=kwargs['timeout']
        del twargs['timeout']

    if 'verbose' in kwargs:
        verbose=True
        del twargs['verbose']

    if 'is_function' in kwargs:
        is_function=kwargs['is_function']
        del twargs['is_function']
        if is_function: is_function=1

	  	
# if second argument is set to 1, then input string is a filename to upload to server

    cmd=arg[0]
    flag=0 ; slen=0L
    if len(arg) == 2:
        flag=arg[1]
        filename=tools.expand_name(arg[0])
        if flag == 1:
            if not os.path.isfile(filename):
                print("Non-existent file: "+filename)   
                return None
            slen=os.path.getsize(filename)
            if slen == 0:
                print("Zero block length file.")
                return None
             
# Create a TCP/IP socket
# Connect the socket to the port where the server is listening
   
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_address = (ip,port)
    if verbose: print 'Connecting to server: %s on port: %s' % server_address
    try:
        sock.connect(server_address)
    except socket.error as msg:
        print('Error Code : ' + str(msg[0]) + ' Message: ' + msg[1])
        print("Failed to connect to server. Check if server is running on port: "+str(port))
        return None
		
    sock.settimeout(timeout)
    response=None
    data=''
    error=''
    try:
    
# If uploading file, read and send bytes. 

        if flag == 1:
            sfile=os.path.basename(filename)
            tdict={'action':'upload','filename':sfile, 'size':str(slen)} 
            sdict=json.dumps(tdict)
            tools.send_data(sock,sdict)
            with open(filename,'rb') as file:
                sdata=file.read()
                if verbose:
                    print("Client uploading file: "+filename)
                    print "# of bytes: ",slen
                sock.sendall(sdata)

# Send download request 

        elif flag == 2:
            if verbose: print("Downloading file: "+filename)
            tdict={'action':'download','filename':filename}
            sdict=json.dumps(tdict)
            tools.send_data(sock,sdict)

        else:
		
# Send IDL command

            if verbose: print("Executing IDL command: " +cmd)
            tdict={'action':'execute','command':cmd,'is_function':is_function}
            sdict=json.dumps(tdict)
            tools.send_data(sock,sdict)
            edict=json.dumps(twargs)  
            tools.send_data(sock,edict)
           
# Wait for response
 
        tstart=time.time()  
        while 1:		
            data=tools.recv_data(sock)
            elapsed=time.time()-tstart
            if data or (elapsed > timeout) : break

    finally:
        if not data:
            error="Server not responding."
        else:
            tdict=json.loads(data)
            if verbose: 
                print("Server sent response: ")
                print(tdict)

            action=str(tdict['action'])

            if action == 'upload':
                response=str(tdict['filename'])
                error=str(tdict['error'])

            if action == 'download':
                filename=str(tdict['filename'])
                dsize=long(str(tdict['size']))
                error=str(tdict['error'])
                if dsize != 0 : 
                   response,error = tools.rdwrt(sock,filename,dsize,RECV_BUFFER=RECV_BUFFER,**kwargs)

            if action == 'execute':
                response=str(tdict['result'])
                error=str(tdict['error'])
                
                
        if verbose: print("Closing socket.")
        sock.close()
        if verbose and len(error) !=0 : print("Error: "+error)

        return response

################################################################################
   
def upload(file,**kwargs):
    return run(file,1,**kwargs)

################################################################################

def download(file,**kwargs):
    return run(file,2,**kwargs)

################################################################################

# Prep function

def tprep(*arg,**kwargs):
    import tools,os,time
    if not tools.valid_arg(*arg,label='Filename'): return None
    file=arg[0]

# check if threading

    twargs=kwargs.copy()
    thread=False
    if 'thread' in kwargs: 
        thread=kwargs['thread']
        del twargs['thread']

    timeout=100
    if 'timeout' in kwargs: 
        timeout=kwargs['timeout']
        del twargs['timeout']

# check if output directory exists and is writeable

    outdir=os.getcwd()
    if 'outdir' in kwargs: 
        outdir=kwargs['outdir']
        del twargs['outdir']

    outdir=tools.expand_name(outdir)
    vdir=tools.valid_dir(outdir)
    if not vdir[0]:
       print("Output directory does not exist.")
       return None
    if not vdir[1]:
       print("Output directory not writeable.") 
       return None

# determine location of prepped file on server

    tdir=run('result=session_dir("prep",/new)',is_function=True,**twargs)
    if not tdir: return None

# upload file to server if local (ie not URL)

    outfile='prepped_'+os.path.basename(file)
    if tools.valid_url(file):
        URL=True
        location=file
        disp=tools.disp_url(file)
        if type(disp) != str: 
            print("Error accessing URL: "+file)
            return None
        if disp: outfile='prepped_'+disp
    else:
        location=upload(file,**kwargs)
        if not location: return None
        URL=False

# Send prep command to server

    ofile=os.path.join(tdir,outfile)
    prep_cmd='prep_file,'
    if thread: prep_cmd='thread,"prep_file",'
    prep_cmd=prep_cmd+'"'+location+'",out_dir="'+tdir+'",err=err'
    pfile=run(prep_cmd,**twargs)
   
    print("Waiting for results...")
    if thread:
        tstart=time.time()
        while True:
            f=download(ofile,**kwargs)
            elapsed=time.time()-tstart
            if f or elapsed > timeout: break
            time.sleep(3)
            print("Waiting for results...")
    else:
        f=download(ofile,**kwargs)

    if f:
        print("Results downloaded in file: "+f)
    else:
        print("Server timed out.")
    return

###############################################################################

# run prep function in a thread

def prep(*args,**kwargs):

    import threading

# start thread

    t=threading.Thread(target=tprep,args=args,kwargs=kwargs)
    t.start()

    return


