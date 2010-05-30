
=head1

load_scale_cvtermprops.pl

=head1 SYNOPSIS

    $load_scale_cvtermpropr.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name 
 -D  database name 
 -i infile 
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION

This is a script for loading scale values for SP cvterms. 

The terms usually come from breeders scales  (like the potato cooperators guide).

Infile should be in the following format: 
column 1 : cvterm full id (SP:0000xxx)
column 2 : scale name (this is going to be the cvterm name for the prop type_id) 
column 3 :value ( an integer)

cv_name for scale cvtermprops defaults to 'breeders_scale' 


Each term has a cvterm_id (must load first the cvterms from an obo file using gmod_load_cvterms.pl) and the values are stored as cvtermprops. 
Since potato (and other) breeders like to assign numeric scale to sets of values, these numbers are stored in the 'rank' field, and the values will be the vaalues too. If the value is not numeric, the rank will be automatically incremented, starting from '0'.  Prop values are mapped whenever possible to the SP ontology, and should be mapped whenever possible to PATO. 
Such terms will be used in Chado phenotype table in the 'cvalue' column.
This works mostly for colors and shape names. Other scales, usually describing logical rank (e.g. 1=poor to 9=excellent) will not have natural matching terms in PATO. Such terms will be used in Chado phenotype table in the 'value' column, and the actual text and/or numeric value will be stored, without a PATO id.


=head2 AUTHOR

Naama Menda (nm249@cornell.edu)

May 2010
 
=cut


#!/usr/bin/perl
use strict;
use Getopt::Std; 
use CXGN::Tools::File::Spreadsheet;

use CXGN::Phenome::Schema;
use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;

use CXGN::Phenome::Population;
use CXGN::Phenome::Individual;
use CXGN::Chado::Dbxref;
use CXGN::Chado::Phenotype;

my %value_map = (
 
    'SP:0000009' => { # flower color
      L => 'light',
      M => 'medium',
      R => 'red',
      P => 'purple',
      W => 'white',
      B => 'blue',
      '^' => 'white flower tips',
      '*' => 'white star pattern',
      '#' => 'white dots',
      '@' => 'white speckles',
      '~' => 'ruffled margins',
    },
    );    

our ($opt_H, $opt_D, $opt_i, $opt_t);

getopts('H:i:tD:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $file = $opt_i;

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				      dbargs => {AutoCommit => 0,
						 RaiseError => 1}
				    }
    );
my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } );
my $phenome_schema= CXGN::Phenome::Schema->connect( sub { $dbh->get_actual_dbh() } );


#getting the last database ids for resetting at the end in case of rolling back
my $last_cvtermprop_id= $schema->resultset('Cv::Cvtermprop')->get_column('cvtermprop_id')->max; 


##open (my $FH, $file) || die "can't open file $file for reading!!" ; 

#new spreadsheet, skip 2 first columns
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file, 2);
    
# sp_term scale_name value name_string
my $scale_cv_name= "breeders scale";

# population for the potato accessions 

my $population_name = 'Potato accessions';
my $common_name= 'Potato';

my $common_name_id = 2; # find by name = potato !
my $sp_person_id = undef; # who is the owner ? 


#my $population = $phenome_schema->resultset("Population")->find_or_create( 
 #   {
#	name => $population_name,
#	common_name_id => $common_name_id,
#    });
my $population = CXGN::Phenome::Population->new_with_name($dbh, $population_name);

if ($population->get_common_name() ne $common_name) {
	$population->set_common_name_id($common_name_id);
	$population->set_name($population_name);
	$population->set_sp_person_id($sp_person_id);
	$population->store();
}
# for stock :
# my $population = $schema->resultset("Stock::Stock")->find_or_create(
#    { organism_id => $potato_organism_id,
#      name  => $population_name,
#      uniquename => $population_name,
#      type_id => $population_cvterm_id,
#    } );

# for this Unit Ontology has to be loaded! 
my $unit_cv = $schema->resultset("Cv::Cv")->find(
    { name => 'unit.ontology' } );

my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

eval {
	
    my $date;
    
    foreach my $accession (@rows ) { 
	my $date_count = 0;
	my ($acc, $rep) = split (/\|/ , $accession);
	print "accession = $accession, acc= $acc, rep= $rep!\n\n";

	my $plot = $spreadsheet->value_at($accession, "Plot Number");
        #my $individual = $phenome_schema->resultset("Individual")->find_or_create(
	#    { population_id => $population->get_population_id(),
	#      name => $acc,
	#      common_name_id => $common_name_id,
	#      sp_person_id => $sp_person_id,
	#    } );
	my @individuals= CXGN::Phenome::Individual->new_with_name($dbh, $acc, $population->get_population_id() );
	print "*******new_with_name $acc, pop_id = " . $population->get_population_id() . "\n";
	my $individual= $individuals[0] if @individuals;
	print "found " . scalar(@individuals) . " individuals \n";
	if (!@individuals) {
	    print "instanciating new individual!!!!\n";
	    $individual= CXGN::Phenome::Individual->new($dbh);
	    $individual->set_name($acc);
	    $individual->set_population_id($population->get_population_id()); 
	    $individual->set_sp_person_id($sp_person_id); 
	    $individual->set_common_name_id($common_name_id);
	    $individual->store();
	}
	foreach my $label (@columns) { 
	    my $value =  $spreadsheet->value_at($accession, $label);
	    $value =~ s/(\d+\.?\d+?)\D+//g;
	    #print "Value $value \n";
	    next() if $value !~ /^\d/;
	   
	    $date = $spreadsheet->value_at($accession, 'date') unless $date_count;
	    
	    if ($label =~ /date\d/) {
		$date_count++;
		print "***Changing date $date \n\n ";
		$date = $spreadsheet->value_at($accession, "date" . $date_count);
	    }
	   
	    #individual needs to be a new stock and stock_relationship for 
	    #associating with the population stock_id
	    
	    
	    my ($term, $type) = split (/\|/ , $label) ;
	    
	    #db_name = SP , accession = 0000NNN 
	    my ($db_name, $sp_accession) = split (/\:/ , $term);
	    #print STDERR "db_name = '$db_name' sp_accession = '$sp_accession'\n";
	    next() if (!$sp_accession);

	    ####################
	    next() if ($sp_accession eq '0000201'); # 1-9 values in Yencho data file 
	   ## next() if ($sp_accession eq '0000212');  ## Yencho - check data
	    next() if ($sp_accession eq '0000191'); # 1-5 values in Yencho data file .
	    
	    ######################


            #value type should be 'scale' or 'unit'
	    #unit_name should be the scale name or unit name 
	    my ($value_type, $unit_name) = split (/\:/, $type) ; 
	    my $unit = undef;

	    my $parent_cvterm = $schema->resultset("General::Db")->find(
		{ name => $db_name } )->find_related(
		"dbxrefs", { accession=>$sp_accession , } )->find_related("cvterm" , {});
	    
            # if the value type is 'unit' we use the actual parent term for 
	    # the annotation. If it's a 'scale' we need to find out the appropriate
	    #child term, as stored in cvtermprop.
	    # cvtermprops need to be pre-loaded using load_scale_cvtermprops.pl
	    my $sp_term = $parent_cvterm;
	    my $unit_cvterm; # cvterm for the unit specified in the file 
	    if ($value_type eq 'scale') {
		my $cvterm_type = $schema->resultset("Cv::Cv")->find(
		    { name => 'breeders scale' } )->find_related(
		    'cvterms' , { name  => $unit_name} );   
		my $type_id = $cvterm_type->cvterm_id() if $cvterm_type || croak 'NO CVTERM FOUND FOR breeders_scale $unit_name! Cvterms for scales must be pre-loaded.  Cannot proceed';
		##print STDERR "type_id = $type_id for scale $unit_name! \n";
		
                # find the mapped value for relevant sp terms 
		# some values are used outside the definitions of trait scales
		# For such cases I've mapped numeric values to the most relevant
		# existing value from the pre-defined scale.
		# this usually happens for logically contineuos scales (e.g. 1=very poor, 9 =excellent) thus the actual value used for scoring the phenotype is stored in the phenotype table for allowing more acurate quantitative analysis, 
		# although these scores may be very subjective.
		$value = $value_map{$term}{$value} if $value_map{$term};
		
		my ($cvtermprop)= $parent_cvterm->search_related("cvtermpath_objects")->search_related('subject')->search_related(
		    "cvtermprops", { 'cvtermprops.type_id' => $type_id,
				     'cvtermprops.value' => $value , 
		    } );
		
		print "parent term is " . $parent_cvterm->name() . "\n";
		print "Found cvtermprop " . $cvtermprop->get_column('value') . " for child cvterm '" . $cvtermprop->find_related("cvterm" , {} )->name() . "'\n\n" if $cvtermprop ; 
		croak("NO cvtermprop found for term '$term' , value '$value'! Cannot proceed! Check your input!!") if !$cvtermprop;
		$sp_term = $cvtermprop->cvterm() ;
	    } elsif ($value_type eq 'unit') {
		$unit = "unit: " . $unit_name ;
		
		($unit_cvterm) = $unit_cv->find_related("cvterms" , {
		    name => $unit_name } ) if $unit_cv ; 
		
	    }
	    my ($pato_term) = $schema->resultset("General::Db")->find( 
		{ name => 'PATO' , } )->search_related
		("dbxrefs")->search_related
		("cvterm_dbxrefs", {
		    cvterm_id => $sp_term->cvterm_id() , 
		 });
	    my $pato_id = undef;
	    $pato_id = $pato_term->cvterm_id() if $pato_term;
	    
	    ##this is a phenotype. Do not store this as dbxref, 
	    ##since it is not an annotation.
 
	    #my $dbxref = CXGN::Chado::Dbxref->new($dbh, $sp_term->dbxref_id());
	    #my $i_dbxref = $individual->add_individual_dbxref($dbxref, undef, $sp_person_id);
	    #$individual->find_or_create_related("IndividualDbxref" , {
	    #	dbxref_id => $sp_term->dbxref_id(),
	    #	sp_person_id => $sp_person_id,
	    #	create_date => $date , } );
	    #print "Adding dbxref id " . $dbxref->get_dbxref_id() . " to individual " . $individual->get_individual_id() . " ($acc) \n";  
	    

	    my $phenotype = $parent_cvterm->find_or_create_related(
		"phenotype_observables", { 
		    attr_id => $sp_term->cvterm_id(),
		    value => $value ,
		    cvalue_id => $pato_id,
		    uniquename => "Replicate: $rep, plot: $plot, individual_id: "  . $individual->get_individual_id  . ", Term: " . $sp_term->name() . ", parent:  $term",
                    #this needs to be moved to individual_phenotype
		    # and eventually to nd_assay_phenotype
		    # individual_id => $individual->get_individual_id(),
		    # sp_person_id => $sp_person_id,
		});
	    print "Stored phenotype " . $phenotype->phenotype_id() . " with attr " . $sp_term->name . " value = $value, cvalue = PATO " . $pato_id . "\n\n";
	    my $p = CXGN::Chado::Phenotype->new($dbh, $phenotype->phenotype_id() );
	    $p->set_individual_id($individual->get_individual_id() );
	    $p->set_sp_person_id($sp_person_id);
	    $p->store();
	    print "Updated individual_id " . $individual->get_individual_id() . " for phenotype " . $p->get_phenotype_id . " . Date is $date\n";
	    
	    # store the unit for the measurement (if exists) in phenotype_cvterm
	    $phenotype->find_or_create_related("phenotype_cvterms" , {
		cvterm_id => $unit_cvterm->cvterm_id() } ) if $unit_cvterm;
	    print "Loaded phenotype_cvterm with cvterm '" . $unit_cvterm->name() . " '\n" if $unit_cvterm ; 
	}
    }
};


#accession= Premier Russet, cloumn = SP:0000201|scale:NE1014, value = 4


if ($@) { print "An error occured! Rolling backl!\n\n $@ \n\n "; }
elsif ($opt_t) {
    print "TEST RUN. Rolling back and reseting database sequences!!\n\n";
    
    if ($last_cvtermprop_id) { $dbh->do("SELECT setval ('cvtermprop_cvtermprop_id_seq', $last_cvtermprop_id, true)"); }
    else { $dbh->do("SELECT setval ('cvtermprop_cvtermprop_id_seq', 1, false)"); }
    
    
}else {
    print "Transaction succeeded! Commiting cvtermprops! \n\n";
    $dbh->commit();
}
