#!/usr/bin/env python3

# Adapted from https://github.com/tomru/cram-luftdaten.git

""" BRON: KONINKLIJK NEDERLANDS METEOROLOGISCH INSTITUUT (KNMI)
# Opmerking: door stationsverplaatsingen en veranderingen in waarneemmethodieken zijn deze tijdreeksen van uurwaarden mogelijk inhomogeen! Dat betekent dat deze reeks van gemeten waarden niet geschikt is voor trendanalyse. Voor studies naar klimaatverandering verwijzen we naar de gehomogeniseerde reeks maandtemperaturen van De Bilt <http://www.knmi.nl/klimatologie/onderzoeksgegevens/homogeen_260/index.html> of de Centraal Nederland Temperatuur <http://www.knmi.nl/klimatologie/onderzoeksgegevens/CNT/>.
# 
# 
# STN      LON(east)   LAT(north)     ALT(m)  NAME
# 350:         4.936       51.566      14.90  GILZE-RIJEN
# 
# YYYYMMDD = datum (YYYY=jaar,MM=maand,DD=dag); 
# HH       = tijd (HH=uur, UT.12 UT=13 MET, 14 MEZT. Uurvak 05 loopt van 04.00 UT tot 5.00 UT; 
# DD       = Windrichting (in graden) gemiddeld over de laatste 10 minuten van het afgelopen uur (360=noord, 90=oost, 180=zuid, 270=west, 0=windstil 990=veranderlijk. Zie http://www.knmi.nl/kennis-en-datacentrum/achtergrond/klimatologische-brochures-en-boeken; 
# FH       = Uurgemiddelde windsnelheid (in 0.1 m/s). Zie http://www.knmi.nl/kennis-en-datacentrum/achtergrond/klimatologische-brochures-en-boeken; 
# FF       = Windsnelheid (in 0.1 m/s) gemiddeld over de laatste 10 minuten van het afgelopen uur; 
# FX       = Hoogste windstoot (in 0.1 m/s) over het afgelopen uurvak; 
# T        = Temperatuur (in 0.1 graden Celsius) op 1.50 m hoogte tijdens de waarneming; 
# T10N     = Minimumtemperatuur (in 0.1 graden Celsius) op 10 cm hoogte in de afgelopen 6 uur; 
# TD       = Dauwpuntstemperatuur (in 0.1 graden Celsius) op 1.50 m hoogte tijdens de waarneming; 
# SQ       = Duur van de zonneschijn (in 0.1 uren) per uurvak, berekend uit globale straling  (-1 for <0.05 uur); 
# Q        = Globale straling (in J/cm2) per uurvak; 
# DR       = Duur van de neerslag (in 0.1 uur) per uurvak; 
# RH       = Uursom van de neerslag (in 0.1 mm) (-1 voor <0.05 mm); 
# P        = Luchtdruk (in 0.1 hPa) herleid naar zeeniveau, tijdens de waarneming; 
# VV       = Horizontaal zicht tijdens de waarneming (0=minder dan 100m, 1=100-200m, 2=200-300m,..., 49=4900-5000m, 50=5-6km, 56=6-7km, 57=7-8km, ..., 79=29-30km, 80=30-35km, 81=35-40km,..., 89=meer dan 70km); 
# N        = Bewolking (bedekkingsgraad van de bovenlucht in achtsten), tijdens de waarneming (9=bovenlucht onzichtbaar); 
# U        = Relatieve vochtigheid (in procenten) op 1.50 m hoogte tijdens de waarneming; 
# WW       = Weercode (00-99), visueel(WW) of automatisch(WaWa) waargenomen, voor het actuele weer of het weer in het afgelopen uur. Zie http://bibliotheek.knmi.nl/scholierenpdf/weercodes_Nederland; 
# IX       = Weercode indicator voor de wijze van waarnemen op een bemand of automatisch station (1=bemand gebruikmakend van code uit visuele waarnemingen, 2,3=bemand en weggelaten (geen belangrijk weersverschijnsel, geen gegevens), 4=automatisch en opgenomen (gebruikmakend van code uit visuele waarnemingen), 5,6=automatisch en weggelaten (geen belangrijk weersverschijnsel, geen gegevens), 7=automatisch gebruikmakend van code uit automatische waarnemingen); 
# M        = Mist 0=niet voorgekomen, 1=wel voorgekomen in het voorgaande uur en/of tijdens de waarneming; 
# R        = Regen 0=niet voorgekomen, 1=wel voorgekomen in het voorgaande uur en/of tijdens de waarneming; 
# S        = Sneeuw 0=niet voorgekomen, 1=wel voorgekomen in het voorgaande uur en/of tijdens de waarneming; 
# O        = Onweer 0=niet voorgekomen, 1=wel voorgekomen in het voorgaande uur en/of tijdens de waarneming; 
# Y        = IJsvorming 0=niet voorgekomen, 1=wel voorgekomen in het voorgaande uur en/of tijdens de waarneming; 
# 
# STN,YYYYMMDD,   HH,   DD,   FH,   FF,   FX,    T, T10N,   TD,   SQ,    Q,   DR,   RH,    P,   VV,    N,    U,   WW,   IX,    M,    R,    S,    O,    Y
# 

    Note: timestamps are in seconds, therefore precision "s" needs to be set
    when writing, see https://docs.influxdata.com/influxdb/v1.2/tools/api/#write

Settings:

    None

CSV file spec:

    Comma is used as delimiter. First line are the header columns.
    Generally the column name is used as a DB field name.
    
"""

import os
import sys
import csv
from datetime import datetime, timedelta


def get_timestamp(timestr):
    """Converts CSV time value to a UTC timestamp in seconds"""
    naive_dt = datetime.strptime(timestr, "%Y%m%d %H:%M:%S%Z")
    utc = (naive_dt - datetime(1970, 1, 1)) / timedelta(seconds=1)
    return int(utc)

NAME_MAP = {
    "OrigField": "renamedfield",
    "H": "HH",
}

Station_Map = {
    "209": "IJmond",
    "210": "Valkenburg",
    "215": "Voorschoten",
    "225": "IJmuiden",
    "235": "De\ Kooy",
    "240": "Schiphol",
    "242": "Vlieland",
    "248": "Wijdenes",
    "249": "Berkhout",
    "251": "Hoorn\ (Terschelling)",
    "257": "Wijk\ aan\ Zee",
    "258": "Houtribdijk",
    "260": "De\ Bilt",
    "265": "Soesterberg",
    "267": "Stavoren",
    "269": "Lelystad",
    "270": "Leeuwarden",
    "273": "Marknesse",
    "275": "Deelen",
    "277": "Lauwersoog",
    "278": "Heino",
    "279": "Hoogeveen",
    "280": "Eelde",
    "283": "Hupsel",
    "285": "Huibertgat",
    "286": "Nieuw\ Beerta",
    "290": "Twenthe",
    "308": "Cadzand",
    "310": "Vlissingen",
    "311": "Hoofdplaat",
    "312": "Oosterschelde",
    "313": "Vlakte\ v.d.\ Raan",
    "315": "Hansweert",
    "316": "Schaar",
    "319": "Westdorpe",
    "323": "Wilhelminadorp",
    "324": "Stavenisse",
    "330": "Hoek\ van\ Holland",
    "331": "Tholen",
    "340": "Woensdrecht",
    "343": "Rotterdam-Geulhaven",
    "344": "Rotterdam",
    "348": "Cabauw",
    "350": "Gilze-Rijen",
    "356": "Herwijnen",
    "370": "Eindhoven",
    "375": "Volkel",
    "377": "Ell",
    "380": "Maastricht",
    "391": "Arcen",
    "392": "Horst",
}
READER = csv.DictReader(sys.stdin, delimiter=",")
for row in READER:

    measurements = []
    for header, value in row.items():
        if header == "FieldToSkip" or not value:
            continue
        measurements.append("{0}={1}".format(NAME_MAP.get(header, header), value))

    values = {
        "station": Station_Map.get(row["STN"], row["STN"]),
        "measurements": ",".join(measurements),
        "time": get_timestamp(row["YYYYMMDD"] + " " + str(int(row["HH"])-1).zfill(2) + ":59:59UTC") + 1,
        "date": row["YYYYMMDD"],
    }

    print("{station},station={station},date={date} {measurements} {time}".format(**values))
