#!/bin/bash

while true
do
    echo "Starting server..."
    /usr/bin/python3 server.py

    echo "Server stopped. Restarting in 5 seconds..."
    sleep 5
done
