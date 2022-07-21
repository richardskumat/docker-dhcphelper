# https://discourse.pi-hole.net/t/dhcp-with-docker-compose-and-bridge-networking/17038
FROM alpine:3.16
RUN apk --no-cache add dhcp-helper
EXPOSE 67 67/udp
ENTRYPOINT ["dhcp-helper", "-n"]