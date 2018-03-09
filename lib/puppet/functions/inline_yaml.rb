require 'yaml'

Puppet::Functions.create_function(:inline_yaml) do
  dispatch :from_variable do
    param 'Hash', :variable
    optional_param 'Variant[Hash, Array]', :parameters
    return_type 'String'
  end

  def from_variable(variable, parameters = {})
    params = {
      'header'       => '# File managed by puppet - modifications will be lost',
      'indent_lines' => 0,
    }.merge(parameters)

    header = params['header']
    indent_lines = params['indent_lines']

    data = YAML.dump(variable).lines[1..-1].join.rstrip << "\n"
    if indent_lines
      data = data.each_line { |l| (' ' * indent_lines) + l }
    end

    if header
      "#{header}\n#{data}"
    else
      data
    end
  end
end

