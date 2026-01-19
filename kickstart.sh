#!/bin/bash
MAP=de_train
MAXPLAYERS=22
# IP=$(curl -s ifconfig.me || echo "127.0.0.1");
echo "Detected external IP: $IP";
sed -i "s|127.0.0.1|$IP:$HTTP_PORT|g" /opt/steam/hlds/cstrike/server.cfg;
service nginx start;


/opt/steam/hlds/hlds_run -console -game cstrike -strictportbind -ip 0.0.0.0 -port $PORT  +map $MAP -maxplayers $MAXPLAYERS
