.DELETE_ON_ERROR :

.PHONY : all
all : data/municipal_general_2023.geojson				\
      data/municipal_general_2019.geojson				\
      data/municipal_general_2015.geojson				\
      data/municipal_general_2011.geojson				\
      data/municipal_general_2007.geojson				\
      data/municipal_runoff_2019.geojson				\
      data/municipal_runoff_2015.geojson				\
      data/municipal_runoff_2011.geojson				\
      data/municipal_runoff_2007.geojson				\
      data/municipal_primary_1983.geojson				\
      data/municipal_general_1983.geojson				\
      data/municipal_general_2019.csv data/municipal_general_2015.csv	\
      data/municipal_general_2011.csv data/municipal_general_2007.csv	\
      data/municipal_runoff_2019.csv data/municipal_runoff_2015.csv	\
      data/municipal_runoff_2011.csv data/municipal_runoff_2007.csv	\
      data/municipal_primary_1983.csv data/municipal_general_1983.csv

WardPrecincts.zip :
	wget -O $@ "https://data.cityofchicago.org/download/sgsc-bb4n/application%2Fzip"

Precincts2010.zip :
	wget -O $@ "https://data.cityofchicago.org/api/geospatial/tt8i-6jyx?method=export&format=Original"

PRECINCTS_2012.zip :
	wget -O $@ "https://data.cityofchicago.org/api/geospatial/uvpq-qeeq?method=export&format=Original"

precincts_2000_pre2006.zip :
	wget -O $@ "https://illinoiselectiondata.com/downloads/Chicago_precints_historical.zip"

PRECINCTS_07232004.zip :
	wget -O $@ "https://illinoiselectiondata.com/downloads/Chicago_Precincts_2003.zip"

PRECINCTS_pre2006.zip:
	wget -O $@ "https://illinoiselectiondata.com/downloads/Chicago_Precincts_2004.zip"



%.shp : %.zip
	unzip $<
	touch $@

precincts/2000_precincts.geojson : precincts_2000_pre2006.shp
	ogr2ogr -f GeoJSON -t_srs crs:84 $@ $<

precincts/2003_precincts.geojson : PRECINCTS_07232004.shp
	ogr2ogr -f GeoJSON -t_srs crs:84 $@ $<

precincts/2004_precincts.geojson : PRECINCTS_pre2006.shp
	ogr2ogr -f GeoJSON -t_srs crs:84 $@ $<

.INTERMEDIATE : chicago_2008.geojson
chicago_2008.geojson : archive/IL_final.shp
	ogr2ogr -f GeoJSON -where "Name like 'Wd%Pct%'" $@ $<

# I manually edit the 2008 map to get a 2007 map, using the FOIAed pdfs
# of the historic precincts
precincts/2007_precincts.geojson : precincts/2008_precincts.geojson

precincts/2008_precincts.geojson : chicago_2008.geojson
	cat $< | python scripts/parse_precinct.py > $@

precincts/2010_precincts.geojson : Precincts2010.shp
	ogr2ogr -f GeoJSON -t_srs crs:84 $@ $<

# For the municipal election WardPrecincts.zip did not include feature
# for ward 27, precinct 46 which appears in that election. The 2010 file does
# have that precinct. The 2010 precincts aren't fully accurate for ward 19
# so I manually edit those

precincts/2015_precincts.geojson : PRECINCTS_2012.shp
	ogr2ogr -f GeoJSON -t_srs crs:84 $@ $<

WD\ 1-25 : archive/WD\ 1-25.zip
	unzip "$<"
	touch $@

WD\ 26-50 : archive/WD\ 26-50.zip
	unzip "$<"
	touch $@

# Combine most recent files from the two zip archives for 2019 precincts
precincts/2019_precincts.geojson : WD\ 1-25 WD\ 26-50
	python scripts/list_2019_precinct_files.py | \
	xargs -J % mapshaper -i % combine-files \
	-each "WARD = +ID.slice(0, 2); PRECINCT = +ID.slice(2)" \
	-filter-fields WARD,PRECINCT \
	-merge-layers -o $@

.INTERMEDIATE : archive/WardPrecincts_2023.shp
archive/WardPrecincts_2023.shp: archive/WardPrecincts_2023.zip
	unzip -DD -d archive $<

precincts/2023_precincts.geojson: archive/WardPrecincts_2023.shp
	mapshaper -i $< \
	-rename-fields WARD=FIRST_ward,PRECINCT=FIRST_prec \
	-o $@

# Clean up data from the Chicago Elections Project on the 1983 election
precincts/1983_precincts.geojson: archive/1983_WardandPrecinctShapefileMap.shp
	mapshaper -i $< -proj crs=wgs84 -o $@

data/municipal_primary_1983.csv: archive/1983_MayoralPrimary_ElectionResultsSpreadsheet.xlsx
	in2csv $< > $@

data/municipal_general_1983.csv: archive/1983_MayoralGeneral_ElectionResultsSpreadsheet.xlsx
	in2csv $< > $@

data/municipal_%_1983.geojson: precincts/1983_precincts.geojson data/municipal_%_1983.csv
	mapshaper -i $< \
	-join $(filter-out $<,$^) field-types=PREC_ID:str keys=Prec_ID,PREC_ID \
	-o $@

data/municipal_general_%.geojson : precincts/%_precincts.geojson
	python scripts/boe.py $< --year=$* --type=general > $@

data/municipal_runoff_%.geojson : precincts/%_precincts.geojson
	python scripts/boe.py $< --year=$* --type=runoff > $@

%.csv : %.geojson
	cat $< | python scripts/json_to_csv.py | csvsort > $@
