WardPrecincts.zip :
	wget -O $@ "https://data.cityofchicago.org/download/sgsc-bb4n/application%2Fzip"

Precincts2010.zip :
	wget -O $@ "https://data.cityofchicago.org/api/geospatial/tt8i-6jyx?method=export&format=Original"

PRECINCTS_2012.zip :
	wget -O $@ "https://data.cityofchicago.org/api/geospatial/uvpq-qeeq?method=export&format=Original"

%.shp : %.zip
	unzip $<

precincts/2010_precincts.geojson : Precincts2010.shp
	ogr2ogr -f GeoJSON -t_srs crs:84 $@ $<

precincts/2011_precincts.geojson : WardPrecincts.shp
	ogr2ogr -f GeoJSON -t_srs crs:84 $@ $<

precincts/2015_precincts.geojson : PRECINCTS_2012.shp
	ogr2ogr -f GeoJSON -t_srs crs:84 $@ $<


