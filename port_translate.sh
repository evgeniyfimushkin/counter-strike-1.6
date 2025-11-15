# IP клиента
CLIENT_IP=93.158.191.255
# IP контейнера
SERVER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cs1.6)

# Входящие пакеты от клиента на 8088 → перенаправляем на 27015 контейнера
iptables -t nat -A PREROUTING -p udp -s $CLIENT_IP --dport 8088 -j DNAT --to-destination $SERVER_IP:27015

# Исходящие пакеты от сервера к клиенту → меняем порт на 8088
iptables -t nat -A POSTROUTING -p udp -d $CLIENT_IP --sport 27015 -j SNAT --to-source $SERVER_IP:8088


