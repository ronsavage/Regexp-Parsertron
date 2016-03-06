package Regexp::Parsertron;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Section::Simple 'get_data_section';

use Marpa::R2;

use Moo;

use Scalar::Does '-constants';

use Tree;

use Types::Standard qw/Any Object Str/;

has bnf =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has grammar =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has tree =>
(
	default  => sub{return Tree -> new('root')},
	is       => 'rw',
	isa      => Object,
	required => 0,
);

our $VERSION = '0.01';

# ------------------------------------------------

sub BUILD
{
	my($self)	= @_;
	my($bnf)	= get_data_section('V 5.20');

	$self -> bnf($bnf);
	$self -> grammar
	(
		Marpa::R2::Scanless::G -> new
		({
			source => \$self -> bnf
		})
	);

} # End of BUILD.

# ------------------------------------------------

sub as_string
{
	my($self, $candidate) = @_;

	return does($candidate, 'Regexp') ? $candidate : qr/$candidate/;

} # End of as_string.

# ------------------------------------------------

sub parse
{
	my($self, $target, $re, $string) = @_;
	my($what_is_it) = $self -> as_string($re);

	print "target: $target. re: $re. string: $string. what_is_it: $what_is_it \n";

	if ($target =~ $re)
	{
		print "$target matches regexp $re. \n";
	}
	else
	{
		print "$target does not match regexp $re. \n";
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of parse.

# ------------------------------------------------

1;


__DATA__
@@ V 5.20
:default				::= action => [values]

lexeme default			= latm => 1

:start					::= regexp

# G1 stuff.

regexp					::= pattern_set+

pattern_set				::= extended_modifiers pattern

extended_modifiers		::= open_parenthesis question_mark extended_set close_parenthesis

extended_set			::= caret_token positive_letters negative_letter_set

caret_token				::=
caret_token				::= caret

positive_letters		::= a2z

negative_letter_set		::=
negative_letter_set		::= minus_negative_letters

minus_negative_letters	::= minus negative_letters

negative_letters		::= a2z

pattern					::= string*

# L0 stuff, in alphabetical order.

a2z						~ [a-z]

caret					~ '^'

close_parenthesis		~ ')'

minus					~ '-'

non_word				~ [\W]

open_parenthesis		~ '('

question_mark			~ '?'

string					~ word
string					~ non_word

word					~ [\w]
