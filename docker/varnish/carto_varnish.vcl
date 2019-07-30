acl purge {
    "172.0.0.0"/8;
}

backend sqlapi {
    .host = "sqlapi";
    .port = "8080";
}

backend windshaft {
    .host = "windshaft";
    .port = "8181";
}

sub vcl_recv {
    if (req.http.X-Carto-Service == "windshaft") {
      set req.backend = windshaft;
      remove req.http.X-Carto-Service;
    }

    if (req.http.X-Carto-Service == "sqlapi") {
      set req.backend = sqlapi;
      remove req.http.X-Carto-Service;
    }

    if (req.request == "PURGE") {
        if (!client.ip ~ purge) {
            error 405 "Not allowed.";
        }
        return (lookup);
    }
}

sub vcl_hit {
    if (req.request == "PURGE") {
        purge;
        error 200 "Purged.";
    }
}

sub vcl_miss {
    if (req.request == "PURGE") {
        purge;
        error 200 "Purged.";
    }
}
