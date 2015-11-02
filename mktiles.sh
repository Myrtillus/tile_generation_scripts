#!/bin/bash
#
# mktiles.sh
#
# Exit on error
set -o errexit
set -o nounset

# haetaan uusin finland dumppi
DOWNLOADS="/var/tmp/osm"
OSMFILE="finland-latest.osm.pbf"
OSMURL="http://download.geofabrik.de/europe/${OSMFILE}"
#rm -rf ${DOWNLOADDIR}
wget --waitretry=3 -N -P ${DOWNLOADS} ${OSMURL}

# kanta myllays
sudo -u postgres psql -c "DROP DATABASE gis;"


sudo -u postgres createdb --encoding=UTF8 --owner=gisuser gis
sudo -u postgres psql  gis< /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
sudo -u postgres psql  gis< /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
sudo -u postgres psql -d gis -c "GRANT SELECT ON spatial_ref_sys TO PUBLIC;"
sudo -u postgres psql -d gis -c "GRANT ALL ON geometry_columns TO gisuser;"


# Postgresql kantaan ajetaan etelÃ¤-suomen datat
# vasen alakulma 59.7054/20.7305
# oikea ylÃ¤kulma 62.7816/31.4811
#BBOX="20.7305,59.7054,31.4811,62.7816"
BBOX="20.7305,59.7054,31.4811,65"  # oulu mukaan alueeseen

# Kaupin alue pelkastaan
# 61.50659/23.77293
# 61.52932/23.93110
# BBOX="23.77293,61.50659,23.93110,61.52932"


STYLE="/home/nissiant/osm2pgsql_dumpperi/osm2pgsql_dumpperi_tyyli.style"
LOCALOSMFILE="${DOWNLOADS}/${OSMFILE}"
sudo -u postgres osm2pgsql --cache-strategy sparse --bbox ${BBOX} --style ${STYLE} --database gis --username gisuser --slim ${LOCALOSMFILE}

# KESARTAT 
# -talvikuukausina valk. katkoviivalla talvipolut, muuten kaikki kesämerkkaukset
# - vaihda generate_tiles_summer.py tiedostosta oikea xml file käyttöön kesäkuukausille
# ***************

# lasketaan uudet tiilit hakemistoon /var/tmp/osm/tiles
export MAPNIK_MAP_DIR="/var/tmp/osm/tiles"
mkdir -p ${MAPNIK_MAP_DIR}
chown postgres:postgres ${MAPNIK_MAP_DIR}
GENTILESPY="/usr/local/bin/generate_tiles_summer.py"
sudo -u postgres ${GENTILESPY}

# siirrettaan uudet tiilet vanhojen paalle
#sudo cp -R ~/tiles_tmp/* ~/tiles/
#sudo rm -R ~/tiles_tmp/*
PUBLISH_DIR=/var/www/tiles
cp -a ${MAPNIK_MAP_DIR}/* ${PUBLISH_DIR}
rm -rf ${MAPNIK_MAP_DIR}


# TALVIKARTAT 
# - merkkauksessa vain talvipolkujen tallautuvuus
# ***************
# lasketaan uudet tiilit hakemistoon /var/tmp/osm/tiles
export MAPNIK_MAP_DIR="/var/tmp/osm/tiles_winter"
mkdir -p ${MAPNIK_MAP_DIR}
chown postgres:postgres ${MAPNIK_MAP_DIR}
GENTILESPY="/usr/local/bin/generate_tiles_winter.py"

# TALVIKARTAT KOMMENTOITU POIS 24.4.14
# sudo -u postgres ${GENTILESPY}

# siirrettaan uudet tiilet vanhojen paalle

PUBLISH_DIR=/var/www/tiles_winter
cp -a ${MAPNIK_MAP_DIR}/* ${PUBLISH_DIR}
rm -rf ${MAPNIK_MAP_DIR}






