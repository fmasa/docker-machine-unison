# Docker Machine Unison
Syncing files between Windows host and Docker Machine can be pain in the ass.
vboxsf is slow, samba is a bit faster but still slow compared to local filesystem.

With my little shell script you can provision your Docker machine with unison support in seconds.

## Installation

Clone this repository:

    git clone git@github.com:fmasa/docker-machine-unison.git

Add bin subdirectory to your PATH (Unison is there).

Run `./provision.sh` from root directory and voila.
First sync can take several seconds (minutes for huge shared folder), but then thigs are almost instant.
Note that this script must be running all the time to sync files (it's watching changes in your shared folder).

## Configuration
There is `config.conf` in root, where you can fiddle with several options:

- DOCKER_MACHINE – name of the Docker Machine you want to sync your files with
- UNISON_PROFILE_NAME – name of the profile used by unison
- HOST_FOLDER – Folder in Windows to share with the VM
- GUEST_FOLDER – Folder in Docker machine to share with Windows host
- IGNORE – Folders and files to exclude from syncing

*Note: HOST_FOLDER and GUEST_FOLDER should match (i.e. C:/dev --> /c/dev)*