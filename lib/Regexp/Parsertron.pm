package Regexp::Parsertron;

use re 'eval';
use strict;
use warnings;
#use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Section::Simple 'get_data_section';

use Marpa::R2;

use Moo;

use Scalar::Does '-constants'; # For does().

use Tree;

use Try::Tiny;

use Types::Standard qw/Any Int Str/;

has bnf =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has current_node =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has error_str =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has grammar =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has marpa_error_count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has perl_error_count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has re =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has recce =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has test_count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has tree =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has verbose =>
(
	default  => sub {return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

our $VERSION = '0.50';

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

sub _add_daughter
{
	my($self, $event_name, $attributes)	= @_;
	my($node)							= Tree -> new($event_name);

	$node -> meta($attributes);

	print "Adding $event_name to tree. \n" if ($self -> verbose > 1);

	if ($self -> tree eq '')
	{
		$self -> tree($node);
		$self -> current_node($node);
	}
	else
	{
		if ($event_name =~ /^close_(?:bracket|parenthesis)$/)
		{
			$self -> current_node($self -> current_node -> parent) if (! $self -> current_node -> is_root);
		}

		$self -> current_node -> add_child($node);

		# In this 'if', the ^ and $ are mandatory, since we have events
		# with names like non_close_bracket.

		if ($event_name =~ /^open_(?:bracket|parenthesis)$/)
		{
			$self -> current_node($node);
		}
	}

} # End of _add_daughter.

# ------------------------------------------------

sub as_string
{
	my($self) = @_;

	return $self -> _string2re($self -> re);

} # End of as_string.

# ------------------------------------------------

sub next_few_chars
{
	my($self, $stringref, $offset) = @_;
	my($s) = substr($$stringref, $offset, 20);
	$s     =~ tr/\n/ /;
	$s     =~ s/^\s+//;
	$s     =~ s/\s+$//;

	return $s;

} # End of next_few_chars.

# ------------------------------------------------

sub parse
{
	my($self, %opts) = @_;

	# Emulate parts of new(), which makes things a bit earier for the caller.

	$self -> error_str('');
	$self -> re($opts{re}) if (defined $opts{re});

	$self -> recce
	(
		Marpa::R2::Scanless::R -> new
		({
			exhaustion     => 'event',
			grammar        => $self -> grammar,
			ranking_method => 'high_rule_only',
		})
	);

	# Return 0 for success and 1 for failure.

	my($result) = 0;

	my($message);

	try
	{
		if (defined (my $value = $self -> _process) )
		{
			$self -> report if ($self -> verbose > 1);
		}
		else
		{
			$result = 1;

			$self -> error_str('Error: Parse failed') if (! $self -> error_str);

			print '1 Error str: ', $self -> error_str, "\n" if ($self -> verbose && $self -> error_str);
		}
	}
	catch
	{
		$result = 1;

		$self -> marpa_error_count($self -> marpa_error_count + 1);
		$self -> error_str("Error: Parse failed. $_");

		print '2 Error str: ', $self -> error_str, "\n" if ($self -> verbose && $self -> error_str);
	};

	# Return 0 for success and 1 for failure.

	return $result;

} # End of parse.

# ------------------------------------------------

sub _process
{
	my($self)		= @_;
	my($raw_re)		= $self -> re;
	my($test_count)	= $self -> test_count($self -> test_count + 1);

	print "Test count: $test_count. Parsing '$raw_re' => (qr/.../) => " if ($self -> verbose);

	my($string_re)	= $self -> _string2re($raw_re);

	if ($string_re eq '')
	{
		print "\n" if ($self -> verbose);

		return undef;
	}

	print "'$string_re'. \n" if ($self -> verbose);

	my($ref_re)		= \"$string_re"; # Use " in comment for UltraEdit.
	my($length)		= length($string_re);

	my($child);
	my($event_name);
	my($lexeme);
	my($pos);
	my($span, $start);

	# We use read()/lexeme_read()/resume() because we pause at each lexeme.

	for
	(
		$pos = $self -> recce -> read($ref_re);
		($pos < $length);
		$pos = $self -> recce -> resume($pos)
	)
	{
		($start, $span)				= $self -> recce -> pause_span;
		($event_name, $span, $pos)	= $self -> _validate_event($ref_re, $start, $span, $pos,);

		# If the input is exhausted, we exit immediately so we don't try to use
		# the values of $start, $span or $pos. They are ignored upon exit.

		last if ($event_name eq "'exhausted"); # Yes, it has a leading quote.

		$lexeme	= $self -> recce -> literal($start, $span);
		$pos	= $self -> recce -> lexeme_read($event_name);

		die "lexeme_read($event_name) rejected lexeme |$lexeme|\n" if (! defined $pos);

		print "event_name: $event_name. lexeme: $lexeme. \n" if ($self -> verbose > 1);

		$self -> _add_daughter($event_name, {text => $lexeme});
   }

	my($message);

	if ($self -> recce -> exhausted)
	{
		# See https://metacpan.org/pod/distribution/Marpa-R2/pod/Exhaustion.pod#Exhaustion
		# for why this code is exhaustion-loving.

		$message = 'Parse exhausted';

		#print "Warning: $message\n";
	}
	elsif (my $status = $self -> recce -> ambiguous)
	{
		my($terminals)	= $self -> recce -> terminals_expected;
		$terminals		= ['(None)'] if ($#$terminals < 0);
		$message		= "Ambiguous parse. Status: $status. Terminals expected: " . join(', ', @$terminals);

		print "Warning: $message\n";
	}

	$self -> report_tree if ($self -> verbose);

	# Return a defined value for success and undef for failure.

	return $self -> recce -> value;

} # End of _process.

# ------------------------------------------------

sub report
{
	my($self)	= @_;
	my($format)	= "%-20s  %s\n";

	print sprintf($format, 'Name', 'Text');
	print sprintf($format, '----', '----');

	my($meta);

	for my $node ($self -> tree -> traverse)
	{
		$meta = $node -> meta;

		print sprintf($format, $node -> value, $$meta{text});
	}

} # End of report.

# ------------------------------------------------

sub report_tree
{
	my($self) = @_;

	print map("$_\n", @{$self -> tree -> tree2string});

} # End of report_tree.

# ------------------------------------------------

sub _string2re
{
	my($self, $candidate) = @_;

	my($re);

	try
	{
		$re = does($candidate, 'Regexp') ? $candidate : qr/$candidate/;
	}
	catch
	{
		$re = '';

		$self -> perl_error_count($self -> perl_error_count + 1);
		$self -> error_str($self -> test_count . ": Perl cannot convert $candidate into qr/.../ form");
	};

	return $re;

} # End of _string2re.

# ------------------------------------------------

sub _validate_event
{
	my($self, $stringref, $start, $span, $pos) = @_;
	my(@event)       = @{$self -> recce -> events};
	my($event_count) = scalar @event;
	my(@event_name)  = sort map{$$_[0]} @event;
	my($event_name)  = $event_name[0]; # Default.

	# If the input is exhausted, we return immediately so we don't try to use
	# the values of $start, $span or $pos. They are ignored upon return.

	if ($event_name eq "'exhausted") # Yes, it has a leading quote.
	{
		return ($event_name, $span, $pos);
	}

	my($lexeme)        = substr($$stringref, $start, $span);
	my($line, $column) = $self -> recce -> line_column($start);
	my($literal)       = $self -> next_few_chars($stringref, $start + $span);
	my($message)       = "Location: ($line, $column). Lexeme: |$lexeme|. Next few chars: |$literal|";
	$message           = "$message. Events: $event_count. Names: ";

	print $message, join(', ', @event_name), "\n" if ($self -> verbose > 1);

	return ($event_name, $span, $pos);

} # End of _validate_event.

# ------------------------------------------------

1;

__DATA__
@@ V 5.20
:default		::= action => [values]

lexeme default	= latm => 1

:start			::= regexp

# G1 stuff.

regexp			::= open_parenthesis entire_pattern close_parenthesis

entire_pattern	::= question_mark optional_caret positive_flags optional_pattern_set
					| question_mark flag_sequence optional_pattern_set
					| question_mark comment
					| question_mark vertical_bar pattern_set
					| question_mark equals pattern_set
					| question_mark exclamation_mark pattern_set
					| question_mark less_equals pattern_set
					| escaped_K
					| question_mark less_exclamation_mark pattern_set
					| question_mark named_capture_group pattern_set
					| named_backreference
					| question_mark open_brace code close_brace
					| question_mark question_mark open_brace code close_brace
					| question_mark parameter_number

optional_caret				::=
optional_caret				::= caret

positive_flags				::=
positive_flags				::= flag_set

optional_pattern_set		::= colon slash_pattern

# TODO: Let's hope users always use /.../ and not something like m|...|!

slash_pattern				::= slash optional_caret pattern_set optional_dollar slash optional_switches

pattern_set					::= pattern_sequence+

pattern_sequence			::= parenthesis_pattern
								| bracket_pattern
#								| character_sequence

parenthesis_pattern			::= open_parenthesis pattern close_parenthesis

# Perl accepts /()/.

pattern						::=
pattern						::= bracket_pattern
#								| pattern_set

bracket_pattern				::= open_bracket optional_caret characters_in_set close_bracket set_modifiers

# Perl does not accept /[]/.

characters_in_set			::= character_in_set+

character_in_set			::= escaped_close_bracket
								| non_close_bracket

set_modifiers				::=
set_modifiers				::= plus
								| question_mark
#								| TBA. E.g. {...}.

#character_sequence			::= escaped_close_parenthesis
#								| escaped_open_parenthesis
#								| character_set

optional_dollar				::=
optional_dollar				::= dollar

optional_switches			::=
optional_switches			::= flag_set

comment						::= hash non_close_parenthesis_set

non_close_parenthesis_set	::= non_close_parenthesis*

flag_sequence				::= positive_flags negative_flag_set

negative_flag_set			::=
negative_flag_set			::= minus negative_flags

negative_flags				::= flag_set

named_capture_group			::= single_quote capture_name single_quote
								| less_than capture_name greater_than

capture_name				::= word

named_backreference			::= escaped_k single_quote capture_name single_quote
								| escaped_k less_than capture_name greater_than

code						::= [[:print:]]

positive_integer			::= non_zero_digit digit_sequence
								| minus positive_integer

digit_sequence				::= digit_set*

parameter_number			::= positive_integer
								| plus positive_integer
								| minus positive_integer
								| R
								| zero

# L0 stuff, in alphabetical order.

:lexeme						~ caret					pause => before		event => caret
caret						~ '^'

#:lexeme						~ character_set			pause => before		event => character_set
#character_set				~ [^()]*

:lexeme						~ close_brace			pause => before		event => close_brace
close_brace					~ '}'

:lexeme						~ close_bracket			pause => before		event => close_bracket
close_bracket				~ ']'

:lexeme						~ close_parenthesis		pause => before		event => close_parenthesis
close_parenthesis			~ ')'

:lexeme						~ colon					pause => before		event => colon
colon						~ ':'

:lexeme						~ digit_set				pause => before		event => digit_set
digit_set					~ [0-9] # We avoid \d to avoid Unicode digits.

:lexeme						~ dollar				pause => before		event => dollar
dollar						~ '$'

:lexeme						~ equals				pause => before		event => equals
equals						~ '='

:lexeme						~ escaped_close_bracket	pause => before		event => escaped_close_bracket
escaped_close_bracket		~ '\\' ']'

#:lexeme						~ escaped_close_parenthesis	pause => before		event => escaped_close_parenthesis
#escaped_close_parenthesis	~ '\\)'

:lexeme						~ escaped_k				pause => before		event => escaped_k
escaped_k					~ '\\k'

:lexeme						~ escaped_K				pause => before		event => escaped_K
escaped_K					~ '\\K'

#:lexeme						~ escaped_open_parenthesis	pause => before		event => escaped_open_parenthesis
#escaped_open_parenthesis	~ '\\)'

:lexeme						~ exclamation_mark		pause => before		event => exclamation_mark
exclamation_mark			~ '!'

:lexeme						~ flag_set				pause => before		event => flag_set
flag_set					~ [a-z]+

:lexeme						~ greater_than			pause => before		event => greater_than
greater_than				~ '>'

:lexeme						~ hash					pause => before		event => hash
hash						~ ':'

:lexeme						~ less_equals			pause => before		event => less_equals
less_equals					~ '<='

:lexeme						~ less_exclamation_mark	pause => before		event => less_exclamation_mark
less_exclamation_mark		~ '<!'

:lexeme						~ less_than				pause => before		event => less_than
less_than					~ '<'

:lexeme						~ minus					pause => before		event => minus
minus						~ '-'

:lexeme						~ non_close_bracket		pause => before		event => non_close_bracket
non_close_bracket			~ [^\]]+

:lexeme						~ non_close_parenthesis	pause => before		event => non_close_parenthesis
non_close_parenthesis		~ [^\)]*

:lexeme						~ non_zero_digit		pause => before		event => non_zero_digit
non_zero_digit				~ [1-9]

:lexeme						~ open_brace			pause => before		event => open_brace
open_brace					~ '{'

:lexeme						~ open_bracket			pause => before		event => open_bracket
open_bracket				~ '['

:lexeme						~ open_parenthesis		pause => before		event => open_parenthesis
open_parenthesis			~ '('

:lexeme						~ plus					pause => before		event => plus
plus						~ '+'

:lexeme						~ question_mark			pause => before		event => question_mark
question_mark				~ '?'

:lexeme						~ R						pause => before		event => R
R							~ '-'

:lexeme						~ single_quote			pause => before		event => single_quote
single_quote				~ [\'] # The '\' is for UltraEdit's syntax hiliter.

:lexeme						~ slash					pause => before		event => slash
slash						~ '/'

:lexeme						~ vertical_bar			pause => before		event => vertical_bar
vertical_bar				~ '|'

:lexeme						~ word					pause => before		event => word
word						~ [\w]+

:lexeme						~ zero					pause => before		event => zero
zero						~ '-'

@@ POD
=pod

=head1 NAME

C<Regexp::Parsertron> - Parse a Perl regexp into a Tree

=head1 Synopsis

This is part of scripts/synopsis.pl:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Regexp::Parsertron;

	# ---------------------

	my($parser) = Regexp::Parsertron -> new;
	my($re)     ='[yY][eE][sS]';
	my($result) = $parser -> parse(re => $re);

	$parser -> report;

Since that regexp stringifies via C<qr/$re/> to C<(?^:[yY][eE][sS])>, the report says:

	Name                  Text
	----                  ----
	open_parenthesis      (
	question_mark         ?
	caret                 ^
	colon                 :
	text                  [yY][eE][sS]
	close_parenthesis     )

=head1 Description

Parses a regexp into a tree object managed by the L<Tree> module.

This module uses L<Moo>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Regexp::Parsertron> as you would any C<Perl> module:

Run:

	cpanm Regexp::Parsertron

or run:

	sudo cpan Regexp::Parsertron

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = Regexp::Parsertron -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Regexp::Parsertron>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</re([$regexp])>]):

=over 4

=item o re => $regexp

The C<does()> method of L<Scalar::Does> is called to see what C<re> is. If it's already of the
form C<qr/$re/>, then it's processed as is, but if it's not, then it's transformed using C<qr/$re/>.

=back

=head1 Methods

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

=head2 parse([%opts])

Here, '[]' indicate an optional parameter.

Parses the regexp supplied in the call to L</new()> or in the call to L</re($regexp)>, or in the
call to C<parse()> itself. The latter takes precedence.

The hash C<%opts> takes these (key => value) pairs, just as L</new()> does:

=over 4

=item o re => $regexp

See L</Constructor and Initialization> for how $regexp might be pre-processed (i.e. modified before
being parsed).

=back

=head2 re([$regexp])

Here, '[]' indicate an optional parameter.

Gets or sets the regexp to be processed.

=head2 tree()

Returns an object of type L<Tree>. Ignore the root node.

Each node's C<meta> method returns a hashref of information about the node. See the L</FAQ> for
details.

=head1 FAQ

=head2 What is the format of the nodes in the tree build by this module?

Each node's C<meta> method returns a hashref with these (key => value) pairs:

=over 4

=item o name => $string

This is the name of the Marpa-style event which was triggered by detection of some C<text> within
the regexp.

=item o text => $string

This is the text within the regexp which triggered the event just mentioned.

=back

See the L</Synopsis> for sample code and a report after parsing a tiny regexp.

=head2 What is the purpose of this module?

=over 4

=item o To provide a stand-alone parser for regexps

=item o To help me learn more about regexps

=item o To become, I hope, a replacement for the horrendously complex L<Regexp::Assemble>

=back

=head2 Does this module interpret regexps in any way?

No. You have to run your own Perl code to do that. This module just parses them into a data
structure.

And that really means this module does not match the regexp against anything. If I appear to do that
while testing new code, you can't rely on that appearing in production versions of the module.

=head2 Does this module re-write regexps?

Not yet, but that's the plan. So, ultimately, this module might be able to replace some of
L<Regexp::Assemble>'s functionality.

This would include support for assembling complex regexps out of repeated calls to methods within
this module.

=head2 Does this module handle both Perl5 and Perl6?

Initially, it will only handle Perl5 syntax.

=head2 Does this module handle various versions of regexps (i.e., of Perl5)?

Yes, version-dependent regexp syntax will be supported for recent versions of Perl. This is done by
having tokens within the BNF which are replaced at start-up time with version-dependent details.

=head2 Is this an exhaustion-hating or exhaustion-loving app?

Exhaustion-loving.

See L<https://metacpan.org/pod/distribution/Marpa-R2/pod/Exhaustion.pod#Exhaustion>

=head1 References

L<http://perldoc.perl.org/perlre.html>. This is the definitive document.

L<http://perldoc.perl.org/perlretut.html>. Samples with commentary.

L<http://perldoc.perl.org/perlop.html#Regexp-Quote-Like-Operators>

L<http://perldoc.perl.org/perlrequick.html>

L<http://perldoc.perl.org/perlrebackslash.html>

L<http://www.nntp.perl.org/group/perl.perl5.porters/2016/02/msg234642.html>

=head1 See Also

L<Graph::Regexp>

L<Regexp::Assemble>

L<Regexp::ERE>

L<Regexp::Keywords>

L<Regexp::Lexer>

L<Regexp::List>

L<Regexp::Optimizer>

L<Regexp::Parser>

L<Regexp::SAR>. This is vaguely a version of L<Set::FA::Element>.

L<Regexp::Stringify>

L<Regexp::Trie>

And many others...

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Regexp-Parsertron>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp::Parsertron>.

=head1 Author

L<Regexp::Parsertron> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2016.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2016, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut

# Policy: Event names are always the same as the name of the corresponding lexeme.
#
# Note:   Tokens of the form '_xxx_' are replaced with version-dependent values.

