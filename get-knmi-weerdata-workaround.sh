#!/bin/sh

# This script fetches the full set of historical hourly weather data as
# offered on https://www.knmi.nl/nederland-nu/klimatologie/uurgegevens
# and extract the daily measurements.
# To be used as alternative for the interactive selection API on 
# projects.knmi.nl which is down as of february 15th 2021.

# TODO
# - Rewrite using the dezemaand.zip and vorigemaand.zip sets (not sure
#   yet how permanent that will be)

PATH=${HOME}/bin:${PATH}

export INFLUXDB_DATABASE=knmi
export INFLUXDB_HOST=localhost
export INFLUXDB_PORT=8086

DataDir=${HOME}/KNMI/DATA
cd ${DataDir} || exit 1

# Set begin and end date to 2 days ago and yesterday
if date --version >/dev/null 2>&1
then
   # GNU date
   StartDate=$(date -d "2 days ago" "+%Y%m%d")
   EndDate=$(date -d "1 days ago" "+%Y%m%d")
else
   # BSD date
   StartDate=$(date -j -v-2d "+%Y%m%d")
   EndDate=$(date -j -v-1d "+%Y%m%d")
fi

# Override automatic begin- and end-dates
# StartDate=20210215
# EndDate=20210321

# 10-year historical data period
# See https://www.knmi.nl/nederland-nu/klimatologie/uurgegevens for periods
Period=2021-2030

# Station can be in ALL or a subset
# 350 370 375 | ${ALL}
ALL="209 210 215 225 235 240 242 248 249 251 257 258 260 265 267 269 270 273 275 277 278 279 280 283 285 286 290 308 310 311 312 313 315 316 319 323 324 330 331 340 343 344 348 350 356 370 375 377 380 391"

for Station in ${ALL}
do
   DataFile=uurgeg_${Station}_${Period}
   if wget -q -N https://cdn.knmi.nl/knmi/map/page/klimatologie/gegevens/uurgegevens/${DataFile}.zip
   then
      unzip -a -o ${DataFile}.zip
      if [ -r ${DataFile}.txt ]
      then
         Date=${StartDate}
         while [ ${Date} -le ${EndDate} ]
         do 
            egrep "^# STN|,${Date}," ${DataFile}.txt |\
              tr -d '\r' | sed -e 's/^# STN,YYYYMMDD/STN,YYYYMMDD/' -e '/^#/d' |\
              tr -d ' ' | knmi-to_line_protocol.py | to_influx_db.sh
            if date --version >/dev/null 2>&1
            then
               # GNU date
               Date=$(date -d "$(echo ${Date} | sed -e 's/^\([0-9][0-9][0-9][0-9]\)\([0-9][0-9]\)\([-9][0-9]\)/\1-\2-\3/') +1 day" "+%Y%m%d")
            else
               Date=$(date -j -v+1d -f "%Y%m%d" "${Date}" "+%Y%m%d")
            fi
         done
         rm -f ${DataFile}.txt
      fi
   fi
done
