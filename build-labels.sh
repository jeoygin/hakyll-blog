#!/usr/bin/env bash

labels=$( ls _site/label | while read label
do
  echo -e "$label\t$( egrep '<a href="/[0-9]{4}/[0-9]{2}/[0-9]{2}' "_site/label/$label/index.html" | wc -l )"
done | sort -k 2 -gr | head -n 12 | awk 'BEGIN{ORS=""}{print "<li class=\"cat-item\"><a href=\"/label/"$1"\">"$1" ("$2")</a></li>"}' )

sed -e "s:<\!--LABELS-->:$labels:g" templates/default.tmpl > templates/default.html
