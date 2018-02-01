#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Regexp::Parsertron;

# ------------------------------------------------

my($parser)	= Regexp::Parsertron -> new(verbose => 2);
my($re)		= qr/(?(?!\x{100})b|\x{100})/;
my($s)		= '\x{100}';

if ($s =~ $re)
{
	say "$s matches $re";
}
else
{
	say "$s does not match $re";
}
