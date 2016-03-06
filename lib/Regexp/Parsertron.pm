package Regexp::Parsertron;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Section::Simple 'get_data_section';

use Marpa::R2;

use Moo;

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

has rig_test =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
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
	my($self) = @_;

	return $self -> rig_test;

} # End of as_string.

# ------------------------------------------------

sub parse
{
	my($self, $target, $re, $string) = @_;

	print "target: $target. re: $re. string: $string. \n";

	$self -> rig_test($string);

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

=pod

=head1 NAME

C<Regexp::Parsertron> - Parse a Perl regexp into a Tree

=head1 Synopsis


=head1 Description


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
[e.g. L</text([$stringref])>]):

=over 4

=item o close => $arrayref

=back

=head1 Methods

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.


=head1 FAQ

=head2 What is the purpose of this module?

=over 4

=item o To provide a stand-alone parser for regexps

=item o To help me learn more about regexps

=item o To, I hope, form the basis of a replacement for the horrendously complex L<Regexp::Assemble>

=back

=head2 Does this module interpret regexps in any way?

No. You have to run your own Perl code to do that. This module just parses them into a data
structure.

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
:default				::= action => [values]

lexeme default			= latm => 1

:start					::= regexp

regexp					::= pattern_set

pattern_set				::= input_text

input_text				~ 'X'
