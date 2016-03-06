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
	re		=> qr//i,
	target	=> '',
},
{
	count	=> 2,
	re		=> qr/A|B/i,
	target	=> 'A',
},
);

my($result);

for my $test (@test)
{
	# Use this trick to run the tests one-at-a-time. See scripts/test.sh.

	next if ( ($limit > 0) && ($$test{count} != $limit) );

	$result = $parser -> parse(re => $$test{re}, target => $$test{target});
}

