#!/bin/bash

CMD="kafka-consumer-groups --bootstrap-server kafka:9094 --group connect-viewserver-table-updates-sink --describe"

last_lag=0

while true; do
    average_lag=$(docker exec connect sh -c "$CMD" | \
    awk 'NR > 1 && $6 ~ /^[0-9]+$/ {sum += $6; count++} END {if (count > 0) {print sum / count} else {print "No numeric LAG data found"}}')

    if [[ $average_lag =~ ^[0-9]+$ ]]; then
        if [ "$last_lag" -ne "0" ]; then
            lag_diff=$((average_lag - last_lag))
            echo -ne "Average LAG: $average_lag (Change: $lag_diff)    \r"
        else
            echo -ne "Average LAG: $average_lag\r"
        fi
        last_lag=$average_lag
    else
        echo -ne "Average LAG: $average_lag\r"
    fi

    sleep 5
done
