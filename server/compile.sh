#!/bin/sh

fpc -S2cgi -O2 -Sa -Sd -Sh -gl -gh -vewnhi -l -Fusrc/ -Fu../units/ -Fu. -oserver server.lpr -v0i
strip --strip-all server