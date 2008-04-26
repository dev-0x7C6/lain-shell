#!/bin/sh

cd lang
./codepages.sh
cd ..
fpc -S2cgi -OG1 -Or -g -Sa -Sd -Sh -gl -gh -WG -vewnhi -l -Fusrc/ -Fuunits/ -Fu../units/ -Fu. -oclient client.lpr -v0i
strip --strip-all client