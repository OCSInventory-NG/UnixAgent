package Ocsinventory::Compress;
use strict;

use File::Temp qw/ tempdir tempfile /;

sub new {
    my (undef, $params) = @_;

    my $self = {};

    my $logger = $self->{logger} = $params->{logger};


    eval{require Compress::Zlib;};
    $self->{mode} = 'natif' unless $@;

    if ($self->{mode} eq 'natif') {
        $logger->debug ('Compress::Zlib is available.');
    } else {
        $self->{mode} = 'deflated';
        $logger->debug ('I need the Compress::Zlib library'.
            ' to compress the data - The data will be sent uncompressed
            but won\'t be accepted by server prior 1.02');
    }

    bless $self;
}

sub compress {
    my ($self, $content) = @_;
    my $logger = $self->{logger};

    # native mode (zlib)
    if ($self->{mode} eq 'natif') {
        return Compress::Zlib::compress($content);
    } elsif($self->{mode} eq 'deflated'){
        # No compression available
        return $content;
    }
}

sub uncompress {
    my ($self,$data) = @_;
    my $logger = $self->{logger};
    # Native mode
    if ($self->{mode} eq 'natif') {
        return Compress::Zlib::uncompress($data);
    } elsif($self->{mode} eq 'deflated'){
        # No compression available
        return $data;
    }
}
1;
