import json
import sys
import argparse
import logging

from chi_elections.precincts import elections
import scrapelib
from scrapelib.cache import FileCache


logging.basicConfig(level=logging.DEBUG)

parser = argparse.ArgumentParser(description="Chicago municipal election results")
parser.add_argument("--year", type=int, help="year of election")
parser.add_argument(
    "--type", type=str, choices=("general", "runoff"), help="type of election"
)
parser.add_argument("geojson", type=argparse.FileType("r"), help="geojson of precincts")


args = parser.parse_args()

precincts = json.load(args.geojson)

precinct_features = {}
for feature in precincts["features"]:
    properties = feature["properties"]
    for k in list(properties.keys()):
        if k not in ("WARD", "PRECINCT"):
            del properties[k]
    precinct = (properties["WARD"], properties["PRECINCT"])
    precinct_features[precinct] = properties

cache = FileCache("_cache")

session = scrapelib.Scraper(retry_attempts=20)
session.cache_storage = cache
session.cache_write_only = False

elections = elections(session)
(muni_election,) = [
    election
    for name, election in elections.items()
    if (
        "municipal" in name.lower()
        and ((str(args.year) in name and args.type in name.lower()) or "2023" in name)
    )
]

election_results = {}
all_candidates = set()
for name, race in muni_election.races.items():
    if "alder" in name.lower() or "mayor" in name.lower():
        for precinct, votes in race.precincts.items():
            if precinct in election_results:
                election_results[precinct].update(votes)
            else:
                election_results[precinct] = votes
            all_candidates.update(votes.keys())
    for precinct, votes in muni_election.turnout.precincts.items():
        if precinct in election_results:
            election_results[precinct].update(votes)
        else:
            election_results[precinct] = votes
        all_candidates.update(votes.keys())

for precinct, votes in election_results.items():
    other_candidates = all_candidates - votes.keys()
    precinct_features[precinct].update(votes)
    precinct_features[precinct].update({cand: None for cand in other_candidates})


if args.type == "general":
    for precinct in precinct_features:
        assert election_results[precinct]
else:
    for precinct in precinct_features:
        if precinct not in election_results:
            precinct_features[precinct].update({cand: None for cand in all_candidates})

with sys.stdout as f:
    json.dump(precincts, f)
