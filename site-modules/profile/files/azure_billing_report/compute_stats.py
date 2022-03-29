##
# File managed by puppet (class profile::azure_billing_report), changes will be lost.

from datetime import datetime
from jinja2 import Environment, FileSystemLoader

import click
import matplotlib.pyplot as plt
import pandas

def generate_simple_costs(
        data: pandas.DataFrame,
        date_format: str,
        base_file_name: str) -> None:

    data.reset_index(inplace=True)

    data['Date'] = data['Date'].dt.strftime(date_format)
    data.filter(items=['Date', 'Cost'])
    generate_data_files(data[['Date', 'Cost']], base_file_name)


def pad_series(series: pandas.Series) -> pandas.Series:
    return series.astype(str).str.pad(2, fillchar='0')


def generate_data_files(data: pandas.DataFrame, base_name: str) -> None:
    with open(f"{base_name}.md", 'w') as f:
        print(f"Generating {f.name}")
        f.write(data.to_markdown(index=False))
    with open(f"{base_name}.html", 'w') as f:
        print(f"Generating {f.name}")
        f.write(data.to_html(
            index=False,
            float_format=lambda x: '%10.2f' % x)
        )


@click.command()
@click.argument('output_dir', type=click.Path(exists="true"), default="AzureUsage.csv")
def main(output_dir) -> None:

    csv = pandas.read_csv(output_dir + '/AzureUsage.csv', parse_dates=[2])

    # Cost per day
    cost_per_day = csv.groupby('Date', as_index=True).sum()
    cost_per_day.plot(y='Cost')
    plt.savefig(f"{output_dir}/cost_per_day.png")

    cost_per_day.reset_index(inplace=True)
    cost_per_day['Year'] = cost_per_day['Date'].dt.year
    cost_per_day['Month'] = cost_per_day['Date'].dt.month
    cost_per_day['Day'] = cost_per_day['Date'].dt.day
    cost_per_day.sort_values(by=['Year', 'Month', 'Day'], inplace=True, ascending=False)

    generate_simple_costs(cost_per_day, "%Y-%m-%d", output_dir + "/cost_per_day")

    # Cost per month
    cost_per_month = csv.groupby(pandas.Grouper(key='Date', freq='M'), as_index=True).sum()
    cost_per_month.plot(y='Cost')
    plt.savefig(f"{output_dir}/cost_per_month.png")

    cost_per_month.reset_index(inplace=True)
    cost_per_month['Year'] = cost_per_month['Date'].dt.year
    cost_per_month['Month'] = cost_per_month['Date'].dt.month
    cost_per_month.sort_values(by=['Year', 'Month'], inplace=True, ascending=False)

    generate_simple_costs(cost_per_month, "%Y-%m", output_dir + "/cost_per_month")

    # Cost per service per month
    cost_per_service = csv.copy()
    cost_per_service['Year'] = cost_per_service['Date'].dt.year
    cost_per_service['Month'] = cost_per_service['Date'].dt.month
    cost_per_service['Day'] = cost_per_service['Date'].dt.day
    cost_per_service_per_month = cost_per_service.groupby(['Year', 'Month', 'ServiceName', 'ServiceResource']).sum()
    cost_per_service_per_month.reset_index(inplace=True)
    cost_per_service_per_month.sort_values(by=['Year', 'Month','Cost'], inplace=True, ascending=False)
    cost_per_service_per_month['Date'] = cost_per_service_per_month['Year'].astype(str) + \
        '-' + \
        pad_series(cost_per_service_per_month['Month'])

    generate_data_files(
        cost_per_service_per_month[['Date','ServiceName', 'ServiceResource', 'Cost']],
        output_dir + "/cost_per_service_per_month")

    # Cost per service per day
    cost_per_service_per_day = cost_per_service.groupby(['Year', 'Month', 'Day', 'ServiceName', 'ServiceResource']).sum()
    cost_per_service_per_day.reset_index(inplace=True)
    cost_per_service_per_day.sort_values(by=['Year', 'Month', 'Day', 'Cost'], inplace=True, ascending=False)
    cost_per_service_per_day['Date'] = cost_per_service_per_day['Year'].astype(str) + \
        '-' + \
        pad_series(cost_per_service_per_day['Month']) + \
        '-' + \
        pad_series(cost_per_service_per_day['Day'])

    generate_data_files(cost_per_service_per_day[['Date','ServiceName', 'ServiceResource', 'Cost']], output_dir + "/cost_per_service_per_day")

    ##
    # index.html page generation
    ##
    index_file_name = f"{output_dir}/index.html"
    print(f"Generating {index_file_name}")

    generated_date = datetime.now()

    template_file_loader = FileSystemLoader(searchpath='./')
    env = Environment(loader=template_file_loader)
    template = env.get_template('index.html.tmpl')
    index = template.render(generated_date=generated_date)

    with open(index_file_name, 'w') as f:
        f.write(index)

if __name__ == '__main__':
    main()
