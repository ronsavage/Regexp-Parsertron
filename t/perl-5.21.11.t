#!/usr/bin/env perl

use strict;
use warnings;

use File::Slurper 'read_lines';

use Regexp::Parsertron;

# Warning: Can't use Test2 or Test::Stream because of the '#' in the regexps.

use Test::More;

# ------------------------------------------------

# The input file is genetared by scripts/extract.errors.pl.

my($input_file)	= 't/perl-5.21.11.tests';
my(@lines)		= read_lines($input_file);
my($parser)		= Regexp::Parsertron -> new;
my($count)		= 0;

my($expected);
my($got);
my($message);
my($re, $result);

for my $test (@lines)
{
	$count++;

	$re		= qr/$test/;
	$result	= $parser -> parse(re => $re);

	if ($result == 0)
	{
		$got		= $parser -> as_string;
		$message	= "$count: re: $re. got: $got";

		is_deeply($got, "$re", $message);
	}
	else
	{
		BAIL_OUT("Test $count failed to return 0 from process()");
	}

	# Reset for next test.

	$parser -> reset;
}

done_testing;
