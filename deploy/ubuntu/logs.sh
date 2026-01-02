#!/bin/bash
# logs.sh - View logs for all services

case $1 in
  dev)
    tail -f deploy/logs/dev/*.log
    ;;
  prod)
    tail -f deploy/logs/prod/*.log
    ;;
  *)
    echo "Usage: ./deploy/ubuntu/logs.sh [dev|prod]"
    ;;
esac
