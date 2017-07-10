WardPrecincts.zip :
	wget -O $@ "https://data.cityofchicago.org/download/sgsc-bb4n/application%2Fzip"

PRECINCTS_2012.zip :
	wget -O $@ "https://data.cityofchicago.org/api/geospatial/uvpq-qeeq?method=export&format=Original"

%.shp : %.zip
	unzip $<

precincts/2011-08-01_precincts.geojson : WardPrecincts.shp
	ogr2ogr -f GeoJSON -t_srs crs:84 $@ $<

precincts/2016-08-23_precincts.geojson : PRECINCTS_2012.shp
	ogr2ogr -f GeoJSON -t_srs crs:84 $@ $<

