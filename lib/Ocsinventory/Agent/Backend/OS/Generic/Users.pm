package Ocsinventory::Agent::Backend::OS::Generic::Users;

sub check {
    # Useless check for a posix system i guess
    my @who = `who 2>/dev/null`;
    return 1 if @who;
    return;
}

# Initialise the distro entry
sub run {
    my $params = shift;
    my $common = $params->{common};

    my %user;
    # Logged on users
    for (`who`){
        my $user = $1 if /^(\S+)./;
        $common->addUser ({ LOGIN => $user });
    }
    my $last = getLastUsers();
    $common->setHardware($last);

}

sub getLastUsers{
    my $last = `last 2>/dev/null`;

    return unless $last;
    return unless $last =~ /^(\S+)\s+\S+\s+\S+\s+(\S+\s+\S+\s+\S+\s+\S+)/x;

    return {
       LASTLOGGEDUSER => $1,
       DATELASTLOGGEDUSER => $2
    }
}

1;
