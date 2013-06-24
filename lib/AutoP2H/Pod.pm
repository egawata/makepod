package AutoP2H::Pod;

use strict;
use warnings;

use parent qw(Pod::Simple::HTML);

use Class::Accessor::Lite (
    new     => 0,
    rw      => [qw/
        pod_top
        package_top
        package_name
        module_name
    /]
);

sub _add_top_anchor {
    my ($self, $text_r) = @_;

    $self->SUPER::_add_top_anchor($text_r);

    #  Add breadlist
    $$text_r .= 
          q{<div class="breadlist">}
        . q{<a href="} . $self->pod_top . q{">TOP</a> }
        . q{&gt <a href="} . $self->package_top . q{">} . $self->package_name . q{</a> }
        . q{&gt } . $self->module_name
        . q{</div>};

}


1;

