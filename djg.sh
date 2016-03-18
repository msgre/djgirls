#!/bin/bash

source $PWD/config

# basic "shell subcommand structure" via https://gist.github.com/waylan/4080362

PROG_NAME=$(basename $0)


# --- helpers -----------------------------------------------------------------
#
docker_machine(){
    # check state of virtual machine
    # take appropriate action to start it
    docker-machine ls -q --filter name=$DOCKER_MACHINE_NAME | grep ^$DOCKER_MACHINE_NAME\$ > /dev/null
    RC=$?
    if [ $RC -ne 0 ]
    then 
        docker-machine create --driver virtualbox $DOCKER_MACHINE_NAME
    else
        docker-machine ls -q --filter name=$DOCKER_MACHINE_NAME --filter state=running | grep ^$DOCKER_MACHINE_NAME\$ > /dev/null
        RC=$?
        if [ $RC -ne 0 ]
        then 
            docker-machine start $DOCKER_MACHINE_NAME
        fi
    fi

    # evaluate connection to our docker machine 
    eval $(docker-machine env $DOCKER_MACHINE_NAME)
}

containers_cleanup(){
    docker rm -f $DOCKER_INSTANCE_NAME 2> /dev/null
}

sub_help(){
    echo "Usage: ${PROG_NAME} <subcommand> [options]"
    echo "Subcommands:"
    echo "    build    ..."
    echo "    init     ..."
    echo "    shell    ..."
    echo "    local    ..."
    echo "    manage   ..."
    echo "    deploy   ..."
    echo ""
}


# --- build subcommand --------------------------------------------------------
#
sub_build(){
    docker_machine
    containers_cleanup

    # evaluate requirements file presence
    # NOTE: if there is existing requirements.txt file in source code directory,
    # it will be dynamically distributed into docker image build
    # if file doesn't exis
    if [ -e $REQUIREMENTS_FILE ]
    then
        REQUIREMENTS=`cat $REQUIREMENTS_FILE | tr '\n' ' '`
    fi

    # build
    if [ -z "$REQUIREMENTS" ]; then
        docker build -t $DOCKER_IMAGE .
    else
        docker build -t $DOCKER_IMAGE --build-arg REQUIREMENTS="$REQUIREMENTS" .
    fi  
}
  

# --- local subcommand --------------------------------------------------------
#
sub_local(){
    docker_machine
    containers_cleanup

    # get IP address of machine
    IP=`docker-machine ip $DOCKER_MACHINE_NAME`

    # evaluate connection to our docker machine 
    eval $(docker-machine env $DOCKER_MACHINE_NAME)

    # migrate and run!
    docker run --rm -ti --name $DOCKER_INSTANCE_NAME -v $PWD/$SHARED_FOLDER:/$SHARED_FOLDER -p $PORT:8000 $DOCKER_IMAGE migrate
    printf "===================\nPut this address into your web browser please: \033[0;32mhttp://${IP}:${PORT}\033[0m\n===================\n"
    docker run --rm -ti --name $DOCKER_INSTANCE_NAME -v $PWD/$SHARED_FOLDER:/$SHARED_FOLDER -p $PORT:8000 $DOCKER_IMAGE runserver 0.0.0.0:$PORT
}


# --- manage subcommand -------------------------------------------------------
#
sub_manage(){
    docker_machine

    # migrate and run!
    docker run --rm -ti -v $PWD/$SHARED_FOLDER:/$SHARED_FOLDER $DOCKER_IMAGE $@
}


# --- shell subcommand --------------------------------------------------------
#
sub_shell(){
    docker_machine

    # migrate and run!
    docker run --rm -ti -v $PWD/$SHARED_FOLDER:/$SHARED_FOLDER $DOCKER_IMAGE shell
}


# --- init subcommand ---------------------------------------------------------
#
sub_init(){
    docker_machine

    # migrate and run!
    docker run --rm -ti -v $PWD/$SHARED_FOLDER:/$SHARED_FOLDER --entrypoint django-admin.py $DOCKER_IMAGE startproject $1 /$SHARED_FOLDER
}


# --- deploy subcommand -------------------------------------------------------
#
sub_deploy(){
    docker_machine

    echo "TBD"
}



SUBCOMMAND=$1
case $SUBCOMMAND in
    "" | "-h" | "--help")
        sub_help
        ;;
    *)
        shift
        sub_${SUBCOMMAND} $@
        if [ $? = 127 ]; then
            echo "Error: '${SUBCOMMAND}' is not a known subcommand." >&2
            echo "       Run '${PROG_NAME} --help' for a list of known subcommands." >&2
            exit 1
        fi
        ;;
esac
