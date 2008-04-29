#!/bin/sh

cd lang
./codepages.sh
cd ..
fpc -S2cgi -O2 -Sa -Sd -Sh -gl -gh -vewnhi -l -Fusrc/ -Fuunits/ -Fu../units/ -Fu. -oclient client.lpr -v0i
strip --strip-all client