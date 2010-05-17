
=head1

load_scale_cvtermprops.pl

=head1 SYNOPSIS

    $load_scale_cvtermpropr.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name 
 -D  database name 
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION

This is a script for loading scale values for SP cvterms. 
The terms in this scripts come from the potato cooperators guide.
Each term has a cvterm_id (must load first the cvterms from an obo file using gmod_load_cvterms.pl) and the values are stored as cvtermprops. 
Since potato (and other) breeders like to assign numeric scale to sets of values, these numbers are stored in the 'rank' field, and the values will be 'n:myValue' for allowing querying the props by rank and by name. Prop values are not stored in the SP ontology, but should be mapped whenever possible to PATO. 
Such terms will be used in Chado phenotype table in the 'cvalue' column.
This works mostly for colors and shape names. Other scales, usually describing logical rank (e.g. 1=poor to 9=excellent) will not have natural matching terms in PATO. Such terms will be used in cChado phenotype table in the 'value' column, and the actual text and/or numeric value will be stored, without a PATO id.


=head2 AUTHOR

Naama Menda (nm249@cornell.edu)

May 2010
 
=cut


#!/usr/bin/perl
use strict;
use Getopt::Std; 

use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;

our ($opt_H, $opt_D, $opt_t);

getopts('H:tD:');

my $dbhost = $opt_H;
my $dbname = $opt_D;


my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				      dbargs => {AutoCommit => 0,
						 RaiseError => 1}
				    }
    );
my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } );


#getting the last database ids for resetting at the end in case of rolling back
my $last_cvtermprop_id= $schema->resultset('Cv::Cvtermprop')->get_column('cvtermprop_id')->max; 


my %scale = 
    (
    'SP:0000186:NE1014 scale' => { #tuber texture NE1014
	'partial russet' => 1, 
	'heavy russet'   => 2, 
	'moderate russet'=> 3,
	'light russet'   => 4,
	'netted'         => 5,
	'slight net'     => 6,
	'moderately smooth'=> 7,
	'smooth'           => 8,
	'very smooth'      => 9,
    },
    'SP:0000225:NE1014 scale' => { #cross section
	'very flat' => 1, 
	'very flat to flat'=> 2, 
	'flat'=> 3,
	'flat to oval' => 4,
	'intermeidiate/oval' => 5,
	'oval to mostly round' => 6,
	'mostly round'=> 7,
	'round'           => 8,
	'very round'      => 9,
    },
    'SP:0000226:NE1014 scale' => { #skin set depth
	'very poor' => 1, 
	'very poor to poor' => 2, 
	'poor'=> 3,
	'poor to fair' => 4,
	'fair' => 5,
	'fair to good' => 6,
	'good'=> 7,
	'very good'  => 8,
	'excellent' => 9,
     },
      'SP:0000202:NE1014 scale' => { #tuber size
	'small' => 1, 
	'small to small-medium' => 2, 
	'small-medium'=> 3,
	'small-medium to medium' => 4,
	'medium' => 5,
	'medium to medium-large' => 6,
	'medium-large'=> 7,
	'medium-large to large'  => 8,
	'large' => 9,
     },
     'SP:0000212:NE1014 scale' => { #tuber appearance
	'very poor' => 1, 
	'very poor to poor' => 2, 
	'poor'=> 3,
	'poor to fair' => 4,
	'fair' => 5,
	'fair to good' => 6,
	'good'=> 7,
	'very good'  => 8,
	'excellent' => 9,
     },
     'SP:0000226:NE1014 scale' => { #skin set depth
	 'very poor' => 1, 
	 'very poor to poor' => 2, 
	 'poor'=> 3,
	 'poor to fair' => 4,
	 'fair' => 5,
	 'fair to good' => 6,
	 'good'=> 7,
	 'very good'  => 8,
	 'excellent' => 9,
     },
     'SP:0000227:NE1014 scale' => {#potato plant type
	 'decumbent-poor canopy'=>1,
	 'decumbent-fair canopy'=>2,
	 'decumbent-good canopy'=>3,
	 'spreading-poor canopy'=>4,
	 'spreading-fair canopy'=>5,
	 'spreading-good canopy'=>6,
	 'upright-poor canopy'=>7,
	 'upright-fair canopy'=>8,
	 'upright-good canopy'=>9,
     },
     'SP:0000231:NE1014 scale' => { # disease reaction NE1014
	 'dead' =>1,
	 'very severe'=>2,
	 'severe'=>3,
	 'severe to moderate'=>4,
	 'moderate'=>5,
	 'less than moderate'=>6,
	 'almost slight'=>7,
	 'slight'=>8,
	 'none'=>9,
     },
      'SP:0000206:NE1014 scale' => { # vine maturity NE1014
	 'very early' =>1,
	 'early'=>2,
	 'slightly early'=>3,
	 'slightly early to medium'=>4,
	 'medium'=>5,
	 'more than medium'=>6,
	 'slightly late'=>7,
	 'late'=>8,
	 'very late'=>9,
     },
     'SP:0000185:PVP scale' => { # skin color
	 'white' =>1,
	 'light yellow'=>2,
	 'yellow'=>3,
	 'buff'=>4,
	 'tan'=>5,
	 'brown'=>6,
	 'pink'=>7,
	 'red'=>8,
	 'purplish-red'=>9,
	 'purple'=>10,
	 'dark purple-black'=>11,
	 'other'=>12,
     },
     'SP:0000233:PVP scale' => { # tuber thickness
	 'round' =>1,
	 'medium thick'=>2,
	 'slightly flattened'=>3,
	 'flattened'=>4,
	 'other'=>5,
     },
     'SP:0000188:PVP scale' => { # flesh color
	 'white' =>1,
	 'light yellow'=>2,
	 'yellow'=>3,
	 'buff'=>4,
	 'tan'=>5,
	 'brown'=>6,
	 'pink'=>7,
	 'red'=>8,
	 'purplish-red'=>9,
	 'purple'=>10,
	 'dark purple-black'=>11,
	 'other'=>12,
     },
     'SP:0000191:PVP scale' => { # eye depth PVP
	 'protruding' =>1,
	 'protruding to shallow'=>2,
	 'shallow'=>3,
	 'shallow to intermediate'=>4,
	 'intermediate'=>5,
	 'intermediate to deep'=>6,
	 'deep'=>7,
	 'deep to very deep'=>8,
	 'very deep'=>9,
     },
     'SP:0000027:PVP scale'=> { # PVP disease reaction
	 'not tested'=>1,
	 'highly resistant' => 2,
	 'resistant few symptoms'=>3,
	 'resistance few lesions in number and size'=>4,
	 'moderately resistant' => 5,
	 'intermediate susceptible'=>6,
	 'moderate susceptible'=>7,
	 'susceptible'=>8,
	 'highly susceptible'=>9,
     },
     'SP:0000206:PVP scale' => { # PVP maturity
	 'very early (<100 DAP)'=>1,
	 'early (100-110 DAP)'=>2,
	 'mid-season (111-120 DAP)'=>3,
	 'late (121-130 DAP)'=>4,
	 'very late (>130 DAP)'=>5,
     },
     'SP:0000220:potato scale' => { #heat sprout rating
	 'none'=>1,
	 'swollen eyes'=>2,
	 'sprouts caliber 1/4"'=>3,
	 'sprouts caliber 1/2"'=>4,
	 'sprouts caliber. 1"'=>5,
	 'sprouts caliber 2"'=>6,
	 'sprouts caliber 3"'=>7,
	 'new top growth'=>8,
	 'chain tubers'=>9,
     },
     'SP:0000199:potato scale' => { # tuber skin pattern 
	 'eyes' =>1,
	 'eyebrows'=>2,
	 'splashed'=>3,
	 'scatterd'=>4,
	 'spectacled'=>5,
	 'stippled'=>6,
     },
     'SP:0000201:potato scale' => { #tuber shape
	 'compressed' =>1,
	 'round' =>2,
	 'oval' => 3, 
	 'oblong' => 4,
	 'long' =>5,
     },
     'SP:0000009:potato scale' => { #flower color
	 'red' => 'R',
	 'purple' => 'P',
	 'white' => 'W',
	 'blue' => 'B',
	 'no flowers'=>'NF',
	 'white dots'=>'#',
	 'white speckles'=>'@' ,
	 'white star pattern'=>'*',
	 'white tips'=>'^',
	 'very pronounced white tip'=>'V^',
	 'ruffled margins'=>'~',
     },
    );


eval {
    while ( my ($term, $values) = each %scale ) {
	my ($db, $accession, $prop_type) = split (/:/, $term); 
	my ($dbxref) = $schema->resultset("General::Db")->
	    search( { name => $db})->
	    search_related("dbxrefs", { accession=>$accession});
	if (!defined $dbxref) { croak "no dbxref found for accession $accession! \n" } ; 
	my ($cvterm) = $dbxref->
	    search_related("cvterm");
	
	while ( my ($value, $rank) = each %$values ) {
	   
	    my $value_name = $rank . ":" . $value;
	    #set rank to undef if it is not numeric 
	    $rank=undef unless $rank =~ m/\d+$/ ;
	    print "cvterm = " . $cvterm->name() . " prop=$value_name, rank=$rank, type=$prop_type\n";
	    my $new_prop= $cvterm->create_cvtermprops({$prop_type=>$value_name} , {autocreate=>1, rank=>$rank, allow_duplicate_values=>1});
	    while (my ($propname,$cvtermprop)  = each %$new_prop ) {
		print "stored new cvtermprop: $propname, " . $cvtermprop->value() . " rank = " . $cvtermprop->rank() . " (passed rank = '$rank')\n\n" ; 
	    }
	}
    }
};

if ($@) { print "An error occured! Rolling backl!\n\n $@ \n\n "; }
elsif ($opt_t) {
    print "TEST RUN. Rolling back and reseting database sequences!!\n\n";
    
    if ($last_cvtermprop_id) { $dbh->do("SELECT setval ('cvtermprop_cvtermprop_id_seq', $last_cvtermprop_id, true)"); }
    else { $dbh->do("SELECT setval ('cvtermprop_cvtermprop_id_seq', 1, false)"); }


}else {
    print "Transaction succeeded! Commiting cvtermprops! \n\n";
    $dbh->commit();
}
