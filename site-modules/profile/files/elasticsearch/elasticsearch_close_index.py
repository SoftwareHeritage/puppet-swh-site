#!/usr/bin/env python3

import datetime

import click
import iso8601

import elasticsearch


@click.command()
@click.option('--host', '-h', 'hosts',
              multiple=True,
              help="Elasticsearch node instances")
@click.option('--timeout', '-t', default=1200)
@click.option('--close-after-days', '-c', default=30)
def main(hosts, timeout, close_after_days):
    """Janitor script to close indices when date thresholds are
       exceeded.

    """
    today = datetime.date.today()
    close_after_days = datetime.timedelta(days=close_after_days)

    if not hosts:
        raise ValueError("Provide a list of elasticsearch nodes")

    es = elasticsearch.Elasticsearch(hosts=hosts, timeout=timeout)

    for line in sorted(es.cat.indices(h='i,status').splitlines()):
        i, status = line.split()
        # ignore dot-prefixed indexes (e.g. kibana settings)
        if i.startswith('.'):
            continue
        date = i.split('-')[-1]
        if not date.startswith('20'):
            continue
        date = date.replace('.', '-')
        date = iso8601.parse_date(date).date()

        if status == 'open' and date < today - close_after_days:
            print('closing', i)
            es.indices.close(i)


if __name__ == '__main__':
    main()
