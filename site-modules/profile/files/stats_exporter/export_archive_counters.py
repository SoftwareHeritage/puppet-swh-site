#!/usr/bin/python3

import requests
import json
import time

import click


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


def compute_url(server, port, label):
    """Compute the api url to request data from, specific to a label.

    Args:
        server (str): Prometheus server
        port (int): Prometheus server port
        label (str): object_type/label data

    Returns:
        The api url to fetch the label's data

    """
    now = int(time.time())
    url = 'http://%s:%s/api/v1/query_range?query=sum(sql_swh_archive_object_count{object_type="%s"})&start=1544543227&end=%s&step=12h' % (server, port, label, now)  # noqa
    return url


def history_data(history_data_file):
    """Retrieve the history from the history_data_file

    Args:
        history_data_file (str): Path to history file to load from

    Returns:
        dict with key (label in origin, revision, content), values (list of
        history points: timestamp, counter):

    """
    with open(history_data_file, "r") as f:
        return json.load(f)


def get_timestamp_history(server, port, label):
    """Given a label, retrieve its associated graph data.

    Args:
        server (str): Prometheus server
        port (int): Prometheus server port
        label (str): Label object in {content, origin, revision}

    Returns:
        The label's graph data from the prometheur server:port.

    """
    result = []
    url = compute_url(server, port, label)
    response = requests.get(url)
    if response.ok:
        data = response.json()
        # data answer format:
        # {"status":"success","data":{"result":[{"values":[[1544586427,"5375557897"]...  # noqa
        # Prometheus-provided data has to be adapted to js expectations
        result = [adapt_format(i)
                  for i in data['data']['result'][0]['values']]
    return result


@click.command()
@click.option('--server', '-s',
              default='pergamon.internal.softwareheritage.org',
              help="Prometheus instance")
@click.option('--port', '-p',
              default=9090,
              type=click.INT,
              help='Prometheus instance service port')
@click.option('--history-data-file', '-d',
              type=click.Path(exists=True),
              help="History data file with data types to reuse")
def main(server, port, history_data_file):
    """Compute the history graph data for the label/object_type {content,
    revision, origin}.

    This retrieves data from prometheus' sql exporter (and adapt them to the
    expected format of the flot library we use).

    For content, that also retrieves old data fetched from a previous data file
    and aggregates it to the new prometheus data.

    """
    result = {}
    hist_data = history_data(history_data_file)
    # for content, we retrieve existing data and merges with the new one
    content_data = get_timestamp_history(server, port, 'content')
    result['content'] = hist_data['content'] + content_data
    for label in ['origin', 'revision']:
        result[label] = get_timestamp_history(server, port, label)

    print(json.dumps(result))


if __name__ == '__main__':
    main()
