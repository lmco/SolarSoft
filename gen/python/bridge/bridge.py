# Zarro (ADNET) - last updated 8/15/17   

# Loads SSW path and environment variable for access by IDL-Python bridge

# Usage: 
# >>> import bridge
# >>> bridge.startup()
# >>> IDL=bridge.startup()

# Example:
# >>> IDL.run('a=findgen(10)')
# >>> IDL.run('plot,a')
# >>> a=IDL.a
# >>> a
# array([ 0.,  1.,  2.,  3.,  4.,  5.,  6.,  7.,  8.,  9.], dtype=float32)

def startup():
   
   print("Loading Python-IDL bridge...")
   import os
   cur_dir=os.getcwd()
   
# check that required environmentals are defined  
  
   try:
     idl_dir=os.environ['IDL_DIR']
   except:
     print('$IDL_DIR is undefined.')
     return

   try:
     ssw=os.environ['SSW']
   except:
     print('$SSW is undefined. Defaulting to vanilla IDL.')
     ssw=None
     pass
     
# save personal IDL startup (to run later)
   
   try:
     pers_start=os.environ['IDL_STARTUP']
     os.environ['IDL_STARTUP']=''
   except:
     pers_start=''
     pass

# switch to IDL bridge directory and import IDL-Python bridge object

   bridge_dir=os.path.join(idl_dir,'lib','bridges')
   cur_dir=os.getcwd()
   os.chdir(bridge_dir)
   from idlpy import IDL
   
# load preferred instruments

   if ssw:				
    try:
      ssw_instr=os.environ['SSW_INSTR']
      IDL.ssw_instr=ssw_instr
      print('Loading: '+ssw_instr)
      IDL.run("setenv,'SSW_INSTR='+ssw_instr")
    except:
      print('SSW_INSTR is undefined. Defaulting to GEN.')
      pass

    startup_dir=os.path.join(ssw,'gen','idl','ssw_system')
    os.chdir(startup_dir)
    IDL.run("!quiet=1")
    IDL.run("ssw_load")
    IDL.run("a=is_pyidl(/set)")
   
 # now load personal startup
   
   if os.path.isfile(pers_start):
     IDL.pers_start=pers_start
     os.environ['IDL_STARTUP']=pers_start
     print('Executing personal IDL_STARTUP: '+pers_start)
     IDL.run('@'+pers_start)

   IDL.run("!quiet=0")   
   os.chdir(cur_dir)
   return IDL

  
