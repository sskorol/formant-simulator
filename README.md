## Formant Turtlebot Simulator

### Prerequisites

- Install [Docker](https://docs.docker.com/engine/install/ubuntu) and [Compose](https://docs.docker.com/compose/install)
- Install **jq**: `sudo apt-get install jq`
- Add Formant device: from the burger menu select Settings -> Devices -> Add device

### Installation

```shell
git clone https://github.com/sskorol/formant-simulator.git && cd formant-simulator
mv example.env .env && nano .env
```

Adjust `FORMANT_EMAIL` / `FORMANT_PASSWORD` with your Formant credentials. The other fields will be populated automatically.

### Running

```shell
./reprovision.sh -d [DEVICE_NAME]
```
