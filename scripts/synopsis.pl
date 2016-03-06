#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# -----------

my($limit)	= shift || 0;
my($parser)	= Regexp::Parsertron -> new;
my(@test)	=
(
{
	count	=> 1,
	regexp	=> qr//i,
	string	=> '',
	target	=> '',
},
{
	count	=> 2,
	regexp	=> qr/A|B/i,
	string	=> 'A|B',
	target	=> 'A',
},
);

my($result);

for my $test (@test)
{
	# Use this trick to run the tests one-at-a-time. See scripts/test.sh.

	next if ( ($limit > 0) && ($$test{count} != $limit) );

	$result = $parser -> parse($$test{target}, $$test{regexp}, $$test{string});
}

