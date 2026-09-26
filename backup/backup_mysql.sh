#!/bin/bash

# Make the pipeline below fail if mysqldump fails, even though gzip
# (the last command in the pipe) still exits 0.
set -o pipefail

DATEBCK=$(date +%Y%m%d)
SRV=$(hostname)
DB_TYPE=mysql

# Connection/host details and credentials file, overridable via
# environment variables.
DB_HOST="${DB_HOST:-localhost}"
DB_USER="${DB_USER:-root}"
BACKUP_DIR="${BACKUP_DIR:-/srv}"
MYSQL_INFO_FILE="${MYSQL_INFO_FILE:-/root/info/mysql.info}"

. "${MYSQL_INFO_FILE}"

# MySQL options:
# -f, --force Continue even if we get an SQL error.
# -c, --complete-insert Use complete insert statements.
# -C, --compress Use compression in server/client protocol.
# -A, --all-databases Dump all the databases. This will be same as --databases with all databases selected.
# -l, --lock-tables Lock all tables for read.

echo "Starting database backup..."
if mysqldump --events -f -c -C -A -h "${DB_HOST}" -u "${DB_USER}" $PASSWD -l | gzip > "${BACKUP_DIR}/mysql-$SRV-$DATEBCK.sql.gz"; then
    echo "Database backup completed."
else
    echo "Database backup failed." >&2
    exit 1
fi

