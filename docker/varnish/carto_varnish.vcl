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
}
