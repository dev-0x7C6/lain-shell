@echo off

fpc client.lpr -S2cadgi -Cirot -O2 -g -gl -gh -vewnhi -l -Fuunits\ -Fu..\units\ -Fusrc\ -Fulang\ -Fu. -oclient.exe -v0i
strip --strip-all client.exe