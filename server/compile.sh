#!/bin/sh

fpc -S2cgi -OG1 -Or -g -Sa -Sd -Sh -gl -gh -WG -vewnhi -l -Fusrc/ -Fuunits/ -Fu../units/ -Fu. -oserver server.lpr -v0i
strip --strip-all server