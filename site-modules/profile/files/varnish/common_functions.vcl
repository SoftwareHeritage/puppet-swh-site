# Varnish configuration file
# File managed by puppet (module profile::varnish)
# All modifications will be lost.

sub set_ip_headers {
    if (req.http.x-forwarded-for) {
        set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
    } else {
        set req.http.X-Forwarded-For = client.ip;
    }
    set req.http.X-Real-Ip = client.ip;
}

sub clean_ip_headers {
    if (!req.http.x-forwarded-for) {
        return;
    }
    set req.http.x-forwarded-for = regsuball(req.http.x-forwarded-for, ", ?::1[^,]*", "");
}
