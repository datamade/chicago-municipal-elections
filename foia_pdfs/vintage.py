import sys
import datetime
import csv
import itertools

election_date = datetime.datetime.strptime(sys.argv[1], '%Y-%m-%d').date()

to_date = lambda x: datetime.datetime.strptime(x, '%m/%d/%y').date()

with open('vintages.csv') as f:
    reader = csv.DictReader(f)
    for ward, vintages in itertools.groupby(reader, key=lambda x: x['ward']):
        feasible_vintages = (vintage for vintage in vintages
                             if to_date(vintage['begin']) <= election_date)
        vintage = max(feasible_vintages, key=lambda x: to_date(x['begin']))
        print(vintage['file name'])
