# This file has to exist so that at least one file ending in .sh is in the
# initdb.d directory. Because Docker builds fail on a COPY command with no
# target, the lines in the Dockerfile that copy initdb.d/*.sh and *.sql have
# must find at least one file. Unfortunately at this time there is no way
# to have a conditional COPY (copy-if-exists) command in a Dockerfile.
