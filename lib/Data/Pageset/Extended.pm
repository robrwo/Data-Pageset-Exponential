package Data::Pageset::Extended;

use v5.10.1;

use Moo;

use List::Util qw/ all min /;
use PerlX::Maybe;
use POSIX qw/ ceil floor /;
use MooX::TypeTiny;
use Types::Common::Numeric qw/ PositiveOrZeroInt PositiveInt /;
use Types::Standard qw/ is_Int Int /;

use namespace::autoclean;

our $VERSION = 'v0.1.0';

has total_entries => (
    is      => 'rw',
    isa     => PositiveOrZeroInt,
    default => 0,
);

has entries_per_page => (
    is      => 'rw',
    isa     => PositiveInt,
    default => 10,
);

has first_page => (
    is      => 'ro',
    isa     => Int,
    default => 1,
);

has current_page => (
    is      => 'rw',
    isa     => Int,
    lazy    => 1,
    default => \&first_page,
    coerce  => sub { floor( $_[0] // 0 ) },
);

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

sub entries_on_this_page {
    my ($self) = @_;

    if ( $self->total_entries ) {
        return $self->last - $self->first + 1;
    }
    else {
        return 0;
    }
}

sub last_page {
    my ($self) = @_;
    return $self->total_entries
      ? ceil( $self->total_entries / $self->entries_per_page )
      : $self->first_page;
}

sub first {
    my ($self) = @_;
    if ( $self->total_entries ) {
        return ( $self->current_page - 1 ) * $self->entries_per_page + 1;
    }
    else {
        return 0;
    }
}

sub last {
    my ($self) = @_;
    if ( $self->current_page == $self->last_page ) {
        return $self->total_entries;
    }
    else {
        return $self->current_page * $self->entries_per_page;
    }
}

sub previous_page {
    my ($self) = @_;
    my $page = $self->current_page;

    return $page > $self->first_page
      ? $page - 1
      : undef;
}

sub next_page {
    my ($self) = @_;
    my $page = $self->current_page;

    return $page < $self->last_page
      ? $page + 1
      : undef;
}

sub splice {
    my ( $self, $items ) = @_;

    my $last = min( $self->last, scalar(@$items) );

    return $last
      ? @{$items}[ $self->first - 1 .. $last - 1 ]
      : ();
}

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

sub change_entries_per_page {
    my ($self, $value) = @_;

    $self->entries_per_page($value);

    return $self->current_page;
}

sub BUILDARGS {
    my ( $class, @args ) = @_;

    if ( @args && ( @args <= 3 ) && all { is_Int($_) } @args ) {

        return {
                  total_entries    => $args[0],
            maybe entries_per_page => $args[1],
            maybe current_page     => $args[2],
        };

    }

    return {@args};
}

sub isa {
    my ($self, $class) = @_;

    state $classes = { map { $_ => 1 } qw/ Data::Page / };

    return $classes->{$class} || $self->UNIVERSAL::isa($class);
}

1;
