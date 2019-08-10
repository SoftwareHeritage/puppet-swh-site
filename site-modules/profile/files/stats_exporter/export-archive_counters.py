#!/usr/bin/python3

import requests
import json
import time


def adapt_format(item):
    """Javascript expects timestamps to be in milliseconds
       and counter values as floats

    Args
        item (list): List of 2 elements, timestamp and counter

    Return:
        Normalized tuple (timestamp in js expected time, counter as float)

    """
    timestamp = int(item[0])
    counter_value = item[1]
    return [timestamp*1000, float(counter_value)]


def compute_url(label, server='pergamon.internal.softwareheritage.org', port=9090):
    """Compute the api url to request data from, specific to a label.

    """
    now = int(time.time())
    url = 'http://%s:%s/api/v1/query_range?query=sum(sql_swh_archive_object_count{object_type="%s"})&start=1544543227&end=%s&step=12h' % (server, port, label, now)  # noqa
    return url


def history_data(history_data_file="/usr/local/share/swh-data/history-counters.munin.json"):
    """Retrieve the history from the history_data_file

    Args:
        history_data_file (str): Path to history file to load from

    Returns:
        dict with key (label in origin, revision, content), values (list of
        history points: timestamp, counter):

    """
    with open(history_data_file, "r") as f:
        return json.load(f)


def get_timestamp_history(label):
    """Given a label, retrieve its associated graph data.

    Args:
        label (str): Label object in {content, origin, revision}
    """
    result = []
    url = compute_url(label)
    response = requests.get(url)
    if response.ok:
        data = response.json()
        # data answer format:
        # {"status":"success","data":{"result":[{"values":[[1544586427,"5375557897"]...  # noqa
        # Prometheus-provided data has to be adapted to js expectations
        result = [adapt_format(i) for i in
            data['data']['result'][0]['values']]
    return result


def main():
    """Compute the history graph data for the label/object_type {content,
    revision, origin}.

    This retrieves data from prometheus' sql exporter (and adapt them to the
    expected format of the flot library we use).

    For content, that also retrieves old data fetched from a previous data file
    and aggregates it to the new prometheus data.

    """
    result = {}
    hist_data = history_data()
    # for content, we retrieve existing data and merges with the new one
    result['content'] = hist_data['content'] + get_timestamp_history('content')
    for label in ['origin', 'revision']:
        result[label] = get_timestamp_history(label)
    return result


if __name__ == '__main__':
    r = main()
    print(json.dumps(r))
