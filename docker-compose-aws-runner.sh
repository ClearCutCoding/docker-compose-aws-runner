#!/usr/bin/env bash
set -e

# TERMINAL COLORS
COL_RED='\033[1;31m'
COL_YELLOW='\033[1;33m'
COL_GREEN='\033[0;32m'
COL_BLUE='\033[0;34m'
COL_NC='\033[0m' # No Color

#############################################################
# Start containers:             ./docker-compose-aws-runner.sh start
# Stop containers:              ./docker-compose-aws-runner.sh stop
# Terminate containers:         ./docker-compose-aws-runner.sh terminate
# Don't pull images:            ./docker-compose-aws-runner.sh start -p no
#
# MAC SPECIFIC:
#
# Start with docker-sync:       ./docker-compose-aws-runner.sh syncstart
# Stop with-docker-sync:        ./docker-compose-aws-runner.sh syncstop
# Terminate with docker-sync:   ./docker-compose-aws-runner.sh syncterminate
#############################################################

OS=$(uname)
SCRIPT_DIR=$( dirname -- "$0"; )

CMD_AWS="aws"
CMD_COMPOSE="docker-compose"

ARG_PULL="yes"
ARG_COMMAND=

parse_args()
{
    while [ $# -gt 0 ]
    do
        case "${1}" in
            -p|--pull)
                shift
                ARG_PULL="${1}"
                shift
            ;;
            start|stop|terminate|syncstart|syncstop|syncterminate)
                ARG_COMMAND="${1}"
                shift
            ;;
            *)
                echo -e "\nERROR: UNKNOWN ARGUMENT ${1}\n"
                exit 1
            ;;
        esac
    done

    return
}
parse_args "$@"

config_read_file() {
    (grep -E "^${2}=" -m 1 "${1}" 2>/dev/null || echo "VAR=__UNDEFINED__") | head -n 1 | cut -d '=' -f 2-;
}

config_get() {
    val="$(config_read_file docker-compose-aws-runner.cfg "${1}")";
    printf -- "%s" "${val}";
}

VAR_NETWORK=$(config_get network)
VAR_PROFILE=$(config_get aws.profile)
VAR_ACCOUNT=$(config_get aws.account)

####

start_containers() {
    ${CMD_COMPOSE} -f docker-compose.yml -p ${VAR_NETWORK} up -d --remove-orphans
}

stop_containers() {
    ${CMD_COMPOSE} -f docker-compose.yml -p ${VAR_NETWORK} stop
    ${CMD_COMPOSE} stop
}

terminate_containers() {
    ${CMD_COMPOSE} -f docker-compose.yml -p ${VAR_NETWORK} down --remove-orphans
    ${CMD_COMPOSE} down --remove-orphans
}

sync_start_containers() {
    docker-sync start
    ${CMD_COMPOSE} -f docker-compose-sync.yml -p ${VAR_NETWORK} up -d --remove-orphans
}

sync_stop_containers() {
    ${CMD_COMPOSE} -f docker-compose-sync.yml -p ${VAR_NETWORK} stop
    ${CMD_COMPOSE} stop
    docker-sync stop
}

sync_terminate_containers() {
    ${CMD_COMPOSE} -f docker-compose-sync.yml -p ${VAR_NETWORK} down --remove-orphans
    ${CMD_COMPOSE} down --remove-orphans
    docker-sync clean
}

check_aws_cli() {
    which ${CMD_AWS} > /dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo "'${CMD_AWS}' command not found. Please install AWS CLI client."
        exit 1
    fi

    if [[ $(${CMD_AWS} configure --profile ${VAR_PROFILE} list) && $? != 0 ]]; then
        echo "Please run '${CMD_AWS} configure --profile ${VAR_PROFILE}' and set up your credentials."
        exit 1
    fi

    # aws cli v2
    PASS=$(${CMD_AWS} ecr get-login-password --region eu-west-1 --profile ${VAR_PROFILE})
    docker login -u AWS -p ${PASS} ${VAR_ACCOUNT}

    if [[ $? != 0 ]]; then
        echo 'Something went wrong when logging in to ${VAR_PROFILE} profile.'
        exit 1
    fi
}




if [[ ${ARG_COMMAND} == "start" ]]; then

    if [[ ${ARG_PULL} == "yes" ]]; then
        check_aws_cli
        ${CMD_COMPOSE} -f docker-compose.yml pull
    fi

    start_containers

    if [[ ${OS} == "Darwin" ]]; then
        docker images -qf dangling=true | xargs docker rmi -f
    else
        docker images -f dangling=true -q | xargs --no-run-if-empty docker rmi -f
    fi

elif [[ ${ARG_COMMAND} == "stop" ]]; then
    stop_containers

elif [[ ${ARG_COMMAND} == "terminate" ]]; then
    terminate_containers




elif [[ ${ARG_COMMAND} == "syncstart" ]]; then

    if [[ ${ARG_PULL} == "yes" ]]; then
        check_aws_cli
        ${CMD_COMPOSE} -f docker-compose-sync.yml pull
    fi

    sync_start_containers

    if [[ ${OS} == "Darwin" ]]; then
        docker images -qf dangling=true | xargs docker rmi -f
    else
        docker images -f dangling=true -q | xargs --no-run-if-empty docker rmi -f
    fi

elif [[ ${ARG_COMMAND} == "syncstop" ]]; then
    sync_stop_containers

elif [[ ${ARG_COMMAND} == "syncterminate" ]]; then
    sync_terminate_containers

else
  echo -e "\n${COL_RED}Unknown option${COL_NC}\n"

  echo -e "${COL_GREEN}Start containers:             ./docker-compose-aws-runner.sh start${COL_NC}"
  echo -e "${COL_GREEN}Stop containers:              ./docker-compose-aws-runner.sh stop${COL_NC}"
  echo -e "${COL_GREEN}Terminate containers:         ./docker-compose-aws-runner.sh terminate${COL_NC}"
  echo -e "${COL_GREEN}Don't pull images:            ./docker-compose-aws-runner.sh start -p no${COL_NC}"
  echo -e ""
  echo -e "${COL_YELLOW}MAC SPECIFIC${COL_NC}"
  echo -e ""

  echo -e "${COL_GREEN}Start with docker-sync:       ./docker-compose-aws-runner.sh syncstart${COL_NC}"
  echo -e "${COL_GREEN}Stop with-docker-sync:        ./docker-compose-aws-runner.sh syncstop${COL_NC}"
  echo -e "${COL_GREEN}Terminate with docker-sync:   ./docker-compose-aws-runner.sh syncterminate${COL_NC}"
  echo -e ""
fi
