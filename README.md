# Lightroom Catalogs on Network Attached Storage

## Background
I currently have about 25K photos (800GB) stored on a QNAP TS-251+ NAS
(Network Attached Storage) device with a capacity of 3TB (mirrored).
The NAS is connected by gigabit Ethernet to a custom-built PC and a
mini PC, both running Windows 10.  To make storage management as
simple as possible, the PC and laptop are configured "dataless":
virtually all files that must be backed up are stored on the NAS,
which runs CrashPlan to back up files nightly to an external hard
drive and off-site to CrashPlan Central servers.  The capacity of the
NAS can be easily expanded by replacing the mirrored drives
one-at-a-time with larger drives.  The PCs don't need much local
storage, so they have only two 256GB SSDs, one for system files and
applications and one for temporary files as needed by LR6, CS6, and
various other applications.

## Basic Setup
1. Map the network drive folder where the catalog is stored on an
available drive ('P:' in this example).  Be sure to check "Reconnect at
logon", and if the network drive is a NAS, also check "Connect using
different credentials".

1. To enable Lightroom to create and access catalogs on the 'Q:' drive,
create a batch file substQ.bat containing the following command:

'subst Q: P:\'

either in the startup folder for each USER on each machine running
Lightroom:

'C:\Users\USER\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'

or, if all users on a machine will be accessing catalogs on 'P:', in the
folder:

'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp'

1. Create (or move) catalog(s) to 'Q:', e.g. to 'Q:\Lightroom\Catalogs\My
Photos'

1.When LR opens a catalog, it creates a '.lrcat.lock' file in the
catalog's folder, which prevents other instances of LR from accessing
the same catalog at the same time.  However, if LR crashes or is
running when "Sleep", or "Switch user" is done, the catalog is left
locked and cannot be accessed by other users or machines.  Also, while
LR has a catalog open, any backup made of the catalog by another
application such as Windows File History, Backup and Restore, Acronis,
Macrium, Carbonite, CrashPlan, etc. is not guaranteed to capture the
catalog in a consistent state; thus, the backup is not reliably valid.

  * Periodically check the integrity of and backup catalogs with LR,
    and back up these backups.

  * Disable Windows oplocks on '.lock files' by adding the following
    to /etc/smb.conf:

    'veto oplock files = /*.lock/sync.ffs_db/'

  * Install gracefulexit.bat and use it to put a PC to sleep or to switch users.

## *OPTIONAL:* Synchronize LR settings across all machines

## *OPTIONAL:* Synchronize LR plug-ins across all machines

