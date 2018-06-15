#!/usr/bin/env python3

"""Script to execute the export of softwareheritage's rrds data.

"""

import click
import json
import os
import subprocess


DIRPATH='/var/lib/munin/softwareheritage.org/'
FILENAME_PATTERN="prado.softwareheritage.org-softwareheritage_objects_softwareheritage-###-g.rrd"
# The data source used at rrd creation time
DS=42

ENTITIES=[
    "content",
    "origin",
    "revision",
    # "directory_entry_dir",
    # "directory_entry_file",
    # "directory_entry_rev",
    # "directory",
    # "entity",
    # "occurrence_history",
    # "person",
    # "project",
    # "release",
    # "revision_history",
    # "skipped_content",
    # "visit",
]

def compute_cmd(dirpath,
                start,
                step=86400):
    """Compute the command to execute to retrieve the needed data.

    Returns:
        The command as string.

    """
    cmd = ['rrdtool', 'xport', '--json', '--start', str(start), '--end', 'now-1d',
           '--step', str(step)]
    for entity in ENTITIES:
        filename = FILENAME_PATTERN.replace('###', entity)
        filepath = os.path.join(dirpath, filename)

        if os.path.exists(filepath):
            cmd.extend(['DEF:out-%s1=%s:%s:AVERAGE' % (entity, filepath, DS),
                        'XPORT:out-%s1:%s' % (entity, entity)])

    return cmd


def retrieve_json(cmd):
    """Given the cmd command, execute and returns the right json format.

    Args:
        cmd: the command to execute to retrieve the desired json.

    Returns:
        The desired result as json string.
    """
    cmdpipe = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    data = b''
    while True:
        line = cmdpipe.stdout.readline()
        if not line:
            break
        # Hack: the json output is not well-formed...
        line = line.replace(b'\'', b'"')
        line = line.replace(b'about: ', b'"about": ')
        line = line.replace(b'meta:', b'"meta": ')
        data += line

    cmdpipe.stdout.close()
    return json.loads(data.decode('utf-8'))


def prepare_data(data):
    """Prepare the data with x,y coordinate.

    x is the time, y is the actual value.
    """
    # javascript has a ratio of 1000...
    step = data['meta']['step'] * 1000  # nb of milliseconds
    start_ts = data['meta']['start'] * 1000  # starting ts

    legends = data['meta']['legend']

    # The legends, something like
    # ["content-avg", "content-min", "content-max", "directory_entry_dir-avg", ...]
    r = {}
    day_ts = start_ts
    for day, values in enumerate(data['data']):
        day_ts += step
        for col, value in enumerate(values):
            if value is None:
                continue
            legend_col = legends[col]
            l = r.get(legend_col, [])
            l.append((day_ts, value))
            r[legend_col] = l

    return r


@click.command()
@click.option('--dirpath', default=DIRPATH, help="Default path to look for rrd files.")
@click.option('--start', default=1434499200, help="Default starting timestamp")   # Default to 2015-05-12T16:51:25Z
@click.option('--step', default=86400, help="Compute the data step (default to 86400).")
def main(dirpath, start, step):

    # Delegate the execution to the system
    run_cmd = compute_cmd(dirpath, start, step)
    data = retrieve_json(run_cmd)

    # Format data
    data = prepare_data(data)

    print(json.dumps(data))


if __name__ == '__main__':
    main()
