package Data::Pageset::Exponential;

# ABSTRACT: Page numbering for very large page numbers

use v5.10.1;

use Moo;

use List::Util 1.33 qw/ all min /;
use PerlX::Maybe;
use POSIX qw/ ceil floor /;
use MooX::TypeTiny;
use Types::Common::Numeric qw/ PositiveOrZeroInt PositiveInt /;
use Types::Standard qw/ is_Int Int ArrayRef is_HashRef /;

use namespace::autoclean;

# RECOMMEND PREREQ: Type::Tiny::XS
# RECOMMEND PREREQ: Ref::Util::XS

our $VERSION = 'v0.2.3';

=head1 SYNOPSIS

  my $pager = Data::Pageset::Exponential->new(
    total_entries => $total_entries,
    entries_per_page => $per_page,
  );

  $pager->current_page( 1 );

  my $pages = $pager->pages_in_set;

  # Returns
  # [ 1, 2, 3, 10, 20, 30, 100, 200, 300, 1000, 2000, 3000 ]

=head1 DESCRIPTION

This is a pager designed for paging through resultsets that contain
hundreds if not thousands of pages.

The interface is similar to L<Data::Pageset> with sliding pagesets.

=head1 ATTRIBUTES

=head2 C<total_entries>

This is the total number of entries.

It is a read/write attribute.

=cut

has total_entries => (
    is      => 'rw',
    isa     => PositiveOrZeroInt,
    default => 0,
);

=head2 C<entries_per_page>

This is the total number of entries per page. It defaults to C<10>.

It is a read/write attribute.

=cut

has entries_per_page => (
    is      => 'rw',
    isa     => PositiveInt,
    default => 10,
);

=head2 C<first_page>

This returns the first page. It defaults to C<1>.

=cut

has first_page => (
    is      => 'ro',
    isa     => Int,
    default => 1,
);

=head2 C<current_page>

This is the current page number. It defaults to the L</first_page>.

It is a read/write attribute.

=cut

has current_page => (
    is      => 'rw',
    isa     => Int,
    lazy    => 1,
    default => \&first_page,
    coerce  => sub { floor( $_[0] // 0 ) },
);

=head2 C<exponent_base>

This is the base exponent for page sets. It defaults to C<10>.

=cut

has exponent_base => (
    is      => 'ro',
    isa     => PositiveInt,
    default => 10,
);

=head2 C<exponent_max>

This is the maximum exponent for page sets. It defaults to C<3>, for
pages in the thousands.

It should not be greater than

    ceil( log( $total_pages ) / log(10) )

however, larger numbers will increase the size of L</pages_in_set>.

=cut

has exponent_max => (
    is      => 'ro',
    isa     => PositiveInt,
    default => 3,
);

=head2 C<pages_per_exponent>

This is the number of pages per exponent. It defaults to C<3>.

=cut

has pages_per_exponent => (
    is      => 'ro',
    isa     => PositiveInt,
    default => 3,
);

=head2 C<max_pages_per_set>

This is the maximum number of pages in L</pages_in_set>. It defaults
to

  1 + 2 * ( $pages_per_exponent * ( $exponent_max + 1 ) - 1 )

which for the default values is 23.

This should be an odd number.

=cut

has max_pages_per_set => (
    is      => 'lazy',
    isa     => PositiveInt,
    builder => sub {
        my ($self) = @_;
        use integer;
        my $n = $self->pages_per_exponent * ( $self->exponent_max + 1 );
        return ($n - 1) * 2 + 1;
    },
);

=for Pod::Coverage series

=cut

has series => (
    is      => 'lazy',
    isa     => ArrayRef [Int],
    builder => sub {
        my ($self) = @_;

        use integer;

        my @series;

        my $n = $self->exponent_base;
        my $m = $self->exponent_max;

        my $j = 0;
        while ( $j <= $m ) {

            my $i = $n**$j;
            my $a = $i;
            my $p = $self->pages_per_exponent;

            while ( $p-- ) {
                push @series, $a - 1;
                $a += $i;
            }

            $j++;

        }

        my @prevs = map { -$_ } reverse @series[1..$#series];


        return [@prevs, @series];
    },
);

=head1 METHODS

=cut

around current_page => sub {
    my $next = shift;
    my $self = shift;

    # N.B. unlike Data::Page, setting a value outside the first_page
    # or last_page will not return that value.

    my $page = $self->$next(@_);

    return $self->first_page if $page < $self->first_page;

    return $self->last_page if $page > $self->last_page;

    return $page;
};

=head2 C<entries_on_this_page>

Returns the number of entries on the page.

=cut

sub entries_on_this_page {
    my ($self) = @_;

    if ( $self->total_entries ) {
        return $self->last - $self->first + 1;
    }
    else {
        return 0;
    }
}

=head2 C<last_page>

Returns the number of the last page.

=cut

sub last_page {
    my ($self) = @_;
    return $self->total_entries
      ? ceil( $self->total_entries / $self->entries_per_page )
      : $self->first_page;
}

=head2 C<first>

Returns the index of the first entry on the L</current_page>.

=cut

sub first {
    my ($self) = @_;
    if ( $self->total_entries ) {
        return ( $self->current_page - 1 ) * $self->entries_per_page + 1;
    }
    else {
        return 0;
    }
}

=head2 C<last>

Returns the index of the last entry on the L</current_page>.

=cut

sub last {
    my ($self) = @_;
    if ( $self->current_page == $self->last_page ) {
        return $self->total_entries;
    }
    else {
        return $self->current_page * $self->entries_per_page;
    }
}

=head2 C<previous_page>

Returns the number of the previous page.

=cut

sub previous_page {
    my ($self) = @_;
    my $page = $self->current_page;

    return $page > $self->first_page
      ? $page - 1
      : undef;
}

=head2 C<next_page>

Returns the number of the next page.

=cut

sub next_page {
    my ($self) = @_;
    my $page = $self->current_page;

    return $page < $self->last_page
      ? $page + 1
      : undef;
}

=for Pod::Coverage splice

=cut

sub splice {
    my ( $self, $items ) = @_;

    my $last = min( $self->last, scalar(@$items) );

    return $last
      ? @{$items}[ $self->first - 1 .. $last - 1 ]
      : ();
}

=for Pod::Coverage skipped

=cut

sub skipped {
    my ($self) = @_;
    return $self->total_entries
        ? $self->first - 1
        : 0;
}

# Ideally, we'd use a trigger instead, but Moo does not pass the old
# value to a trigger.

around entries_per_page => sub {
    my $next = shift;
    my $self = shift;

    if (@_) {

        my $value = shift;

        my $first = $self->first;

        $self->$next($value);

        $self->current_page( $self->first_page + $first / $value );

        return $value;
    }
    else {

        return $self->$next;

    }
};

=head2 C<pages_in_set>

Returns an array reference of pages in the page set.

=cut

sub pages_in_set {
    my ($self) = @_;

    use integer;

    my $first = $self->first_page;
    my $last  = $self->last_page;
    my $page  = $self->current_page;

    return [
        grep { $first <= $_ && $_ <= $last }
        map { $page + $_ } @{ $self->series }
    ];
}

=head2 C<previous_set>

This returns the first page number of the previous page set, for the
first exponent.

It is added for compatability with L<Data::Pageset>.

=cut

sub previous_set {
    my ($self) = @_;

    my $page = $self->current_page - (2 * $self->pages_per_exponent) - 1;
    return $page < $self->first_page
        ? undef
        : $page;
}

=head2 C<next_set>

This returns the first page number of the next page set, for the first
exponent.

It is added for compatability with L<Data::Pageset>.

=cut

sub next_set {
    my ($self) = @_;

    my $page = $self->current_page + (2 * $self->pages_per_exponent) - 1;
    return $page > $self->last_page
        ? undef
        : $page;
}

=for Pod::Coverage change_entries_per_page

=cut

sub change_entries_per_page {
    my ($self, $value) = @_;

    $self->entries_per_page($value);

    return $self->current_page;
}

=for Pod::Coverage BUILDARGS

=cut

sub BUILDARGS {
    my ( $class, @args ) = @_;

    if (@args == 1 && is_HashRef(@args)) {
        return $args[0];
    }

    if ( @args && ( @args <= 3 ) && all { is_Int($_) } @args ) {

        return {
                  total_entries    => $args[0],
            maybe entries_per_page => $args[1],
            maybe current_page     => $args[2],
        };

    }

    return {@args};
}

=for Pod::Coverage isa

=cut

sub isa {
    my ($self, $class) = @_;

    state $classes = { map { $_ => 1 } qw/ Data::Page / };

    return $classes->{$class} || $self->UNIVERSAL::isa($class);
}

=head1 KNOWN ISSUES

=head2 Fake @ISA

This module is based on a complete rewrite of L<Data::Page> using
L<Moo>, rather than extending it.  Because of that, it needs to fake
C<@ISA>.  This may break some applications.

=head1 SEE ALSO

=over

=item *

L<Data::Page>

=item *

L<Data::Pageset>

=back

=head1 append:AUTHOR

Test code was adapted from L<Data::Page> to ensure compatability.

=cut

1;
