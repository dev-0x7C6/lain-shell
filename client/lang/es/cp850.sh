#!/bin/sh

echo [ES] Convert lang.txt from utf8 to cp850 ...
iconv -f utf-8 -t CP850 lang.txt > lang_cp850.txt
echo [ES] Convert users.txt from utf8 to cp850 ...
iconv -f utf-8 -t CP850 users.txt > users_cp850.txt
echo [ES] Convert engine.txt from utf8 to cp850 ...
iconv -f utf-8 -t CP850 engine.txt > engine_cp850.txt