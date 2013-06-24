package AutoP2H::Pod;

use strict;
use warnings;

use parent qw(Pod::Simple::HTML);

use Class::Accessor::Lite (
    new     => 0,
    rw      => [qw/
        pod_top
        release_top
        release_name
        package_name
    /]
);

sub _add_top_anchor {
    my ($self, $text_r) = @_;

    $self->SUPER::_add_top_anchor($text_r);

    $self->package_name( $self->{Title} ); # unless $self->package_name;

    #  Add breadlist
    $$text_r .= 
          q{<div class="breadlist">}
        . q{<a href="} . $self->pod_top . q{">TOP</a> }
        . q{&gt <a href="} . $self->release_top . q{">} . $self->release_name . q{</a> }
        . q{&gt } . $self->package_name
        . q{</div>};

}


1;

