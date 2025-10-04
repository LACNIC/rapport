# RPT

(It's pronounced "Rapport." Not "report," because that's a different Fort thing.)

Relying Party Tester.

This project is in early development.

## Dependencies

- `sh` (I'm aiming for no bashisms)
- `rsync` (tested 3.2.7)
- `apache2` (tested 2.4.52)
- [`barry`](https://github.com/LACNIC/barry/)
- The Relying Party you want to test
- [`tmpfs`](https://man7.org/linux/man-pages/man5/tmpfs.5.html) (optional)
- A means to create x509 certificates (`openssl` exampled below)
- [`valgrind`](https://valgrind.org/) (optional)

The project is just a bunch of shell scripts, so it needs no installation.

## Run

Sample commands are for Ubuntu.

Create the RRDP HTTPS certificate:

```sh
# Notice the 'localhost' commonName (CN)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-subj "/C=AU/ST=Some-State/O=IWPL/CN=localhost" \
	-keyout "tools/rpt.key" -out "tools/rpt.crt"
```

Install the certificate (so the RP will trust it):

```sh
sudo cp "tools/rpt.crt" "/usr/local/share/ca-certificates/"
sudo update-ca-certificates
```

Mount the tmpfs (optional):

```sh
./1-setup.sh
```

Run tests as many times as needed:

```sh
# See "Arguments" below.
RP="fort" ./2-test.sh
```

Drop the tmpfs (if you mounted it):

```sh
./3-cleanup.sh
```

Uninstall the RRDP certificate:

```sh
sudo rm "/usr/local/share/ca-certificates/rpt.crt"
sudo update-ca-certificates
```

## Arguments

`./2-test.sh`'s behavior can be tweaked by several environment variables.

(They are environment variables instead of args because I like to override their defaults and share them with other projects by way of `~/.bashrc`.)

### `$RP`

The "simple name" of the Relying Party you want to test. (Each test run only targets one RP.) At present, the available values are `fort2`, `routinator`, `rpki-client` and `rpki-prover`.

There is no default; defining this variable is mandatory.

If there's an open source implementation I've missed, let me know. If you can provide the configuration file ([sample](tools/fort.sh)), all the better.

### `$FORT`

The string that can be used to invoke Fort 2's binary. It's optional; defaults to `fort`.

You can override this to point to an installation outside of `$PATH`. In particular, I use it it to test Fort's development builds:

```sh
RP=fort2 FORT=~/git/fort/src/fort ./2-test.sh
```

Fort versions 2.0.0+ can be tested.

### `$ROUTINATOR`

Routinator's equivalent to [`$FORT`](#fort). Optional; defaults to `routinator`.

### `$RPKI_CLIENT`

rpki-client's equivalent to [`$FORT`](#fort). Optional; defaults to `rpki-client`.

### `$RPKI_PROVER`

RPKI Prover's equivalent to [`$FORT`](#fort). Optional; defaults to `rpki-prover`.

### `MEMCHECK`

Controls the inclusion of the memory leak checks (ie. Valgrind). Nonzero means "included," zero means "excluded."

Memory leak checks are only useful in test runs involving RPs written in memory-unsafe languages. In these cases, disabling these checks results in a **much** faster (albeit incomplete) test run.

`$MEMCHECK` is optional. Its default value depends on `$RP`:

- Fort: 1
- Routinator: 0
- rpki-client: 1
- rpki-prover: 0

If you exclude memory leak checks, you can ditch the `valgrind` dependency.
