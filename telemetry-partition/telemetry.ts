import * as blessed from 'blessed';
import * as contrib from 'blessed-contrib';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

const screen = blessed.screen({
    autoPadding: true,
    smartCSR: true,
    title: 'Kafka Consumer Lag Monitoring'
});

/* const lcd = contrib.lcd({
    elements: 30, // how many elements in the display. or how many characters can be displayed.
    display: 0, // what should be displayed before first call to setDisplay
    elementSpacing: 1, // spacing between each element
    elementPadding: 4, // how far away from the edges to put the elements
    //width: '80%', // adjust as necessary, for example, 80% of the screen width
    //height: '15%', // adjust to make the height 50% smaller than you would normally have
    // @ts-ignore
    color: 'green', // color for the segments
    // @ts-ignore
    label: 'Avg. Consumer Lag',
    // @ts-ignore
    border: { type: 'line', fg: 'green' },
    top: 'center',
    // top: '25%', // Position it starting from 25% from the top of the screen

}); */

const log = blessed.log({
    parent: screen,
    top: 'center',
    left: 'center',
    width: '90%',
    height: '90%',
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
    label: ' Partition Consumer Lag ',
    tags: true,
    fg: 'white',
    selectedFg: 'green',
    bg: 'black'
});

screen.append(log)
// lcd.setOptions({})
screen.key(['escape', 'q', 'C-c'], function (ch, key) {
    return process.exit(0);
});

screen.render()


const deploymentName = "confluent-tools";
const namespace = "mktx-platform-tools";
let lastLag = 0;

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
    await new Promise(resolve => setTimeout(resolve, 30000));
    return getPodName();
}

async function fetchLag(podName: string) {
    const cmd = `kubectl exec --insecure-skip-tls-verify -i -t -n ${namespace} ${podName} -c confluent-tools -- sh -c "kafka-consumer-groups --bootstrap-server b-1.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096,b-2.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096,b-3.kauaimskdevdev1.jt7u5d.c10.kafka.us-east-1.amazonaws.com:9096 --group connect-viewserver-table-updates-mongodb-sink-connector --describe --command-config /tmp/client_sasl.properties" | awk 'NR == 10 {print $6; exit}'`;
    try {
        const { stdout } = await execAsync(cmd);
        return stdout.trim();
    } catch (e) {
        console.error(e)
        return '0';
    }
}

async function monitorLag() {
    let podName = await getPodName();
    if (!podName) {
        podName = await scaleDeployment();
    }

    let lastTimestamp = Date.now();
    while (true) {
        try {
            const currentTimestamp = Date.now();
            const lag = await fetchLag(podName!); 

            const lagNumber = parseFloat(lag);
            if (!isNaN(lagNumber)) {
                const timeDiff = (currentTimestamp - lastTimestamp) / 1000;
                const lagDiff = lagNumber - lastLag;
                const rateOfChange = timeDiff > 0 ? lagDiff / timeDiff : 0;

                log.log(`{bold}Partition Lag{/bold}: ${lagNumber} | {bold}Change{/bold}: ${lagDiff} | {bold}${rateOfChange.toFixed(2)}{/bold} msgs/sec`);
                lastLag = lagNumber;
                lastTimestamp = currentTimestamp;
            } else {
                log.log(`Current Lag: ${lag}`);
            }
        } catch (error) {
            log.log("{red-fg}ERROR{/red-fg}");
            console.error(error);
        }

        await new Promise(resolve => setTimeout(resolve, 5000));
        screen.render();
    }
}


monitorLag();