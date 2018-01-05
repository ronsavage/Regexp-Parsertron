#!/usr/bin/env perl

use strict;
use warnings;

# -----------

my($s)	= 'a';
my($re)	= qr/^/;

print "String: $s. Regexp: $re. \n";

if ($s =~ $re)
{
	print "Match. \n";
}
else
{
	print "Does not match. \n";
}
