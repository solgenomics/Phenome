#!/usr/bin/env perl


=head1 NAME

 LoadPhenomeInStock.pm

=head1 SYNOPSIS

mx-run ThisPackageName [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

This is a patch for loading data in phenome.population and phenome.individual in the stock module, which will eventually replace these 2 tables.

This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>

=head1 AUTHOR

 Naama Menda<nm249@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package LoadPhenomeInStock;

use Try::Tiny;
use Moose;
extends 'CXGN::Metadata::Dbpatch';

use Bio::Chado::Schema;

use CXGN::Phenome::Population;
use CXGN::Phenome::Individual;
use CXGN::Chado::Dbxref;
use CXGN::People::Person;

sub init_patch {
    my $self=shift;
    my $name = __PACKAGE__;
    print "dbpatch name is : '" .  $name . "'\n\n";
    my $description = 'Loading the phenome individual data into the stock module';
    my @previous_requested_patches = ('CopyAccessionToStock', 'AddStockLinks'); #ADD HERE

    $self->name($name);
    $self->description($description);
    $self->prereq(\@previous_requested_patches);

}

sub patch {
    my $self=shift;

    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";

    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    my $schema = Bio::Chado::Schema->connect( sub { $self->dbh->clone } ,  { on_connect_do => ['SET search_path TO public;'], autocommit => 1 });

    my %names_hash = ( 'Tomato' => 'Solanum lycopersicum' ,
                       'Potato' => 'Solanum tuberosum',
                       'Eggplant' => 'Solanum melongena',
                       'Pepper' => 'Capsicum annuum',
                       'Coffee' => 'Coffea arabica',
                       'Petunia' => 'Petunia x hybrida',
        );
    my $coderef = sub {
	print "Finding/creating cvterm for population\n";
	my $population_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
	    { name   => 'population',
	      cv     => 'stock type',
	      db     => 'null',
	      dbxref => 'population',
	    });
	##
	print "Finding/creating cvterm for accession (individual)\n";
	my $accession_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
	    { name   => 'accession',
	      cv     => 'stock type',
	      db     => 'null',
	      dbxref => 'accession',
	    });
	print "Finding/creating cvtem for stock relationship 'is_member_of' \n";

	my $member_of = $schema->resultset("Cv::Cvterm")->create_with(
	    { name   => 'is_member_of',
	      cv     => 'stock relationship',
	      db     => 'null',
	      dbxref => 'is_member_of',
	    });
	#find the cvterm for sgn person_id
	my $person_id_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
	    { name   => 'sp_person_id',
	      cv     => 'local',
	      db     => 'null',
	      dbxref => 'autocreated:sp_person_id',
	    });
##
	#set the searchpath
	$self->dbh->do('set search_path to phenome, public');
	# first load the populations
	my $q = "SELECT population_id FROM phenome.population";
	my $sth = $self->dbh->prepare($q);
	$sth->execute();
	while (my $pop_id = $sth->fetchrow_array() ) {
            my $population = CXGN::Phenome::Population->new($self->dbh, $pop_id);
	    my $name = $population->get_name;
	    my $desc = $population->get_description;
	    my $sp_person_id = $population->get_sp_person_id;
	    my $create_date = $population->get_create_date;

	    my $organism = $schema->resultset("Organism::Organism")->find_or_create( {
		species => 'any' } );
	    my $organism_id = $organism->organism_id();
	    # background_accession_id
	    if ($population->get_background_accession_id) {
		my $aq = "SELECT chado_organism_id  FROM sgn.accession where accession_id = ? ";
		my $a_sth = $self->dbh->prepare($aq);
		$a_sth->execute($population->get_background_accession_id);
		($organism_id)  =  $a_sth->fetchrow_array() ;
	    }
	    #############
	    print "creating new stock for population $name\n";
	    my $stock_population = $schema->resultset("Stock::Stock")->find_or_create(
		{ organism_id => $organism_id,
		  name  => $name,
		  uniquename => $name,
		  description => $desc,
		  type_id => $population_cvterm->cvterm_id(),
		} );
            #now load the stock in the population table
            $population->set_stock_id($stock_population->stock_id);
            $population->store();
            ##
	    #store the properties for the population
	    $stock_population->create_stockprops({ sp_person_id => $sp_person_id},
						 { autocreate => 1 , cv_name => 'local'});
	    $stock_population->create_stockprops({ create_date => $create_date},
					     { autocreate => 1 , cv_name => 'local' });
	    print "Fetching population dbxrefs \n";
	    my @pop_dbxrefs = $population->get_all_population_dbxrefs;
	    foreach my $pdxref (@pop_dbxrefs) {
		my $pd = $population->get_population_dbxref($pdxref);
		my $dbxref_id = $pd->get_dbxref_id;
		my $d_person_id = $pd->get_sp_person_id;
		my $d_create_date = $pd->get_create_date;
		my $d_obsolete = $pd->get_obsolete;
		my $stock_dbxref = $stock_population->find_or_create_related('stock_dbxrefs', { dbxref_id => $dbxref_id, } );
		$stock_dbxref->create_stock_dbxrefprops( { sp_person_id => $d_person_id } , { autocreate => 1 , cv_name => 'local' } );
		$stock_dbxref->create_stock_dbxrefprops( { create_date => $d_create_date } , { autocreate => 1 , cv_name => 'local' } );
		$stock_dbxref->create_stock_dbxrefprops( { obsolete => $d_obsolete } , { autocreate => 1 , cv_name => 'local' } );
	    }

	    print "Loading individuals: \n";
	    my @individuals = $population->get_individuals();
	    foreach my $ind (@individuals) {
		my $iname = $ind->get_name;
		my $idesc = $ind->get_description;
		my $iperson_id = $ind->get_sp_person_id;
		my $icreate_date  = $ind->get_create_date;
		my $imodified_date  = $ind->get_modification_date;
		my $i_obsolete     = $ind->get_obsolete;
		my $updated_by   = $ind->get_updated_by;
		my $common_name = $ind->get_common_name;
		my $i_organism_id = $organism_id ;
                if ($common_name) {
                    print "Finding organism_id for common_name $common_name (" . $names_hash{$common_name} . ")\n"; 
                    ($i_organism_id) = $schema->resultset("Organism::Organism")->find( {
                        species => $names_hash{$common_name} } )->organism_id;
                }
                print "creating new stock for individual $iname\n";
                my $stock_individual = $schema->resultset("Stock::Stock")->find(
		    {  name  => $iname,
                       uniquename => $iname,
                       type_id => $accession_cvterm->cvterm_id(),
                    } );
                if ($stock_individual) {
                    print "stock exists! Updating description ... \n";
                    $stock_individual->description($idesc);
                    $stock_individual->update;
                } else {
                    $stock_individual = $schema->resultset("Stock::Stock")->create(
                        { organism_id => $i_organism_id,
                          name  => $iname,
                          uniquename => $iname,
                          description => $idesc,
                          type_id => $accession_cvterm->cvterm_id(),
                          is_obsolete => $i_obsolete,
                        } );
                
                #load the new stock_id in the individual table 
                $ind->set_stock_id( $stock_individual->stock_id );
                $ind->store();
                ##
		#load the population relationship
		$stock_population->find_or_create_related('stock_relationship_objects', {
		    type_id => $member_of->cvterm_id(),
		    subject_id => $stock_individual->stock_id(),
							  } );
		#load the stock properties
		print "loading stock properties\n";
		$stock_individual->create_stockprops({ sp_person_id => $iperson_id},
						     { autocreate => 1 , cv_name => 'local'});
		$stock_individual->create_stockprops({ create_date => $icreate_date},
						     { autocreate => 1, cv_name => 'local' }) if $icreate_date;
		$stock_individual->create_stockprops({ modified_date => $imodified_date},
						     { autocreate => 1 , cv_name => 'local'}) if $imodified_date;
		$stock_individual->create_stockprops({ common_name => $common_name},
						     { autocreate => 1 , cv_name => 'stock_property' , db_name => 'SGN' }) if $common_name;

		$stock_individual->create_stockprops({ updated_by => $updated_by},
						     { autocreate => 1 , cv_name => 'local'}) if $updated_by;

		#each individual has dbxrefs, alleles, images, phenotypes
		print "Storing stock_dbxrefs\n";
		my @i_dbxrefs = $ind->get_dbxrefs;
		foreach my $d (@i_dbxrefs) {
		    #store the  stock_dbxref
		    my $stock_dbxref = $stock_individual->find_or_create_related('stock_dbxrefs' , { dbxref_id => $d->get_dbxref_id, } );
		    #get the metadata from individual_dbxref
		    my $idx = $ind->get_individual_dbxref($d);
		    my $idx_person_id = $idx->get_sp_person_id;
		    my $idx_create = $idx->get_create_date;
		    my $idx_modified = $idx->get_modification_date;
		    my $idx_obsolete = $idx->get_obsolete;

		    #each dbxref may have individual_dbxref_evidence
		    #(in case of ontology annotations)
		    my @idxe = $idx->get_object_dbxref_evidence;
		    if (!@idxe) { # if this is not an ontology annotation
			#store the metadata in stock_dbxrefprop
			print "Storing stock_dbxrefprops\n";
			$stock_dbxref->create_stock_dbxrefprops( { sp_person_id => $idx_person_id},
								 { autocreate => 1 , cv_name => 'local'}) if $idx_person_id;
			$stock_dbxref->create_stock_dbxrefprops({ create_date => $idx_create},
								{ autocreate => 1, cv_name => 'local' }) if $idx_create;

			$stock_dbxref->create_stock_dbxrefprops({ modified_date => $idx_modified },
								{ autocreate => 1 , cv_name => 'local'}) if $idx_modified;
			$stock_dbxref->create_stock_dbxrefprops({ obsolete => '1'},
								{ autocreate => 1 , cv_name => 'local'}) if $idx_obsolete eq 't' ;
		    }
		    else { # evidence matadata overrides individual_dbxref metadata
			foreach my $ev (@idxe) {
			    print "Storing stock_dbxrefprops for ontology evidence codes \n";

			    my $e_person_id = $ev->get_sp_person_id || $idx_person_id;
			    $stock_dbxref->create_stock_dbxrefprops( { sp_person_id => $e_person_id},
								     { autocreate => 1 , cv_name => 'local'}) if $e_person_id;
			    my $e_create = $ev->get_create_date || $idx_create;
			    $stock_dbxref->create_stock_dbxrefprops({ create_date => $e_create},
								    { autocreate => 1, cv_name => 'local' }) if $e_create;
			    my $e_modified = $ev->get_modification_date || $idx_modified;
			    $stock_dbxref->create_stock_dbxrefprops({ modified_date => $e_modified },
								    { autocreate => 1 , cv_name => 'local'}) if $e_modified;
			    my $e_obsolete = $ev->get_obsolete;
			    $stock_dbxref->create_stock_dbxrefprops({ obsolete => '1'},
								    { autocreate => 1 , cv_name => 'local'}) if $e_obsolete eq 't';
			    my $e_rel = CXGN::Chado::Dbxref->new($self->dbh, $ev->get_relationship_type_id)->get_cvterm_name;
			    $stock_dbxref->create_stock_dbxrefprops({ $e_rel => '1'},
								    { cv_name => 'relationship'}) if $e_rel;
			    my $e_code = CXGN::Chado::Dbxref->new($self->dbh, $ev->get_evidence_code_id)->get_cvterm_name;
			    $stock_dbxref->create_stock_dbxrefprops({ $e_code => '1'},
								    { cv_name => 'evidence_code'}) if $e_code;
			    my $e_desc = CXGN::Chado::Dbxref->new($self->dbh, $ev->get_evidence_description_id)->get_cvterm_name;
			    $stock_dbxref->create_stock_dbxrefprops({ $e_desc => '1'},
								    { cv_name => 'evidence_code'}) if $e_desc;
			    my $e_with = CXGN::Chado::Dbxref->new($self->dbh, $ev->get_evidence_with)->get_dbxref_id;
			    $stock_dbxref->create_stock_dbxrefprops({ evidence_with => $e_with},
								    { autocreate =>1 , cv_name => 'local'}) if $e_with;
			    my $e_ref = CXGN::Chado::Dbxref->new($self->dbh, $ev->get_reference_id)->get_dbxref_id;
			    $stock_dbxref->create_stock_dbxrefprops({ reference => $e_ref},
								    { autocreate =>1 , cv_name => 'local'}) if $e_ref;
			}
		    }
		}
		#individual aliases
		my @synonyms = $ind->get_aliases;
		print "Storing synonyms\n";
		foreach my $s (@synonyms) {
		    $stock_individual->create_stockprops({ synonym => $s},
							 {autocreate => 1,
							  cv_name => 'null'
							 });
		}
		#########find linked alleles
		my @alleles = $ind->get_alleles;
		foreach my $a (@alleles) {
		    print "Adding allele ... \n";
		    my $a_id = $a->get_allele_id;
		    $stock_individual->create_stockprops({ 'sgn allele_id' => $a_id},
							 {autocreate => 1,
							  cv_name => 'local'
							 });
		}
		##find linked images
		my @images = $ind->get_image_ids;
		foreach my $i_id (@images) {
		    print "Adding image $i_id\n";
		    $stock_individual->create_stockprops({ 'sgn image_id' => $i_id},
							 {autocreate => 1,
							  cv_name => 'local'
							 });
		}
                }###########################################
		## find linked phenotypes
		#
		# create a new nd_experiment and store the phenotype in the natural div module
		if ($ind->has_phenotype) {
		    print "Found phenotypes! Storing in Natural Diversity module \n";
		    # get the project
		    my $project_name = $population->get_name;
		    my @pop_owners = $population->get_owners;
		    my $project_desc = 'Phenotypes recorded for population $project_name';
		    if ( defined($pop_owners[0]) ) {
			print "owner is " . $pop_owners[0] . "\n" ;
			my $owner = CXGN::People::Person->new($self->dbh, $pop_owners[0]);
			$project_desc .= 'by ' . $owner->get_first_name . ' ' . $owner->get_last_name ;
		    }
		    my $project = $schema->resultset("Project::Project")->find_or_create( {
			name => $project_name,
			description => $project_desc , } );
		    # get the geolocation
		    my $geo_description = 'unknown';
		    my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find_or_create( {
			description => $geo_description , } );

		    # find the cvterm for a phenotyping experiment
		    my $pheno_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
			{ name   => 'phenotyping experiment',
			  cv     => 'experiment type',
			  db     => 'null',
			  dbxref => 'phenotyping experiment',
			});
		    ###store a new nd_experiment. Each phenotyped population is going to get a new experiment_id
		    my $experiment = $schema->resultset('NaturalDiversity::NdExperiment')->create( {
			nd_geolocation_id => $geolocation->nd_geolocation_id(),
			type_id => $pheno_cvterm->cvterm_id(), } );

		    #link to the project
		    $experiment->find_or_create_related('nd_experiment_projects', {
			project_id => $project->project_id } );

		    #link to the stock
		    $experiment->find_or_create_related('nd_experiment_stocks' , {
			stock_id => $stock_individual->stock_id(),
			type_id  =>  $pheno_cvterm->cvterm_id(),
							});

		    my $pq = "SELECT sp_person_id, phenotype_id FROM public.phenotype WHERE individual_id = ?";
		    my $p_sth = $self->dbh->prepare($pq);
		    $p_sth->execute($ind->get_individual_id);
		    while ( my ($p_person_id, $phenotype_id ) = $p_sth->fetchrow_array ) {

			#create experimentprop for the person_id
			if ($p_person_id) {
			    $experiment->find_or_create_related('nd_experimentprops', {
				value => $p_person_id,
				type_id => $person_id_cvterm->cvterm_id,
								});
			}
			my ($phenotype) = $schema->resultset("Phenotype::Phenotype")->find( {
			    phenotype_id => $phenotype_id, });

			if ( $phenotype->find_related("nd_experiment_phenotypes", {} ) ) {
			    warn "This experiment has been stored before (phenotype_id = $phenotype_id) ! Skipping! \n";
			    next();
			}
			########################################################
			# link the phenotype with the experiment
			my $nd_experiment_phenotype = $experiment->find_or_create_related('nd_experiment_phenotypes', { phenotype_id => $phenotype_id } );
			print "Individual stock " . $stock_individual->name . " has phenotype " . $phenotype->uniquename . " linked to experiment " . $experiment->nd_experiment_id . "\n";
		    }
		}
		if ($ind->has_genotype) {
		    #store genotyping experiment
		    # get data from phenome.genotype and genotype_experiment
                    print "Found genotypes! Storing new experiment and linking to phenome.genotype_region\n";
		    # get the project
		    my $project_name = $population->get_name;
		    my @pop_owners = $population->get_owners;
		    my $project_desc = 'genotypes recorded for population $project_name';
		    if ( defined($pop_owners[0]) ) {
			print "owner is " . $pop_owners[0] . "\n" ;
			my $owner = CXGN::People::Person->new($self->dbh, $pop_owners[0]);
			$project_desc .= 'by ' . $owner->get_first_name . ' ' . $owner->get_last_name ;
		    }
		    my $project = $schema->resultset("Project::Project")->find_or_create( {
			name => $project_name,
			description => $project_desc , } );
		    # get the geolocation
		    my $geo_description = 'unknown';
		    my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find_or_create( {
			description => $geo_description , } );

		    # find the cvterm for a phenotyping experiment
		    my $geno_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
			{ name   => 'genotyping experiment',
			  cv     => 'experiment type',
			  db     => 'null',
			  dbxref => 'genotyping experiment',
			});
		    ###store a new nd_experiment. Each genotyped population is going to get a new experiment_id
		    my $experiment = $schema->resultset('NaturalDiversity::NdExperiment')->create( {
			nd_geolocation_id => $geolocation->nd_geolocation_id(),
			type_id => $geno_cvterm->cvterm_id(), } );

		    #link to the project
		    $experiment->find_or_create_related('nd_experiment_projects', {
			project_id => $project->project_id } );

		    #link to the stock
		    $experiment->find_or_create_related('nd_experiment_stocks' , {
			stock_id => $stock_individual->stock_id(),
			type_id  =>  $geno_cvterm->cvterm_id(),
							});
                    ##########################
#######################
                    $experiment->find_or_create_related('nd_experimentprops', {
                        value => $pop_owners[0],
                        type_id => $person_id_cvterm->cvterm_id,
                                                        }) if $pop_owners[0];
                    
                    ########################################################
			# link the genotype_region with the experiment
			my @genotypes = $ind->get_genotypes();
                        foreach my $g (@genotypes) {
                            my @regions = $g->get_genotype_regions;
                            foreach my $gr (@regions) {
                                my $gr_id = $gr->get_genotype_region_id;
                                $experiment->create_nd_experimentprops(
                                    { 'sgn genotype_region_id' => $gr_id },
                                    { autocreate => 1 , cv_name => 'local' } );
                                print "Individual stock " . $stock_individual->name . " has genotype region ($gr_id) linked to experiment " . $experiment->nd_experiment_id . "\n";
                            }
                        }
                }
            }
        }
        
	print "You're done!\n";
	if ($self->trial) {
	    print "Trail mode! Rolling back transaction\n\n";
	    $schema->txn_rollback
	}
	return 1;
    };

    try {
	$schema->txn_do($coderef);
	print "Data committed! \n";
    } catch {
	die "Load failed! " . $_ . "\n" ;
    };
}

return 1;
