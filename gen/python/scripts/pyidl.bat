
rem Windows bat file to start Python with IDL bridge
rem Zarro (ADNET) 5-27-2017

set PYTHONPATH=%IDL_DIR%\bin\bin.x86_64;%IDL_DIR%\lib\bridges;%SSW%\gen\python\bridge
rem set PYTHONSTARTUP=%SSW%\gen\python\startup.py

python -B


