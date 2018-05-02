#!/bin/bash
set -e -o pipefail

help() {
    echo
    echo 'Usage ./setup.sh ~/path/to/TRITON_PRIVATE_KEY'
    echo
    echo 'Checks that your Triton environment is sane and configures'
    echo 'an environment file to use.'
    echo
    echo 'TRITON_PRIVATE_KEY is the filesystem path to an SSH private key'
    echo 'used to connect to Triton.'
    echo
}

# Check for correct configuration
check() {

    if [ -z "$1" ]; then
        tput rev  # reverse
        tput bold # bold
        echo 'Please provide a path to a SSH private key to access Triton.'
        tput sgr0 # clear

        help
        exit 1
    fi

    if [ ! -f "$1" ]; then
        tput rev  # reverse
        tput bold # bold
        echo 'SSH private key for Triton is unreadable.'
        tput sgr0 # clear

        help
        exit 1
    fi

    # Assign args to named vars
    TRITON_PRIVATE_KEY_PATH=$1

    command -v triton >/dev/null 2>&1 || {
        echo
        tput rev  # reverse
        tput bold # bold
        echo 'Error! Joyent Triton CLI is required, but does not appear to be installed.'
        tput sgr0 # clear
        echo 'See https://www.joyent.com/blog/introducing-the-triton-command-line-tool'
        exit 1
    }

    TRITON_USER=$(triton profile get | awk -F": " '/account:/{print $2}')
    TRITON_DC=$(triton profile get | awk -F"/" '/url:/{print $3}' | awk -F'.' '{print $1}')
    TRITON_ACCOUNT=$(triton account get | awk -F": " '/id:/{print $2}')
    TRITON_DOMAIN=$(triton profile get | awk -F"/" '/url:/{print $3}' | awk -F'api.' '{print $2}')

    SDC_URL=$(triton env | grep SDC_URL | awk -F"=" '{print $2}' | awk -F"\"" '{print $2}')
    SDC_ACCOUNT=$(triton env | grep SDC_ACCOUNT | awk -F"=" '{print $2}' | awk -F"\"" '{print $2}')
    SDC_KEY_ID=$(triton env | grep SDC_KEY_ID | awk -F"=" '{print $2}' | awk -F"\"" '{print $2}')

    TRITON_CREDS_PATH=/root/.triton

    echo '# Site URL' > .env
    echo BASE_URL=https://webconsole-tsg.svc.${TRITON_ACCOUNT}.${TRITON_DC}.triton.zone >> .env
    echo COOKIE_DOMAIN=triton.zone >> .env
    echo >> .env

    echo PORT=8081 >> .env
    echo 'COOKIE_PASSWORD='$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 36) >> .env
    echo COOKIE_SECURE=1 >> .env
    echo COOKIE_HTTP_ONLY=1 >> .env
    echo SDC_KEY_PATH=/root/.ssh/id_rsa >> .env
    echo TRITON_CREDS_PATH=${TRITON_CREDS_PATH} >> .env
    echo SDC_URL=${SDC_URL} >> .env
    echo SDC_ACCOUNT=${SDC_ACCOUNT} >> .env
    echo SDC_KEY_ID=${SDC_KEY_ID} >> .env

    echo SDC_KEY=$(cat "${TRITON_PRIVATE_KEY_PATH}" | tr '\n' '#') >> .env
    echo SDC_KEY_PUB=$(cat "${TRITON_PRIVATE_KEY_PATH}".pub | tr '\n' '#') >> .env

    echo >> .env
    echo NODE_ENV=production >> .env
    echo NAMESPACE=tsg >> .env
}

# ---------------------------------------------------
# parse arguments

# Get function list
funcs=($(declare -F -p | cut -d " " -f 3))

until
    if [ ! -z "$1" ]; then
        # check if the first arg is a function in this file, or use a default
        if [[ " ${funcs[@]} " =~ " $1 " ]]; then
            cmd=$1
            shift 1
        else
            cmd="check"
        fi

        $cmd "$@"
        if [ $? == 127 ]; then
            help
        fi

        exit
    else
        help
    fi
do
    echo
done
