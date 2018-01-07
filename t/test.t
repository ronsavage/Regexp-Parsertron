#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# Warning: Can't use Test2 or Test::Stream because of the '#' in the regexps.

use Test::More;

# ------------------------------------------------

my(@test)	=
(
{
	count		=> 1,
	expected	=> '(?^:(?#Comment))',
	re			=> qr/(?#Comment)/,
},
{
	count		=> 2,
	expected	=> '(?^u:(?))',
	re			=> qr/(?)/,
},
{
	count		=> 3,
	expected	=> '(?^u:(?a))',
	re			=> qr/(?a)/,
},
{
	count		=> 4,
	expected	=> '(?^u:(?a-i))',
	re			=> qr/(?a-i)/,
},
{
	count		=> 5,
	expected	=> '(?^u:(?^a))',
	re			=> qr/(?^a)/,
},
{
	count		=> 6,
	expected	=> '(?^u:(?a:))',
	re			=> qr/(?a:)/,
},
{
	count		=> 7,
	expected	=> '(?^u:(?a:b))',
	re			=> qr/(?a:b)/,
},
{
	count		=> 8,
	expected	=> '(?^u:(?:))',
	re			=> qr/(?:)/,
},
{
	count		=> 9,
	expected	=> '(?^u:[yY][eE][sS])',
	re			=> qr/[yY][eE][sS]/,
},
{
	count		=> 10,
	expected	=> '(?^u:(A|B))',
	re			=> qr/(A|B)/,
},
{
	count		=> 11,
	expected	=> '(?^i:Perl|JavaScript)',
	re			=> qr/Perl|JavaScript/i,
},
{
	count		=> 12,
	expected	=> '(?^i:Perl|JavaScript|C++)',
	re			=> qr/Perl|JavaScript/i,
},
{
	count		=> 13,
	expected	=> '(?^u:/ab+bc/)',
	re			=> '/ab+bc/',
},
{
	count		=> 14,
	expected	=> '(?^u:^)',
	re			=> qr/^/,
},
);

my($parser)	= Regexp::Parsertron -> new;

my($expected);
my($got);
my($message);
my($result);

for my $test (@test)
{
	diag $$test{re} . "\n";

	$result = $parser -> parse(re => $$test{re});

	if ($$test{count} == 12)
	{
		$parser -> add(text => '|C++', uid => 6);
	}

	if ($result == 0)
	{
		$got		= $parser -> as_string;
		$expected	= $$test{expected};
		$message	= "$$test{count}: re: $$test{re}. got: $got";
		$message	.= ' (After calling add(...) )' if ($$test{count} == 12);

		is_deeply("$got", $expected, $message);
	}
	else
	{
		BAIL_OUT("Test $$test{count} failed to return 0 from parse()");
	}

	# Reset for next test.

	$parser -> reset;
}

done_testing;
