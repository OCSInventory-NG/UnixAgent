package Ocsinventory::Agent::Backend::OS::MacOS::Domains;
use strict;

# straight up theft from the other modules...

sub check {
    my $hostname;
    chomp ($hostname = `hostname`);
    my @domain = split (/\./, $hostname);
    shift (@domain);
    return 1 if @domain;
    -f "/etc/resolv.conf"
 }
sub run {
    my $params = shift;
    my $common = $params->{common};

    my $domain;
    my $hostname;
    chomp ($hostname = `hostname`);
    my @domain = split (/\./, $hostname);
    shift (@domain);
    $domain = join ('.',@domain);

    if (!$domain) {
      my %domain;

      open RESOLV, "/etc/resolv.conf" or warn;
      while(<RESOLV>){
        $domain{$2} = 1 if (/^(domain|search)\s+(.+)/);
      }
      close RESOLV;

      $domain = join "/", keys %domain;
    }

    # If no domain name, we send "WORKGROUP"
    $domain = 'WORKGROUP' unless $domain;

    # User domain
    my $userdomain = `defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server Workgroup 2>/dev/null`;
    chomp($userdomain);
    if ($userdomain eq "" ) {
        $userdomain = `hostname -s`;
        chomp($userdomain);
    }

    $common->setHardware({
        WORKGROUP => $domain
    });
}

1;
