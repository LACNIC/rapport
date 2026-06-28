#!/bin/sh

REDIR_DIR="sandbox/apache2-redirect"
REDIR_CONF="$REDIR_DIR/apache2.conf"
REDIR_PIDFILE="$REDIR_DIR/apache2.pid"
NORMAL_PIDFILE="sandbox/apache2/apache2.pid"

wait_for_file() {
	# $1 = path to wait for, $2 = timeout in tenths of a second (100 = 10s)
	path_file="$1"
	timeout=100
	n=0
	while [ ! -f "$path_file" ]; do
		n=$((n + 1))
		test "$n" -le "$timeout" || return 1
		sleep 0.1
	done
	return 0
}

wait_for_pid_gone() {
	# $1 = pid, $2 = timeout in tenths of a second (100 = 10s)
	pid="$1"
	timeout=100
	n=0
	while kill -0 "$pid" 2> /dev/null; do
		n=$((n + 1))
		test "$n" -le "$timeout" || return 1
		sleep 0.1
	done
	return 0
}

start_redirect_apache() {
	v_normal_pid=""
	test -f "$NORMAL_PIDFILE" && v_normal_pid="$(cat "$NORMAL_PIDFILE")"

	tools/apache2-stop.sh \
		|| fail "Could not stop the shared Apache instance; see above."
	if [ -n "$v_normal_pid" ]; then
		wait_for_pid_gone "$v_normal_pid" \
			|| fail "Timeout waiting for the shared Apache instance to exit."
	fi

	mkdir -p "$REDIR_DIR/logs"
	cat > "$REDIR_CONF" <<- CONF
		ServerName localhost

		ServerRoot $PWD/$REDIR_DIR
		PidFile apache2.pid

		ErrorLog logs/main.log
		LogLevel info

		LoadModule mpm_event_module /usr/lib/apache2/modules/mod_mpm_event.so
		LoadModule authz_core_module /usr/lib/apache2/modules/mod_authz_core.so
		LoadModule ssl_module /usr/lib/apache2/modules/mod_ssl.so
		LoadModule alias_module /usr/lib/apache2/modules/mod_alias.so

		Listen 8443
		<VirtualHost *:8443>
			DocumentRoot $PWD/sandbox/apache2/content
			CustomLog $PWD/$APACHE_REQLOG "%U%q %>s"
			SSLEngine on
			SSLCertificateFile $PWD/custom/rpt.crt
			SSLCertificateKeyFile $PWD/custom/rpt.key

			Redirect 302 /$TEST/notification.xml https://attacker.invalid/$TEST/notification.xml
		</VirtualHost>
	CONF

	"$APACHE2" -f "$PWD/$REDIR_CONF" \
		|| fail "Could not start the throwaway redirect Apache instance."
	wait_for_file "$REDIR_PIDFILE" \
		|| fail "Timeout waiting for the throwaway Apache instance to start."
}

restore_normal_apache() {
	if [ -f "$REDIR_PIDFILE" ]; then
		kill "$(cat "$REDIR_PIDFILE")" 2> /dev/null
		wait_for_pid_gone "$(cat "$REDIR_PIDFILE")" 2> /dev/null
	fi
	tools/apache2-start.sh
	wait_for_file "$NORMAL_PIDFILE" \
		|| echo "$TESTID warning: shared Apache instance did not restart cleanly" 1>&2
}