			    CALL_EXTERNAL routines
			    ======================

This directory contains C software to support IDL routines using CALL_EXTERNAL.
The IDL procedure files themselves are in other directories within the CDS
software tree.

There are makefiles in this directory for various operating systems, as well as
a MAKE.COM file and option files for VMS (not recently tested).  For example,
under OSF one would type

	make -f Makefile.osf

Currently supported operating systems are Linux, OSF, VMS, and SunOS.  Other
operating systems would require additional makefiles or equivalents.
CALL_EXTERNAL is not supported under Ultrix.

In order to use this software, the environment variable (VMS: logical name)
CDS_EXTERNAL must be defined to point to the file created when the software is
compiled.  Generally, in Unix this is a file called "external.so" (although
some versions of Unix act differently).  In VMS it is EXTERNAL.EXE.

The CDS IDL procedure files are written so as to use CALL_EXTERNAL only when
the enviroment variable CDS_EXTERNAL is defined, and to use some other
procedure (or return an error) when it is not defined.

Currently, the only routine supported are rearrange.pro and fmedian.pro,
although other routines may be added in the future.

The "fortran" subdirectory contains an earlier version, in which FMEDIAN was
implemented through FORTRAN rather than C.
