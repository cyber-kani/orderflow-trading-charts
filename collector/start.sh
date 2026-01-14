#!/bin/bash
# Start OrderFlow Delta & Big Order Collector
# This runs for 13 hours by default, tracking delta and big orders

cd "$(dirname "$0")"

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Start the collector
echo "Starting OrderFlow Collector..."
node collector.js
