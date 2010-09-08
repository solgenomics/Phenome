
=head1

load_solcap_data_entry.pl

=head1 SYNOPSIS

    $ThisScript.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name 
 -D  database name 
 -i infile 
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION

This is a script for loading solcap phenotypes, as scored in the field/lab -post harvest 

See the solCap template for the 'Data entry' spreadsheet for  more details 



=head2 AUTHOR

Naama Menda (nm249@cornell.edu)

August 2010
 
=cut


#!/usr/bin/perl
use strict;
use Getopt::Std; 
use CXGN::Tools::File::Spreadsheet;

use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Date::Calc qw(
		  Delta_Days
		  check_date
		  );
use Carp qw /croak/ ;



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

my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } ,  { on_connect_do => ['SET search_path TO  public;'] } );


#getting the last database ids for resetting at the end in case of rolling back
###############
my $last_nd_experiment_id = $schema->resultset('NaturalDiversity::NdExperiment')->get_column('nd_experiment_id')->max;
my $last_cvterm_id = $schema->resultset('Cv::Cvterm')->get_column('cvterm_id')->max;

my $last_nd_experiment_project_id = $schema->resultset('NaturalDiversity::NdExperimentProject')->get_column('nd_experiment_project_id')->max;
my $last_nd_experiment_stock_id = $schema->resultset('NaturalDiversity::NdExperimentStock')->get_column('nd_experiment_stock_id')->max;
my $last_nd_experiment_phenotype_id = $schema->resultset('NaturalDiversity::NdExperimentPhenotype')->get_column('nd_experiment_phenotype_id')->max;
my $last_phenotype_id = $schema->resultset('Phenotype::Phenotype')->get_column('phenotype_id')->max;

my %seq  = (
    'nd_experiment_nd_experiment_id_seq' => $last_nd_experiment_id,
    'cvterm_cvterm_id_seq' => $last_cvterm_id,
    'nd_experiment_project_nd_experiment_project_id_seq' => $last_nd_experiment_project_id,
    'nd_experiment_stock_nd_experiment_stock_id_seq' => $last_nd_experiment_stock_id,
    'nd_experiment_phenotype_nd_experiment_phenotype_id_seq' => $last_nd_experiment_phenotype_id,
    'phenotype_phenotype_id_seq' => $last_phenotype_id, 
    );

# get the project 
my $project_name = 'solcap vintage tomatoes 2009, Fremont, OH';
my $project = $schema->resultset("Project::Project")->find( {
    name => $project_name,
} );
# get the geolocation 
my $geo_description = 'OSU-OARDC Fremont, OH';
my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find( {
    description => $geo_description ,
} );

# find the cvterm for a phenotyping experiment
my $pheno_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
                         { name   => 'phenotyping experiment',
                           cv     => 'experiment type',
                           db     => 'null',
                           dbxref => 'phenotyping experiment',
                         });


#new spreadsheet, skip 3 first columns
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file, 3);
    
my $sp_person_id = undef; # who is the owner ? SolCap was loaded for the project. 

my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

eval {
	
    foreach my $sct (@rows ) { 
	my $plot = $spreadsheet->value_at($sct, "Plot Number");
	my $rep = $spreadsheet->value_at($sct, "Replicate Number");
	#find the stock for this plot # The sct# is the parent!!# 
	my ($parent_stock) = $schema->resultset("Stock::Stockprop")->find( {
	    value => $sct 
	    })->search_related('stock'); 
	my $stock = $schema->resultset("Stock::StockRelationship")->search( {
	    object_id => $parent_stock->stock_id() } )->search_related('subject');

	my $comment = $spreadsheet->value_at($sct, "Comment");
	
	my $prop_type = $schema->resultset("Cv::Cv")->find( {
	    'me.name' => 'project_property' } )->find_related('cvterms', {
		'me.name' => 'project transplanting date' } );
	my $tp_date = $project->find_related('projectprops' , {
	    type_id => $prop_type->cvterm_id() 
	    } )->value();
	my ($tp_year, $tp_month, $tp_day) = split /\// , $tp_date;

	COLUMN: foreach my $label (@columns) { 
	    my $value =  $spreadsheet->value_at($sct, $label);
	    
	    ($value, undef) = split (/\s/, $value) ;
	 
	    my ($db_name, $sp_accession) = split (/\:/ , $label);
	    next() if (!$sp_accession);
	   
	    if ($label =~ /SP:0000366/) {
		my ($m_year, $m_month, $m_day) = split /\//, $value ;
		
		next() if !( check_date($m_year,$m_month,$m_day) ) ; 
		$value  = Delta_Days($tp_year,$tp_month,$tp_day, $m_year,$m_month,$m_day); 
	    }
	    ######################
	    next() if !$value;
	    
	    my $parent_cvterm = $schema->resultset("General::Db")->find( {
		name => $db_name } )->find_related("dbxrefs", { 
		    accession=>$sp_accession , } )->find_related("cvterm" , {});
	    
            my $sp_term = $parent_cvterm;
            # if the value type is 'unit' we use the actual parent term for 
	    # the annotation. If it's a 'scale' we need to find out the appropriate
	    #child term, as stored in cvtermprop.
	    # cvtermprops need to be pre-loaded using load_scale_cvtermprops.pl
	    
	    ##my $unit_cvterm; # cvterm for the unit specified in the file 
	    ##if ($value_type eq 'scale') {
	    ##	my $cvterm_type = $schema->resultset("Cv::Cv")->find(
	    ##	    { name => 'breeders scale' } )->find_related(
	    ##	    'cvterms' , { name  => $unit_name} );   
	    ##	my $type_id = $cvterm_type->cvterm_id() if $cvterm_type || croak 'NO CVTERM FOUND FOR breeders_scale $unit_name! Cvterms for scales must be pre-loaded.  Cannot proceed';
	    
	    # find the mapped value for relevant sp terms 
	    # some values are used outside the definitions of trait scales
	    # For such cases I've mapped numeric values to the most relevant
	    # existing value from the pre-defined scale.
	    # this usually happens for logically contineuos scales (e.g. 1=very poor, 9 =excellent) thus the actual value used for scoring the phenotype is stored in the phenotype table for allowing more acurate quantitative analysis, 
	    # although these scores may be very subjective.
	    ##$value = $value_map{$term}{$value} if $value_map{$term};
	    
	    ##my ($cvtermprop)= $parent_cvterm->search_related("cvtermpath_objects")->search_related('subject')->search_related(
	    ##    "cvtermprops", { 'cvtermprops.type_id' => $type_id,
	    ##		     'cvtermprops.value' => $value , 
	    ##   } );
	    
	    ##print "parent term is " . $parent_cvterm->name() . "\n";
	    ##	print "Found cvtermprop " . $cvtermprop->get_column('value') . " for child cvterm '" . $cvtermprop->find_related("cvterm" , {} )->name() . "'\n\n" if $cvtermprop ; 
	    ##croak("NO cvtermprop found for term '$term' , value '$value'! Cannot proceed! Check your input!!") if !$cvtermprop;
	    ##$sp_term = $cvtermprop->cvterm() ;
	    ##} elsif ($value_type eq 'unit') {
	    ##	$unit = "unit: " . $unit_name ;
	    
	    ##($unit_cvterm) = $unit_cv->find_related("cvterms" , {
	    ##name => $unit_name } ) if $unit_cv ; 
	    ##
	    ##}

	    my ($pato_term) = $schema->resultset("General::Db")->find( {
		name => 'PATO' , } )->search_related
		    ("dbxrefs")->search_related
		    ("cvterm_dbxrefs", {
			cvterm_id => $sp_term->cvterm_id() , 
		    });
	    my $pato_id = undef;
	    $pato_id = $pato_term->cvterm_id() if $pato_term;
	    
	    #store the phenotype
	    my $phenotype = $sp_term->find_or_create_related("phenotype_observables", { 
		attr_id => $sp_term->cvterm_id(),
		value => $value ,
		cvalue_id => $pato_id,
		uniquename => "$project_name, Replicate: $rep, plot: $plot, Term: " . $sp_term->name() ,
	    });
	    
	    
	    #check if the phenotype is already associated with an experiment
	    # which means this loading script has been run before .
	    if ( $phenotype->find_related("nd_experiment_phenotypes", {} ) ) {
		warn "This experiment has been stored before! Skipping! \n";
		next();
	    }
	    print STDOUT "db_name = '$db_name' sp_accession = '$sp_accession'\n";
	    print "Value $value \n";
	    print "Stored phenotype " . $phenotype->phenotype_id() . " with attr " . $sp_term->name . " value = $value, cvalue = PATO " . $pato_id . "\n\n";
	    ########################################################
	    ###store a new nd_experiment. Each phenotype is going to get a new experiment_id
	    my $experiment = $schema->resultset('NaturalDiversity::NdExperiment')->create( {
		nd_geolocation_id => $geolocation->nd_geolocation_id(),
		type_id => $pheno_cvterm->cvterm_id(),
	    } );
	    
	    #link to the project
	    $experiment->find_or_create_related('nd_experiment_projects', {
		project_id => $project->project_id()
		} );
	    
	    #link to the stock
	    $experiment->find_or_create_related('nd_experiment_stocks' , {
		stock_id => $stock->stock_id(),
		type_id  =>  $pheno_cvterm->cvterm_id(),
	    });
	    
	    
	    # link the phenotype with the experiment
	    my $nd_experiment_phenotype = $experiment->find_or_create_related('nd_experiment_phenotype', { phenotype_id => $phenotype->phenotype_id() } );
	    
	    	    
	    # store the unit for the measurement (if exists) in phenotype_cvterm
	    #$phenotype->find_or_create_related("phenotype_cvterms" , {
	    #	cvterm_id => $unit_cvterm->cvterm_id() } ) if $unit_cvterm;
	    #print "Loaded phenotype_cvterm with cvterm '" . $unit_cvterm->name() . " '\n" if $unit_cvterm ; 
	}
    }
};



if ($@) { print "An error occured! Rolling backl!\n\n $@ \n\n "; }
elsif ($opt_t) {
    print "TEST RUN. Rolling back and reseting database sequences!!\n\n";
    foreach my $value ( keys %seq ) { 
	my $maxval= $seq{$value} || 0;
	if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
	else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
    $dbh->rollback;

}else {
    print "Transaction succeeded! Commiting phenotyping experiments! \n\n";
    $dbh->commit();
}
