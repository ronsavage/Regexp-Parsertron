#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Regexp::Parsertron;

use Try::Tiny;

# -----------

my($parser)	= Regexp::Parsertron -> new(verbose => 2);
my(%input)	=
(
	1 => q!(?|(.{2,4}))!,
	2 => q!Perl|JavaScript|(?:Flub|BCPL)!,
);

my($as_string);
my($error_str);
my($found);
my($re, $result, %re);
my($s);

for my $key (sort keys %input)
{
	say "Case $key: ";

	$error_str	= '';
	$s			= $input{$key};

	try
	{
		$re	= qr/$s/;
	}
	catch
	{
		$error_str = "Perl error for $s: $_"; # Do it this way because continue and next don't work inside try.

		print $error_str;
	};

	next if ($error_str);

	try
	{
		$result		= $parser -> parse(re => $s);
		$as_string	= $parser -> as_string;
		$re{$key}	= $as_string;

		say "result: $result (0 is success). as_string: $as_string";

		for my $target ('?')
		{
			$found = $parser -> find($target);

			say "uids of nodes whose text matches $target: ", join(', ', @$found);
		}

		$result = $parser -> validate;

		say "Result of calling validate() on $s: $result (0 is success)";
	}
	catch
	{
		say "Marpa error: $error_str";
	};

	$parser -> reset;
}

say '-' x 50;
