@echo off

fpc server.lpr -S2cgi -OG1 -gl -gh -WG -vewnhi -l -Fusrc\ -Fu..\units\ -Fu. -oserver.exe -v0i
strip --strip-all server.exe