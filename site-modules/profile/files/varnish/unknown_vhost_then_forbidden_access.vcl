# known_vhost_determine_forbidden_access.vcl
#
# Now that we passed along all vhosts declared, we should be able to determine
# if the access to such query should be forbidden or not
#
# File managed by puppet. All modifications will be lost.

sub vcl_recv {
    if (var.get("known-vhost") != "yes") {
        return(synth(403, "Forbidden access to unknown vhost " + req.http.host));
    }
}
