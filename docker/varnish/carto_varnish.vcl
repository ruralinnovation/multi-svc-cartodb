acl purge {
    "cartodb";
    "postgis";
    "windshaft";
    "sqlapi";
    "localhost";
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
    if (server.port == 8181) {
      set req.backend = windshaft;
    }

    if (server.port == 8080) {
      set req.backend = sqlapi;
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
