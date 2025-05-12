#!/bin/bash

export ORACLE_SID={{ databases.primary.db_sid }}
export ORACLE_HOME={{ databases.primary.oracle_db_home }}
export PATH={{ databases.primary.oracle_db_home }}/bin:$PATH

MASTER_LOG="{{ done_dir }}/primary_info.log"
FAILURE_LOG="{{ done_dir }}/primary_info_fail.log"

# Ensure log files are empty before running
> "$MASTER_LOG"
> "$FAILURE_LOG"

# Run the query to fetch DBID and control file location
sqlplus -s / as sysdba <<SQL | tee -a "$MASTER_LOG"
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SET LINESIZE 1000
SET TRIMOUT ON
SET TRIMSPOOL ON

-- Fetch DBID
SELECT 'DBID:' || dbid FROM v\$database;

EXIT;
SQL

# Capture SQL*Plus exit status
sqlplus_exit_code=$?

# Check if the SQL*Plus command was successful
if [[ $sqlplus_exit_code -ne 0 ]]; then
    echo "ERROR: SQL*Plus command failed with exit status $sqlplus_exit_code. Check logs for details." | tee -a "$FAILURE_LOG"
    exit 1
fi

# Extracting values using grep and awk
DBID=$(grep "DBID:" "$MASTER_LOG" | awk -F ':' '{print $2}')

if [[ -n "$DBID" ]]; then
    echo "DBID: $DBID"
    echo "$DBID" > "{{ scripts_dir }}/dbid.txt"
else 
    echo "ERROR: DBID is empty!" | tee -a "$FAILURE_LOG"
fi

# Output the values
echo "DBID: $DBID"

# Save the values to a file for later use
echo "$DBID" > "{{ scripts_dir }}/dbid.txt"

# Check for failures and exit accordingly
if [[ -s "$FAILURE_LOG" ]]; then
    cat "$FAILURE_LOG"
    rm -f "$FAILURE_LOG"
    exit 1
fi

echo "DBID and control file location fetched successfully!" | tee -a "$MASTER_LOG"
rm -f "$FAILURE_LOG"
exit 0