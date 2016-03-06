#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# -----------

my($parser)	= Regexp::Parsertron -> new;
my(@test)	=
(
{
	count	=> 1,
	re		=> '(?#Comment)',
	target	=> 'z',
},
{
	count	=> 2,
	re		=> '(?)',
	target	=> 'z',
},
{
	count	=> 3,
	re		=> '(?a)',
	target	=> 'z',
},
{
	count	=> 4,
	re		=> '(?a-i)',
	target	=> 'z',
},
{
	count	=> 5,
	re		=> '(?^a)',
	target	=> 'z',
},
{
	count	=> 6,
	re		=> '(?a:)',
	target	=> 'z',
},
{
	count	=> 7,
	re		=> '(?a:b)',
	target	=> 'z',
},
{
	count	=> 8,
	re		=> '(?:)',
	target	=> 'z',
},
{
	count	=> 9,
	re		=> '(?:a)z',
	target	=> 'z',
},
{
	count	=> 10,
	re		=> '(?:a-i)z',
	target	=> 'z',
},
{
	count	=> 11,
	re		=> '(?^:a)z',
	target	=> 'z',
},
{
	count	=> 12,
	re		=> '[yY][eE][sS]',
	target	=> 'z',
},
);

my($limit);

my($result);

for my $test (@test)
{
	# Use this trick to run the tests one-at-a-time. See scripts/test.sh.

	$limit = shift(@ARGV);

	print "limit: $limit. \n";

	next if ( ($limit > 0) && ($$test{count} != $limit) );

	$result = $parser -> parse(count => $$test{count}, re => $$test{re}, target => $$test{target});
}

$parser -> report;
