#!/usr/bin/env bash

rsync -avz --delete-after --delete --exclude .DS_Store _site/ root@jeoygin.org:/var/www/jeoygin.org/public_html/
