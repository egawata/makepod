#!/usr/bin/perl

use strict;
use warnings;

use File::ChangeNotify;
use File::Spec::Functions;
use File::Path qw(make_path);
#use Pod::HtmlTree;
use Pod::Simple::HTML;
use Cwd;
use Getopt::Long;


my $basedir = getcwd();
my $dirstr = 'lib';
my $outdir = '/var/www/pod';
my $release_name = (File::Spec->splitdir($basedir))[-1];
my $css = '/pod/default.css';
my @dirs;

GetOptions(
    'b|basedir=s'   => \$basedir,
    'o|out=s'       => \$outdir,
    'd|dir=s'       => \$dirstr,
    'css=s'         => \$css,
    'n|name=s'      => \$release_name,
);

@dirs = map { catdir($basedir, $_) } (split ':', $dirstr);
@dirs or die "No watching directories specified";

print "Start watching dir $dirstr ...\n\n";

my $watcher = File::ChangeNotify->instantiate_watcher(
                    directories     => \@dirs,
                    filter  => qr/\.(?:pm|pl)$/,
                );

while ( my @events = $watcher->wait_for_events() ) {
    for (@events) {
        my $p = Pod::Simple::HTML->new;
        $p->index(1);
        $p->html_css($css);

        my $path = $_->path();
        print "File $path changed.\n";

        my $html;
        $p->output_string(\$html);
        $p->parse_file($path);
        
        my $rel_path = $path;
        $rel_path =~ s/^$basedir//;
        my $outfile = catdir($outdir, $release_name, $rel_path);
        $outfile =~ s/\.(pm|pl)$/.html/;

        print "Outfile $outfile\n";
        make_path_outfile($outfile);        

        open my $OUT, '>', $outfile 
            or die "Failed to open file $outfile : $!\n";
        print $OUT $html;
        close $OUT;
    }

    print "Finished. (sleep 5 seconds)\n";
    sleep(5);
}


sub make_path_outfile {
    my ($outfile) = @_;

    my $dir = (File::Spec->splitpath($outfile))[1];
    make_path($dir);
}



