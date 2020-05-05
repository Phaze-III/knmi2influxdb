#!/bin/sh

# TODO
# - Use and store intermediate files
# - Split larger (> 100000 lines) influx input files in smaller chunks

export INFLUXDB_DATABASE=knmi
export INFLUXDB_HOST=localhost

# Set begin date to yesterday, end date to today
if date --version >/dev/null 2>&1
then
   # GNU date
   byear=$(date -d "1 days ago" "+%Y")
   bmonth=$(date -d "1 days ago" "+%m")
   bday=$(date -d "1 days ago" "+%d")

   eyear=$(date -d today "+%Y")
   emonth=$(date -d today "+%m")
   eday=$(date -d today "+%d")
else
   # BSD date
   byear=$(date -j -v-1d "+%Y")
   bmonth=$(date -j -v-1d "+%m")
   bday=$(date -j -v-1d "+%d")

   eyear=$(date -j "+%Y")
   emonth=$(date -j "+%m")
   eday=$(date -j "+%d")
fi

# Override automatic begin- and end-dates
# To be used when bulk-importing historical data

#byear=2019
#bmonth=01
#bday=01

#eyear=2019
#emonth=12
#eday=31

# Sensor can be ALL or a subset
# 350 370 375 | 350:370:375 | ALL
for Sensor in ALL
do
   curl -s --data "stns=${Sensor}&vars=ALL" \
           --data "byear=${byear}&bmonth=${bmonth}&bday=${bday}" \
           --data "eyear=${eyear}&emonth=${emonth}&eday=${eday}" \
              http://projects.knmi.nl/klimatologie/uurgegevens/getdata_uur.cgi |\
     tr -d '\r' | sed -e 's/^# STN,YYYYMMDD/STN,YYYYMMDD/' -e '/^#/d' |\
     tr -d ' ' | knmi-to_line_protocol.py | to_influx_db.sh
done
