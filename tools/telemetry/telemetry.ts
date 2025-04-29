import * as blessed from 'blessed';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

const screen = blessed.screen({
    autoPadding: true,
    smartCSR: true,
    title: 'Kafka Consumer Lag Monitoring'
});

const leftPanel = blessed.log({
    parent: screen,
    top: '0',
    left: '0',
    width: '50%',
    height: '100%',
    label: ' Partition Lag ',
    // @ts-ignore
    border: { type: 'line', fg: 'green' },
    scrollbar: {
        ch: ' ',
        // @ts-ignore
        inverse: true
    },
    scrollable: true,
    alwaysScroll: true,
    scrollback: 100,
    mouse: true,
    keys: true,
    vi: true,
    tags: true,
    fg: 'white',
    selectedFg: 'green',
    bg: 'black'
});

const rightPanel = blessed.log({
    parent: screen,
    top: '0',
    left: '50%',
    width: '50%',
    height: '100%',
    label: ' Avg. Consumer Lag ',
    // @ts-ignore
    border: { type: 'line', fg: 'green' },
    scrollbar: {
        ch: ' ',
        // @ts-ignore
        inverse: true
    },
    scrollable: true,
    alwaysScroll: true,
    scrollback: 100,
    mouse: true,
    keys: true,
    vi: true,
    tags: true,
    fg: 'white',
    selectedFg: 'green',
    bg: 'black'
});

screen.append(leftPanel);
screen.append(rightPanel);

screen.key(['escape', 'q', 'C-c'], function (ch, key) {
    return process.exit(0);
});

screen.render();

const deploymentName = "confluent-tools";
const namespace = "mktx-platform-tools";

async function getPodName() {
    try {
        const { stdout } = await execAsync(`kubectl get pods --insecure-skip-tls-verify -n ${namespace} -l app=confluent-tools -o jsonpath='{.items[0].metadata.name}'`);
        return stdout.trim();
    } catch (error) {
        console.error('Failed to get pod name:', error);
        return null;
    }
}

async function scaleDeployment() {
    console.log(`No pod found with the specified label. Attempting to scale up ${deploymentName}...`);
    await execAsync(`kubectl scale deployment/${deploymentName} --replicas=1 -n ${namespace}`);
    console.log("Scaling operation initiated. Waiting for pods to start...");
    await new Promise(resolve => setTimeout(resolve, 30000)); // wait 30 seconds
    return getPodName();
}


const PARTITION_COUNT = 30;

async function monitorLag() {
    let podName = await getPodName();
    if (!podName) {
        podName = await scaleDeployment();
    }

    let lastPartitionLag = 0;
    let lastAverageLag = 0;
    let lastTimestamp = Date.now();

    while (true) {
        try {
            const currentTimestamp = Date.now();

            const partitionCmd = `kubectl exec --insecure-skip-tls-verify -i -t -n ${namespace} ${podName} -c confluent-tools -- sh -c "kafka-consumer-groups --bootstrap-server b-1.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096,b-2.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096,b-3.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096 --group connect-viewserver-table-updates-mongodb-sink-connector --describe --command-config /tmp/client_sasl.properties" | awk 'NR == 10 {print $6; exit}'`;
            const averageCmd = `kubectl exec --insecure-skip-tls-verify -i -t -n ${namespace} ${podName} -c confluent-tools -- sh -c "kafka-consumer-groups --bootstrap-server b-1.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096,b-2.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096,b-3.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096 --group connect-viewserver-table-updates-mongodb-sink-connector --describe --command-config /tmp/client_sasl.properties" | awk 'NR > 1 && \$6 ~ /^[0-9]+$/ {sum += \$6; count++} END {if (count > 0) {print sum / count} else {print "No numeric Lag data found"}}'`;

            const [partitionLag, averageLag] = await Promise.all([
                execAsync(partitionCmd).then(res => res.stdout.trim()).catch(e => { console.error(e); return '0'; }),
                execAsync(averageCmd).then(res => res.stdout.trim()).catch(e => { console.error(e); return '0'; })
            ]);

            const partitionLagNumber = parseFloat(partitionLag);
            const averageLagNumber = parseFloat(averageLag);

            const timeDiff = (currentTimestamp - lastTimestamp) / 1000;
            const partitionLagDiff = partitionLagNumber - lastPartitionLag;
            const averageLagDiff = averageLagNumber - lastAverageLag;

            const partitionRateOfChange = timeDiff > 0 ? partitionLagDiff / timeDiff : 0;
            const averageRateOfChange = timeDiff > 0 ? (averageLagDiff / timeDiff) * PARTITION_COUNT : 0;

            leftPanel.log(`{bold}Partition Lag{/bold}: ${partitionLagNumber} | {bold}Change{/bold}: ${partitionLagDiff} | {bold}${partitionRateOfChange.toFixed(2)}{/bold} msgs/sec`);
            rightPanel.log(`{bold}Avg. Lag{/bold}: ${averageLagNumber} | {bold}Change{/bold}: ${averageLagDiff} | {bold}${averageRateOfChange.toFixed(2)}{/bold} msgs/sec`);

            lastPartitionLag = partitionLagNumber;
            lastAverageLag = averageLagNumber;
            lastTimestamp = currentTimestamp;
        } catch (error) {
            leftPanel.log("{red-fg}ERROR{/red-fg}");
            rightPanel.log("{red-fg}ERROR{/red-fg}");
            console.error(error);
        }

        await new Promise(resolve => setTimeout(resolve, 5000));
        screen.render();
    }
}


monitorLag();