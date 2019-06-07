package Ocsinventory::Agent::Backend::OS::Solaris::Domains;
use strict;

sub check { 
  my $params = shift;
  my $common = $params->{common};
  $common->can_run ("uname") 
}

sub run { 
    my $params = shift;
    my $common = $params->{common};

    my $domain;

    chomp($domain = `host \$(uname -n)|awk '{print \$1}'|cut -f2- -d.`);

    if (!$domain) {
        my %domain;

        if (open RESOLV, "/etc/resolv.conf") {
            while(<RESOLV>) {
               $domain{$2} = 1 if (/^(domain|search)\s+(.+)/);
            }
            close RESOLV;
        }
        $domain = join "/", keys %domain;
    }
    # If no domain name, we send "WORKGROUP"
    $domain = 'WORKGROUP' unless $domain;
    $common->setHardware({
        WORKGROUP => $domain
    });
}

1;
