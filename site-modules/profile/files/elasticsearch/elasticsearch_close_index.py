#!/usr/bin/env python3

import click
import datetime
import iso8601

import elasticsearch

@click.command()
@click.option('--host', '-h', 'hosts',
              multiple=True,
              help="Elasticsearch node instances")
@click.option('--timeout', '-t', default=1200)
@click.option('--freeze-after-days', '-f', default=7)
@click.option('--close-after-days', '-c', default=30)
def main(hosts, timeout, freeze_after_days, close_after_days):
    """Janitor script to manage (freeze or close) indices when respective date threshold are
       exceeded.

    """
    today = datetime.date.today()
    days = lambda n: datetime.timedelta(days=n)

    if not hosts:
        raise ValueError("Provide a list of elasticsearch nodes")

    es = elasticsearch.Elasticsearch(hosts=hosts, timeout=timeout)

    for l in sorted(es.cat.indices(h='i,sth,status').splitlines()):
        i, throttled, status = l.split()
        throttled = throttled == 'true'
        if throttled and status != 'open':
            continue
        # ignore dot-prefixed indexes (e.g. kibana settings)
        if i.startswith('.'):
            continue
        date = i.split('-')[-1]
        if not date.startswith('20'):
            continue
        date = date.replace('.', '-')
        date = iso8601.parse_date(date).date()
        info = es.indices.get(i)[i]
        shards = int(info['settings']['index']['number_of_shards'])

        if not throttled and date < today - days(freeze_after_days):
            print('freezing', i)
            es.indices.freeze(i, wait_for_active_shards=shards)
            status = 'open'

        if status == 'open' and date < today - days(close_after_days):
            print('closing', i)
            es.indices.close(i)


if __name__ == '__main__':
    main()
