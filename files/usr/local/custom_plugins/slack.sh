#!/usr/bin/env bash

WEBHOOK_URL=$1
SHINKEN_STATE=$2
SHINKEN_HOST=$3
SHINKEN_MESSAGE=$4
SHINKEN_SERVICE=$5

# Set the message icon based on Nagios service state
if [ "$SHINKEN_STATE" = "CRITICAL" ]
then
    ICON=":exclamation:"
elif [ "$SHINKEN_STATE" = "WARNING" ]
then
    ICON=":warning:"
elif [ "$SHINKEN_STATE" = "OK" ]
then
    ICON=":white_check_mark:"
elif [ "$SHINKEN_STATE" = "UNKNOWN" ]
then
    ICON=":question:"
else
    ICON=":white_medium_square:"
fi

# Send message to Slack
if [ "$SHINKEN_SERVICE" ]
then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\": \"${ICON} ${SHINKEN_STATE}\nHOST: ${SHINKEN_HOST}\nSERVICE: ${SHINKEN_SERVICE}\nMESSAGE: ${SHINKEN_MESSAGE}\n<https://shinken.mrphp.com.au/webui/service/${SHINKEN_HOST}/${SHINKEN_SERVICE}|shinken> | <https://shinken.mrphp.com.au/thruk/#cgi-bin/extinfo.cgi?type=2&host=${SHINKEN_HOST}&service=${SHINKEN_SERVICE}|thruk>\"}" \
        ${WEBHOOK_URL}
else
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\": \"${ICON} ${SHINKEN_STATE}\nHOST: ${SHINKEN_HOST}\nMESSAGE: ${SHINKEN_MESSAGE}\n<https://shinken.mrphp.com.au/webui/service/${SHINKEN_HOST}}|shinken> | <https://shinken.mrphp.com.au/thruk/#cgi-bin/status.cgi?host=${SHINKEN_HOST}|thruk>\"}" \
        ${WEBHOOK_URL}
fi
