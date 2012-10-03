#!/bin/sh

if [ -z "$1" ]; then
 echo "Usage: $0 distdir"
 exit 1
fi

lftp <<-END
 open m2
 cd public_html/agoraguide/
 lcd $1
 mirror -R
 close
END

# vim: syntax=lftp
