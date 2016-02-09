
=head1

load_solcap_data_entry.pl

=head1 SYNOPSIS

    $ThisScript.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 -t  Test run . Rolling back at the end.

(geolocation  and project names  will be loaded from the metadata.txt file in the same directory. Must be the same file used with load_geolocation_project.pl)

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
use CXGN::People::Person;
use File::Basename;

use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Date::Calc qw(
		  Delta_Days
		  check_date
		  );
use Carp qw /croak/ ;
use Try::Tiny;

our ($opt_H, $opt_D, $opt_i, $opt_t);

getopts('H:i:tD:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $file = $opt_i;

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				      dbargs => {AutoCommit => 1,
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


#new spreadsheet, skip first column
my $gp_file = dirname($file) . "/metadata.txt";
my $gp = CXGN::Tools::File::Spreadsheet->new($gp_file, 1);
my @gp_row = $gp->row_labels();

# get the project
my $project_name = $gp->value_at($gp_row[0], "project_name");

my $project = $schema->resultset("Project::Project")->find( {
    name => $project_name,
} );
# get the geolocation
my $geo_description = $gp->value_at($gp_row[0], "geo_description");
my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find( {
    description => $geo_description ,
} );

# find the cvterm for a phenotyping experiment
my $pheno_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
                         { name   => 'phenotyping experiment',
                           cv     => 'experiment_type',
                           db     => 'null',
                           dbxref => 'phenotyping experiment',
                         });


my $username = 'solcap_project';
my $sp_person_id= CXGN::People::Person->get_person_by_username($dbh, $username);

die "User $username for Solcap must be pre-loaded in the database! \n" if !$sp_person_id ;

#find the cvterm for sgn person_id
my $person_id_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'sp_person_id',
      cv     => 'local',
      db     => 'null',
      dbxref => 'autocreated:sp_person_id',
    });

#new spreadsheet, skip 3 first columns
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file, 3);

# for this Unit Ontology has to be loaded!
my $unit_cv = $schema->resultset("Cv::Cv")->find(
    { name => 'unit.ontology' } );


my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

my $coderef = sub {
    foreach my $uniq_id (@rows ) {
	my $sct = $spreadsheet->value_at($uniq_id, "Line #");
        my $plot = $spreadsheet->value_at($uniq_id, "Plot Number");
	my $rep = $spreadsheet->value_at($uniq_id, "Replicate Number");
	#find the stock for this plot # The sct# is the parent!!#
	print "looking at sct# $sct \n";
        my ($parent_stock) = $schema->resultset("Cv::Cvterm")->search( {
	    'me.name' => 'solcap number' } )->search_related('stockprops', {
		value => $sct } )->search_related('stock');
        if (!$parent_stock) {
            warn "No stock found for sct# $sct. Check your database! \n" ;
            next()
        }
        #find the stock object
        my ($stock) = $schema->resultset("Stock::StockRelationship")->search( {
	    object_id => $parent_stock->stock_id() } )->search_related('subject', { name =>  $plot } );
        if (!$stock) {
	    warn "No stock found for plot $plot with parent " . $parent_stock->name . " Skipping!\n";
            next();
	}
	my $comment = $spreadsheet->value_at($uniq_id, "Comment");
	my $prop_type = $schema->resultset("Cv::Cv")->find( {
	    'me.name' => 'project_property' } )->find_related('cvterms', {
		'me.name' => 'project transplanting date' } );
	my $tp_date_prop = $project->find_related('projectprops' , {
	    type_id => $prop_type->cvterm_id() } );
        my $tp_date =  $tp_date_prop->value() if $tp_date_prop;
	my ($tp_year, $tp_month, $tp_day) = split /\// , $tp_date;

        ###store a new nd_experiment. One experiment per stock
        my $experiment = $schema->resultset('NaturalDiversity::NdExperiment')->create(
            {
                nd_geolocation_id => $geolocation->nd_geolocation_id(),
                type_id => $pheno_cvterm->cvterm_id(),
            } );
        #link to the project
        $experiment->find_or_create_related('nd_experiment_projects', {
            project_id => $project->project_id()
                                            } );
        #create experimentprop for the person_id
        if ($sp_person_id) {
            $experiment->find_or_create_related('nd_experimentprops', {
                value => $sp_person_id,
                type_id => $person_id_cvterm->cvterm_id,
                                                });
        }
        #link the experiment to the stock
        $experiment->find_or_create_related('nd_experiment_stocks' , {
            stock_id => $stock->stock_id(),
            type_id  =>  $pheno_cvterm->cvterm_id(),
                                            });

      COLUMN: foreach my $label (@columns) {
          my $value =  $spreadsheet->value_at($uniq_id, $label);
          ($value, undef) = split (/\s/, $value) ;

          #sp terms have a label to determine if these have a scale or a quantitative unit
          my ($term, $type) = split (/\|/ , $label) ;

          my ($db_name, $sp_accession) = split (/\:/ , $term);
          if (!$sp_accession) {
              print "NO sp_accession found for label $label!!\n";
              next;
          }
          if ( ($label =~ /SP:0000366/) || ($label =~ /SP:0000126/) )  {
              my ($m_year, $m_month, $m_day) = split /\//, $value ;
              next() if !( check_date($m_year,$m_month,$m_day) ) ;
              $value  = Delta_Days($tp_year,$tp_month,$tp_day, $m_year,$m_month,$m_day);
              print "Year = $m_year ($tp_year) , month = $m_month ($tp_month), day = $m_day ($tp_day), delta = $value!\n";
          }
          ######################
          next() if $value =~ /^\.$/; #skip NA values (label is '.')
          my ($value_type, $unit_name) = split (/\:/, $type) ;

          #SP id is the column header, and will be used as the parent term
          #in case of qualitative phenotypes which have a specific SP term 
          #(e.g. plant habit: determinate, indeterminate)
          my $parent_cvterm = $schema->resultset("General::Db")->find( {
              name => $db_name } )->find_related("dbxrefs", {
                  accession=>$sp_accession , } )->find_related("cvterm" , {});

          my $sp_term = $parent_cvterm;
          my $observable_term = $parent_cvterm;
          # if the type is a boolean then we store 0 or 1 as the phenotype value
          if ($value_type eq 'boolean') {
              $value = 'absent' if ( $value =~ /a/i || $value == 0 ) ;
              $value = 'present' if ( $value =~ /p/i || $value ==1 ) ;
          }
          my $unit_cvterm; # cvterm for the unit specified in the file

          #if the type is qualitative observation, we need to store the matching sp term
          # currently tomato solcap files have these qualitative terms:
          # inflorescence structure (simple/compound/intermediate)
          # growth type (determinate/indeterminate)
          my $child_term;
          if  ($label =~ /SP:0000128/) { #mapping of child term values for plant habit
              $value = 'determinate' if $value =~ /^d/i ;
              $value = 'indeterminate' if $value =~/^i/i ;
          }
          if ($value_type eq 'qual') {
              #SP:0000128|qual	SP:0000071|qual
              ($child_term)= $parent_cvterm->direct_children->search(  {
                  'lower(name)' =>  { like => lc($value) . '%' } } );
              if (!$child_term) {
                  warn("NO child term found for term '$term' , value '$value'! Cannot proceed! Check your input!!") ;
                  next LABEL;
              }
              ##load the parent term as observable_id, value is the actual value,
              ##and child term is loaded into phenotyep_cvterm
              #####################################################
              print "Found child term " . $child_term->name . "\n";
              $value = $child_term->name;
          } elsif ($value_type eq 'unit') { # unit:milimeter
              #remove trailing spaces
              $unit_name =~ s/^\s+//;
              $unit_name =~ s/\s+$//;
              ($unit_cvterm) = $unit_cv->find_related(
                  "cvterms" , { name => $unit_name } ) if $unit_cv ;
              #$observable_term = $sp_term;
          }
          my ($pato_term) = $schema->resultset("General::Db")->find( {
              name => 'PATO' , } )->search_related
                  ("dbxrefs")->search_related
                  ("cvterm_dbxrefs", {
                      cvterm_id => $sp_term->cvterm_id() ,
                   });
          my $pato_id = undef;
          $pato_id = $pato_term->cvterm_id() if $pato_term;

          #store the phenotype
          
          ##my $phenotype = $sp_term->find_or_create_related("phenotype_observables", {
           ##   attr_id => $sp_term->cvterm_id(),
            ##  value => $value ,
             ## cvalue_id => $pato_id,
              ##uniquename => "$project_name, Replicate: $rep, plot: $plot, Term: " . $sp_term->name() ,
               ##                                            });
          
          my $phenotype = $sp_term->find_or_create_related(
              "phenotype_cvalues", {
                    observable_id => $observable_term->cvterm_id, #sp_term
		    attr_id => $pato_id,
		    value => $value ,
                    uniquename => "Stock: " . $stock->stock_id . ", Replicate: $rep, plot: $plot," . ", Term: " . $sp_term->name() . ", parent:  $term",
              });
          #add phenotype prop for quality terms (yield, brix, ph, acids)
          if ($label =~ m/SP:0000198|SP:0000165|SP:0000170|SP:0000345/) {
              my $method = 'Quality';
              ##not sure if this should be phenotypeprop 
              $phenotype->create_phenotypeprops(
                  { method => $method } , { autocreate => 1 } ) ;
          }
          #for qualitative traits, store the value also in phenotyep_cvterm
          if ($child_term) {
              $phenotype->find_or_create_related(
                  "phenotype_cvterms" , {
                      cvterm_id => $child_term->cvterm_id,
                  } );
          }
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

          # link the phenotype with the experiment
          my $nd_experiment_phenotype = $experiment->find_or_create_related('nd_experiment_phenotypes', { phenotype_id => $phenotype->phenotype_id() } );

          # store the unit for the measurement (if exists) in phenotype_cvterm
          $phenotype->find_or_create_related("phenotype_cvterms" , {
              cvterm_id => $unit_cvterm->cvterm_id() } ) if $unit_cvterm;
          print "Loaded phenotype_cvterm with cvterm '" . $unit_cvterm->name() . " '\n" if $unit_cvterm ;
      }
    }
    if ($opt_t) {
        die "TEST RUN! rolling back\n";
    }
};


try {
    $schema->txn_do($coderef);
    if (!$opt_t) { print "Transaction succeeded! Commiting phenotyping experiments! \n\n"; }
} catch {
    # Transaction failed
    foreach my $value ( keys %seq ) {
        my $maxval= $seq{$value} || 0;
        if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
        else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
    die "An error occured! Rolling back  and reseting database sequences!" . $_ . "\n";
};
