#!/usr/bin/perl

use strict;
use warnings;

use File::ChangeNotify;
use File::Spec::Functions;
use Pod::HtmlTree;
use Cwd;

my $basedir = getcwd();
my $dir = catdir($basedir, 'lib');
print "Start watching dir $dir ...\n\n";

my $watcher = File::ChangeNotify->instantiate_watcher(
                    directories     => [ $dir ],
                    filter  => qr/\.(?:pm|pl)$/,
                );

while ( my @events = $watcher->wait_for_events() ) {
    for (@events) {
        print "File ". $_->path() . " changed.\n";
    }

    eval {
        Pod::HtmlTree::pod2htmltree('/pod')
    };
    if ( $@ ) {
        print "***** Failed to make pod *****\n$@";
        sleep;
        next;
    }

    my $htmldir = catdir($basedir, 'docs', 'html');

    opendir my $DIR, $htmldir
        or die "Failed to open doc directory $htmldir";
    while ( my $dir = readdir($DIR) ) {
        $dir eq 't' and next;
        my $full_dir = catdir($htmldir, $dir);
        -d $full_dir or next;
        
        system('cp', '-R', $full_dir, '/var/www/pod');
    }
    
    closedir $DIR;

    print "Finished. (sleep 5 seconds)\n";
    sleep(5);
}




