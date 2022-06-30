# 00_early_vcl_recv.vcl
#
# Do early manglement of the host header to simplify its future handling
#
# File managed by puppet. All modifications will be lost.

import std;

sub vcl_recv {
  # Keep original Host header in X-Swh-Original-Host.
  set req.http.x-swh-original-host = req.http.host;

  # Set Host header to lower case and trim trailing port number.
  set req.http.host = regsub(std.tolower(req.http.host), ":[0-9]+$", "");
}
