# RPT

(It's pronounced "Rapport." Not "report," because that's a different Fort thing.)

Relying Party Tester.

This project is in early development.

## Dependencies

- `sh` (I'm aiming for no bashisms)
- `rsync` (tested 3.2.7)
- `apache2` (tested 2.4.52)
- Routinator
- A means to create x509 certificates (`openssl` exampled below)

The project is just a bunch of shell scripts, so it needs no installation.

## Run

Sample commands are for Ubuntu.

Create the RRDP HTTPS certificate:

```sh
cd /path/to/cloned/rapport
mkdir -p custom/
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-subj "/C=AU/ST=Some-State/O=IWPL/CN=localhost" \
	-keyout "custom/rpt.key" -out "custom/rpt.crt"
```

Then run tests as many times as needed:

```sh
# See "Arguments" below.
./2-test.sh
```

## Arguments

### `$ROUTINATOR`

The string that can be used to invoke Routinator's binary. It's optional; defaults to `routinator`.

You can override this to point to an installation outside of `$PATH`. In particular, I use it it to test Routinator's development builds:

```sh
ROUTINATOR=~/git/routinator/src/routinator ./2-test.sh
```
