#!/bin/bash

case $1 in
  dev)
    tail -f deploy/logs/dev/*.log
    ;;
  prod)
    tail -f deploy/logs/prod/*.log
    ;;
  *)
    echo "Usage: ./deploy/scripts/view_logs.sh [dev|prod]"
    ;;
esac
