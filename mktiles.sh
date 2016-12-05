#!/bin/bash
#
# mktiles.sh
#
# Exit on error
set -o errexit
set -o nounset

export LC_ALL="en_US.UTF-8"


# FINLAND DUMPPI LAKKASI TOIMIMASTA, VAIHDETTU YKSITTAISTEN ALUEIDEN SUORAAN HAKUUN JA DUMPPAUKSEEN 19.7.2016

# haetaan uusin finland dumppi
#DOWNLOADS="/var/tmp/osm"
#OSMFILE="finland-latest.osm.pbf"
#OSMFILE="finland-latest.osm"
#OSMURL="http://download.geofabrik.de/europe/${OSMFILE}"

#wget --waitretry=3 -N -P ${DOWNLOADS} ${OSMURL}





# kanta myllays, tuhotaan vanha kanta ja tehdaan kaikki alusta
sudo -u postgres psql -c "DROP DATABASE gis;"
sudo -u postgres createdb --encoding=UTF8 --owner=gisuser gis
sudo -u postgres psql  gis< /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
sudo -u postgres psql  gis< /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
sudo -u postgres psql -d gis -c "GRANT SELECT ON spatial_ref_sys TO PUBLIC;"
sudo -u postgres psql -d gis -c "GRANT ALL ON geometry_columns TO gisuser;"

# *****************************************
# Postgresql kantaan ajetaan etelÃ¤-suomen datat
#BBOX="20.7305,59.7054,31.4811,65"  # oulu mukaan alueeseen

#STYLE="/home/nissiant/Documents/Mapbox/project/osm2pgsql_style/pkk_maps.style"
#LOCALOSMFILE="${DOWNLOADS}/${OSMFILE}"
#sudo -u postgres osm2pgsql --cache-strategy sparse --bbox ${BBOX} --style ${STYLE} --database gis --username gisuser --slim ${LOCALOSMFILE}

# slim mode saattoi aiheuttaa ongelmia 18.7.2016
# *************************************************



# HAETAAN ERI ALUEIDEN DATAT SUORAAN SERVERILTA, FINLAND DUMPPI LAKKASI TOIMIMASTA 16.7.2016
# Dumppaillaan eri alueet yksi kerrallaan postgis kantaan mukaan
STYLE="/home/nissiant/Documents/Mapbox/project/osm2pgsql_style/pkk_maps.style"

BBOX="22.8,60.5,25,61.97"  # Tampere
wget -O /var/tmp/osm/tampere.osm "http://www.overpass-api.de/api/xapi_meta?*[bbox=${BBOX}]"

sleep 60

BBOX="25.1024,64.8437,26.1111,65.2924"  # Oulu
wget -O /var/tmp/osm/oulu.osm "http://www.overpass-api.de/api/xapi_meta?*[bbox=${BBOX}]"

sleep 60

BBOX="25.3000,60.2500,26.0000,60.5300"  # Porvoo
wget -O /var/tmp/osm/porvoo.osm "http://www.overpass-api.de/api/xapi_meta?*[bbox=${BBOX}]"


sleep 60

BBOX="25.4005,66.4042,26.1474,66.6554"  # Rovaniemi
wget -O /var/tmp/osm/rovaniemi.osm "http://www.overpass-api.de/api/xapi_meta?*[bbox=${BBOX}]"

# yhdistetaan eri osm fileet duplikaatti avainten poistamiseksi
# http://forum.openstreetmap.org/viewtopic.php?id=23765

/home/nissiant/Garmin_OSM_TK_map/osmosis/bin/osmosis --rx /var/tmp/osm/tampere.osm --rx /var/tmp/osm/oulu.osm --rx /var/tmp/osm/porvoo.osm --rx /var/tmp/osm/rovaniemi.osm --merge --merge --merge --wx /var/tmp/osm/merged.osm

# dumpataan osm data kantaan
BBOX="20,60,30,70"  # Porvoo, huomaa append
sudo -u postgres osm2pgsql --cache-strategy sparse --bbox ${BBOX} --style ${STYLE} --database gis --username gisuser --slim /var/tmp/osm/merged.osm

# tuhotaan roikkumasta
rm /var/tmp/osm/*.osm


# KESARTAT 
# -talvikuukausina valk. katkoviivalla talvipolut, muuten kaikki kesämerkkaukset
# - vaihda generate_tiles_summer.py tiedostosta oikea xml file käyttöön kesäkuukausille
# ***************

# lasketaan uudet tiilet hakemistoon /var/tmp/osm/tiles
export MAPNIK_MAP_DIR="/var/tmp/osm/tiles"
mkdir -p ${MAPNIK_MAP_DIR}
chown postgres:postgres ${MAPNIK_MAP_DIR}
GENTILESPY="/usr/local/bin/generate_tiles_summer.py"
sudo -u postgres ${GENTILESPY}

# siirrettaan uudet tiilet vanhojen paalle
PUBLISH_DIR=/var/www/tiles
cp -a ${MAPNIK_MAP_DIR}/* ${PUBLISH_DIR}
rm -rf ${MAPNIK_MAP_DIR}


# talvikartat de-aktivoitu 5.4.2016

# TALVIKARTAT 
# - merkkauksessa vain talvipolkujen tallautuvuus
# ***************
# lasketaan uudet tiilet hakemistoon /var/tmp/osm/tiles
#export MAPNIK_MAP_DIR="/var/tmp/osm/tiles_winter"
#mkdir -p ${MAPNIK_MAP_DIR}
#chown postgres:postgres ${MAPNIK_MAP_DIR}
#GENTILESPY="/usr/local/bin/generate_tiles_winter.py"

# TALVIKARTAT, aktivoitu 29.12.2015
#sudo -u postgres ${GENTILESPY}

# siirrettaan uudet tiilet vanhojen paalle

#PUBLISH_DIR=/var/www/tiles_winter
#cp -a ${MAPNIK_MAP_DIR}/* ${PUBLISH_DIR}
#rm -rf ${MAPNIK_MAP_DIR}






