#!/usr/bin/env bash

# Install:
# sudo apt-get install gearman
# sudo systemctl disable gearman-job-server.service
#
# gearman check for nagios
# written by Georg Thoma (georg@thoma.cn) on 07-04-2014

PROGNAME=`/usr/bin/basename $0`
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION="0.04"
export TIMEFORMAT="%R"

#. $PROGPATH/utils.sh

# Defaults
hostname=127.0.0.1
port=4730
timeout=50

# search for gearmanstuff
GEARMAN_BIN=`which gearman 2>&1 | grep -v "no gearman in"`
if [ "x$GEARMAN_BIN" == "x" ] ; then # result of check is empty
   echo "gearman executable not found in path"
   exit $STATE_UNKNOWN
fi
GEARADMIN_BIN=`which gearadmin 2>&1 | grep -v "no gearadmin in"`
if [ "x$GEARADMIN_BIN" == "x" ] ; then # result of check is empty
   echo "gearadmin executable not found in path"
   exit $STATE_UNKNOWN
fi


print_usage() {
    echo "Usage: $PROGNAME [-H hostname -p port -t timeout]"
    echo "Usage: $PROGNAME --help"
    echo "Usage: $PROGNAME --version"
}

print_help() {
    print_revision $PROGNAME $REVISION
    echo ""
    print_usage
    echo ""
    echo "gearman check plugin for nagios"
    echo ""
    support
}

# Grab the command line arguments

exitstatus=$STATE_WARNING #default
while test -n "$1"; do
    case "$1" in
        --help)
            print_help
            exit $STATE_OK
            ;;
        -h)
            print_help
            exit $STATE_OK
            ;;
        --version)
            print_revision $PROGNAME $REVISION
            exit $STATE_OK
            ;;
        -V)
            print_revision $PROGNAME $REVISION
            exit $STATE_OK
            ;;
        -H)
            hostname=$2
            shift
            ;;
        --hostname)
            hostname=$2
            shift
            ;;
        -t)
            timeout=$2
            shift
            ;;
        --timeout)
            timeout=$2
            shift
            ;;
        -p)
            port=$2
            shift
            ;;
        --port)
            port=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
    esac
    shift
done

# check if server is running and replys to version query
VERSION_RESULT=`$GEARADMIN_BIN -h $hostname -p $port --server-version 2>&1 `
if [ "x$VERSION_RESULT" == "x" ] ; then # result of check is empty
      echo "CRITICAL: Server is not running / responding"
      exitstatus=$STATE_CRITICAL
      exit $exitstatus
fi

# drop funtion echo to remove functions without workers
DROP_RESULT=`$GEARADMIN_BIN -h $hostname -p $port --drop-function echo_for_nagios 2>&1 `

# check for worker echo_for_nagios and start a new one if needed
CHECKWORKER_RESULT=`$GEARADMIN_BIN -h $hostname -p $port --status | grep echo_for_nagios`
if [ "x$CHECKWORKER_RESULT" == "x" ] ; then # result of check is empty
   nohup $GEARMAN_BIN -h $hostname -p $port -w -f echo_for_nagios -- echo echo >/dev/null 2>&1 &
fi

# check the time to get the status from gearmanserver
CHECKWORKER_TIME=$( { time $GEARADMIN_BIN -h $hostname --status ; } 2>&1 |tail -1 )

# check if worker returns "echo"
CHECK_RESULT=`cat /dev/null | $GEARMAN_BIN -h $hostname -p $port -t $timeout -f echo_for_nagios 2>&1`

# validate result and set message and exitstatus
if [ "$CHECK_RESULT" = "echo" ] ; then # we got echo back
      echo "OK: got an echo back from gearman server version: $VERSION_RESULT, responded in $CHECKWORKER_TIME sec|time=$CHECKWORKER_TIME;;;"
      exitstatus=$STATE_OK
   else  # timeout reached, no echo
      echo "CRITICAL: $CHECK_RESULT"
      exitstatus=$STATE_CRITICAL
fi
exit $exitstatus