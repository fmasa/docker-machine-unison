#!/usr/bin/env bash

set -x -e;

DOCKER_MACHINE=${DOCKER_MACHINE_NAME:-default}
INSTALLATION_FOLDER=$(pwd)

loadConfig() {
    CONGFIGS="$(sed -e 's/:[^:\/\/]/="/g;s/$/"/g;s/ *=/=/g' config.conf)"
    eval $(sed -e 's/:[^:\/\/]/="/g;s/$/"/g;s/ *=/=/g' config.conf)
}

selectDockerMachine() {
    export DOCKER_MACHINE_IP="$(docker-machine ip $DOCKER_MACHINE)"
}

executeCommand() {
    docker-machine ssh $1 $2
}

removeVirtualboxSharedFolders () {
    echo "($1) Checking whether /c/Users (vboxsf) is mounted ...";
    if [[ $(executeCommand $1 mount | grep c/Users) ]]; then
        echo "($1) Removing /c/Users"
        executeCommand $1 "sudo umount //c/Users"
    fi
}

createDirectory () {
    echo "($1) Creating $2 ..."
    local command="
        [ -d $2 ] || {
            sudo mkdir -p $2;
            sudo chown docker $2;
        }
    "
    executeCommand $1 "$command"
}

checkAndInstallUnison () {
    echo "($1) Checking whether unison is installed ..."

    if [[ $(executeCommand $1 "unison -version" | grep "unison version 2.48.3") ]]; then
        echo "($1) unison 2.48.3 found."
    else
        echo "($1) Installing unison ..."
        executeCommand $1 "cd // &&
            sudo curl -sL https://www.archlinux.org/packages/extra/x86_64/unison/download | sudo tar Jx;"
    fi
}

setUpUnison() {

    echo "Setting up unison ..."

    # create ssh-config file
    ssh_config="
Host $DOCKER_MACHINE_IP
    User docker
    IdentityFile ~/.docker/machine/machines/$DOCKER_MACHINE/id_rsa
"

    [ -d .docker-unison ] || mkdir .docker-unison

    ssh_config_file="$(pwd)/.docker-unison/ssh-config"

    [ -f $ssh_config_file ] || echo "$ssh_config" > $ssh_config_file


    if [ -z ${USERPROFILE+x} ]; then
      UNISONDIR=$HOME
    else
      UNISONDIR=$USERPROFILE
    fi

    cd $UNISONDIR
    [ -d .unison ] || mkdir .unison

    if [ ! -f ".unison/$UNISON_PROFILE_NAME.prf" ]; then

        echo "Creating unison profile ..."

        if [ -z ${UNISON_FASTCHECK+x} ]; then
            UNISON_FASTCHECK='false' # Fastcheck is disabled by default
        fi


        profile="
root = $HOST_FOLDER
root = ssh://$DOCKER_MACHINE_IP/$GUEST_FOLDER
ignore = Name $IGNORE
follow = Regex .*

prefer = $HOST_FOLDER
repeat = 2
terse = true
dontchmod = true
perms = 0
fastcheck = $UNISON_FASTCHECK
sshargs = -F $ssh_config_file
"
        echo "$profile" > ".unison/$UNISON_PROFILE_NAME.prf"
    fi

    echo "Done!"
}


startUnison () {
    "$INSTALLATION_FOLDER/bin/unison" $UNISON_PROFILE_NAME
}

loadConfig
selectDockerMachine


removeVirtualboxSharedFolders $DOCKER_MACHINE
createDirectory $DOCKER_MACHINE $GUEST_FOLDER
checkAndInstallUnison $DOCKER_MACHINE
setUpUnison
"$INSTALLATION_FOLDER/bin/unison" $UNISON_PROFILE_NAME
