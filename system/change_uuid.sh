#!/bin/bash

if [ ${#} -lt 1 ]; then
    echo "Usage: ${0} <disk_path1> [disk_path2] ..."
    exit 1
fi

for DISK in "${@}"; do
    if [ ! -b "${DISK}" ]; then
        echo "Error: ${DISK} is not a valid block device."
        exit 2
    fi

    OLD_UUID=$(blkid -s UUID -o value "${DISK}")
    NEW_UUID=$(uuidgen)
    tune2fs -U "${NEW_UUID}" "${DISK}"
    echo "UUID changed on ${DISK}: ${OLD_UUID} -> ${NEW_UUID}"

    # Files matching this pattern are searched for the old UUID and updated,
    # overridable via environment variable.
    GRUB_FILES="${GRUB_FILES:-/etc/grub*}"
    for file in ${GRUB_FILES}; do
        if grep -q "${OLD_UUID}" "${file}"; then
            echo "Updating UUID in ${file}"
            sed -i "s/${OLD_UUID}/${NEW_UUID}/g" "${file}"
        fi
    done
done

echo "Process completed."
