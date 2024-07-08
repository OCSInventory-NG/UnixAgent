package Ocsinventory::Agent::Backend::OS::Generic::Packaging::Flatpak;

sub check {
    my $params = shift;
    my $common = $params->{common};
    return unless $common->can_run("flatpak");
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    if ($common->can_run("flatpak list")) {
        foreach(`flatpak list`){
            /(\S+)(\/)(\S+)(\/)(\S+)\s+(\S+)/;

            my $name = $1;
            my $version = $5;
            my $publisher = "Flatpak package";
            my $comments = $6;
            
            $common->addSoftware({
                'COMMENTS' => $comments,
                'NAME' => $name,
                'PUBLISHER' => $publisher,
                'VERSION' => $version
            });
        }
    } 
}

1;
