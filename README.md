Set up the RRDP key:

```sh
# Notice the 'localhost' commonName (CN)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-subj "/C=AU/ST=Some-State/O=IWPL/CN=localhost" \
	-keyout "tools/rpt.key" -out "tools/rpt.crt"
sudo cp "tools/rpt.crt" "/usr/local/share/ca-certificates/"
sudo update-ca-certificates
```

Mount the tmpfs:

```sh
./1-setup.sh
```

Run tests as many times as needed:

```sh
./2-test.sh
```

Drop the tmpfs:

```sh
./3-cleanup.sh
```

Delete the RRDP key:

```sh
sudo rm "/usr/local/share/ca-certificates/rpt.crt"
sudo update-ca-certificates
```
