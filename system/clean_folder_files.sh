#!/bin/bash

function print_help {
  echo "Usage: script [folder_to_clean allowed path] [maxsizefolder in gb or anysize] [min_allowed_file_age in days]"
}

folder=${1}

# Max allowed folder size, in GB
max_folder_size=${2}

# Min allowed age to keep in the folder, in days
file_min_allowed_age=${3}

# File listing the folders this script is allowed to clean, overridable
# via environment variable.
allowed_folders_file="${ALLOWED_FOLDERS_FILE:-/root/bin/custom/clean-folder_files.allowed}"

allowed_folders=$(cat "${allowed_folders_file}")

if [ -n "${folder}" ] && [ -n "${max_folder_size}" ] && [ -n "${file_min_allowed_age}" ] && echo "${allowed_folders}" | grep -q -w "${folder}"; then
    # If max_folder_size is "anysize", always delete files based on age.
    if [ "${max_folder_size}" == "anysize" ]; then
        find "${folder}" -type f -mtime +"${file_min_allowed_age}" -exec rm {} \;
    else
        # Convert max_folder_size (GB) to kilobytes
        max_size_kb=$((max_folder_size * 1024 * 1024))
        dir_size_kb=$(du -sk "${folder}" | awk '{print $1}')

        # If directory size is greater than max_size_kb, delete files based on age.
        if [ "${dir_size_kb}" -gt "${max_size_kb}" ]; then
            find "${folder}" -maxdepth 1 -type f -mtime +"${file_min_allowed_age}" -exec rm -f "{}" \;
        fi
    fi
else
    print_help
    exit 1
fi
