#!/usr/bin/env bash

# This file is subject to the terms and conditions defined in
# file 'LICENSE', which is part of this source code package.
#
# (c) Christian Mahner 2021, v0.9

if [ "$UID" -ne "0" ]; then
  echo "Error: collector must be run as root. Running with uid: $UID"
  exit 1
fi

if [ -z "$(which snapraid)" ]; then
  echo "Error: Could not find snapraid binary. Make sure snapraid is available from $PATH"
  exit 1
fi

# call snapraid smart to get probability values
snapraidOutput=$(snapraid smart)

# truncate output
resultTable="$(echo "$snapraidOutput" | tail -n +6 | head -n -5)"

# get list of hard drives
disks=$(echo "$resultTable" | awk '{print $7}' | sort | xargs)

echo "# HELP snapraid_disk_fail_probability fail probability for individual failing disk within the next year based on SMART vals calculated by snapraid"
echo "# TYPE snapraid_disk_fail_probability gauge"

for disk in $disks
do
  # parse probability value for each disk
  fp=$(echo "$resultTable" | grep "$disk" | awk '{print $4}')
  if [[ ${fp::-1} =~ ^[0-9]+$ ]]; then
    fp=${fp::-1}
  else
    fp=0
  fi

  echo "snapraid_disk_fail_probability{disk=\"$disk\"} $fp"
done

echo "# HELP snapraid_total_fail_probability fail probability for one disk failing withing the next year"
echo "# TYPE snapraid_total_fail_probability gauge"

tfp="$(echo "$snapraidOutput" | tail -n +6 | tail -n 1 | awk '{print $NF}' | grep -oP '[0-9]+')"

echo "snapraid_total_fail_probability $tfp"