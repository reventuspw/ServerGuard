#!/bin/bash
# Determines LOCAL_IP and REMOTE_IP from SERVER_1_IP / SERVER_2_IP (.env).
# Must be sourced after .env is loaded.

if [ -z "$SERVER_1_IP" ] || [ -z "$SERVER_2_IP" ]; then
    echo "ERROR: SERVER_1_IP and SERVER_2_IP must be set in .env" >&2
    exit 1
fi

LOCAL_IP=$(ip route get 8.8.8.8 2>/dev/null | awk 'NR==1 {for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')

if [ -z "$LOCAL_IP" ]; then
    echo "ERROR: Could not determine local IP address" >&2
    exit 1
fi

if [ "$LOCAL_IP" = "$SERVER_1_IP" ]; then
    echo "This machine is SERVER_1 ($SERVER_1_IP), peer is SERVER_2 ($SERVER_2_IP)"
    REMOTE_IP="$SERVER_2_IP"
elif [ "$LOCAL_IP" = "$SERVER_2_IP" ]; then
    echo "This machine is SERVER_2 ($SERVER_2_IP), peer is SERVER_1 ($SERVER_1_IP)"
    REMOTE_IP="$SERVER_1_IP"
else
    echo "ERROR: Local IP ($LOCAL_IP) matches neither SERVER_1_IP ($SERVER_1_IP) nor SERVER_2_IP ($SERVER_2_IP)" >&2
    exit 1
fi
