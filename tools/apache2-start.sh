#!/bin/sh

. tools/vars.sh

echo "Starting apache2 ($APACHE2) from ${PWD}"
$APACHE2 -f "${PWD}/sandbox/apache2/apache2.conf"
