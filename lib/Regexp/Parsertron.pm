package Regexp::Parsertron;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Section::Simple 'get_data_section';

use Marpa::R2;

use Moo;

use Scalar::Does '-constants'; # For does().

use Tree;

use Try::Tiny;

use Types::Standard qw/Any Bool Int Str/;

has bnf =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has current_node =>
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

has match_count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has miss_count =>
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
	isa      => Str,
	required => 0,
);

has recce =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
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
	isa      => Bool,
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

	print "Adding $event_name to tree. \n";

	if ($self -> tree eq '')
	{
		$self -> tree($node);
		$self -> current_node($node);

		print "Root: \n";

		$self -> report;
	}
	else
	{
		if ($event_name eq 'open_parenthesis')
		{
		}

		$self -> current_node -> add_child($node);

		if ($event_name eq 'close_parenthesis')
		{
			$self -> current_node($self -> current_node -> getParent) if (! $self -> current_node -> is_root);
		}
	}

	$self -> report;

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

	$self -> count($opts{count})	if (defined $opts{count});
	$self -> re($opts{re})			if (defined $opts{re});

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
		}
		else
		{
			$result = 1;

			print "Error: Parse failed\n";
		}
	}
	catch
	{
		$result = 1;

		print "Error: Parse failed. ${_}";
	};

	# Return 0 for success and 1 for failure.

	return 0;

} # End of parse.

# ------------------------------------------------

sub _process
{
	my($self)		= @_;
	my($raw_re)		= $self -> re;
	my($string_re)	= $self -> _string2re($raw_re);
	my($ref_re)		= \"$string_re"; # Use " in comment for UltraEdit.
	my($length)		= length($string_re);
	my($re_count)	= $self -> count;

	print "$re_count: Parsing '$raw_re' => '$string_re'. ";

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

		print "event_name: $event_name. lexeme: $lexeme. \n";

		$self -> _add_daughter($event_name, {text => $lexeme});
   }

	my($message);

	if ($self -> recce -> exhausted)
	{
		$message = 'Parse exhausted';

		print "Warning: $message\n";
	}
	elsif (my $status = $self -> recce -> ambiguous)
	{
		my($terminals)	= $self -> recce -> terminals_expected;
		$terminals		= ['(None)'] if ($#$terminals < 0);
		$message		= "Ambiguous parse. Status: $status. Terminals expected: " . join(', ', @$terminals);

		print "Warning: $message\n";
	}

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

	print 'Match count: ', $self -> match_count, '. Miss count: ', $self -> miss_count, ". \n";

} # End of report.

# ------------------------------------------------

sub _string2re
{
	my($self, $candidate) = @_;

	return does($candidate, 'Regexp') ? $candidate : qr/$candidate/;

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

	print $message, join(', ', @event_name), "\n";# if ($self -> verbose);

	return ($event_name, $span, $pos);

} # End of _validate_event.

# ------------------------------------------------

1;

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

__DATA__
@@ V 5.20
:default					::= action => [values]

lexeme default				= latm => 1

:start						::= regexp

# G1 stuff.

regexp						::= open_parenthesis global_extended_sequence pattern_sequence close_parenthesis

global_extended_sequence	::= question_mark caret positive_letters negative_letter_set

positive_letters			::=
positive_letters			::= a2z

negative_letter_set			::=
negative_letter_set			::= minus_negative_letters

minus_negative_letters		::= minus negative_letters

negative_letters			::= a2z

pattern_sequence		::= question_mark comment
							| question_mark extended_set
							| question_mark extended_set colon character_sequence
							| question_mark colon character_sequence

pattern_set				::= open_parenthesis pattern close_parenthesis
							| open_bracket character_in_set close_bracket
							| character_sequence

pattern					::= regexp

character_sequence		::= character*

comment					::= hash pattern

# L0 stuff, in alphabetical order.

:lexeme					~ a2z					pause => before		event => a2z
a2z						~ [a-z]

:lexeme					~ caret					pause => before		event => caret
caret					~ '^'

:lexeme					~ character				pause => before		event => character
character				~ escaped_close_parenthesis
							| escaped_open_parenthesis
							| non_parenthesis_char

:lexeme					~ character_in_set		pause => before		event => character_in_set
character_in_set		~ escaped_close_bracket
							| non_close_bracket_char

:lexeme					~ close_bracket			pause => before		event => close_bracket
close_bracket			~ '])'

:lexeme					~ close_parenthesis		pause => before		event => close_parenthesis
close_parenthesis		~ ')'

:lexeme					~ colon					pause => before		event => colon
colon					~ ':'

escaped_close_bracket	~ '\\' ']'

escaped_close_parenthesis	~ '\\)'

escaped_open_parenthesis	~ '\\)'

:lexeme					~ hash					pause => before		event => hash
hash					~ ':'

:lexeme					~ minus					pause => before		event => minus
minus					~ '-'

non_close_bracket_char	~ [^\]]

non_parenthesis_char	~ [^()]

:lexeme					~ open_bracket			pause => before		event => open_bracket
open_bracket			~ '['

:lexeme					~ open_parenthesis		pause => before		event => open_parenthesis
open_parenthesis		~ '('

:lexeme					~ question_mark			pause => before		event => question_mark
question_mark			~ '?'
