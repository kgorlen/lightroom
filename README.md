# Lightroom Classic Catalogs on Network Attached Storage

## Background
I currently have about 30K photos (>1TB) stored on a QNAP TS-251+ NAS
(Network Attached Storage) device with a capacity of 3TB (mirrored).
The NAS is connected by gigabit Ethernet to a custom-built PC and a
mini PC, both running Windows 10.  To make storage management as
simple as possible, the PC and laptop are configured *dataless*:
virtually all files that must be backed up are stored on the NAS[1],
which runs [CrashPlan](https://www.crashplan.com/)[2][3] to back up
files nightly to an external hard drive and off-site to CrashPlan
Central servers.  In particular, each user's `Pictures` folder is
located in their home folder on the NAS.  The capacity of the NAS can
be easily expanded by replacing the mirrored drives one-at-a-time with
larger drives.  The PCs don't need much local storage, so they have
only two 256GB SSDs, one for system files and applications and one for
temporary files as needed by Photoshop and other applications.

I've been accessing the same Lightroom Classic (*LrC*) catalog on a
NAS since 2011, except for a few months in 2016 after replacing a
Netgear ReadyNAS with the QNAP TS-251+, which had a defective SMB
implementation that caused *LrC* and other failures.  During this
period I modified the `lightroom.ffs_batch` file described below to
copy the catalog in addition to the settings to/from an internal SSD.

Note: I recommend neither QNAP (unreliable, poorly documented
software) or CrashPlan (deteriorating service).  I've just not found
clearly better, economical alternatives.

## CAUTION!
Lightroom Classic (*LrC*) normally will not access a catalog that
resides on a network drive.  In 2007, Adobe engineer Dan Tull[4][5]
tested *LrC* catalogs on a corporate network drive by disconnecting
the cable and observed catalog corruption, so Adobe coded *LrC* to
disallow them on network drives.  Technically, however, network drives
are designed to behave like local drives.  An *LrC* catalog is an
SQLite[6] database, the integrity of which is maintained via standard
Windows file operations, which are also supported by SMB[7], the
protocol Windows uses to access files on network drives.  Thus,
catalog corruption is the result of hardware failure or software
defects, not inherent technical limitations or
incompatibilities.[8][9] But since more hardware and software is
involved in accessing network-attached storage than internal or
directly-attached external storage, the risk of catalog corruption is
greater.  However, there is also risk in other methods proposed[10] for
using a catalog from multiple machines, such as inadvertently
disconnecting an external hard drive while Lightroom is running or
while synchronizing with Dropbox, Google Drive, One Drive, etc.

Also, *LrC* currently requires that the `Previews.lrdata` folder must
reside in the same folder as the catalog. Thus, when the catalog is on
a network drive, previews will also reside there, possibly slowing
performance.

Setting up the NAS:

  * with an uninterruptible power supply (UPS), to protect against
	power failures,
	
  * with RAID, to protect against single-drive failures, and
  
  * as an "always up" device automatically running nightly backups,
	when *LrC* catalogs are less likely to be in use,
	
provides protections not typically provided on desktop PCs that offset
the added risk of storing and accessing catalogs on the NAS.

## Basic Setup
*LrC* will create and access catalogs on a network folder
(`\\NAS0\home\Pictures\Lightroom` in this example) by means of a
letter drive (`L:` in this example).

1. Install the `catmap.bat` script according to the instructions in
that file.

1. The letter drive must be mapped when a user logs in.  Copy the
sample `Startup\catmap.bat` shortcut to the startup folder for each
user on each machine running *LrC*:

		%AppData%\Microsoft\Windows\Start Menu\Programs\Startup

	and if necessary, edit the shortcut `Target` property to use a
	different letter drive and network folder.
	
	Be sure to use the same letter drive and network folder for a
	given user on all PCs if synchronizing *LrC* settings across PCs as
	described below.

1. Create (or move) catalog folder(s) to `L:`, e.g. to `L:\Catalogs\My
   Photos`

When *LrC* opens a catalog, it creates a `.lrcat.lock` file in the
catalog's folder, which prevents other instances of *LrC* from accessing
the same catalog at the same time.  However, if *LrC* crashes or is
running when "Sleep", or "Switch user" is done, the catalog is left
locked and cannot be accessed by other users or machines.  Also, while
*LrC* has a catalog open, any copy made of the catalog by another
application such as Windows File History, Backup and Restore, Acronis,
Macrium, Carbonite, CrashPlan, Google Drive, One Drive, Dropbox,
etc. is not guaranteed to capture the catalog in a consistent state;
thus, such a backup is not reliably valid.

  * Periodically check the integrity of and back up catalogs with *LrC*,
    and back up these backups.

  * Install `gracefulexit.bat` (instructions are in that file) and use
    it to put a PC to sleep, switch user, and logoff.

  * *OPTIONAL:* Files can remain locked when applications exit
	abnormally or PCs crash.  To reduce occurrences of this problem,
	disable Windows oplocks on `.lock files` (and FreeFileFileSync
	`sync.ffs_db` databases, see below) by adding the following to
	`/etc/smb.conf` on the NAS:

		veto oplock files = /*.lock/sync.ffs_db/

## *OPTIONAL:* Synchronize *LrC* settings across all PCs

*LrC* changes settings files frequently when running, so synchronization
is implemented by running *LrC* via a shortcut which, in turn, runs
a file synchronization utility (FreeFileSync in this case) before and
after running *LrC* to sync settings from/to a folder on the NAS:

	C:\Windows\System32\cmd.exe /c ""%AppData%\FreeFileSync\Config\lightroom.ffs_batch" && "%ProgramFiles%\Adobe\Adobe Lightroom Classic\Lightroom.exe" & "%AppData%\FreeFileSync\Config\lightroom.ffs_batch""

1. Install [FreeFileSync](https://www.freefilesync.org) (*FFS*).

1. Create `%AppData%\FreeFileSync\Config` folders to store each
   user's `lightroom.ffs_batch` file.
   
1. Create `%AppData%\FreeFileSync\Logs` folders to store each user's
   *FFS* logs.

1. Create folders on the NAS for each user's *LrC* settings, e.g.:

		\\<my NAS>\home\AppData\Roaming\Adobe\Lightroom

1. Edit `lightroom.ffs_batch` with *FFS* to change `NAS0` to
   the name of your NAS.

1. For each user, run *LrC* on the machine on which the latest *LrC*
   settings reside to sync these to the NAS, then open
   `lightroom.ffs_batch` with *FFS* on all other machines and manually
   sync the *LrC* settings from the NAS to `%AppData%\Adobe\Lightroom`.

1. Pin the `lightroom` shortcut to each user's Start Menu and/or
   taskbar (<https://www.digitalcitizen.life/how-pin-special-windows-shortcuts-taskbar>).

## *OPTIONAL:* Synchronize *LrC* plug-ins across all PCs

*LrC* plug-ins are synchronized when updated by a file synchronization
utility (FreeFileSync in this case).  For each machine:

1. Install [FreeFileSync](https://www.freefilesync.org) (*FFS*).

1. Create the `%CommonProgramFiles%\FreeFileSync\Config` folder to
   store the `Realtime.ffs_batch` and `Realtime.ffs_real` files.

1. Create the `%CommonProgramFiles%\FreeFileSync\Log` folder to store
   *FFS* logs.

1. Create a folder on the NAS to store the *FFS*
   `Realtime.ffs_batch` and `Realtime.ffs_real` files, e.g.:

		\\<my NAS>\<my path>\FreeFileSync\Common Files\Config

1. Create a folder on the NAS to store *LrC* plug-ins, e.g.:

		\\<my NAS>\<my path>\Lightroom\LR Plugins

1. Assure that a user account e.g. `myaccount`, has RW permission
   on:
   
	* `%CommonProgramFiles%\LR Plugins` and subfolders

	* `%CommonProgramFiles%\FreeFileSync` and subfolders

	* `\\<my NAS>\<my path>\Lightroom\LR Plugins` and subfolders
   
	* `\\<my NAS>\<my path>\FreeFileSync\Common Files\Config` and subfolders

1. Edit `%CommonProgramFiles%\FreeFileSync\Config\Realtime.ffs_batch` with
   *FFS* to change the path names to match those of your NAS folders.
   A folder pair to synchronize `%Public%\Pictures\Screen Saver Photos`
   is included; remove if not wanted.

1. Open `Realtime.ffs_batch` with *FFS* on the machine on which the
   latest *LrC* plug-ins reside, sync these to the NAS, then open
   `Realtime.ffs_batch` with *FFS* on all other machines and manually
   sync the *LrC* plug-ins from the NAS to `%ProgramFiles%\Common
   Files\LR Plugins`.
   
1. Create the `Realtime.ffs_real` file (see <https://freefilesync.org/manual.php?topic=realtimesync>):

	* run `"C:\Program Files\FreeFileSync\RealTimeSync.exe"`
	
	* File -> Open `%CommonProgramFiles%\FreeFileSync\Config\Realtime.ffs_batch`
	
	* File -> Save as `Realtime.ffs_real`

1. [Create a Task Scheduler task](https://www.sevenforums.com/tutorials/67503-task-create-run-program-startup-log.html) to
   run RealTimeSync at system startup:

	* Run under a user account (e.g. `myaccount`) that has read and write
      permission on all synced folders

	* Run whether user is logged on or not
	
	* Trigger: At startup
	
	* Action: Start a program `"%ProgramFiles%\FreeFileSync\RealTimeSync.exe"`
	
	* Add arguments: `"%CommonProgramFiles%\FreeFileSync\Config\Realtime.ffs_real"`

	* Settings: Do not start a new instance

1. Restart, then check the `%CommonProgramFiles%\FreeFileSync\Log` folder to confirm that folders
are synchronizing.

## *OPTIONAL:* Synchronize Photoshop settings across all machines

Photoshop, Bridge, CameraRaw, Color, and Plugins settings are
synchronized when updated by a file synchronization utility
(FreeFileSync in this case), and also by `gracefulexit.bat`
on sleep, switch user, and logoff.

1. Create folders on the NAS for each user's Photoshop settings, e.g.:

		\\<my NAS>\home\AppData\Roaming\Adobe\Photoshop*
		\\<my NAS>\home\AppData\Roaming\Adobe\Bridge*
		\\<my NAS>\home\AppData\Roaming\Adobe\CameraRaw
		\\<my NAS>\home\AppData\Roaming\Adobe\Color
		\\<my NAS>\home\AppData\Roaming\Adobe\Plugins
		
	The exact names of the Photoshop and Bridge folders depend upon
	the versions installed, e.g. `Photoshop 2020` and `Bridge 2020`.

1. Copy the following files to each user's `%AppData%\FreeFileSync\Config` folder:

		full.ffs_batch
		watched.ffs_batch

1. Edit these files to change NAS0 to the name of your NAS and
Photoshop and Bridge folders to match the versions installed.  Folder
pairs for the `Affinity` settings, `Desktop`, and `Favorites` are
included; remove if not wanted.

1. For each user, open `full.ffs_batch` with *FFS* on the machine on which the
   latest Photshop settings reside, sync these to the NAS, then open
   `full.ffs_batch` with *FFS* on all other machines and manually
   sync the setting from the NAS to the local machine.
   
1. Create the `watched.ffs_real` file (see <https://freefilesync.org/manual.php?topic=realtimesync>):

	* run `"C:\Program Files\FreeFileSync\RealTimeSync.exe"`
	
	* File -> Open `%AppData%\FreeFileSync\Config\watched.ffs_batch`
	
	* File -> Save as `%AppData%\FreeFileSync\Config\watched.ffs_real`

1. Copy the `RealTimeSync` shortcut to each user's Startup folder:

		%AppData%\Microsoft\Windows\Start Menu\Programs\Startup

1. Login as each user and check the `%AppData%\FreeFileSync\Logs`
folder to confirm that folders are synchronizing.

## References

[1] *How to Change the Location of User Folders in Windows 10*, <https://www.dummies.com/computers/operating-systems/windows-10/how-to-change-the-location-of-user-folders-in-windows-10/>

[2] *CrashPlan Photographer's Backup Guide*, <https://support.code42.com/CrashPlan/6/Backup/Photographers_backup_guide>

[3] *Running CrashPlan in an Ubuntu VM*, <https://forum.qnap.com/viewtopic.php?t=117951>

[4] Reply by Dan Tull, Adobe Employee, <https://feedback.photoshop.com/photoshop_family/topics/multi_user_multi_computer?topic-reply-list[settings][filter_by]=all&topic-reply-list[settings][reply_id]=5744549#reply_5744549>

[5] Post by johnrellis, <https://community.adobe.com/t5/lightroom-classic/operating-lightroom-cc-classic-via-network-drive/m-p/9997623?page=1#M115849>

[6] *Write-Ahead Logging*, <https://sqlite.org/wal.html>

[7] *Samba Locks and Oplocks*, <https://www.oreilly.com/openbook/samba/book/ch05_05.html>

[8] *Client/Server Applications*, <https://www.sqlite.org/whentouse.html>

[9] *More information*, <https://helpx.adobe.com/lightroom-classic/kb/lightroom-error-catalog-cannot-be-opened-lrcat-lock.html>

[10] *Sharing Lightroom Catalog with Multiple Computers*, <https://photographylife.com/sharing-lightroom-catalog-with-multiple-computers>

