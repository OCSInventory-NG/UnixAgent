package Ocsinventory::Agent::AccountConfig;
use strict;
use warnings;

# AccountConfig read and write the setting for the client given by the server
# This file will be overwrite and is not designed to be changed by the user

# DESPITE ITS NAME, ACCOUNTCONFIG IS NOT A CONFIG FILE!

sub new {
    my (undef,$params) = @_;

    my $self = {};
    bless $self;

    $self->{config} = $params->{config};
    my $logger = $self->{logger} = $params->{logger};

    # Configuration reading
    $self->{xml} = {};

    if ($self->{config}->{accountconfig}) {
        if (! -f $self->{config}->{accountconfig}) {
            $self->create_xml_file();
            $self->create_txt_file();
        } else {
            # either read as xml or txt
            if ($self->read() == 0) {
                $logger->debug("XML parsing of ocsinv.conf failed, will attempt to read from ocsinv.txt");
                $self->read_txt_config();
            }
        }
    }

    $self;
}

sub get {
    my ($self, $name) = @_;

    my $logger = $self->{logger};

    return $self->{xml}->{$name} if $name;
    return $self->{xml};
}

sub set {
    my ($self, $name, $value) = @_;

    my $logger = $self->{logger};

    $self->{xml}->{$name} = $value;

    $self->write();
    $self->write_txt_config();

}


sub write {
    my ($self, $args) = @_;

    my $logger = $self->{logger};

    return unless $self->{config}->{accountconfig};
    my $xml = XML::Simple::XMLout( $self->{xml} , RootName => 'CONF',
        NoAttr => 1 );

    my $fault;
    if (!open CONF, ">".$self->{config}->{accountconfig}) {
        $fault = 1;
    } else {
        print CONF $xml;
        $fault = 1 if (!close CONF);
    }

    if ($fault) {
        $logger->error ("Can't save setting change in `".$self->{config}->{accountconfig}."'");
    }
}

sub read {
    my ($self) = @_;

    my $logger = $self->{logger};

    eval {
        $self->{xml} = XML::Simple::XMLin(
            $self->{config}->{accountconfig},
            SuppressEmpty => undef
        );

    };

    if ($@) {
        return 0;
    } else {
        return 1;
    }
}

sub create_xml_file {
    my ($self) = @_;

    my $logger = $self->{logger};

    $logger->debug ('accountconfig file: `'. $self->{config}->{accountconfig}.
    " doesn't exist. I create an empty one");
    return unless $self->{config}->{accountconfig};

    my $xml = XML::Simple::XMLout( $self->{xml} , RootName => 'CONF',
        NoAttr => 1 );
    my $fault;
    if (!open CONF, ">".$self->{config}->{accountconfig}) {
        $fault = 1;
    } else {
        print CONF $xml;
        $fault = 1 if (!close CONF);
    }

    if ($fault) {
        $logger->error ("Can't create file `".$self->{config}->{accountconfig}."'");
    }
}

sub write_txt_config {
    my ($self) = @_;
    my $txt_config_path = $self->{config}->{accountconfig};
    # replace .conf with .txt
    $txt_config_path =~ s/\.conf$/.txt/; 

    if (open my $fh, '>', $txt_config_path) {
        foreach my $key (keys %{$self->{xml}}) {
            my $value = $self->{xml}->{$key};
            print $fh "$key=$value\n";
        }
        close $fh;
    } else {
        $self->{logger}->error("Can't save setting change in `$txt_config_path`");
    }
}

sub read_txt_config {
    my ($self) = @_;
    my $txt_config_path = $self->{config}->{accountconfig};
    # replace .conf with .txt
    $txt_config_path =~ s/\.conf$/.txt/; 
    if (-f $txt_config_path) {
        open my $fh, '<', $txt_config_path or do {
            $self->{logger}->error("Cannot open $txt_config_path for reading");
            return;
        };

        while (my $line = <$fh>) {
            chomp $line;
            my ($key, $value) = split /=/, $line, 2;
            $self->{xml}->{$key} = $value;
        }

        close $fh;
    }
}

sub create_txt_file {
    my ($self) = @_;
    my $logger = $self->{logger};
    my $txt_config_path = $self->{config}->{accountconfig};
    # replace .conf with .txt
    $txt_config_path =~ s/\.conf$/.txt/; 
    $logger->debug ('accountconfig file: `'.$txt_config_path.
    " doesn't exist. I create an empty one");

    if (open my $fh, '>', $txt_config_path) {
        close $fh;
    } else {
        $self->{logger}->error("Can't create `$txt_config_path`");
    }
}


1;