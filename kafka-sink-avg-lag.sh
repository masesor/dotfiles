#!/bin/bash

CMD="kafka-consumer-groups --bootstrap-server b-1.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096,b-2.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096,b-3.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096 --group connect-viewserver-table-updates-mongodb-sink-connector --describe --command-config /tmp/client_sasl.properties"
POD_NAME=$(kubectl get pods --insecure-skip-tls-verify -n mktx-platform-tools -l app=confluent-tools -o jsonpath='{.items[0].metadata.name}')

DEPLOYMENT_NAME="confluent-tools"
NAMESPACE="mktx-platform-tools"

if [ -z "$POD_NAME" ]; then
    echo "No pod found with the specified label. Attempting to scale up $DEPLOYMENT_NAME..."
    kubectl scale deployment/$DEPLOYMENT_NAME --replicas=1 -n $NAMESPACE
    echo "Scaling operation initiated. Waiting for pods to start..."
    sleep 30
    POD_NAME=$(kubectl get pods --insecure-skip-tls-verify -n mktx-platform-tools -l app=confluent-tools -o jsonpath='{.items[0].metadata.name}')
fi

last_lag=0

while true; do
    average_lag=$(kubectl exec --insecure-skip-tls-verify -i -t -n $NAMESPACE $POD_NAME -c confluent-tools -- sh -c "$CMD" | \
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
