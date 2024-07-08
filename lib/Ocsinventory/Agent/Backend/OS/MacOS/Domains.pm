package Ocsinventory::Agent::Backend::OS::MacOS::Domains;
use strict;

# straight up theft from the other modules...

sub check {
    my $params = shift;
    my $common = $params->{common};
    return unless $common->can_run('dsconfigad');
    my @domain = `dsconfigad -show`;
    return 1 if @domain;
    0
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $domain;
    my $domainInfo;
    chomp ($domainInfo = `dsconfigad -show`);
    
    my @domainInfo = split (/\n/, $domainInfo);
    
    shift(@domainInfo);

    if($domainInfo[0]) {
        @domainInfo = split(/\=/, $domainInfo[0]);
        $domain = $domainInfo[1];
        $domain =~ s/^\s+//;
    }

    $common->setHardware({
        WORKGROUP => $domain
    });
}

1;
