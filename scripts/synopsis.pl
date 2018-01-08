#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Regexp::Parsertron;

# ---------------------

my($re)		= qr/Perl|JavaScript/i;
my($parser)	= Regexp::Parsertron -> new(verbose => 1);

# Return 0 for success and 1 for failure.

my($result) = $parser -> parse(re => $re);

print "Calling add(text => '|C++', uid => 6)\n";

$parser -> add(text => '|C++', uid => 6);
$parser -> raw_tree;
$parser -> cooked_tree;

my($get) = $parser -> get;

print "Original:  $re. Result: $result. (0 is success)\n";
print "Get:       $get\n";
print 'Perl error count:  ', $parser -> perl_error_count, "\n";
print 'Marpa error count: ', $parser -> marpa_error_count, "\n";

my($target) = 'C++';

if ($target eq $get)
{
	say "Matches $target. ";
}
else
{
	say "Doesn't match $target. ";
}
