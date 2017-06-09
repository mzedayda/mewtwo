build:
	coffee -o lib -c src
	coffee -o test/lib -c test/src

build-watch:
	coffee -o lib -wc src
	coffee -o test/lib -wc test/src

run: build
	node lib/index.js

test: build
	mocha --growl test/lib

test-watch: build
	mocha test/lib --growl -w 
