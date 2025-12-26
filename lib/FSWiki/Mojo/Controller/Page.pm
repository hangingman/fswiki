package FSWiki::Mojo::Controller::Page;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub index ($self) {
    $self->render(text => 'Hello from Mojolicious!');
}

sub show ($self) {
    my $name = $self->param('name');
    $self->render(text => "Showing page: $name");
}

sub edit ($self) {
    my $name = $self->param('name');
    $self->render(text => "Editing page: $name");
}

1;
