# docker-dhcphelper

This projects builds a ct with dhcphelper.

Dockerhub images can be found at [https://hub.docker.com/r/qwe1/docker-dhcphelper](https://hub.docker.com/r/qwe1/docker-dhcphelper).

I intend to use this image as a dhcp relay for testing a pihole setup in my homelab
with Pihole, Traefik and dhcphelper.

Dockerfile is based on the post in [https://discourse.pi-hole.net/t/dhcp-with-docker-compose-and-bridge-networking/17038](https://discourse.pi-hole.net/t/dhcp-with-docker-compose-and-bridge-networking/17038) by user DerFetzer. Thank you.
## About dhcphelper

dhcp-helper version 1.2-r0, Copyright (C) 2004-2012 Simon Kelley
### Alpine version's Dhcphelper options as of 2022

``` none
Usage: dhcp-helper [OPTIONS]
Options are:
-s <server>      Forward DHCP requests to <server>
-b <interface>   Forward DHCP requests as broadcasts via <interface>
-i <interface>   Listen for DHCP requests on <interface>
-e <interface>   Do not listen for DHCP requests on <interface>
-u <user>        Change to user <user> (defaults to nobody)
-r <file>        Write daemon PID to this file (default /var/run/dhcp-helper.pid)
-p               Use alternative ports (1067/1068)
-d               Debug mode
-n               Do not demonize
-v               Give version and copyright info and then exit
```

## Docker-compose example with ansible

Below is an example with Pihole, DHCP-Helper and Traefik:


``` yaml
---
- name: Run docker-compose
  docker_compose:
    project_name: compose1
    state: present
    pull: yes
    remove_orphans: yes
    remove_volumes: yes
    restarted: yes
    remove_images: all
    definition:
      version: '2'
      networks:
        sample:
          external: true
      services:

        pihole:
         container_name: pihole
         image: pihole/pihole:latest
         restart: unless-stopped
         hostname: pihole
         networks:
           sample:
             ipv4_address: '172.18.0.100'
         environment:
           - TZ=Europe/London
           - WEBPASSWORD={{ pihole_docker_webpassword }}
           - DNSMASQ_LISTENING=all
           - VIRTUAL_HOST={{ acer_pihole_domain }}
           # ansible_default_ipv4.address|default(ansible_all_ipv4_addresses[0])
           # https://medium.com/opsops/ansible-default-ipv4-is-not-what-you-think-edb8ab154b10
           - ServerIP={{ ansible_default_ipv4.address|default(ansible_all_ipv4_addresses[0]) }}
           #- ServerIP=172.18.0.100
           - DNSMASQ_USER=pihole
           #- WEB_PORT={{ pihole_server_port }}
         labels:
           - "traefik.enable=true"
           - "traefik.http.routers.pihole.rule=Host(`{{ acer_pihole_domain }}`)"
           - "traefik.http.routers.pihole.rule=PathPrefix(`/admin`)"
           - "traefik.http.routers.pihole.entrypoints=websecure"
           - "traefik.http.routers.pihole.tls.certresolver=myresolver"
           - "traefik.http.routers.pihole.tls.domains[0].main={{ acer_pihole_domain }}"
           - "traefik.http.services.pihole.loadbalancer.server.port={{ pihole_server_port }}"
         dns:
           - 127.0.0.1
           - 1.1.1.1
         #network_mode: host
         cap_add:
           - NET_ADMIN
         ports:
           - 53:53/tcp
           - 53:53/udp
         depends_on:
         #  - letsencrypt-cloudflare
           - dhcphelper
         volumes:
           - /var/docker/pihole/etc-pihole:/etc/pihole
           - /var/docker/pihole/etc-dnsmasq.d:/etc/dnsmasq.d
           - /var/docker/pihole/backups:/tmp/backups

        dhcphelper:
         container_name: dhcphelper
         image: qwe1/docker-dhcphelper
         restart: unless-stopped
         command: -s 172.18.0.100
         network_mode: host
         cap_add:
           - NET_ADMIN
         labels:
           - "traefik.enable=false"

        traefik:
         image: traefik:2.8
         restart: unless-stopped
         container_name: traefik
         depends_on:
           - pihole
         command:
           - "--providers.docker=true"
           - "--providers.docker.exposedbydefault=false"
           - "--entrypoints.web.address=:80"
           - "--entrypoints.websecure.address=:443"
           - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
           - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
           - "--certificatesresolvers.myresolver.acme.dnschallenge=true"
           - "--certificatesresolvers.myresolver.acme.dnschallenge.provider=cloudflare"
           - "--certificatesresolvers.myresolver.acme.email={{ traefik_var_CF_API_EMAIL }}"
           - "--certificatesresolvers.myresolver.acme.storage=/acme.json"
           - "--global.sendAnonymousUsage=false"
           #- --api.dashboard=true
           #- --api.insecure=true
         environment:
           - CF_API_EMAIL={{ traefik_var_CF_API_EMAIL }}
           - CF_API_KEY={{ traefik_var_CF_API_KEY }}
         dns:
           - 127.0.0.1
           - 1.1.1.1
         ports:
           - 80:80
           - 443:443
         networks:
           - sample
         volumes:
           - /var/run/docker.sock:/var/run/docker.sock
           - /var/docker/traefik/acme.json:/acme.json

  tags:
    - docker
    - docker-compose
```
