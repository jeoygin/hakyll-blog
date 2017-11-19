
build:
	stack build
	stack exec site build

monitor:
	stack exec site watch

clean:
	stack exec site clean

deploy:
	rsync -avz --delete-after --delete --exclude .DS_Store _site/ root@jeoygin.org:/var/www/jeoygin.org/public_html/

labels:
	./build-labels.sh
