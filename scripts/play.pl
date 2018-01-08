#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

# -----------

my($one)	= '(?:(?<n>foo)|(?<n>bar))\k<n>';
my($re1)	= qr/$one/;

say "one: $one. re1: $re1";

my($s)	= 'foofoo';
my($re)	= qr/(?:(?<n>foo)|(?<n>bar))\k<n>/;

say "String: $s. Regexp: $re. ";

if ($s =~ $re)
{
	print "Match. \n";
}
else
{
	say "Does not match. ";
}
