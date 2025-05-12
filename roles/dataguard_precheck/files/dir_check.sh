#!/bin/bash

MASTER_LOG="{{ done_dir }}/dir_check.log"
FAILURE_LOG="{{ done_dir }}/dir_check_fail.log"

# Ensure log files are empty before running
> "$MASTER_LOG"
> "$FAILURE_LOG"

dir_to_check="$1"

# Check if the directory exists
if [ -d "$dir_to_check" ]; then
    echo "$dir_to_check Directory exists." | tee -a "$MASTER_LOG"
    if [ -r "{{ databases.standby.oracle_db_base }}/admin" ] && [ -w "{{ databases.standby.oracle_db_base }}/admin" ] && [ -x "{{ databases.standby.oracle_db_base }}/admin" ]; then
        echo "$dir_to_check Directory has read and write & execute permissions" | tee -a "$MASTER_LOG"
    else
        echo "$dir_to_check Directory permissions are not correct .  Please refer readme prerequisites section for more details" | tee -a "$FAILURE_LOG"
    fi
else
    echo "Directory does not exist." | tee -a "$FAILURE_LOG"
fi

# Check for failures and exit accordingly
if [[ -s "$FAILURE_LOG" ]]; then
    cat "$FAILURE_LOG"
    rm -f "$FAILURE_LOG"
    exit 1
fi

echo "$ORACLE_BASE/admin have read/write permission to oracle user on standby host." | tee -a "$MASTER_LOG"
rm -f "$FAILURE_LOG"
exit 0