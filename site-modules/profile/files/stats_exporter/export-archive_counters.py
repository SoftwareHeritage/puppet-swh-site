#!/usr/bin/python3

import requests
import json
import time

def clean_item(item):
    """Javascript expects timestamps to be in milliseconds
       and counter values as floats

    """
    timestamp = int(item[0])
    counter_value = item[1]
    return [timestamp*1000, float(counter_value)]
    

def get_timestamp_history(label):
    result = []
    rrd_data = []
    now = int(time.time())
    url = 'http://pergamon.internal.softwareheritage.org:9090/api/v1/query_range?'
    url = url + 'query=sum(sql_swh_archive_object_count) by (object_type)'
    url = url + '&start=1544543227&end=%s&step=12h' % now

    # We only want to process timevalues for Source files
    if (label == "content"):
        # Historical data has already been processed for javascript usage
        # No need to clean it further
        with open("/usr/local/share/swh-data/history-counters.munin.json", "r") as f:
            rrd_data = json.load(f)[label]

    response = requests.get(url)
    if response.ok:
        data = response.json()
        # In contrast, Prometheus-provided data has to be adapted to
        # Javascript expectations
        result = [clean_item(i) for i in
            data['data']['result'][0]['values']]
    return rrd_data + result


def main():
   result = {}
   for label in ['content', 'origin', 'revision']:
       result[label] = get_timestamp_history(label)
   return result
    

if __name__ == '__main__':
    r = main()
    print(json.dumps(r))
