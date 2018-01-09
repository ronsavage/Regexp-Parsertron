#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Capture::Tiny ':all';

use File::Slurper 'read_lines';

use Regexp::Parsertron;

# Warning: Can't use Test2 or Test::Stream because of the '#' in the regexps.

use Test::More;

use Try::Tiny;

# ------------------------------------------------

# The input file is generated by scripts/extract.errors.pl.

my($input_file)	= 'xt/author/perl-5.21.11.tests';
my(@lines)		= read_lines($input_file);
my($parser)		= Regexp::Parsertron -> new;
my($count)		= 0;

my($expected);
my($got);
my($message);
my($perl_error);
my($re, $result, @result);
my($stdout, $stderr);

for my $test (@lines)
{
	$count++;

	$stderr = '';

	# The try is for when Perl throws an error on a regexp syntax error.
	# The capture is for when Perl prints a warning to stderr. Eg: /a{4,1}/ because 4 > 1.

	try
	{
		($stdout, $stderr) = capture
		{
			$re = qr/$test/;
		};
	}
	catch
	{
		$stderr = $_;
	};

	if ($stderr)
	{
		# This line is 'print', not 'say'!

		#print "Count: $count. Perl error: " . $stderr;

		next;
	}

	try
	{
		$result = $parser -> parse(re => $re);

		if ($result == 0)
		{
			$got		= $parser -> as_string;
			$message	= "Count: $count: re: $re. got: $got";

			is_deeply($got, "$re", $message);
		}
		else
		{
			#say "Count: $count. " . $parser -> warning_str;
		}
	}
	catch
	{
		# This line is 'print', not 'say'!

		#print "Count: $count: Error in $test: $_" if (defined);
	};

	# Reset for next test.

	$parser -> reset;
}

print "# Internal test count: $count\n";

done_testing;