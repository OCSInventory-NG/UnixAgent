package Ocsinventory::Agent::Backend::OS::Linux::Distro::OSRelease;

use warnings;
use strict;

sub check {
    my $params = shift;
    my $common = $params->{common};
    $common->can_read ("/etc/os-release") 
}

sub run {

    my $name;
    my $version;
    my $description;

    my $params = shift;
    my $common = $params->{common};

    open V, "/etc/os-release" or warn;
    foreach (<V>) {
       next if /^#/;
       $name = $1 if (/^NAME="?([^"]+)"?/);
       $version = $1 if (/^VERSION_ID="?([^"]+)"?/);
       $description=$1 if (/^PRETTY_NAME="?([^"]+)"?/);
    }
    close V;
    chomp($name);

    # Debian version number is set in/etc/debian_version file
    if (-r "/etc/debian_version") {
        if (`uname -v` =~ /debian/i) {
            open V, "/etc/debian_version" or warn;
            foreach (<V>) {
                $version = $1 if ($_ =~ /^(\d+.*)/);
            }
            close V;
            chomp($version);
	}
    }

    # CentOS exact version number is set in /etc/centos-release file
    if (-r "/etc/centos-release") {
        open V, "/etc/centos-release" or warn;
        foreach ($description=<V>) {
            $version = $1 if ($_ =~ /(\d+\.\d+)./g);
        }
        close V;
        chomp($version);
        chomp($description);
    }

    $common->setHardware({
        OSNAME => "$name $version",
        OSVERSION => $version,
        OSCOMMENTS => $description,
    });

}

1;
