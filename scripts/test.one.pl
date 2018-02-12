#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# ------------------------------------------------

my($parser)	= Regexp::Parsertron -> new(verbose => 2);
#my($re)	= qr/(?(?!\x{100})b|\x{100})/;
#my($s)		= '\x{100}';
my($re)		= qr/^/;
my($s)		= 'anything';

if ($s =~ $re)
{
	say "'$s' matches $re";
}
else
{
	say "'$s' does not match $re";
}
