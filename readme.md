# docker-dhchelper

This projects builds a ct with dhchelper.

Dockerhub images can be found at [https://hub.docker.com/r/qwe1/docker-dhchelper](https://hub.docker.com/r/qwe1/docker-dhchelper).

I intend to use this image as a dhcp relay for testing a pihole setup in my homelab
with Pihole, Traefik and dhchelper.

## About dhchelper

dhcp-helper version 1.2-r0, Copyright (C) 2004-2012 Simon Kelley
### Alpine version's Dhchelper options as of 2022

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