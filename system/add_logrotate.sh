#!/bin/bash

if [ "${#}" -ne 2 ]; then
    echo "Usage: ${0} <file_name> <container_value>" >&2
    exit 1
fi

file_name="${1}"
containers="${2}"

# Base directory holding the per-application logs and tools, overridable
# via environment variable.
efs_base_dir="${EFS_BASE_DIR:-/media/efs/directory}"

logrotate_conf="./${file_name}"

cat << EOF > "${logrotate_conf}"
${efs_base_dir}/logs/${file_name}/mail/*${containers}*/*log
${efs_base_dir}/logs/${file_name}/tomcat/*${containers}*/*log
${efs_base_dir}/logs/${file_name}/zabbix/*${containers}*/*log
${efs_base_dir}/logs/${file_name}/elasticsearch/*${containers}*/*log
${efs_base_dir}/logs/${file_name}/mongodb/*${containers}*/*log
${efs_base_dir}/logs/${file_name}/samba/*${containers}*/*log
${efs_base_dir}/logs/${file_name}/redis/*${containers}*/*log
${efs_base_dir}/logs/${file_name}/proftpd/*${containers}*/*log
${efs_base_dir}/logs/${file_name}/httpd/*${containers}*/*log
${efs_base_dir}/logs/${file_name}/fpm/*${containers}*/*log
${efs_base_dir}/logs/${file_name}/mariadb/*${containers}*/*log
${efs_base_dir}/logs/${file_name}/laravel/*${containers}*/*log
${efs_base_dir}/logs/${file_name}/ssh/*${containers}*/*log
${efs_base_dir}/logs/${file_name}/zabbix/*${containers}*/*log {
    daily
    rotate 520
    dateext
    missingok
    sharedscripts
    compress
    delaycompress
    postrotate
        #send logrotate
        ${efs_base_dir}/${file_name}/tools/tomcat-rotate-logs.sh > /dev/null
        #archive tomcat logs
        ${efs_base_dir}/${file_name}/tools/tomcat-archive-logs.sh > /dev/null
        #todo: archive mail,zabbix and api logs
        rm -f ${efs_base_dir}/logs/${file_name}/logrotate*-20*
        date >> ${efs_base_dir}/logs/${file_name}/logrotate.log
    endscript
}
EOF

echo "The file ${logrotate_conf} has been created successfully."
