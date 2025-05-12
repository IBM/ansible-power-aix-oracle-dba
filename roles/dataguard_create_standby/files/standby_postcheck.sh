#!/bin/bash

# Set environment variables
export ORACLE_SID={{ databases[database_name].db_sid }}
export ORACLE_HOME={{ databases[database_name].oracle_db_home }}
export PATH={{ databases[database_name].oracle_db_home }}/bin:$PATH
tnsnames_dir="${ORACLE_HOME}/network/admin/{{ databases[database_name].db_unique_name }}_rman_listener"

MASTER_LOG="{{ done_dir }}/standby_post_restore.log"
FAILURE_LOG="{{ done_dir }}/standby_post_restore_failure.log"
RESTORE_LOG_FILE="{{ done_dir }}/standby_rman_restore.log"
PFILE=${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora
TMP_FILE="${PFILE}.tmp"

# Ensure log files are empty before running
> "$MASTER_LOG"
> "$FAILURE_LOG"
# Convert 'with_backup' variable to lowercase for consistency
WITH_BACKUP="$(echo {{ with_backup }} | tr '[:upper:]' '[:lower:]')"

if [[ "$WITH_BACKUP" == "true" ]]; then
    # Check if RMAN Restore was successful
    if ! grep -q "Finished recover at" "$RESTORE_LOG_FILE"; then
        echo "ERROR: RMAN Recover failed or incomplete. Exiting..." | tee -a "$FAILURE_LOG"
        exit 1
    fi

    # Extract Controlfile Location from RMAN Logs
    CONTROLFILE_PATH=$(grep "output file name=" "$RESTORE_LOG_FILE" | awk -F '=' '{print $2}' | tr -d ' ')
    if [[ -z "$CONTROLFILE_PATH" ]]; then
        echo "ERROR: Controlfile location not found in RMAN logs." | tee -a "$FAILURE_LOG"
        exit 1
    fi

    # Update PFILE with new Controlfile Location
    awk 'tolower($0) !~ /(control_files)/' "$PFILE" > "$TMP_FILE"
    echo "*.control_files = '$CONTROLFILE_PATH'" >> "$TMP_FILE"

    # Replace the original file
    mv "$TMP_FILE" "$PFILE"

    # Create SPFILE from PFILE on standby database
sqlplus -s / as sysdba <<SQL | tee -a "$MASTER_LOG"
CREATE SPFILE FROM PFILE='$PFILE';
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER SYSTEM REGISTER;
ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO SCOPE=BOTH SID='*';
EXIT;
SQL

    # Capture SQL*Plus exit status
    sqlplus_exit_code=$?

    # Validate SQL*Plus exit status
    if [[ $sqlplus_exit_code -ne 0 ]]; then
        echo "ERROR: SQL*Plus command failed. Check logs for details." | tee -a "$FAILURE_LOG"
        exit 1
    fi

elif [[ "$WITH_BACKUP" == "false" ]]; then
    export TNS_ADMIN="${tnsnames_dir}"
    $ORACLE_HOME/bin/lsnrctl stop rman_listener >> "$MASTER_LOG" 2>&1

    if [[ $? -eq 0 ]]; then
        echo "RMAN Listener stop successful" | tee -a "$MASTER_LOG"
    else
        echo "RMAN Listener stop failed" | tee -a "$FAILURE_LOG"
        exit 1
    fi

    # Verify if RMAN Listener is stopped
    if ! ps -ef | grep "[t]ns" | grep -q "rman_listener"; then
        echo "RMAN Listener successfully stopped" | tee -a "$MASTER_LOG"
    else
        echo "ERROR: RMAN Listener still running" | tee -a "$FAILURE_LOG"
        exit 1
    fi

    # Remove RMAN Listener directory
    rm -rf "${tnsnames_dir}"

    # Validate if directory is removed
    if [[ -d "${tnsnames_dir}" ]]; then
        echo "ERROR: Failed to remove directory ${tnsnames_dir}" | tee -a "$FAILURE_LOG"
        exit 1
    else
        echo "RMAN Listener directory removed successfully" | tee -a "$MASTER_LOG"
    fi

    unset TNS_ADMIN
     # Restart standby database for sanity
sqlplus -s / as sysdba <<SQL | tee -a "$MASTER_LOG"
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER SYSTEM SET LOCAL_LISTENER='(ADDRESS=(PROTOCOL=TCP)(HOST={{ standby_host }})(PORT={{ databases.standby.listener_port }}))';
ALTER SYSTEM REGISTER;
ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO SCOPE=BOTH SID='*';
EXIT;
SQL

    # Capture SQL*Plus exit status
    sqlplus_exit_code=$?

    # Validate SQL*Plus exit status
    if [[ $sqlplus_exit_code -ne 0 ]]; then
        echo "ERROR: SQL*Plus command failed. Check logs for details." | tee -a "$FAILURE_LOG"
        exit 1
    fi
else
    echo "ERROR: Invalid value for 'with_backup'. Please provide 'true' or 'false'." | tee -a "$FAILURE_LOG"
    exit 1
fi

# Check for failures and exit accordingly
if [[ -s "$FAILURE_LOG" ]]; then
    cat "$FAILURE_LOG"
    rm -f "$FAILURE_LOG"
    exit 1
fi

echo "Dataguard recovery process started successfully" | tee -a "$MASTER_LOG"
touch "{{ done_dir }}/post_restore.success"
rm -f "$FAILURE_LOG"
exit 0