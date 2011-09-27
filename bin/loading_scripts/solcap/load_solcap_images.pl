#!/usr/bin/perl

=head1 NAME

load_solcap_images.pl

=head1 SYNOPSYS

load_solcap_images.pl -D [ sandbox | cxgn | trial ] -H hostname -i dirname

=head1 DESCRIPTION

Loads  images  into the SGN database, using the SGN::Image framework.
Then link the loaded image with the relevant stock  (see phenome.stock_image table)

Requires the following parameters:

=over 8

=item -D

a database parameter, which can either be "cxgn", "sandbox", or "trial". "cxgn" and "sandbox" will cause the script to connect to the respective databases; "trial" will connect to sandbox, but not perform any of the database modifications.

=item -H

host name

=item -i

a dirname that contains image filenames or subdirectories named after database accessions, containing one or more images (see option -d) .

=item -u

user_name - from sgn_people.sp_person.

=item -l

location, as stored in stockprop (when plots are loaded with load_solcap_plots.pl)

=item -d

files are stored in sub directories named after database accessions

=item -e

image file extension . Defaults to 'jpg'


=item -t

trial mode . Nothing will be stored.


=back

The script will generate an error file, named like the filename supplied, with the extension .err.

=head1 AUTHOR(S)

Naama Menda (nm249@cornell.edu) September 2011.

=cut

use strict;

use CXGN::Metadata::Schema;
use CXGN::Metadata::Metadbdata;
use CXGN::DB::InsertDBH;
use SGN::Image;
use Bio::Chado::Schema;
use CXGN::People::Person;
use Carp qw /croak/;

use File::Basename;
use SGN::Context;
use Getopt::Std;


our ($opt_H, $opt_D, $opt_t, $opt_i, $opt_u, $opt_d, $opt_e, $opt_f, $opt_l, $opt_y);
getopts('H:D:u:i:e:f:tdl:y:');

my $dbhost    = $opt_H;
my $dbname    = $opt_D;
my $dirname   = $opt_i;
my $sp_person = $opt_u;
my $location  = $opt_l;
my $year      = $opt_y;

my $ext = $opt_e || 'jpg';

if (!$dbhost && !$dbname) {
    print "dbhost = $dbhost , dbname = $dbname\n";
    print "opt_t = $opt_t, opt_u = $opt_u, opt_d= $opt_d opt_i = $dirname\n";
    usage();
}

if (!$dirname) { print "dirname = $dirname\n" ; usage(); }

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				    } );

my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } ,  { on_connect_do => ['SET search_path TO  public;'] }
    );
my $metadata_schema = CXGN::Metadata::Schema->connect(
    sub { $dbh->get_actual_dbh },
    { on_connect_do => ['SET search_path TO metadata;'] },
    );
my $sp_person_id= CXGN::People::Person->get_person_by_username($dbh, $sp_person);
my %name2id = ();


my $ch = SGN::Context->new();
my $image_dir =  $opt_f || $ch->get_conf("image_dir");

print "PLEASE VERIFY:\n";
print "Using dbhost: $dbhost. DB name: $dbname. \n";
print "Path to image is: $image_dir\n";
print "CONTINUE? ";
my $a = (<STDIN>);
if ($a !~ /[yY]/) { exit(); }

if (($dbname eq "sandbox") && ($image_dir !~ /sandbox/)) { 
    die "The image directory needs to be set to image_files_sandbox if running on rubisco/sandbox. Please change the image_dir parameter in SGN.conf\n\n";
					  }
if (($dbname eq "cxgn") && ($image_dir =~ /sandbox/)) { 
    warn "The image directory needs to be set to image_files when the script is running on the production database. Please change the image_dir parameter in SGN.conf\n\n";
}

my %image_hash = ();  # used to retrieve images that are already loaded
my %connections = (); # keep track of object -- image connections that have already been made.

my $object_rs = $schema->resultset("Stock::Stock")->search( { } ) ;
while (my $object = $object_rs->next ) {
    my $id = $object->stock_id;
    my $name = $object->name;
    $name2id{lc($name)} = $id;
}

# cache image chado object - image links to prevent reloading of the
# same data
#
print "Caching image-stock links...\n";

my $q = "SELECT * FROM phenome.stock_image";
my $sth = $dbh->prepare($q);
$sth->execute();
while ( my $hashref = $sth->fetchrow_hashref() ) {
    my $image_id = $hashref->{image_id};
    my $chado_table_id = $hashref->{stock_id};  ##### table specific
    my $i = SGN::Image->new($dbh, $image_id);
    my $original_filename = $i->get_original_filename();
    $image_hash{$original_filename} = $i; # this doesn't have the file extension
    $connections{$image_id."-".$chado_table_id}++;
}

open (ERR, ">load_solcap_images.err") || die "Can't open error file\n";

my @files = glob "$dirname/*.$ext";
@files = glob "$dirname/*" if $opt_d ;
my @sub_files;

my $new_image_count = 0;


foreach my $file (@files) {
    eval {
	chomp($file);
	@sub_files = ($file);
	@sub_files =  glob "$file/*.$ext" if $opt_d;

	my $object_name = basename($file, ".$ext" );
	print  "object_name = '".$object_name."' \n";
	#$individual_name =~s/(W\d{3,4}).*\.JPG/$1/i if $individual_name =~m/^W\d{3}/;
	#2009_oh_8902_fruit-t
	# solcap images:
	#my ($year, $place, $plot, undef) = split /_/ , $object_name;
        #2009_ca_2138_fruit_c.jpg
        my ($year, $place, $name, undef,undef) = split /_/ , $object_name;

        #my $stock = $schema->resultset("Stock::Stock")->find( {
	#    stock_id => $name2id{ lc($name) }  } );
	my ($stock) = $schema->resultset("Stock::Stock")->search(
            {
                name => $name,
                uniquename => { 'ilike' => $name . '%' . $year . '%' . $location . '%'}
            } );

	if (!$stock) {
	    warn "no stock found for plot # $name ! Skipping !!\n\n";
            next();
	}

        foreach my $filename (@sub_files) {
	    chomp $filename;
	    print STDOUT "Processing file $file...\n";
	    print STDOUT "Loading $name, image $filename\n";
	    print ERR "Loading $name, image $filename\n";
	    my $image_id; # this will be set later, depending if the image is new or not
	    if (! -e $filename) {
		warn "The specified file $filename does not exist! Skipping...\n";
	    	next();
	    }

	    if (!exists($name2id{lc($name)})) {
		message ("$name does not exist in the database...\n");
	    }

	    else {
		print ERR "Adding $filename...\n";
		if (exists($image_hash{$filename})) {
		    message("$filename is already loaded into the database...\n");
		    $image_id = $image_hash{$filename}->get_image_id();
		    $connections{$image_id."-".$name2id{lc($name)}}++;
		    if ($connections{$image_id."-".$name2id{lc($name)}} > 1) {
			message("The connection between $name and image $filename has already been made. Skipping...\n");
		    }
		    elsif ($image_hash{$filename}) {
			message("Associating stock " . $name2id{lc($name)} . "with already loaded image $filename...\n") ;
                        ################################
		    }
		}
		else {
		    print ERR qq { Generating new image object for image $filename and associating it with stock $name, id $name2id{lc($name) } ...\n };
		    my $caption = $name;

		    if ($opt_t)  {
			print STDOUT qq { Would associate file $filename to stock $name, id $name2id{lc($name)}\n };
			$new_image_count++;
		    }
		    else {
			my $image = SGN::Image->new($dbh);
			$image_hash{$filename}=$image;

			$image->process_image("$filename", undef, undef);
			$image->set_description("$caption");
			$image->set_name(basename($filename , ".$ext"));
			$image->set_sp_person_id($sp_person_id);
			$image->set_obsolete("f");
			$image_id = $image->store();
			$new_image_count++;
		    }
		}
	    }
            my $metadata = CXGN::Metadata::Metadbdata->new($metadata_schema, $sp_person);
            my $metadata_id = $metadata->store()->get_metadata_id();
            die "NO METADATA ID FOUND\n" if !$metadata_id; 
#store the image_id - stock_id link
            my $q = "INSERT INTO phenome.stock_image (stock_id, image_id, metadata_id) VALUES (?,?,?)";
            my $sth  = $dbh->prepare($q);
            $sth->execute($stock->stock_id, $image_id, $metadata_id);
        } else {
            print "image $image_id is already linked with stock " . $stock->stock_id . "\n";
        }
    };
    if ($@) {
	print STDOUT "ERROR OCCURRED WHILE SAVING NEW INFORMATION. $@\n";
	$dbh->rollback();
    }
    else {
	$dbh->commit();
    }
}


close(ERR);
close(F);


print STDOUT "Inserted  $new_image_count images.\n";
print STDOUT "Done. \n";

sub usage {
    print "Usage: load_images.pl -D dbname [ cxgn | sandbox ]  -H dbhost -t [trial mode ] -i input dir -l location of the plots (as loaded into stockprop). \n Images will be stored in phenome.stock_image \n";
    exit();
}

sub message {
    my $message=shift;
    print STDOUT $message;
    print ERR $message;
}
