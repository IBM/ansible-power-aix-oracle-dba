#!/bin/bash

# Set environment variables
export ORACLE_SID={{ databases[database_name].db_sid }}
export ORACLE_HOME={{ databases[database_name].oracle_db_home }}
export PATH={{ databases[database_name].oracle_db_home }}/bin:$PATH
standby_unique_name="{{ databases[database_name].db_unique_name}}"
tnsnames_file="$ORACLE_HOME/network/admin/tnsnames.ora"

MASTER_LOG="{{ done_dir }}/primary_post_restore.log"
FAILURE_LOG="{{ done_dir }}/primary_post_restore_failure.log"

# Ensure log files are empty before running
> "$MASTER_LOG"
> "$FAILURE_LOG"

# Set log_archive_dest_2 dynamically based on data protection modes
case "{{ dataguard_protection_mode | lower }}" in
    maximum_performance)
        dataguard_protection_mode="PERFORMANCE"
        ;;
    maximum_availability)
        dataguard_protection_mode="AVAILABILITY"
        ;;
    maximum_protection)
        dataguard_protection_mode="PROTECTION"
        ;;
    *)
        echo "Invalid data protection mode! Provide data protection modes out of three: maximum_availability, maximum_performance, or maximum_protection." | tee -a "$FAILURE_LOG"
        exit 1
        ;;
esac

# Change protection Mode in primary
sqlplus -s / as sysdba <<SQL | tee -a "$MASTER_LOG"
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SET LINESIZE 1000
SET TRIMOUT ON
SET TRIMSPOOL ON
SET ECHO ON;
SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
WHENEVER OSERROR EXIT FAILURE;
ALTER DATABASE SET STANDBY DATABASE TO MAXIMIZE ${dataguard_protection_mode};
-- Fetch dataguard protection mode
SELECT 'PROTECTION_MODE:' || PROTECTION_MODE from v\$database;
EXIT;
SQL

# Capture SQL*Plus exit status
sqlplus_exit_code=$?

# Read protection mode from log file
PROTECTION_MODE=$(awk -F ':' '/PROTECTION_MODE:/ {print $2}' "$MASTER_LOG" | sed 's/MAXIMUM //')

# Validate protection mode and SQL*Plus exit status
if [[ "$PROTECTION_MODE" == "${dataguard_protection_mode}" && $sqlplus_exit_code -eq 0 ]]; then
    echo "Dataguard successfully configured with PROTECTION_MODE: MAXIMUM ${dataguard_protection_mode}" | tee -a "$MASTER_LOG"
    touch "{{ done_dir }}/dataguard.success"
else 
    echo "ERROR: Dataguard configuration failed, verify logs" | tee -a "$FAILURE_LOG"
    exit 1
fi

# Check for failures and exit accordingly
if [[ -s "$FAILURE_LOG" ]]; then
    cat "$FAILURE_LOG"
    rm -f "$FAILURE_LOG"
    exit 1
fi

echo "Dataguard configured successfully" | tee -a "$MASTER_LOG"
touch "{{ done_dir }}/dataguard.success"
rm -f "$FAILURE_LOG"
exit 0
