# Lightroom Classic Catalogs on Network Attached Storage

## Background
I currently have about 30K photos (1TB) stored on a QNAP TS-251+ NAS
(Network Attached Storage) device with a capacity of 3TB (mirrored).
The NAS is connected by gigabit Ethernet to a custom-built PC and a
mini PC, both running Windows 10.  To make storage management as
simple as possible, the PC and laptop are configured *dataless*:
virtually all files that must be backed up are stored on the NAS,
which runs CrashPlan to back up files nightly to an external hard
drive and off-site to CrashPlan Central servers.  In particular, each
user's `Pictures` folder is located in their home folder on the NAS.
The capacity of the NAS can be easily expanded by replacing the
mirrored drives one-at-a-time with larger drives.  The PCs don't need
much local storage, so they have only two 256GB SSDs, one for system
files and applications and one for temporary files as needed by
Lightroom Classic Photoshop, Affinity Photo, and various other
applications.

## CAUTION!
Lightroom Classic (*LrC*) normally will not access a catalog that
resides on a network drive.  In 2007, Adobe engineer Dan Tull[1][2]
tested LrC catalogs on a corporate network drive by disconnecting the
cable and observed catalog corruption, so Adobe coded LrC to disallow
them on network drives.  Technically, however, network drives are
designed to behave like local drives.  An LrC catalog is an SQLite
database, the integrity of which is maintained via standard Windows
file locking, which is also supported by SMB, the protocol Windows
uses to access files on network drives.  Thus, catalog corruption is
the result of hardware failure or software bugs, not inherent
technical limitations or incompatibilities.  But since more hardware
and software are involved in accessing network-attached storage than
internal or directly-attached external storage, the risk of catalog
corruption is greater.

Also, LrC currently requires that the `Previews.lrdata` folder must
reside in the same folder as the catalog. Thus, when the catalog is on
a network drive, previews will also reside there, slowing performance.

## Basic Setup
1. LrC will create and access catalogs on a network folder
(`\\NAS0\home\Pictures` in this example) by means of a letter drive (`P:` in
this example).  Create a batch file `substP.bat` containing the
following commands:

		:MAP
		subst P: \\NAS0\home\Pictures
		if not exist P:\ (
			ping -n 6 127.0.0.1>nul
			goto MAP
		)

	in the startup folder for each user on each machine running LrC:

		%AppData%\Microsoft\Windows\Start Menu\Programs\Startup

1. Create (or move) catalog(s) to `P:`, e.g. to `P:\Lightroom\Catalogs\My
Photos`

1. When LrC opens a catalog, it creates a `.lrcat.lock` file in the
catalog's folder, which prevents other instances of LrC from accessing
the same catalog at the same time.  However, if LrC crashes or is
running when "Sleep", or "Switch user" is done, the catalog is left
locked and cannot be accessed by other users or machines.  Also, while
LrC has a catalog open, any backup made of the catalog by another
application such as Windows File History, Backup and Restore, Acronis,
Macrium, Carbonite, CrashPlan, Google Drive, One Drive, Dropbox,
etc. is not guaranteed to capture the catalog in a consistent state;
thus, such a backup is not reliably valid.

  * Periodically check the integrity of and back up catalogs with LrC,
    and back up these backups.

  * Disable Windows oplocks on `.lock files` (and FreeFileFileSync, see
    below) by adding the following to `/etc/smb.conf` on the NAS:

		veto oplock files = /*.lock/sync.ffs_db/

  * Install `gracefulexit.bat` (instructions are in that file) and use
    it to put a PC to sleep or to switch users.

## *OPTIONAL:* Synchronize LrC settings across all machines

This is implemented by running LrC via a shortcut which, in turn, runs
a file synchronization utility (FreeFileSync in this case) before and
after running LrC to sync settings from/to a folder on the NAS:

	C:\Windows\System32\cmd.exe /c ""%AppData%\FreeFileSync\Config\lightroom.ffs_batch" && "%ProgramFiles%\Adobe\Adobe Lightroom Classic\Lightroom.exe" & "%AppData%\FreeFileSync\Config\lightroom.ffs_batch""

1. Install [FreeFileSync](https://www.freefilesync.org) (*FFS*).  Create
the folder `%AppData%\FreeFileSync\Config` to store each user's
`.ffs_batch` and `.ffs_real` files, and `%AppData%\FreeFileSync\Logs`
to store each user's *FFS* logs.

1. Create folders on NAS for each user's LrC settings:

		\\<NAS>\home\AppData\Roaming\Adobe\Lightroom

1. Edit `lightroom.ffs_batch` with *FFS* to change `NAS0` to
   the name of your NAS.

1. Copy `lightroom.ffs_batch` and the `lightroom` shortcut to each
   user's `%AppData%\FreeFileSync\Config` folder and pin it to each
   user's task bar and/or Start Menu.

1. For each user, run LrC on the machine on which the latest LrC
settings reside to sync these to the NAS, then open
`lightroom.ffs_batch` with *FFS* on all other machines and manually
sync the LrC settings from the NAS to `%AppData%\Adobe\Lightroom`.

## *OPTIONAL:* Synchronize LrC plug-ins across all machines

To Be Provided

## References

[1] Reply by Dan Tull, Adobe Employee, <https://feedback.photoshop.com/photoshop_family/topics/multi_user_multi_computer?topic-reply-list[settings][filter_by]=all&topic-reply-list[settings][reply_id]=5744549#reply_5744549>

[2] <https://www.lightroomqueen.com/community/threads/catalog-on-nas.30499/page-3#post-1256767>

[3] <https://sqlite.org/lockingv3.html>

