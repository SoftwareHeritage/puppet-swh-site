# The following function allows to unflatten keys from the following form:
# mediawiki::vhosts::domain::basic_auth_content: some-basic-auth-content
# mediawiki::vhosts::domain::icinga_http_auth_pair: some-http-auth-pair
# mediawiki::vhosts::domain::mysql::password: some-password
# mediawiki::vhosts::other-domain::basic_auth_content: other-basic-auth-content
# mediawiki::vhosts::other-domain::icinga_http_auth_pair: other-http-auth-pair
# into a nested ruby dict of the form:
# {
#   'mediawiki' => {
#     'vhosts' => {
#       'domain' => {
#         'basic_auth_content' => 'some-basic-auth-content'
#         'icinga_http_auth_pair' => 'some-http-auth-pair'
#         'mysql' => {
#           'password' => 'some-password'
#         }
#       'other-domain' => {
#         'basic_auth_content' => 'other-basic-auth-content'
#         'icinga_http_auth_pair' => 'other-http-auth-pair'
#       }
#     }
#   }
# }
Puppet::Functions.create_function(:'unflatten_keys') do
  dispatch :unflatten_keys do
    param 'Hash', :flattened
  end

  def unflatten_keys(flattened)
    result = {}

    flattened.each do |key, value|
      # Split the key by '::' to get the path components
      parts = key.split('::')

      # Navigate/create the nested structure
      current = result
      parts[0...-1].each do |part|
        current[part] ||= {}
        current = current[part]
      end

      # Set the final value
      current[parts[-1]] = value
    end

    result
  end
end
