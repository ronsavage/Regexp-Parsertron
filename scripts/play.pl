#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

# -----------

my($one)	= '[yY][eE][sS]';
my($re1)	= qr/$one/;

say "one: $one. re1: $re1";

my($s)	= 'foofoo';
my($re)	= qr/(?#Comment)(?:(?<n>foo)|(?<n>bar))\k<n>/;

say "String: $s. Regexp: $re. ";

if ($s =~ $re)
{
	print "Match. \n";
}
else
{
	say "Does not match. ";
}
