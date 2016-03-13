#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# ---------------------

my(@test)	=
(
{
	count	=> 1,
	re		=> '(?#Comment)',
},
{
	count	=> 2,
	re		=> '(?)',
},
{
	count	=> 3,
	re		=> '(?a)',
},
{
	count	=> 4,
	re		=> '(?a-i)',
},
{
	count	=> 5,
	re		=> '(?^a)',
},
{
	count	=> 6,
	re		=> '(?a:)',
},
{
	count	=> 7,
	re		=> '(?a:b)',
},
{
	count	=> 8,
	re		=> '(?:)',
},
{
	count	=> 9,
	re		=> '[yY][eE][sS]',
},
{
	count	=> 10,
	re		=> '(A|B)',
},
);

my($number)		= shift(@ARGV) || 0;
my($parser)		= Regexp::Parsertron -> new(verbose => 1);

my($result);

for my $test (@test)
{
	# Use this trick to run the tests one-at-a-time. See scripts/test.sh.

	next if ( ($number > 0) && ($$test{count} != $number) );

	$result = $parser -> parse(re => $$test{re});
}
