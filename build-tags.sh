#!/usr/bin/env bash

tags=$( ls _site/tags | while read tag
do
  echo -e "$tag\t$( egrep '<a href="/[0-9]{4}/[0-9]{2}/[0-9]{2}' "_site/tags/$tag/index.html" | wc -l )"
done | sort -k 2 -gr | head -n 12 | awk 'BEGIN{ORS=""}{print "<li class=\"cat-item\"><a href=\"/tags/"$1"\">"$1" ("$2")</a></li>"}' )

sed -e "s:<\!--TAGS-->:$tags:g" templates/default.tmpl > templates/default.html
