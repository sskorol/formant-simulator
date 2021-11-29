#!/bin/bash

help()
{
    echo ""
    echo "Usage: $0 -d device-sim"
    echo -e "\t-d Formant device name (must exist) *"
    echo -e "\t-h Show help"
    exit 1
}

while getopts "d:h" opt
do
    case "$opt" in
      d) DEVICE_NAME="$OPTARG" ;;
      h | ?) help ;;
    esac
done

if [[ -z "$DEVICE_NAME" ]]; then
    echo "Device name is mandatory"
    help
fi

FORMANT_USER=formant

# Stop and cleanup containers / volumes if running
echo "Stopping Formant services ..."
docker-compose down && docker system prune -f && docker volume prune -f

# Add required user/groups
if [ ! "$(id -u formant 2>/dev/null)" ]; then
    echo "Setting up formant user"
    sudo groupadd -g 706 formant >/dev/null
    if [ "$name" == "Linux" ]; then
        sudo useradd --gid 706 -u 706 --system formant >/dev/null
        if [ $(getent group video) ]; then
            echo "Adding formant user to video group"
            sudo usermod -aG video formant || true
        fi

        if [ $(getent group audio) ]; then
            echo "Adding formant user to audio group"
            sudo usermod -aG audio formant || true
        fi
        if [[ $(getent group docker) ]]; then
            echo "Adding formant user to docker group"
            sudo usermod -aG docker formant
            sudo chmod 666 /var/run/docker.sock
        fi
    fi
fi

# Recreate agent volume folder
sudo rm -rf /var/lib/formant
sudo mkdir -p /var/lib/formant
sudo chown -R $FORMANT_USER:$FORMANT_USER /var/lib/formant

# Add formant agent user:group to .env
FUID=$(id -u $FORMANT_USER)
FGID=$(id -g $FORMANT_USER)
sed -i "s/FORMANT_AGENT_USER=.*/FORMANT_AGENT_USER=$FUID:$FGID/" .env

# Import env variables from .env
export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)

# Request Formant token
AUTH_RESPONSE=$(curl -sS -X POST $FORMANT_BASE_URL/auth/login \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -d "{ \"email\": \"$FORMANT_EMAIL\", \"password\": \"$FORMANT_PASSWORD\" }")
AUTH_TOKEN=$(echo $AUTH_RESPONSE | jq -r '.authentication.accessToken')
echo "Successfully authenticated $FORMANT_EMAIL"

# Retrieve enabled device by name
DEVICE_RESPONSE=$(curl -sS -X POST $FORMANT_BASE_URL/devices/query \
     -H 'Accept: application/json' \
     -H "Authorization: Bearer $AUTH_TOKEN" \
     -H 'Content-Type: application/json' \
     -d "{ \"name\": \"$DEVICE_NAME\", \"enabled\": true }")
DEVICE_ID=$(echo $DEVICE_RESPONSE | jq -r '.items[0].id')
echo "Processing device: $DEVICE_NAME -> $DEVICE_ID"

# Unprovision device
UNPROVISION_RESPONSE=$(curl -sS -X POST $FORMANT_BASE_URL/devices/$DEVICE_ID/unprovision \
     -H 'Accept: application/json' \
     -H "Authorization: Bearer $AUTH_TOKEN")
echo "Unprovisioned $DEVICE_NAME"

# Generate provisioning token
PROVISIONING_RESPONSE=$(curl -sS -X POST $FORMANT_BASE_URL/devices/$DEVICE_ID/provisioning-token \
     -H 'Accept: application/json' \
     -H "Authorization: Bearer $AUTH_TOKEN")
PROVISIONING_TOKEN=$(echo $PROVISIONING_RESPONSE | jq -r '.token')

# Update token in .env to be able to reprovision device on docker agent start
sed -i "s/TOKEN=.*/TOKEN=$PROVISIONING_TOKEN/" .env
echo "Generated new provisioning token: $PROVISIONING_TOKEN"

echo "Starting Formant services ..."
docker-compose up -d
