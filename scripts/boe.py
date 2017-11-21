import json

from chi_elections.precincts import elections
import scrapelib
from scrapelib.cache import FileCache

with open('../precincts/2015_precincts.geojson') as f:
    precincts_2015 = json.load(f)

precinct_features = {}
for feature in precincts_2015['features']:
    properties = feature['properties']
    precinct = (properties['WARD'], properties['PRECINCT'])
    precinct_features[precinct] = properties

cache = FileCache('_cache')

session = scrapelib.Scraper()
session.cache_storage = cache
session.cache_write_only = False

elections = elections(session)
print(elections.keys())
muni_election, = [election for name, election in
                  elections.items()
                  if ('municipal' in name.lower()
                      and '2015' in name
                      and 'general' in name.lower())]

election_results = {}
all_candidates = set()
for name, race in muni_election.races.items():
    if 'alderman' in name.lower() or 'mayor' in name.lower():
        print(name)
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

for precinct, votes in election_results.items():
    other_candidates = all_candidates - votes.keys()
    precinct_features[precinct].update(votes)
    precinct_features[precinct].update({cand: None for cand in other_candidates})

with open('out.geojson', 'w') as f:
    json.dump(precincts_2015, f)

