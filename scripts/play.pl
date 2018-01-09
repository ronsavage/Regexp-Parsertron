#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Regexp::Parsertron;

# -----------

my($one)	= '(?:(?<n>foo)|(?<n>bar))\k<n>';
my($re1)	= qr/$one/;

say "one: $one. re1: $re1";

my($two)	= '/foofoo/';
my($re2)	= qr/$two/;

say "two: $two. re2: $re2";

my($s)	= 'foofoo';
my($re)	= qr/(?:(?<n>foo)|(?<n>bar))\k<n>/;

say "String: $s. Regexp: $re. ";

if ($s =~ $re)
{
	say "Match. ";
}
else
{
	say "Does not match. ";
}

my($parser)		= Regexp::Parsertron -> new(verbose => 2);
my($result)		= $parser -> parse(re => $two);
my($as_string)	= $parser -> as_string;

say "result: $result (0 is success). as_string: $as_string";
