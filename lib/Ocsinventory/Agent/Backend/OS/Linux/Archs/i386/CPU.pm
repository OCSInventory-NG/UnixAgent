package Ocsinventory::Agent::Backend::OS::Linux::Archs::i386::CPU;

use strict;

use Config;
use Data::Dumper;

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

	# Prefer dmidecode to give us the information we're looking for
   	@cpu = `dmidecode -t processor`;

   	for (@cpu){
		$current->{CORES} = $1 if /Core\sCount:\s*(\d+)/i;
		$current->{CURRENT_SPEED} = $1 if /Current\sSpeed:\s*(\d+)/i;
		$current->{HPT} = 'yes' if /^\s*HTT\s/i;
		$current->{MANUFACTURER} = $1 if /Manufacturer:\s*(.*)/i;
		$current->{SOCKET} = $1 if /Upgrade:\s*Socket\s(.*)/i;
		$current->{SPEED} = $1 if /Max\sSpeed:\s*(\d+)/i;
		$current->{TYPE} = $1 if /Version:\s*(.*)/i;
		$current->{VOLTAGE} = $1 if /Voltage:\s*(.*)V/i;
		$l2cacheid = $1 if /L2\sCache\sHandle:\s*(0x[0-9a-f]+)/i;

		# Add and reset CPU when encountering a blank line
		if (/^\s*$/ && defined $current){
			if (defined $current->{CORES} &&
				defined $current->{SPEED} &&
				defined $current->{MANUFACTURER} &&
				defined $current->{TYPE}
			) {
				$current->{CPUARCH} = $cpuarch;
				$current->{DATA_WIDTH} = $datawidth;

				# replace repeated whitespace, because some processors like to do that
				$current->{TYPE} =~ s/\s{2,}/ /g;

				if (defined $l2cacheid){
					@cache = `dmidecode -t cache`;
					$l2cachesection = 0;
					for my $l2cacheline (@cache){
						if ($l2cacheline =~ /Handle (0x[0-9a-f]+)/i){
							$l2cachesection = $1 eq $l2cacheid;
						}

						if ($l2cachesection && $l2cacheline =~ /Installed\sSize:\s*([0-9]+)/i){
							$current->{L2CACHESIZE} = $1;
						}
					}
				}

				$common->addCPU($current);
				$cpucount++;
			}

			$current = $l2cacheid = undef;
		}
	}

  	# If dmidecode fails, fall back on /proc/cpuinfo
	if ($cpucount eq 0) {
		undef @cpu;

		open CPUINFO, "</proc/cpuinfo" or warn;
		for (<CPUINFO>) {
			if (/^vendor_id\s*:\s*(Authentic|Genuine|)(.+)/i) {
				$current->{MANUFACTURER} = $2;
				$current->{MANUFACTURER} =~ s/(TMx86|TransmetaCPU)/Transmeta/;
				$current->{MANUFACTURER} =~ s/CyrixInstead/Cyrix/;
				$current->{MANUFACTURER} =~ s/CentaurHauls/VIA/;
			}

			$current->{CORES} = $1 if /^siblings\s*:\s*(\d+)/i;
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
			$common->addCPU($current);
		}
	}
}

1
