#!/bin/bash

DELETE_CMD="kafka-topics --bootstrap-server b-3.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096,b-2.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096,b-1.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096 --delete --topic dev.viewserver.table.updates --command-config /tmp/client_sasl.properties"
CREATE_CMD="kafka-topics --bootstrap-server b-3.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096,b-2.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096,b-1.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096 --create --topic dev.viewserver.table.updates --partitions 30 --replication-factor 3 --command-config /tmp/client_sasl.properties"
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
echo "Removing topic..."
kubectl exec --insecure-skip-tls-verify -i -t -n mktx-platform-tools $POD_NAME -c confluent-tools -- sh -c "$DELETE_CMD"
echo "Creating topic..."
kubectl exec --insecure-skip-tls-verify -i -t -n mktx-platform-tools $POD_NAME -c confluent-tools -- sh -c "$CREATE_CMD"
echo "Done!"
