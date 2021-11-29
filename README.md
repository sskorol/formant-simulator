## Formant Turtlebot Simulator

### Installation

```shell
git clone https://github.com/sskorol/formant-simulator.git && cd formant-simulator
mv example.env .env && nano .env
```

Ajust `FORMANT_EMAIL` / `FORMANT_PASSWORD` with your Formant credentials. The other fields will be populated automatically.

### Running

```shell
./reprovision.sh -d [DEVICE_NAME]
```
