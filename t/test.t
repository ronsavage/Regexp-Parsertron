use strict;
use warnings;

use Regexp::Parsertron;

# Warning: Can't use Test::Stream because of the '#' in the regexps.

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
	expected	=> '(?^:(?))',
	re			=> qr/(?)/,
},
{
	count		=> 3,
	expected	=> '(?^:(?a))',
	re			=> qr/(?a)/,
},
{
	count		=> 4,
	expected	=> '(?^:(?a-i))',
	re			=> qr/(?a-i)/,
},
{
	count		=> 5,
	expected	=> '(?^:(?^a))',
	re			=> qr/(?^a)/,
},
{
	count		=> 6,
	expected	=> '(?^:(?a:))',
	re			=> qr/(?a:)/,
},
{
	count		=> 7,
	expected	=> '(?^:(?a:b))',
	re			=> qr/(?a:b)/,
},
{
	count		=> 8,
	expected	=> '(?^:(?:))',
	re			=> qr/(?:)/,
},
{
	count		=> 9,
	expected	=> '(?^:[yY][eE][sS])',
	re			=> qr/[yY][eE][sS]/,
},
{
	count		=> 10,
	expected	=> '(?^:(A|B))',
	re			=> qr/(A|B)/,
},
);

my($limit)	= shift || 0;
my($parser)	= Regexp::Parsertron -> new;

my($expected);
my($got);
my($result);

for my $test (@test)
{
	# Use this trick to run the tests one-at-a-time. See scripts/test.sh.

	next if ( ($limit > 0) && ($$test{count} != $limit) );

	$result = $parser -> parse(re => $$test{re});

	if ($result == 0)
	{
		$got		= $parser -> as_string;
		$expected	= $$test{expected};

		is_deeply("$got", $expected, "$$test{count}: $$test{re}");
	}
	else
	{
		die "Test $$test{count} failed to return 0 from run()\n";
	}

	# Reset tree for next test.

	$parser -> tree('');
}

done_testing;
