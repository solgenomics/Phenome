#!/usr/bin/perl

=head1 NAME

load_bcs_images.pl

=head1 SYNOPSYS

load_bcs_images.pl -D [ sandbox | cxgn | trial ] -H hostname -i dirname -r chado table name [script will load image ids into ChadoTableprop ]  

=head1 DESCRIPTION

Loads  images  into the SGN database, using the SGN::Image framework.
Then link the loaded image with the user-supplied chado objects (e.g. stock, nd_experiment)  
    

Requires the following parameters: 

=over 8

=item -D

a database parameter, which can either be "cxgn", "sandbox", or "trial". "cxgn" and "sandbox" will cause the script to connect to the respective databases; "trial" will connect to sandbox, but not perform any of the database modifications. 

=item -H 

host name 

=item -r 

Chado table name to link with the image (e.g. 'stock' for storing the image_ids in the stockprop table)

=item -i

a dirname that contains image filenames or subdirectories named after database accessions, containing one or more images (see option -d) .

=item -u

use name - from sgn_people.sp_person. 


=item -d 

files are stored in sub directories named after database accessions 

=item -e 

image file extension . Defaults to 'jpg'


=item -t 

trial mode . Nothing will be stored.


=back

The script will generate an error file, named like the filename supplied, with the extension .err.

=head1 AUTHOR(S)

Naama Menda (nm249@cornell.edu) October 2010.

=cut

use strict;

use CXGN::DB::InsertDBH;
use SGN::Image;
use Bio::Chado::Schema;
use CXGN::People::Person;
use Carp qw /croak/;

use File::Basename;
use SGN::Context;
use Getopt::Std;


our ($opt_H, $opt_D, $opt_t, $opt_i, $opt_u, $opt_r, $opt_d, $opt_e);
getopts('H:D:u:ti:e:dr:g:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $dirname = $opt_i;
my $sp_person=$opt_u;

my $chado_table = $opt_r;
my $ext = $opt_e || 'jpg';

if (!$dbhost && !$dbname) { 
    usage();
}

if (!$dirname) { usage(); }

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				    } );

my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } ,  { on_connect_do => ['SET search_path TO  public;'] }
    );
my $sp_person_id= CXGN::People::Person->get_person_by_username($dbh, $sp_person);
my %name2id = ();


my $ch = SGN::Context->new();
my $image_dir =  $ch->get_conf("image_dir");

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
    die "The image directory needs to be set to image_files when the script is running on the production database. Please change the image_dir parameter in SGN.conf\n\n";
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
print "Caching image $chado_table links...\n";

my $type = $schema->resultset("Cv::Cvterm")->find( {
    name => 'sgn image_id' } );

if ($type) {
    my $rs = $schema->resultset("Stock::Stockprop")->search( { 
	type_id => $type->cvterm_id } );
    while ( my $prop = $rs->next ) {
	my $image_id = $prop->value;
	my $chado_table_id = $prop->stock_id;  ##### table specific
	my $i = SGN::Image->new($dbh, $image_id);
	my $original_filename = $i->get_original_filename();
	$image_hash{$original_filename} = $i; # this doesn't have the file extension
	$connections{$image_id."-".$chado_table_id}++;
    }
}

open (ERR, ">$opt_i" . ".err") || die "Can't open error file\n";

my @files = glob "$dirname/*.$ext";
@files = glob "$dirname/*" if $opt_d ;
my @sub_files;

my $new_image_count = 0;


foreach my $file (@files) { 
    eval { 
	chomp($file);
	@sub_files = ($file);
	@sub_files =  glob "$file/*.$ext" if $opt_d;
	
	
	my $object_name = basename($file);
	print  "object_name = $object_name \n";
	#$individual_name =~s/(W\d{3,4}).*\.JPG/$1/i if $individual_name =~m/^W\d{3}/;
	#2009_oh_8902_fruit-t
	my ($year, $place, $plot, undef) = split /_/ , $object_name; 
	
	print  "plot = $plot \n";
	
	if (!$plot) { die "File $file has no object name in it!"; }
	my $stock = $schema->resultset("Stock::Stock")->find( {
	    stock_id => $name2id{ lc($plot) }  } );
	foreach my $filename (@sub_files) {
	    chomp $filename;
	    print STDOUT "Processing file $file...\n";
	    print STDOUT "Loading $plot, image $filename\n";
	    print ERR "Loading $plot, image $filename\n";
	    my $image_id; # this will be set later, depending if the image is new or not
	    if (! -e $filename) { 
		warn "The specified file $filename does not exist! Skipping...\n";
	    	next();
	    }
	    
	    if (!exists($name2id{lc($plot)})) { 
		message ("$plot does not exist in the database...\n");
	    }
	    
	    else {
		print ERR "Adding $filename...\n";
		if (exists($image_hash{$filename})) { 
		    print ERR "$filename is already loaded into the database...\n";
		    $image_id = $image_hash{$filename}->get_image_id();
		    $connections{$image_id."-".$name2id{lc($plot)}}++;
		    if ($connections{$image_id."-".$name2id{lc($plot)}} > 1) { 
			print ERR "The connection between $plot and image $filename has already been made. Skipping...\n";
		    }
		    elsif ($image_hash{$filename}) { 
			print ERR qq  { Associating $chado_table $name2id{lc($plot)} with already loaded image $filename...\n };
			#$image_hash{$filename}->associate_individual($name2id{lc($individual_name)});
			################################
		    }
		    else { 
			print ERR qq { Generating new image object for image $filename and associating it with $chado_table $plot, id $name2id{lc($plot) } ...\n };
			my $caption = $plot;
			
			if ($opt_t)  { 
			    print STDOUT qq { Would associate file $filename to $chado_table $plot, id $name2id{lc($plot)}\n };
			    $new_image_count++;
			}
			else { 
			    my $image = SGN::Image->new($dbh);   
			    $image_hash{$filename}=$image;
			    
			    $image->process_image("$filename", undef, undef); 
			    $image->set_description("$caption");
			    $image->set_name(basename($filename));
			    $image->set_sp_person_id($sp_person_id);
			    $image->set_obsolete("f");
			    $image_id = $image->store();
			    #link the image with the BCS object 
			    $new_image_count++;
			}
		    }
		}
	    }
	    #store the image_id as a stockprop
	    $stock->create_stockprops( { 'sgn image_id' => $image_id } , {autocreate => 1 } );
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
