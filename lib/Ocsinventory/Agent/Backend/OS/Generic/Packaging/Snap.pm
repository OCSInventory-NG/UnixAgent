package Ocsinventory::Agent::Backend::OS::Generic::Packaging::Snap;

sub check {
    my $params = shift;
    my $common = $params->{common};
    return unless $common->can_run("snap");
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    if ($common->can_run("snap list")) {
        my $i = 0;
        foreach(`snap list`){
            /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/;
            if($i >= 1) {
                my $name = $1;
                my $version = $2;
                my $publisher = $5;
                my $comments = "Snap package";

                $common->addSoftware({
                    'COMMENTS' => $comments,
                    'NAME' => $name,
                    'PUBLISHER' => $publisher,
                    'VERSION' => $version
                });
            }
            $i++;
        }
    }
}

1;