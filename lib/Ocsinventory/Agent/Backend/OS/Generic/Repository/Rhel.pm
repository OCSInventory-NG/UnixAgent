package Ocsinventory::Agent::Backend::OS::Generic::Repository::Rhel;

use strict;
use warnings;

sub check {
    my $params = shift;
    my $common = $params->{common};
    return unless $common->can_run("dnf");
}

my $repo_name;
my $repo_baseurl;
my $repo_filename;
my $repo_pkgs;
my $repo_rev;
my $repo_size;
my $repo_expire;
my $repo_updated;
my $repo_lastupdated;
my $repo_mirrors;

sub run {
    my $params = shift;
    my $common = $params->{common};
    my @repository=`LANG=C dnf -v repolist 2>/dev/null`;

    for (my $i=0;$i<$#repository;$i++){
         my $line=$repository[$i];
         if ($line =~ /^$/ && $repo_name && $repo_filename) {
            $common->addRepo({
                BASEURL => $repo_baseurl,
                FILENAME => $repo_filename,
                NAME => $repo_name,
                PKGS => $repo_pkgs,
                REVISION => $repo_rev,
                SIZE => $repo_size,
                UPDATED => $repo_updated,
                LASTUPDATED => $repo_lastupdated,
                EXPIRE => $repo_expire,
                MIRRORS => $repo_mirrors,
            });
            $repo_name = $repo_expire = $repo_baseurl = $repo_filename = $repo_pkgs = $repo_rev = $repo_size = $repo_mirrors = $repo_updated = $repo_lastupdated = undef;
        }

        $repo_name=$1 if ($line =~ /^Repo-name\s+:\s(.*)/i);
        $repo_baseurl=$1 if ($line =~ /^Repo-baseurl\s+:\s(.*)/i);
        $repo_filename=$1 if ($line =~ /^Repo-filename:\s(.*)/i);
        $repo_pkgs=$1 if ($line =~ /^Repo-pkgs\s+:\s(.*)/i);
        $repo_rev=$1 if ($line =~ /^Repo-revision\s+:\s(.*)/i);
        $repo_size=$1 if ($line =~ /^Repo-size\s+:\s(.*)/i);
        $repo_expire=$1 if ($line =~ /^Repo-expire\s+:\s(.*)/i);
        $repo_updated=$1 if ($line =~ /^Repo-updated\s+:\s(.*)/i);
        $repo_lastupdated=$1 if ($line =~ /Updated\s+:\s(.*)/i);
        $repo_mirrors=$1 if ($line =~ /^Repo-metalink\s+:\s(.*)/i);
    }
}

1;
