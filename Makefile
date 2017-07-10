WardPrecincts.zip :
	wget -O $@ "https://data.cityofchicago.org/download/sgsc-bb4n/application%2Fzip"

WardPrecincts.shp : WardPrecincts.zip
	unzip $<

precincts/2011-08-01_precincts.geojson : WardPrecincts.shp
	ogr2ogr -f GeoJSON -t_srs crs:84 $@ $<
