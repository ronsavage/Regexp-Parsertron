#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# Warning: Can't use Test2 or Test::Stream because of the '#' in the regexps.

use Test::More;

# ---------------------

my($re)		= qr/Perl|JavaScript/i;
my($parser)	= Regexp::Parsertron -> new(re => $re);

# Return 0 for success and 1 for failure.

my($result) = $parser -> parse(re => $re);

$parser -> add(text => '|C++', uid => 6);

my($count) = 0;

ok($parser -> uid == 7, 'Check uid counts'); $count++;

my(%text) =
(
	1 => '(',
	3 => '^',
	5 => ':',
	6 => 'Perl|JavaScript|C++',
);

my($text);

for my $uid (sort keys %text)
{
	$text = $parser -> get($uid);

	ok($text{$uid} eq $text, "Check text of uid $uid => $text"); $count++;

}

print "# Internal test count: $count\n";

done_testing();

