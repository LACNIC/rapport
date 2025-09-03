Set up the RRDP key:

```sh
# Set 'localhost' as common name
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout "tools/fft.key" -out "tools/fft.crt"
sudo cp "tools/fft.crt" "/usr/local/share/ca-certificates/"
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
sudo rm "/usr/local/share/ca-certificates/fft.crt"
sudo update-ca-certificates
```
