#!/bin/bash
helm install goodbye ./hello-chart \
  --set appName="goodbye" \
  --set message="Goodbye world!" \
  --set endpoint="/goodbye" \
  --set resources.cpu="250m" \
  --set autoscaler.maxReplicas=20