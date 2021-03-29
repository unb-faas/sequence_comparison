#!/bin/bash
sudo yum install git python36 gcc python36-devel aws-cli -y
pip install fastapi psutil
pip install uvicorn[standard]
mkdir -p /app
cd /app
git clone https://github.com/unb-faas/sequence_comparison.git
cd /app/sequence_comparison/algorithms/hirschberg/Python/app/
sed -i "s/\/localhost/\/teste/" main.py
./start.sh