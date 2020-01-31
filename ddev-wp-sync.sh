#!/usr/bin/env bash
#
# Simple Files and DB dump/sync script for DDEV local WordPress development.
#
# License: MIT
#
# Instructions:
# 1. Place this file in your local DDEV project root, chmod 440
# 2. Gitignore the file
# 3. Modify the variables below to fit your local and remote environments
# 4. If your WordPress database has a custom prefix, modify line 65
# 5. Run this script from your local project root
# 6. Enter the database password when prompted
# 7. The script will execute. If you encounter an error, and the script fails 
#    or exits unexpectedly, check that your variables are set up correctly
#    (i.e., absolute paths to files, proper user and host names, etc.)

###############################################################################

### Variables ###

# Set to 0 to skip
DO_DB=1
DO_FILES=1
# Set based on your production and local setup
HOST="remote_host_ip_or_url"
USER="db_username"
DB="db_name"
NAME="remote_ssh_username"
PROD="live_site_url"
LOCAL="ddev_local_site_url"
HOST_FILES="live_site_files_path"
LOCAL_FILES="local_site_files_path"

###############################################################################

# On exit clean up the database dump file from local
cleanup() {
  rm $DB.sql.gz
}

# If a simple command fails, stop script execution 
set -e

# Hide inputs on password prompt
stty -echo

# DB sync
if [[ $DO_DB = 1 ]];
  then
    # Dump the database from remote server to local
    echo "Dumping $DB from $HOST to $DB.sql.gz"
    ssh $NAME@$HOST "mysqldump -u $USER -p --verbose $DB | gzip -9" > $DB.sql.gz 
    echo "DB dump complete"
    sleep 2

    # Import dump into DDEV
    echo "Importing $DB.sql.gz to DDEV local DB"
    ddev import-db --src="$DB.sql.gz"
    echo "DB import successful"
    sleep 2

    # Swap out prod urls in database for local url
    echo "Replacing production URL with DDEV local site URL in database"
    ddev . wp search-replace $PROD $LOCAL 'wp_options' # <-- Set this to your DB's custom prefix
    echo "DB sync complete"
    sleep 2
  else
    echo "DB not synced..."
fi

# File sync
if [[ $DO_FILES = 1 ]];
  then
    # Rsync the contents of WP uploads directory down from remote server
    echo "Syncing files from $HOST to DDEV local site"
    rsync -chavzP --stats $NAME@$HOST:$HOST_FILES $LOCAL_FILES
    echo "Files sync complete"
    sleep 2
  else
    echo "Files not synced..."
fi

echo "Sync complete, you're ready to start developing locally"

trap cleanup EXIT SIGINT SIGTERM SIGHUP
