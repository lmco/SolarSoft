# Zarro (ADNET) - last updated 8/9/17

# run RHESSI event list test

def tevent_list(*args,**kwargs):

    import client,os,tools,time

    thread=False
    if 'thread' in kwargs: thread=kwargs['thread']
    timeout=100
    if 'timeout' in kwargs: timeout=kwargs['timeout']

# determine where to download file on client

    lfile='test.fits'
    if len(args) == 1: lfile=args[0]
    lfile=tools.expand_name(lfile)
    ldir=os.path.dirname(lfile)
    if not ldir: ldir=os.getcwd()
    if not os.access(ldir,os.W_OK):
        print("No write access to: "+ldir)
        return None
	
# check if program is registered

    rfile='rhessi_event_list'
    cmd='result=pyidl_path("'+rfile+'",err=err)'
    rdir=client.run(cmd)
    if not rdir:
        print("Unregistered program: "+rfile)
        return None
    
# determine temp directory on server where to save result

    tdir=client.run('result=session_dir()')
    if not tdir: return None
   
# run program in registered directory

    lname=os.path.basename(lfile)
    tfile=os.path.join(tdir,lname)
    cmd='cd,'+'"'+rdir+'"'
    client.run(cmd)
    cmd=rfile+','+'"'+tfile+'"'
    if thread: cmd=cmd+',/thread'
    client.run(cmd,**kwargs)

# download output file

    print("Waiting for results...")
    if thread:
        tstart=time.time()
        while True:    
            f=client.download(tfile,**kwargs)
            elapsed=time.time()-tstart
            if f or elapsed > timeout: break
            time.sleep(3)
            print("Waiting for results...")
    else:
        f=client.download(tfile,**kwargs)
    
    if f: 
        print("Results downloaded in file: "+f)
    else:
        print("Server timed out.")
    return



###############################################################################

# run event list function in a thread

def event_list(*args,**kwargs):

    import threading
    
# start thread 

    t=threading.Thread(target=tevent_list,args=args,kwargs=kwargs)
    t.start()

    return
