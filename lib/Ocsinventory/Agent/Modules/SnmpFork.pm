###############################################################################
## OCSINVENTORY-NG
## Copyleft OCS Inventory NG Team
## Web : http://www.ocsinventory-ng.org
##
## Wrapper for SNMP scan (local and online mode) that handles the forking of the
## SNMP scan process
##
## This code is open source and may be copied and modified as long as the source
## code is always made freely available.
## Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################

package Ocsinventory::Agent::Modules::SnmpFork;

use strict;
no strict 'refs';
no strict 'subs';
use warnings;

use XML::Simple;
use Digest::MD5;


# launch the SNMP scan in a forked process
# takes the native scan function to call, subnets to scan, nb of forks and self
sub fork_snmpscan {
    my ($scan_function, $nets_to_scan, $fork_count, $self) = @_;

    my $logger = $self->{logger};
    
    # get fork count from config or calculate it
    $fork_count = $fork_count // 0;
    if ($fork_count !~ /^\d+$/ || $fork_count <= 0) {
        $logger->debug("Invalid fork_nb value in config: $fork_count. Falling back to calculated value.");
        $fork_count = get_forks_nb();
    }

    # split nets_to_scan among forks
    my @split_nets_to_scan = split_array_across_forks($nets_to_scan, $fork_count);

    my @pipes;
    my @aggregated_content;

    # fork processes
    for (my $i = 0; $i < $fork_count; $i++) {
        # pipe
        my ($reader, $writer);
        pipe($reader, $writer);
        $reader->autoflush(1);
        $writer->autoflush(1);
        push @pipes, $reader;

        my $pid = fork();
        if ($pid) {
            # parent
            close $writer;
        } elsif (defined $pid) {
            # child
            close $reader;
            my $subnets_to_scan = $split_nets_to_scan[$i];

            # calling scan function
            my $xml_result = $scan_function->($self, $subnets_to_scan);

            # write xml result to pipe
            print $writer $xml_result;
            close $writer;
            exit 0;
        } else {
            $logger->error("Fork failed: $!");
        }
    }

    # parent process: read and aggregate XML from pipes
    foreach my $reader (@pipes) {
        while (my $line = <$reader>) {
            push @aggregated_content, $line;
        }
        close $reader;
    }

    # wait for all child processes to finish
    my $child_pid;
    while (($child_pid = waitpid(-1, 0)) > 0) {
        $logger->debug("Child process $child_pid finished with exit code $?");
    }

    # aggregated content into one content block
    my $content_block = join("", @aggregated_content);

    # final XML structure
    my $final_xml = <<"END_XML";
<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    $content_block
  </CONTENT>
  <DEVICEID>$self->{context}->{config}->{deviceid}</DEVICEID>
  <QUERY>SNMP</QUERY>
</REQUEST>
END_XML

    return $final_xml;
}

# split the array of IPs into even portions for each fork
sub split_array_across_forks {
    my ($nets_to_scan, $fork_count) = @_;
    my @split_nets;

    my $i = 0;
    foreach my $subnet (@$nets_to_scan) {
        push(@{$split_nets[$i]}, $subnet);
        $i = ($i + 1) % $fork_count;
    }

    return @split_nets;
}

# default nb of forks is nb of cores
sub get_forks_nb {
    my $cores = `nproc`;
    chomp($cores);
    return $cores;
}


1;
