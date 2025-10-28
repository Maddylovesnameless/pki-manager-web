#!/bin/sh
set -e

echo "Starting PKI Manager Backend..."

# Start the server (migrations handled by application startup)
echo "Starting server..."
exec "$@"
