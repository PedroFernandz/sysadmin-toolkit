#!/usr/bin/env python3
"""Interactive MySQL/MariaDB backup tool.

Lists the databases visible to a MySQL user and creates a plain .sql dump
of the one selected interactively.

Configuration (all optional, environment variables):
    MYSQL_BIN       Path/name of the mysql client (default: mysql)
    MYSQLDUMP_BIN   Path/name of mysqldump (default: mysqldump)
    MYSQL_HOST      Host to connect to (default: client default, e.g. local socket)
    MYSQL_PORT      Port to connect to (default: client default, e.g. 3306)
    BACKUP_DIR      Directory where the .sql file is written (default: current directory)
"""

import getpass
import os
import stat
import subprocess
import sys
import tempfile
from datetime import datetime

MYSQL_BIN = os.environ.get("MYSQL_BIN", "mysql")
MYSQLDUMP_BIN = os.environ.get("MYSQLDUMP_BIN", "mysqldump")
MYSQL_HOST = os.environ.get("MYSQL_HOST", "")
MYSQL_PORT = os.environ.get("MYSQL_PORT", "")
BACKUP_DIR = os.environ.get("BACKUP_DIR", ".")

# Schemas that are never offered as a backup target.
EXCLUDED_DATABASES = {"information_schema", "performance_schema"}


def connection_args():
    """Extra mysql/mysqldump connection flags, only added when explicitly set."""
    args = []
    if MYSQL_HOST:
        args += ["-h", MYSQL_HOST]
    if MYSQL_PORT:
        args += ["-P", MYSQL_PORT]
    return args


def make_defaults_file(user, password):
    """Create a temporary MySQL defaults-extra-file (mode 0600) with the
    credentials, so the password never appears on the command line or in
    a shell string (it is only ever read from this file by the mysql
    client itself).
    """
    fd, path = tempfile.mkstemp(prefix="mysql_backup_", suffix=".cnf")
    os.chmod(path, stat.S_IRUSR | stat.S_IWUSR)
    with os.fdopen(fd, "w") as f:
        f.write("[client]\n")
        f.write(f"user={user}\n")
        f.write(f"password={password}\n")
    return path


def run_mysql(defaults_file, sql):
    """Run a SQL statement through the mysql client using an argument list
    (no shell=True, no interpolated command string)."""
    cmd = [MYSQL_BIN, f"--defaults-extra-file={defaults_file}"]
    cmd += connection_args()
    cmd += ["-N", "--execute", sql]
    return subprocess.run(cmd, capture_output=True, text=True)


def list_databases(defaults_file):
    result = run_mysql(defaults_file, "SHOW DATABASES;")
    if result.returncode != 0:
        return None
    names = [line.strip() for line in result.stdout.splitlines()]
    return [db for db in names if db and db not in EXCLUDED_DATABASES]


def main():
    mysql_user = input("Please enter your MySQL user: ").strip()
    mysql_password = getpass.getpass("Please enter your MySQL password: ")

    defaults_file = make_defaults_file(mysql_user, mysql_password)
    try:
        check = run_mysql(defaults_file, "SELECT 1;")
        if check.returncode != 0:
            print("Invalid MySQL user or password. Please check your credentials. Exiting.")
            return 1

        databases = list_databases(defaults_file)
        if not databases:
            print("Error connecting to MySQL. Please check your username and password. Exiting.")
            return 1

        print("List of databases:")
        db_map = {}
        for i, db in enumerate(databases, start=1):
            print(f"{i} - {db}")
            db_map[i] = db

        selection = input(
            "Please select the database you want to backup (enter the associated number): "
        ).strip()
        if not selection.isdigit() or int(selection) not in db_map:
            print("Invalid number. Exiting.")
            return 1
        selected_db = db_map[int(selection)]

        os.makedirs(BACKUP_DIR, exist_ok=True)
        backup_file = os.path.join(
            BACKUP_DIR, f"{selected_db}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"
        )

        dump_cmd = [MYSQLDUMP_BIN, f"--defaults-extra-file={defaults_file}"]
        dump_cmd += connection_args()
        dump_cmd += [selected_db]

        with open(backup_file, "w") as out:
            result = subprocess.run(dump_cmd, stdout=out, stderr=subprocess.PIPE, text=True)

        if result.returncode == 0:
            print(f"Backup of database '{selected_db}' was successful. File: {backup_file}")
            return 0

        print(f"Error while backing up database '{selected_db}'.")
        if result.stderr:
            print(result.stderr.strip(), file=sys.stderr)
        if os.path.exists(backup_file):
            os.remove(backup_file)
        return 1
    finally:
        os.remove(defaults_file)


if __name__ == "__main__":
    sys.exit(main())
