package Ocsinventory::Agent::Backend::OS::Linux::Archs::i386::CPU;

use strict;

use Config;

sub check { can_read("/proc/cpuinfo"); can_run("arch"); }

sub run {

	my $params = shift;
	my $common = $params->{common};

	my @cpu;
	my @cache;
	my $current;
	my $cpuarch = `arch`;
	chomp($cpuarch);
	my $datawidth;
	my $index;
	my $cpucount = 0;
	my $l2cacheid;
	my $l2cachesection;

	if ($cpuarch eq "x86_64"){
		$datawidth = 64;
	} else {
		$datawidth = 32;
	}


	open CPUINFO, "</proc/cpuinfo" or warn;
	for (<CPUINFO>) {
		if (/^vendor_id\s*:\s*(Authentic|Genuine|)(.+)/i) {
			$current->{MANUFACTURER} = $2;
			$current->{MANUFACTURER} =~ s/(TMx86|TransmetaCPU)/Transmeta/;
			$current->{MANUFACTURER} =~ s/CyrixInstead/Cyrix/;
			$current->{MANUFACTURER} =~ s/CentaurHauls/VIA/;
		}
		$current->{CORES} = $1 if /^cpu\scores\s*:\s*(\d+)/i;
		$current->{LOGICAL_CPUS} = $1 if /^siblings\s*:\s*(\d+)/i;
		$current->{SPEED} = $current->{CURRENT_SPEED} = $1 if /^cpu\sMHz\s*:\s*(\d+)/i;
		$current->{TYPE} = $1 if /^model\sname\s*:\s*(.+)/i;
		$current->{HPT} = 'yes' if /^flags\s*:.*\bht\b/i;
		$index = $1 if ! defined $index && /^processor\s*:\s*(\d+)/i;
		$index = $1 if /^physical\sid\s*:\s*(\d+)/i;
		if (/^\s*$/) {
			$current->{HPT} = 'no' if $current->{HPT} ne 'yes';
			$current->{CPUARCH} = $cpuarch;
			$current->{DATA_WIDTH} = $datawidth;
			$current->{TYPE} =~ s/\s{2,}/ /g;
			$cpu[$index] = $current;
			$current = $index = undef;
		}
	}
	for my $current (@cpu) {
		if (defined $current) {
			$common->addCPU($current);
		}
	}

}

1
