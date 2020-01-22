#!/usr/bin/perl

=head1 NAME

load_bcs_images_varitome.pl

=head1 SYNOPSYS

load_bcs_images.pl -D [ sandbox | cxgn | trial ] -H hostname -i dirname -r chado table name [defaults to stock_image script will load image ids into ChadoTableprop] -u username -b image_dir_path -d dir_name  -e file_ext [jpg] -m map file -t [trial mode] 

=head1 DESCRIPTION

Loads  images  into the SGN database, using the SGN::Image framework.
Then link the loaded image with the user-supplied chado objects (e.g. stock, nd_experiment)  
    

Requires the following parameters: 

=over 11

=item -D

a database parameter, which can either be "cxgn", "sandbox", or "trial". "cxgn" and "sandbox" will cause the script to connect to the respective databases; "trial" will connect to sandbox, but not perform any of the database modifications. 

=item -H 

host name 

=item -m 

map file. If provided links between stock names - image file name , is read from a mapping file.
Row labels are expected to be unique file names, column header for the associated stocks is 'name' 

=item -i

a dirname that contains image filenames or subdirectories named after database accessions, containing one or more images (see option -d) .

=item -u

use name - from sgn_people.sp_person. 

=item -b

the dir where the database stores the images (the concatenated values from image_path and image_dir from sgn_local.conf or sgn.conf)

=item -d 

files are stored in sub directories named after database accessions 

=item -e 

image file extension . Defaults to 'jpg'

=item -r 

image linking table name. Defaults to stock_image

=item -s 

list of sub directory names, comma delimited. If files are arrange in subdirs. e.g. "flower,fruits,leaf"

=item -t 

trial mode . Nothing will be stored.


=back

The script will generate an error file, named like the filename supplied, with the extension .err.

=head1 AUTHOR(S)

Naama Menda (nm249@cornell.edu) September 2018.

=cut

use strict;

use CXGN::Metadata::Schema;
use CXGN::Metadata::Metadbdata;
use CXGN::DB::InsertDBH;
use CXGN::Image;
use Bio::Chado::Schema;
use CXGN::People::Person;
use Carp qw /croak/;
use Data::Dumper qw / Dumper /;

use File::Basename;
use SGN::Context;
use Getopt::Std;

use CXGN::Tools::File::Spreadsheet;
use File::Glob qw | bsd_glob |;

our ($opt_H, $opt_D, $opt_t, $opt_i, $opt_u, $opt_r, $opt_d, $opt_e, $opt_m, $opt_b, $opt_s);
getopts('H:D:u:i:e:tdr:m:b:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $dirname = $opt_i;
my $sp_person=$opt_u;
my $db_image_dir = $opt_b;
my $chado_table = $opt_r;
my $ext = $opt_e || 'jpg';
my @sub_subdirs = split "," , $opt_s;
    
if (!$dbhost && !$dbname) { 
    print "dbhost = $dbhost , dbname = $dbname\n";
    print "opt_t = $opt_t, opt_u = $opt_u, opt_r = $chado_table, opt_i = $dirname\n";
    usage();
}

if (!$dirname) { print "dirname = $dirname\n" ; usage(); }

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				    } );

my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } ,  { on_connect_do => ['SET search_path TO  public;'] }
    );


print STDERR "Generate metadata_id... ";
my $metadata_schema = CXGN::Metadata::Schema->connect("dbi:Pg:database=$dbname;host=".$dbh->dbhost(), "postgres", $dbh->dbpass(), {on_connect_do => "SET search_path TO 'metadata', 'public'", });

my $sp_person_id= CXGN::People::Person->get_person_by_username($dbh, $sp_person);
my %name2id = ();


print "PLEASE VERIFY:\n";
print "Using dbhost: $dbhost. DB name: $dbname. \n";
print "Path to image is: $db_image_dir\n";
print "Subdirs are $opt_s\n" if $opt_s;
print "CONTINUE? ";

my $a = (<STDIN>);
if ($a !~ /[yY]/) { exit(); }

if (($dbname eq "sandbox") && ($db_image_dir !~ /sandbox/)) { 
    die "The image directory needs to be set to image_files_sandbox if running on rubisco/sandbox. Please change the image_dir parameter in SGN.conf\n\n";
					  }
if (($dbname eq "cxgn") && ($db_image_dir =~ /sandbox/)) { 
    warn "The image directory needs to be set to image_files when the script is running on the production database. Please change the image_dir parameter in SGN.conf\n\n";
}

my %image_hash = ();  # used to retrieve images that are already loaded
my %connections = (); # keep track of object -- image connections that have already been made.

print STDERR "Caching stock table...\n";
my $object_rs = $schema->resultset("Stock::Stock")->search( { } ) ;
while (my $object = $object_rs->next ) {
    my $id = $object->stock_id;
    my $name = $object->name;
    $name2id{lc($name)} = $id;
}

# cache image chado object - image links to prevent reloading of the
# same data
#
print "Caching image $chado_table links...\n";

my $image_q = "SELECT * FROM metadata.md_image";
my $connections_q = "SELECT * from phenome.stock_image";
my $image_sth = $dbh->prepare($image_q);
my $connections_sth = $dbh->prepare($connections_q);
$image_sth->execute();
$connections_sth->execute();
while ( my $connections_hashref = $connections_sth->fetchrow_hashref() ) {
    my $image_id = $connections_hashref->{image_id};
    my $chado_table_id = $connections_hashref->{stock_id};  ##### table specific
     $connections{$image_id."-".$chado_table_id}++;
}
while ( my $image_hashref = $image_sth->fetchrow_hashref() ) {
    my $image_id = $image_hashref->{image_id};
    my $i = CXGN::Image->new(dbh=>$dbh, image_id=>$image_id, image_dir=>$db_image_dir); # SGN::Image...$ch
    my $original_filename = $i->get_original_filename();
    $image_hash{$original_filename} = $i; # this doesn't have the file extension  
}
print STDERR "\n";

open (ERR, ">load_bcs_images.err") || die "Can't open error file\n";

my @files;

if (! $opt_d) { 
    @files = bsd_glob "$dirname/*.$ext";
}
else { 
    @files = bsd_glob "$dirname/*" if $opt_d ; #should be a list of dir names named after accession names
}

print STDERR "DIRS = ". join("\n", @files) ."\n";


my $new_image_count = 0;

my $metadata = CXGN::Metadata::Metadbdata->new($metadata_schema, $sp_person);
my $metadata_id = $metadata->store()->get_metadata_id();

#read from spreadsheet:
my $map_file = $opt_m; #
my %name_map;

if ($opt_m) {
    my $s = CXGN::Tools::File::Spreadsheet->new($map_file); #
    my @rows = $s->row_labels(); #
    foreach my $file_name (@rows) { #
    	my $stock_name = $s->value_at($file_name, 'name'); #
	$name_map{$file_name} = $stock_name;
    }
}

#each file dir should have 3 sub directories
#fruit_scans, leaf_scans, pericarp_sections
my @sub_dirs;
my @sub_files;

foreach my $file (@files) { # this $file should be the accession name
    eval {
	chomp($file);
	@sub_files = ($file);

	if ($opt_d) {
	    @sub_dirs =  bsd_glob "$file/*" ;
	}
	print STDERR "SUBDIRS FOR $file: ".Dumper(\@sub_dirs)."\n";
	
	my $accession_name = basename($file);
	print STDERR "ACCESSION=$accession_name\n";
	my $stock_id = $name2id{ lc($accession_name) };
	
	if ( !$stock_id ) { 
	    warn "***STOCK $accession_name does not exist! Skipping to next stock ****\n\n"; 
	    next(); 
	}
	
	my $stock = $schema->resultset("Stock::Stock")->find( {
	    stock_id => $stock_id  } );
	
	foreach my $subdir (@sub_dirs) {
	    chomp $subdir;
	    @sub_files =  bsd_glob "$subdir/*" ;
	    
	    print STDERR "FILES FOR $file: ".Dumper(\@sub_files)."\n";
	    
	    foreach my $filename (@sub_files) {
		
		chomp $filename;
		my $object =  basename($file );
		if  ( $filename =~ m/thumbnail*/i ) { next ; } #do not load thumbnail images, those will be generated automatically by the image object
		
		my $image_base = basename($filename);
		my ($object_name, $description, $extension);
		if ($opt_m) {
		    $object_name = $name_map{$object . "." . $ext } ;
		}
	    
		print STDERR "OBJECT = $object...\n";
#	    if ($image_base =~ /(.*?)\_(.*?)(\..*?)?$/) { 
		if ($image_base =~ m/(.*)(\.$ext)/i) { 
		    $extension = $2;
		    $image_base = $1;
		}
		#if ($image_base =~ m/(.*)\_(.*)/)  { 
		#$object_name = $1;
		#$description = $2;

	        #}
		else { 
		    $object_name = $image_base;
		}
		print STDERR "Object: $object OBJECT NAME: $object_name DESCRPTION: $description EXTENSION: $extension\n";


		print STDOUT "Processing file $file...\n";
		print STDOUT "Loading $image_base, image $filename\n";
		print ERR "Loading $object_name, image $filename\n";
		my $image_id; # this will be set later, depending if the image is new or not
		if (! -e $filename) { 
		    warn "The specified file $filename does not exist! Skipping...\n";
		    next();
		}
		if (!exists($name2id{lc($object)})) { 
		    message ("$object does not exist in the database...\n");
		}

		else {
		    print ERR "Adding $filename...\n";
		    if (exists($image_hash{$image_base})) { 
			print STDERR "****$image_base is already loaded into the database...\n";
			$image_id = $image_hash{$image_base}->get_image_id();
			$connections{$image_id."-".$name2id{lc($object)}}++;
			if ($connections{$image_id."-".$name2id{lc($object)}} > 1) { 
			    print STDERR "*****The connection between $object and image $image_base has already been made. Skipping...\n";
			}
			elsif ($image_hash{$image_base}) { 
			    print STDERR qq  { Associating $chado_table $name2id{lc($object)} with already loaded image $image_base...\n };
			}
		    }
		    else { 
			print STDERR qq { ##NEW IMAGE : Generating new image object for image '$image_base' and associating it with $chado_table $object, id $name2id{lc($object) } ...\n };
			
			if ($opt_t)  { 
			    print STDOUT qq { ## Would associate file $image_base to $chado_table $object_name, id $name2id{lc($object)}\n };
			    $new_image_count++;
			}
			else { 
			    my $image = CXGN::Image->new(dbh=>$dbh, image_dir=>$db_image_dir);   
			    $image_hash{$filename}=$image;

			    $image->process_image("$filename", $chado_table , $name2id{lc($object)}); 
			    $image->set_description("$description");
			    $image->set_name(basename($filename , ".$ext"));
			    $image->set_sp_person_id($sp_person_id);
			    $image->set_obsolete("f");
			    $image_id = $image->store();

	
			    #add subdir name as an image tag
			    my $subdir_name = basename($subdir);
			    my $tag_id = CXGN::Tag::exists_tag_named($dbh, $subdir_name);
			    my $tag_object = CXGN::Tag->new($dbh, $tag_id);
			    if (!$tag_id) {
				$tag_object->set_name($subdir_name);
				$tag_object->set_sp_person_id($sp_person_id);
				$tag_object->store();
			    }
			    $image->add_tag($tag_object);
			    print STDERR "ADDING TAG $subdir_name to image\n";

			    #link the image with the BCS object 
			    $new_image_count++;
			    my $image_subpath = $image->image_subpath();
			    print STDERR "FINAL IMAGE PATH = $db_image_dir/$image_subpath\n";
			}
		    }
		}

		if (!$opt_t) {
		    print STDERR "Connecting image $filename and id $image_id with stock $stock_id\n";
		    #store the image_id - stock_id link
		    my $q1 = "SELECT stock_image_id FROM phenome.stock_image WHERE stock_id = ? AND  image_id = ?" ;
		    my $sth1 = $dbh->prepare($q1);
		    my $exists = $sth1->execute($stock_id, $image_id);
		    if ( ($exists*1)  ) {
			print STDERR "Stock $stock_id already linked with image $image_id\n";
		    } else {
			my $q = "INSERT INTO phenome.stock_image (stock_id, image_id, metadata_id) VALUES (?,?,?)";
			my $sth  = $dbh->prepare($q);
			my $stock_image_id = $sth->execute($stock_id, $image_id, $metadata_id);
			print STDERR  "linking stock $stock_id with image $image_id db id = $stock_image_id \n";
		    }
		}
	    }
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
    print "Usage: load_images.pl -D dbname [ cxgn | sandbox ]  -H dbhost -t [trial mode ] -i input dir -r chado table name for the object to link with the image \n";
    exit();
}

sub message {
    my $message=shift;
    print STDOUT $message;
    print ERR $message;
}
