#!/bin/bash

DIR=Perl-modules/html/Regexp
FILE=Parsertron.html

mkdir -p $DR/$DIR ~/savage.net.au/$DIR

pod2html.pl -i lib/Regexp/Parsertron.pm -o $DR/$DIR/$FILE

cp $DR/$DIR/$FILE ~/savage.net.au/$DIR
