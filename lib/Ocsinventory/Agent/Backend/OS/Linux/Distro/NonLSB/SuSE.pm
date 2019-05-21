package Ocsinventory::Agent::Backend::OS::Linux::Distro::NonLSB::SuSE;
use strict;

sub check {
    my $params = shift;
    my $common = $params->{common};
    $common->can_read ("/etc/SuSE-release")
}

sub run {
    my $v;
    my $version;
    my $patchlevel;
    my $osname;

    my $params = shift;
    my $common = $params->{common};

    if(-s "/etc/os-release"){
	open V, "/etc/os-release" or warn;
	foreach (<V>) {
        	next if (/^#/);
		$osname=$1 if (/^PRETTY_NAME="([A-Z]*[a-z]*[0-9]*.*)"/);
        	$version=$1 if (/^VERSION_ID="([0-9]*.*)"/);
        	$patchlevel=$1 if (/^VERSION="([A-Z]*[0-9]*.*)"/);
        }
        close V;
    }else{
	open V, "/etc/SuSE-release" or warn;
	$osname=<V>;
	foreach (<V>) {
        	next if (/^#/);
        	$version=$1 if (/^VERSION = ([0-9]+)/);
        	$patchlevel=$1 if (/^PATCHLEVEL = ([0-9]+)/);
        }
        close V;
    }

    $common->setHardware({
        OSNAME => $osname,
	OSVERSION => $version,
        OSCOMMENTS => $patchlevel
    });
}

1;
