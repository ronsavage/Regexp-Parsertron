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

say "Calling append(text => '|C++', uid => 6)";

$parser -> append(text => '|C++', uid => 6);
$parser -> print_raw_tree;
$parser -> print_cooked_tree;

my($as_string) = $parser -> as_string;

say "Original:    $re. Result: $result (0 is success)";
say "as_string(): $as_string";

$result = $parser -> validate;

say "validate():  Result: $result (0 is success)";

# Return 0 for success and 1 for failure.

say 'Add complexity to the regexp';

$parser -> reset;
$parser -> verbose(0);

$re		= qr/Perl|JavaScript|(?:Flub|BCPL)/i;
$result	= $parser -> parse(re => $re);

$parser -> print_raw_tree;
