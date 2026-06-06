package Ocsinventory::Agent::Backend::Virtualization::Lxc;

use strict;

sub check {
    my $params = shift;
    my $common = $params->{common};
    $common->can_run('lxc-ls') && $common->can_run('lxc-info')
}

sub run {

    my $params = shift;
    my $common = $params->{common};

    foreach (`lxc-ls -1`) {
        chomp;
        my $vm = $_;
        next unless $vm =~ /^\S+$/;

        my ($name, $vmid, $status, $memory);
        my $vcpu = 0;

        foreach (`lxc-info -n '$vm'`) {
            $name  = $1 if /^Name:\s*(\S+)$/;
            $vmid  = $1 if /^PID:\s*(\S+)$/;
            if (/^State:\s*(\S+)$/) {
                $status = $1 eq 'RUNNING' ? 'Running' :
                          $1 eq 'FROZEN'  ? 'Paused'  : 'Off';
            }
        }

        # Use lxc-info -c to read config keys for both cgroup v1 and v2.
        # Avoids lxc-cgroup, which fails on cgroup v2 hosts (Debian 13+, RHEL 9+).
        # Works for both running and stopped containers.
        foreach (`lxc-info -n '$vm' -c lxc.cgroup.memory.limit_in_bytes -c lxc.cgroup2.memory.max -c lxc.cgroup.cpuset.cpus -c lxc.cgroup2.cpuset.cpus 2>/dev/null`) {
            next unless /^\s*(\S[^=]*?)\s*=\s*(\S+)\s*$/;
            my ($key, $val) = ($1, $2);

            if (!defined($memory) && ($key eq 'lxc.cgroup.memory.limit_in_bytes' || $key eq 'lxc.cgroup2.memory.max')) {
                # 'max' is the cgroup v2 sentinel for unlimited; skip it
                $memory = $val unless $val eq 'max';
            }

            if ($key eq 'lxc.cgroup.cpuset.cpus' || $key eq 'lxc.cgroup2.cpuset.cpus') {
                $vcpu = 0;
                foreach my $cpu_range (split(/,/, $val)) {
                    if ($cpu_range =~ /(\d+)-(\d+)/) {
                        $vcpu += $2 - $1 + 1;
                    } else {
                        $vcpu += 1;
                    }
                }
            }
        }

        $common->addVirtualMachine({
            MEMORY    => $memory,
            NAME      => $name,
            STATUS    => $status,
            SUBSYSTEM => 'LXC Container',
            VCPU      => $vcpu,
            VMID      => $vmid,
            VMTYPE    => 'LXC',
        });
    }
}

1;
