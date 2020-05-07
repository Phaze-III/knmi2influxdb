#!/bin/sh

# TODO
# - Use and store intermediate files
# - Split larger (> 100000 lines) influx input files in smaller chunks

export INFLUXDB_DATABASE=knmi
export INFLUXDB_HOST=localhost
export INFLUXDB_PORT=8086

# Set begin and end date to yesterday
if date --version >/dev/null 2>&1
then
   # GNU date
   byear=$(date -d "1 days ago" "+%Y")
   bmonth=$(date -d "1 days ago" "+%m")
   bday=$(date -d "1 days ago" "+%d")
else
   # BSD date
   byear=$(date -j -v-1d "+%Y")
   bmonth=$(date -j -v-1d "+%m")
   bday=$(date -j -v-1d "+%d")
fi

eyear=${byear}
emonth=${bmonth}
eday=${bday}

# Override automatic begin- and end-dates by uncommenting a b*
# and/or e* block. To be used when bulk-importing historical data.
# Blocks of 3 months should be within InfluxDB limits.

#byear=2020
#bmonth=01
#bday=01

#eyear=2020
#emonth=03
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
