#!/bin/sh

if [ -f "sandbox/apache2/apache2.pid" ]; then
	kill $(cat "sandbox/apache2/apache2.pid")
fi
if [ -f "sandbox/rsyncd/rsyncd.pid" ]; then
	kill $(cat "sandbox/rsyncd/rsyncd.pid")
fi

mkdir -p "custom/keys"
mkdir -p "sandbox/checks"
mkdir -p "sandbox/apache2"
mkdir -p "sandbox/rsyncd"
mkdir -p "sandbox/tests"

if [ ! -f "custom/keys/50.pem" ]; then
	for i in $(seq 0 50); do
		echo "Creating custom/keys/$i.pem"
		openssl genrsa -out "custom/keys/$i.pem" 2048
	done
fi

rm -rf sandbox/checks/*
rm -rf sandbox/apache2/*
rm -rf sandbox/rsyncd/*
rm -rf sandbox/tests/*

touch "sandbox/checks/totals.txt"
touch "sandbox/checks/warns.txt"

cp "tools/apache2.conf" "sandbox/apache2"
mkdir -p "sandbox/apache2/content"
mkdir -p "sandbox/apache2/logs"
cp "tools/rsyncd.conf" "sandbox/rsyncd"
mkdir -p "sandbox/rsyncd/content"
