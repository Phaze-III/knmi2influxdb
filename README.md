# knmi2influxdb

Fetch historical hourly KNMI weather data and convert to influx line protocol

Adapted from https://github.com/tomru/cram-luftdaten

KNMI data is stored as is, no fieldname or value conversions. A sample
Grafana dashboard for visualisation is provided.

# Usage

* Create a new InfluxDB with 'create database knmi'
* Modify the INFLUXDB-settings in get-knmi-weerdata.sh as needed
* Run get-knmi-weerdata.sh to fetch and insert the KNMI-data

The get-knmi-weerdata.sh script as provided fetches the hourly data from
all stations from yesterday. Begin and end dates and the selection of
specific stations can be set in the script for initializing the database
over longer periods. Please note that bulk-importing more than 100000
lines of data might trigger InfluxDB limits.

When running the script from daily cron please pick a time after 12:00 UTC.

# Additional info

* http://projects.knmi.nl/klimatologie/uurgegevens/selectie.cgi
* http://www.knmi.nl/kennis-en-datacentrum/achtergrond/data-ophalen-vanuit-een-script
