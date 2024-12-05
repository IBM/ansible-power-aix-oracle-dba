#!/usr/bin/ksh93
# Copyright (c) IBM Corporation 2024
# This script performs Oracle silent installation along with release update.

db_oracle_home="$1"
ora_inventory="$2"
temp_dir="$3"
db_oracle_home_escaped=$(echo "$db_oracle_home" | sed 's/\//\\\//g')
db_oracle_home_name=$(sed -n "/LOC=\"$db_oracle_home_escaped\"/s/.*HOME NAME=\"\([^\"]*\)\".*/\1/p" "$ora_inventory/ContentsXML/inventory.xml")
install_log="$temp_dir/logs/oracle_detach.out"

# Main

# Detach Grid Home for [FATAL] [INS-41881] or [INS-40110]

if [ ! -f "$temp_dir/done/grid.install.done" ]; then
    echo "INFO: Grid installation not done, skipping Grid home detach."
    exit 0
fi

if [ -f "$temp_dir/done/grid.upgrade.done" ]; then
    echo "INFO: Grid Upgrade completed, skipping Grid home detach."
    exit 0
fi

if [ -f "$temp_dir/done/grid.home.detach.done" ]; then
    echo "INFO: Grid home already detached. Skipping this step."
    exit 0
fi

# Perform the Oracle home detachment 
echo "$(date) $db_oracle_home/oui/bin/runInstaller -silent -detachHome ORACLE_HOME=$db_oracle_home ORACLE_HOME_NAME=$db_oracle_home_name" >> $install_log
export SKIP_ROOTPRE="TRUE"
$db_oracle_home/oui/bin/runInstaller -silent -detachHome ORACLE_HOME="$db_oracle_home" ORACLE_HOME_NAME="$db_oracle_home_name" >> $install_log 2>&1

# Check if detachment was successful
if ! grep -q "$db_oracle_home" "$ora_inventory/ContentsXML/inventory.xml"; then
    touch "$temp_dir/done/grid.home.detach.done"
    echo "Grid home detach completed successfully and removed from inventory.xml."
else
    echo "ERROR: Grid home not found or could not be detached from inventory. See $install_log for details."
    exit 1
fi

exit 0
