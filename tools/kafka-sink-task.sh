#!/bin/bash

POD_NAME="mongodb-sink-connect-cluster-connect-0"
NAMESPACE="kube-system"
CONTAINER="mongodb-sink-connect-cluster-connect"

function run_curl {
    local cmd="curl -X $1 -H 'Content-Type: application/json' localhost:8083$2 -w '\n'"
    echo "Executing: $cmd"
    kubectl exec --insecure-skip-tls-verify -i -t -n $NAMESPACE $POD_NAME -c $CONTAINER -- sh -c "$cmd"
}

case "$1" in
    --list)
        run_curl GET "/connectors/"
        ;;
    --tasks)
        run_curl GET "/connectors/viewserver-table-updates-mongodb-sink-connector/tasks"
        ;;
    --task-status)
        run_curl GET "/connectors/viewserver-table-updates-mongodb-sink-connector/tasks/0/status"
        ;;
    --restart-connector)
        run_curl POST "/connectors/viewserver-table-updates-mongodb-sink-connector/restart"
        ;;
    --restart-task)
        run_curl POST "/connectors/viewserver-table-updates-mongodb-sink-connector/tasks/0/restart"
        ;;
    --pause-connector)
        run_curl PUT "/connectors/viewserver-table-updates-mongodb-sink-connector/pause"
        ;;
    --resume-connector)
        run_curl PUT "/connectors/viewserver-table-updates-mongodb-sink-connector/resume"
        ;;
    *)
        echo "Usage: $0 [--list | --tasks | --task-status | --restart-connector | --restart-task | --pause-connector | --resume-connector]"
        exit 1
        ;;
esac
