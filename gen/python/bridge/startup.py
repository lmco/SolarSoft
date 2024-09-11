
# PYTHON start-up file. Define PYTHONSTARTUP to point to this file

print("Running Python-IDL bridge startup...")
try:
    import bridge
    IDL=bridge.startup()
except:
    from idlpy import * 
