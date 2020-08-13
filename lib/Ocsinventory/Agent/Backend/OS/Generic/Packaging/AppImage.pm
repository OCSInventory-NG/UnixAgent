package Ocsinventory::Agent::Backend::OS::Generic::Packaging::AppImage;

sub check {
    my $params = shift;
    my $common = $params->{common};
    $common->can_run("updatedb")
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    foreach(`locate -i "*.appimage"`){
        /^(\/)(\S+)(\/)(\S+)/;
        
        my $name = $4;
        my $publisher = "AppImage";

        $common->addSoftware({
            'NAME' => $name,
            'PUBLISHER' => $publisher
        });
    }
}

1;
