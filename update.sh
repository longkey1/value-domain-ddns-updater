#!/usr/bin/env bash

# functions
function usage() {
  cat <<EOF
$(basename ${0}) is a tool for ...
Usage:
  $(basename ${0}) [<options>]
Options:
  -d  target domain
  -h  target host name
  -p  password for value domain ddns update
  -l  log file
  -h  print this
EOF
  exit 1
}
function log() {
  local _dry_run=""
  if [ -z "${FLAG_EXEC}" ]; then
    _dry_run="***DRY RUN*** "
  fi

  echo -e "$(date '+%Y-%m-%dT%H:%M:%S') ${_dry_run}$@"| tee -a ${LOG_FILE}
}
function update() {
  local _dns_ip="$(dig ${HOST}.${DOMAIN} +short)"
  local _current_ip=$(curl -s ifconfig.io)
  stat="skipped"
  if [ ! "${_dns_ip}" = "${_current_ip}" ]; then
    stat="updated"
    if [ ! -z "${FLAG_EXEC}" ]; then
      local _res=$(wget -O - "https://dyn.value-domain.com/cgi-bin/dyn.fcg?d=${DOMAIN}&p=${PASSWORD}&h=${HOST}")
      if ! echo ${_res} | grep 'status=0' > /dev/null; then
        stat="failed"
      fi
    fi
  fi

  log "${stat}. dns: ${_dns_ip} current: ${_current_ip}"
}



# options
while getopts d:h:p:l:x opt
do
  case ${opt} in
  "d" )
    readonly DOMAIN=${OPTARG}
    ;;
  "h" )
    readonly HOST=${OPTARG}
    ;;
  "p" )
    readonly PASSWORD=${OPTARG}
    ;;
  "l" )
    readonly LOG_FILE=${OPTARG}
    ;;
  "x" )
    readonly FLAG_EXEC="TRUE"
    ;;
  :|\?) usage;;
  esac
done
if [ -z "${DOMAIN}" -o -z "${HOST}" -o -z "${PASSWORD}" ]; then
  usage
  exit 1
fi
if [ -z "${LOG_FILE}" ]; then
  readonly LOG_FILE="/var/log/value-domain-ddns-updater.log"
fi



#
# main
#
update
