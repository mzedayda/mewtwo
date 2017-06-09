build:
	coffee -o lib -c src
	coffee -o test/lib -c test/src

run: build
	node lib/index.js

test: build
	mocha test/lib

test-watch: build
	mocha -w test/lib
