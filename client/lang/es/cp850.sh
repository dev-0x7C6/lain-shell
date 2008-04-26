#!/bin/sh

echo [ES] Convert from utf8 to cp850 ...
iconv -f utf-8 -t CP850 lang.txt > lang_cp850.txt