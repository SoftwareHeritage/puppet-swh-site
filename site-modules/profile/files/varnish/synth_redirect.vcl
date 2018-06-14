# synth_redirect.vcl
#
# Redirect to the x-redir http header when receiving a synthesized code 850
#
# Example use:
# sub vcl_recv {
#   set req.http.x-redir = "https://" + req.http.host + req.url;
#   return(synth(850, "Moved permanently"));
# }
#
# File managed by puppet. All modifications will be lost.

sub vcl_synth {
    if (resp.status == 850) {
        set resp.http.Location = req.http.x-redir;
        set resp.status = 302;
        return (deliver);
    }
}
