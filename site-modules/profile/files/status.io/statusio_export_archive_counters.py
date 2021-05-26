#!/usr/bin/python3
# File managed by puppet (class ::profile::status_io_metrics), changes will be lost.

# python3 update_metrics.py -m swh_web_accepted_save_requests --api-id 1234 --api-key 456 --status-page-id 123 \
#   --metric-id 456 -f environment="production" -f "load_task_status=~scheduled|not_yet_scheduled" -f instance=moma.internal.softwareheritage.org
import statusio
import requests
from datetime import datetime, timedelta
from typing import List, Tuple
import os
import click

# 2014-03-28T05:43:00+00:00
API_DATE_FORMAT = "%Y-%m-%dT%H:%M:%S+00:00"


def extract_metrics(raw_data) -> List[List]:
    return raw_data["data"]["result"][0]["values"]


def get_average(values: List[int]) -> float:
    return sum(values) / len(values)


def escape_filter(filter: str) -> str:
    if "=~" in filter:
        separator = "=~"
    else:
        separator = "="

    terms = filter.split(separator)

    return f'{terms[0]}{separator}"{terms[1]}"'


def get_prometheus_values(
    prometheus_url: str,
    metric: str,
    filters: List[str],
    start: int,
    end: int,
    interval: int,
) -> List[List]:
    escaped_filters = [escape_filter(filter) for filter in filters]

    metric_filters = ",".join(escaped_filters)

    url = f"{prometheus_url}?query=sum({metric}{{{metric_filters}}})&start={start}&end={end}&step={interval}"

    response = requests.get(url)
    if response.ok == False:
        raise ValueError(f"Unable to get prometheus metrics: {response.text}")

    return extract_metrics(response.json())


def extract_status_io_data(prometheus_data: List[List]) -> Tuple[List[str], List[int]]:
    dates = []
    values = []

    for tuple in prometheus_data:
        date = datetime.fromtimestamp(tuple[0])

        dates.append(date.strftime(API_DATE_FORMAT))
        values.append(int(tuple[1]))

    return (dates, values)


@click.command()
@click.option(
    "--prometheus-server",
    "-s",
    default="pergamon.internal.softwareheritage.org",
    help="Prometheus instance",
)
@click.option(
    "--prometheus-port",
    "-p",
    default=9090,
    type=click.INT,
    help="Prometheus instance service port",
)
@click.option(
    "--prometheus-metric",
    "-m",
    required=True,
    help="Prometheus metric to query",
)
@click.option(
    "--prometheus-filter",
    "-f",
    multiple=True,
    help="Prometheus metric to query",
)
@click.option(
    "--api-id",
    required=True,
    help="status io api id",
)
@click.option(
    "--api-key",
    required=True,
    help="status io api key",
)
@click.option(
    "--status-page-id",
    required=True,
    help="status io status page id",
)
@click.option(
    "--metric-id",
    required=True,
    help="status io metric id",
)
def main(
    prometheus_server: str,
    prometheus_port: int,
    prometheus_metric: str,
    prometheus_filter: List[str],
    api_id: str,
    api_key: str,
    status_page_id: str,
    metric_id: str,
):
    """populate a status.io metric from a prometheus metric"""

    prometheus_url = f"http://{prometheus_server}:{prometheus_port}/api/v1/query_range"

    # dates computation
    current_time = datetime.utcnow()
    day_start = current_time - timedelta(days=1)
    hour_interval = 3600
    day_interval = 3600 * 24
    week_start = current_time - timedelta(days=7)
    month_start = current_time - timedelta(days=30)

    api = statusio.Api(api_id=api_id, api_key=api_key)

    raw_values = get_prometheus_values(
        prometheus_url,
        prometheus_metric,
        prometheus_filter,
        day_start.timestamp(),
        current_time.timestamp(),
        hour_interval,
    )

    day_dates, day_values = extract_status_io_data(raw_values)
    day_avg = get_average(day_values)

    raw_values = get_prometheus_values(
        prometheus_url,
        prometheus_metric,
        prometheus_filter,
        week_start.timestamp(),
        current_time.timestamp(),
        day_interval,
    )

    week_dates, week_values = extract_status_io_data(raw_values)
    week_avg = get_average(week_values)

    raw_values = get_prometheus_values(
        prometheus_url,
        prometheus_metric,
        prometheus_filter,
        month_start.timestamp(),
        current_time.timestamp(),
        day_interval,
    )

    month_dates, month_values = extract_status_io_data(raw_values)
    month_avg = get_average(month_values)

    result = api.MetricUpdate(
        statuspage_id=status_page_id,
        metric_id=metric_id,
        day_avg=day_avg,
        day_start=day_start.timestamp(),
        day_dates=day_dates,
        day_values=day_values,
        week_avg=week_avg,
        week_start=week_start.timestamp(),
        week_dates=week_dates,
        week_values=week_values,
        month_avg=month_avg,
        month_start=month_start.timestamp(),
        month_dates=month_dates,
        month_values=month_values,
    )

    # this line will be sent by email via cron 
    # if the return code is not 0
    print(result)

    if result.get("result") == False:
        exit(1)
    exit(0)


if __name__ == "__main__":
    main()
