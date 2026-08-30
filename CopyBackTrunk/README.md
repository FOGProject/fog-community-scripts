### AUTHOR: Tom Elliott
---

* All this does is copy the files from the trunk web folder to the real document root.
* It can take an argument to tell what path of trunk else it will assume ~/trunk.
* After deploying it restarts the web server and PHP-FPM (so opcache does not
  keep serving the old code) and every **running** `FOG*` systemd service. The
  daemons load the webroot this script replaces, so without that restart a
  deploy that changes daemon behavior appears to do nothing. Note this
  interrupts an in-flight replication transfer or multicast session, which is
  picked up again on the daemon's next pass — `installfog.sh` has always
  behaved the same way.
