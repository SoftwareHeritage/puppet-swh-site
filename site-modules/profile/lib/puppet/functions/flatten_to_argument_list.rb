require 'shellwords'

Puppet::Functions.create_function(:flatten_to_argument_list) do
  dispatch :flatten_to_argument_list do
    param 'Hash', :variable
    optional_param 'String', :escaping_type
    optional_param 'String', :prefix
    return_type 'Array[String]'
  end

  def flatten_to_argument_list(variable, escaping_type = 'systemd', prefix = '--')
    ret = []
    variable.each do |key, value|
      arg = "#{prefix}#{key}".gsub('_', '-')
      if Hash === value
        ret += flatten_to_argument_list(value, escaping_type, "#{arg}.")
      else
        if value == true
          ret.push(arg)
        else
          if escaping_type == 'systemd'
            # This replaces every backslash with four backslashes to please
            # systemd's EnvironmentFile escaping. Yes, gsub needs four
            # backslashes per output backslash.
            value.gsub!('\\', '\\\\\\\\\\\\\\\\')
          elsif escaping_type == 'shell'
            value = Shellwords.escape(value)
          end
          ret.push("#{arg}=#{value}")
        end
      end
    end
    ret
  end
end
