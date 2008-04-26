#!/bin/sh

echo [PL] Convert from utf8 to cp852 ...
iconv -f utf-8 -t CP852 lang.txt > lang_cp852.txt