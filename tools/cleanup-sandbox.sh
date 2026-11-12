#!/bin/sh

for i in sandbox/apache2/*; do
	test -f "$i/apache2.pid" && kill $(cat "$i/apache2.pid")
done
if [ -f "sandbox/rsyncd/rsyncd.pid" ]; then
	kill $(cat "sandbox/rsyncd/rsyncd.pid")
fi

mkdir -p "custom/keys"
if [ ! -f "custom/keys/50.pem" ]; then
	for i in $(seq 0 50); do
		echo "Creating custom/keys/$i.pem"
		openssl genrsa -out "custom/keys/$i.pem" 2048
	done
fi

rm -rf sandbox/*
mkdir -p "sandbox/counters"
touch "sandbox/counters/total.txt"
touch "sandbox/counters/warns.txt"
mkdir "sandbox/tests"

mkdir -p "sandbox/rsyncd"
cp "tools/rsyncd.conf" "sandbox/rsyncd"
mkdir "sandbox/rsyncd/content"
mkdir "sandbox/rsyncd/repo1"
mkdir "sandbox/rsyncd/repo2"
mkdir "sandbox/rsyncd/repo3"
mkdir "sandbox/rsyncd/repo4"
