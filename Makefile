MAKEFLAGS += --silent

build:
	stack build
	stack exec site build

monitor:
	stack exec site watch

clean:
	stack exec site clean

deploy:
	rsync -avz --delete-after --delete --exclude .DS_Store _site/ jeoygin.org:/var/www/jeoygin.org/public_html/

neworg:
        ifdef n
		touch "posts/`date +%Y-%m-%d`-${n}.org"
        else
		echo "Please input var 'n'"
        endif

labels:
	./build-labels.sh
