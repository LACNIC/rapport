#!/bin/sh

if [ -f "sandbox/apache2/apache2.pid" ]; then
	kill $(cat "sandbox/apache2/apache2.pid")
fi
if [ -f "sandbox/rsyncd/rsyncd.pid" ]; then
	kill $(cat "sandbox/rsyncd/rsyncd.pid")
fi

mkdir -p "sandbox/keys"
mkdir -p "sandbox/apache2"
mkdir -p "sandbox/rsyncd"
mkdir -p "sandbox/tests"

if [ -z "$(ls -A sandbox/keys)" ]; then    # "If sandbox/keys is empty"
	for i in $(seq 0 20); do
		echo "Creating sandbox/keys/$i.pem"
		openssl genrsa -out "sandbox/keys/$i.pem" 2048
	done
fi

rm -rf sandbox/apache2/*
rm -rf sandbox/rsyncd/*
rm -rf sandbox/tests/*

cp "tools/apache2.conf" "sandbox/apache2"
mkdir -p "sandbox/apache2/content"
mkdir -p "sandbox/apache2/logs"
cp "tools/rsyncd.conf" "sandbox/rsyncd"
mkdir -p "sandbox/rsyncd/content"
