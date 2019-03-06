import os
import re
import sys
from os.path import abspath, dirname, join


ARCHIVE_DIR = join(dirname(dirname(__file__)), "archive")
ward_nums = [i for i in range(1, 51)]
precinct_files = []

for ward_num in ward_nums:
    if ward_num < 26:
        ward_dir = join(ARCHIVE_DIR, "WD 1-25", "Ward {:>02}".format(ward_num))
    else:
        ward_dir = join(ARCHIVE_DIR, "WD 26-50", "Ward {:>02}".format(ward_num))

    dir_items = os.listdir(ward_dir)
    # Check for Redist directory, use if available
    redist_dirs = sorted([item for item in dir_items if "Redist" in item])
    if len(redist_dirs) > 0:
        # Take last Redist dir alphabetically to get the latest redistricting
        redist_dir = redist_dirs[-1]
        redist_shapefiles = [
            item for item
            in os.listdir(join(ward_dir, redist_dir))
            if item.endswith(".shp")
        ]
        precinct_files.append(join(ward_dir, redist_dir, redist_shapefiles[0]))
        continue

    # Check if any files end with a year for redistricing in the ward directory
    redist_files = [item for item in dir_items if re.match(r".*[\d]{4}\.shp$", item)]
    if len(redist_files) == 1:
        precinct_files.append(join(ward_dir, redist_files[0]))
        continue

    # If the previous patterns aren't met, use the remaining shapefile
    precinct_shp = [item for item in dir_items if item.endswith(".shp")][0]
    precinct_files.append(join(ward_dir, precinct_shp))

sys.stdout.write(
    " ".join(['"{}"'.format(precinct_file) for precinct_file in precinct_files])
)
