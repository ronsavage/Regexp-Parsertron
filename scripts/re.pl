#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# ---------------------

my($s)	= '+a';
my($re)	= '/^[+]([^(]+)$/mi';

print "String: $s. Regexp: $re. ", ( ($s =~ $re) ? "Match. \n" : "No match. \n");

my($parser) = Regexp::Parsertron -> new(verbose => 2);

# Return 0 for success and 1 for failure.

my($result) = $parser -> parse(re => $re);

$parser -> report_tree if ($result == 1);

print "Parsing $re. \n";
print 'Perl error count:  ', $parser -> perl_error_count, "\n";
print 'Marpa error count: ', $parser -> marpa_error_count, "\n";
