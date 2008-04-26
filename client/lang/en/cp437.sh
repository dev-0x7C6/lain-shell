#!/bin/sh

echo [EN] Convert from utf8 to cp437 ...
iconv -f utf-8 -t CP437 lang.txt > lang_cp437.txt