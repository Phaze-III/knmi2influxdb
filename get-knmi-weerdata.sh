#!/bin/sh

# Documentation: https://www.knmi.nl/kennis-en-datacentrum/achtergrond/data-ophalen-vanuit-een-script
#
# Deviations from documentation:
#   - The hour-field in the result is 'H', not 'HH' as shown.
#     This script converts 'H' to 'HH' to keep in line with the
#     original format used. 'HH' is also used in the archived data.
#   - End hour has to be specified as 00 to get the last hour '24'

# TODO
# - Use and store intermediate files

KNMIURL="https://daggegevens.knmi.nl/klimatologie/uurgegevens"

export INFLUXDB_DATABASE=knmi
export INFLUXDB_HOST=localhost
export INFLUXDB_PORT=8086

NDAYS=5

# Set begin and end date to yesterday
if date --version >/dev/null 2>&1
then
   # GNU date
   StartDate=$(date -d "${NDAYS} days ago" "+%Y%m%d")
   EndDate=$(date "+%Y%m%d")
else
   # BSD date
   StartDate=$(date -j -v-${NDAYS}d "+%Y%m%d")
   EndDate=$(date -j "+%Y%m%d")
fi

# Override automatic begin- and end-dates by changing and uncommenting a StartDate
# or EndDate assignment. Can be used when bulk-importing historical data. Data is
# fetched per day to stay within InfluxDB limits.

#StartDate=20211120
#EndDate=20211118

# Vars can be ALL or a subset
# ALL returns duplicate field names for HH and YYYYMMDD since around 20240125
# without data in the corresponding columns. The duplicate names are filtered
# out in the sed pre-parser.

Vars="ALL"
# Vars="WIND:TEMP:SUNR:PRCP:P:VICL:WW:IX:WEER" # Same set and order as ALL

# Sensor can be ALL or a subset
# 350 370 375 | 350:370:375 | ALL

for Sensor in ALL
do
   Date=${StartDate}
   while [ ${Date} -le ${EndDate} ]
   do
      curl -s --data "stns=${Sensor}&vars=${Vars}" \
              --data "start=${Date}01" \
              --data "end=${Date}00" \
                 ${KNMIURL} |\
        tr -d '\r' | sed -e 's/^# STN,YYYYMMDD/STN,YYYYMMDD/' \
                         -e 's/,   HH,YYYYMMDD$//' \
                         -e '/^\"*#/d' \
                         -e 's/,H,/,HH,/' |\
        tr -d ' ' | knmi-to_line_protocol.py | to_influx_db.sh
      if date --version >/dev/null 2>&1
      then
         # GNU date
         Date=$(date -d "$(echo ${Date} | sed -e 's/^\([0-9][0-9][0-9][0-9]\)\([0-9][0-9]\)\([-9][0-9]\)/\1-\2-\3/') +1 day" "+%Y%m%d")
      else
         Date=$(date -j -v+1d -f "%Y%m%d" "${Date}" "+%Y%m%d")
      fi
   done
done
