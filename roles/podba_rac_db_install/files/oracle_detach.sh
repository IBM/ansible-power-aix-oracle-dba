#!/usr/bin/ksh93
# Copyright (c) IBM Corporation 2024
# This script performs Oracle silent installation along with release update.

db_oracle_home="$1"
ora_inventory="$2"
oh="$3"
temp_dir="$4"
db_oracle_home_escaped=$(echo "$db_oracle_home" | sed 's/\//\\\//g')
db_oracle_home_name=$(sed -n "/LOC=\"$db_oracle_home_escaped\"/s/.*HOME NAME=\"\([^\"]*\)\".*/\1/p" "$ora_inventory/ContentsXML/inventory.xml")
install_log="$temp_dir/logs/oracle_detach.$oh.out"

# Main

# Detach Home for [FATAL] [INS-35955]

if [ ! -f "$temp_dir/done/oracle.install.$oh.done" ]; then
    echo "INFO: Oracle installation not done, skipping Oracle home detach."
    exit 0
fi

if [ -f "$temp_dir/done/oracle.rac.install.$oh.done" ]; then
    echo "INFO: Oracle RAC installation completed, skipping Oracle home detach."
    exit 0
fi

if [ -f "$temp_dir/done/oracle.home.detach.$oh.done" ]; then
    echo "INFO: Oracle home already detached. Skipping this step."
    exit 0
fi

# Perform the Oracle home detachment 
echo "$(date) $db_oracle_home/oui/bin/runInstaller -silent -detachHome ORACLE_HOME=$db_oracle_home ORACLE_HOME_NAME=$db_oracle_home_name" >> $install_log
export SKIP_ROOTPRE="TRUE"
$db_oracle_home/oui/bin/runInstaller -silent -detachHome ORACLE_HOME="$db_oracle_home" ORACLE_HOME_NAME="$db_oracle_home_name" >> $install_log 2>&1

# Check if detachment was successful
if grep -q "'DetachHome' was successful." $install_log && ! grep -q "$db_oracle_home" "$ora_inventory/ContentsXML/inventory.xml"; then
    touch "$temp_dir/done/oracle.home.detach.$oh.done"
    echo "Oracle home detach completed successfully and removed from inventory.xml."
else
    echo "ERROR: Oracle home not found or could not be detached from inventory. See $install_log for details."
    exit 1
fi

exit 0
