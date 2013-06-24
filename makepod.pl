#!/usr/bin/perl

use strict;
use warnings;


use File::Spec;

my $libpath;

BEGIN {
    my $thisfile = readlink(__FILE__) || __FILE__ ;
    $libpath  = ( File::Spec->splitpath($thisfile) )[1];
    $libpath = File::Spec->catdir( $libpath, 'lib' );
    print "$libpath\n";
    $libpath =~ s{/$}{};
}

use lib $libpath;

use File::ChangeNotify;
use File::Path qw(make_path);
use Cwd;
use Getopt::Long;
use HTML::Entities;
use Data::Dumper;
use AutoP2H::Pod;
use Pod::Simple::Search;


$Pod::Simple::HTML::Content_decl = q{<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">};

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

@dirs = split ':', $dirstr;
@dirs or die "No watched directories specified";


#  Make initial HTMLs.
for ( @dirs ) {
    my $ps = Pod::Simple::Search->new();
    $ps->inc(0);
    my $name2path = $ps->survey( File::Spec->catdir($basedir, $_) );
    
    for my $path ( values %$name2path ) {
        make_html($path);
    }
}


print "Start watching dir $dirstr ...\n\n";

my $watcher = File::ChangeNotify->instantiate_watcher(
                    directories     => [ map { File::Spec->catdir($basedir, $_) } @dirs ],
                    filter  => qr/\.(?:pm|pl)$/,
                );

while ( my @events = $watcher->wait_for_events() ) {
    
    my %map = map { $_->path => 1 } grep { $_->type =~ m/^(create|modify)$/ } @events;
    my @paths = keys %map;
    for (@paths) {
        make_html($_);
    }

    print "Finished. (sleep 5 seconds)\n";
    sleep(5);
}


sub make_path_outfile {
    my ($outfile) = @_;

    my $dir = (File::Spec->splitpath($outfile))[1];
    make_path($dir);
}


sub make_html {
    my ($path) = @_;

    print "Processing $path ...\n";

    my $p = AutoP2H::Pod->new;
    $p->index(1);
    $p->html_css($css);

    my $rel_path = $path;
    $rel_path =~ s/^$basedir//;

    #  現在の階層から見た、対象のパッケージの階層の深さ。
    #  index に戻るときの相対パスを生成するために使う。
    #  (splitdir の戻り値は ARRAY。scalar で受け取ることで、個数が入る)
    my $rel_depth = grep { $_ ne '' } File::Spec->splitdir($rel_path);

    $p->pod_top( File::Spec->catfile(('..') x ($rel_depth), 'index.html') );
    $p->release_top( File::Spec->catfile(('..') x ($rel_depth - 1), 'index.html' ) );
    $p->release_name( $release_name );

    my $html;
    $p->output_string(\$html);
    $p->parse_file($path);

    my $outfile = File::Spec->catdir($outdir, $release_name, $rel_path);
    $outfile =~ s/\.(pm|pl)$/.html/;

    make_path_outfile($outfile);        

    open my $OUT, '>', $outfile 
        or die "Failed to open file $outfile : $!\n";
    print $OUT decode_entities($html);
    close $OUT;
}

