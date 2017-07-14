use strict;
use warnings;

package Class::Tiny::Immutable;

use Carp ();
use Class::Tiny ();
our @ISA = 'Class::Tiny';

our $VERSION = '0.001';

sub prepare_class {
  my ( $class, $pkg ) = @_;
  no strict 'refs';
  @{"${pkg}::ISA"} = "Class::Tiny::Immutable::Object" unless @{"${pkg}::ISA"};
}

sub __gen_sub_body {
  my ($self, $name, $has_default, $default_type) = @_;
  
  if ($has_default && $default_type eq 'CODE') {
    return <<"HERE";
sub $name {
  return (
      ( \@_ == 1 )
    ? ( exists \$_[0]{$name} ? \$_[0]{$name} : ( \$_[0]{$name} = \$default->( \$_[0] ) ) )
    : Carp::croak( "$name is a read-only accessor" )
  );
}
HERE
  }
  elsif ($has_default) {
    return <<"HERE";
sub $name {
  return (
      ( \@_ == 1 )
    ? ( exists \$_[0]{$name} ? \$_[0]{$name} : ( \$_[0]{$name} = \$default ) )
    : Carp::croak( "$name is a read-only accessor" )
  );
}
HERE
  }
  else {
    return <<"HERE";
sub $name {
  return \@_ == 1 ? \$_[0]{$name} : Carp::croak( "$name is a read-only accessor" );
}
HERE
  }
}

package Class::Tiny::Immutable::Object;

our @ISA = 'Class::Tiny::Object';

our $VERSION = '0.001';

sub BUILD {
  my ( $self, $args ) = @_;
  my $attrs = Class::Tiny::Immutable->get_all_attribute_defaults_for( ref $self );
  my @missing;
  foreach my $name ( keys %$attrs ) {
    # Any attribute without a defined default is required
    push @missing, $name unless defined $attrs->{$name} or exists $args->{$name};
  }
  Carp::croak( 'Missing required attributes: ' . join( ', ', sort @missing ) ) if @missing;
}

1;

=head1 NAME

Class::Tiny::Immutable - Minimalist class construction, with read-only
attributes

=head1 SYNOPSIS

In I<Person.pm>:

  package Person;
  
  use Class::Tiny::Immutable qw( name );
  
  1;

In I<Employee.pm>:

  package Employee;
  use parent 'Person';
  
  use Class::Tiny::Immutable qw( ssn ), {
    timestamp => sub { time }   # lazy attribute with default
  };
  
  1;

In I<example.pl>:

  use Employee;
  
  my $obj = Employee->new; # dies, name and ssn attributes are required
  my $obj = Employee->new( name => "Larry", ssn => "111-22-3333" );
  
  my $name = $obj->name;
  my $timestamp = $obj->timestamp;
  
  # no attributes can be set
  $obj->ssn("222-33-4444"); # dies
  $obj->timestamp(time); # dies

=head1 DESCRIPTION

L<Class::Tiny::Immutable> is a wrapper around L<Class::Tiny> which makes the
generated attributes read-only, and required to be set in the object
constructor if they do not have a lazy default defined. In other words,
attributes are either "lazy" or "required".

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Moo>, L<MooseX::AttributeShortcuts>
