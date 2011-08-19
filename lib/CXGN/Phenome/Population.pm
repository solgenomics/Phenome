
=head1 NAME

CXGN::Phenome::Population - a class that deals with populations, 
such as mapping populations, mutant populations, 
inbred lines etc in the SGN database.

=head1 DESCRIPTION

This class inherits from CXGN::DB::ModifiableI and can therefore be
used to implement user-modifiable pages easily. It also inherits (wow,
multiple inheritance) from CXGN::Phenome::Main, which handles the
database connection.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu), Isaak Tecle (iyt2@cornell.edu), Naama Menda<nm249@cornell.edu>

=head1 FUNCTIONS

This class implements the following functions:

=cut

package CXGN::Phenome::Population;

use strict;
use CXGN::DB::Connection;
use CXGN::People::Person;
use CXGN::Chado::Cvterm;
use CXGN::Phenome::UserTrait;
use CXGN::Phenome::PopulationDbxref;
use List::Compare;
use Cache::File;
use File::Path qw / mkpath /;

use base qw / CXGN::DB::ModifiableI  /;


=head2 function new

  Synopsis:	my $p = CXGN::Phenome::Population->new($dbh, $population_id)
  Arguments:	a database handle and a population id
  Returns:	a population object
  Side effects:	if $population_id is omitted, an empty project is created. 
                if an illegal $population_id is supplied, undef is returned.
  Description:	

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $population_id = shift;

    my $self=$class->SUPER::new($dbh);

    if ($population_id) { 
	$self->set_population_id($population_id);
	$population_id = $self->fetch();
	#if (!$population_id) { return undef; }
    }
    return $self;

}

=head2 function new_with_name

  Synopsis:	my $population = CXGN::Phenome::Population->new_with_name($dbh, $population_name)
  Arguments:	a database handle and a population name
  Returns:	a population object
  Side effects:	if a non - existing  $population_name is supplied, undef is returned.
  Description:

=cut

sub new_with_name {
    my $self = shift;
    my $dbh=shift;
    my $name=shift;
    my $population=undef;
    my $query = "SELECT population_id FROM phenome.population WHERE name ilike ?";
    my $sth=$dbh->prepare($query);
    $sth->execute($name);
    my ($pop_id) = $sth->fetchrow_array;
    $population= $self->new($dbh,$pop_id); 
    return $population;
}

=head2 new_with_stock_id

 Usage: CXGN::Phenome::Population->new_with_stock_id($dbh, $stock_id)
 Desc:  get a population object with the stock id. There is now 1-1 mapping between populations and stocks. This function is used for bridging existing code that needs refactoring. The population table is now deprecated, and stock should be used instead.
 Ret:   new CXGN::Phenome::Population object
 Args:  dbh, stock_id
 Side Effects:
 Example:

=cut

sub new_with_stock_id {
    my ($self, $dbh, $stock_id) = @_;
    my $q = "SELECT population_id FROM phenome.population WHERE stock_id = ? ";
    my $sth = $dbh->prepare($q);
    $sth->execute($stock_id);
    my ($population_id) = $sth->fetchrow_array;
    return $self->new($dbh , $population_id);
}


sub fetch {
    my $self= shift;
    my $query = "SELECT population_id, population.name, description,
                        background_accession_id, population.sp_person_id,
                        population.create_date, population.modified_date, population.obsolete,
                        cross_type_id, female_parent_id, male_parent_id, recurrent_parent_id,
                        donor_parent_id, comment, web_uploaded,
                        population.common_name_id, sgn.common_name.common_name, population.stock_id
                  FROM phenome.population 
                  LEFT JOIN sgn.accession ON (population.background_accession_id = sgn.accession.accession_id)
                  LEFT JOIN sgn.common_name ON (population.common_name_id = common_name.common_name_id)
                  WHERE population_id=? and population.obsolete='f'";

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_population_id());

    my ($population_id, $name, $description, $background_accession_id, 
	$sp_person_id, $create_date, $modified_date, $obsolete, $cross_type_id,
	$female_parent_id, $male_parent_id, $recurrent_parent_id, 
	$donor_parent_id, $comment, $web_uploaded, $common_name_id, $common_name, $stock_id) = $sth->fetchrow_array();

    $self->set_population_id($population_id);
    $self->set_name($name);
    $self->set_description($description);
    $self->set_background_accession_id($background_accession_id);
    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
    $self->set_obsolete($obsolete);
    $self->set_cross_type_id($cross_type_id);
    $self->set_female_parent_id($female_parent_id);
    $self->set_male_parent_id($male_parent_id);
    $self->set_recurrent_parent_id($recurrent_parent_id);
    $self->set_donor_parent_id($donor_parent_id);
    $self->set_comment($comment);
    $self->set_web_uploaded($web_uploaded);
    $self->set_common_name_id($common_name_id);
    $self->set_common_name($common_name);
    $self->set_stock_id($stock_id);
    return $population_id;
}

=head2 function store

  Synopsis: $self->store()
  Arguments:	none
  Returns:	database id
  Side effects:	Update an existing population
  Description

=cut

sub store {
    my $self = shift;
    my $population_id = $self->get_population_id();
    if ($population_id) {
	my $query = "UPDATE phenome.population SET
                       name = ?,
                       description = ?,
                       background_accession_id=?,
                       sp_person_id=?,
                       modified_date = now(),
                       cross_type_id = ?,
                       female_parent_id = ?,
                       male_parent_id = ?,
                       recurrent_parent_id = ?,
                       donor_parent_id = ?, 
                       comment = ?,
                       web_uploaded = ?,
                       common_name_id = ?,
                       stock_id = ?
                     WHERE
                       population_id = ?
                     ";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_name(),
		      $self->get_description(),
		      $self->get_background_accession_id(),
		      $self->get_sp_person_id(),
		      $self->get_cross_type_id(),
		      $self->get_female_parent_id(),
		      $self->get_male_parent_id(),
		      $self->get_recurrent_parent_id(),
		      $self->get_donor_parent_id(),
		      $self->get_comment(),
		      $self->get_web_uploaded(),
                      $self->get_common_name_id(),
                      $self->get_stock_id(),
                      $self->get_population_id()
	             );
    }
    else {
	my $query = "INSERT INTO phenome.population
                      (name, description, background_accession_id,
                       sp_person_id, modified_date, cross_type_id, female_parent_id, male_parent_id, recurrent_parent_id, donor_parent_id, comment, web_uploaded, common_name_id, stock_id)
                     VALUES
                      (?, ?, ?, ?, now(), ?, ?, ?, ?, ?, ?,?, ?, ?)
                      RETURNING population_id";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_name(),
		      $self->get_description(),
		      $self->get_background_accession_id(),
                      $self->get_sp_person_id(),
		      $self->get_cross_type_id(),
		      $self->get_female_parent_id(),
		      $self->get_male_parent_id(),
		      $self->get_recurrent_parent_id(),
		      $self->get_donor_parent_id(),
		      $self->get_comment(),
		      $self->get_web_uploaded(),
		      $self->get_common_name_id,
                      $self->get_stock_id
	    );
        ($population_id) = $sth->fetchrow_array();
        $self->set_population_id($population_id);
    }
    return $population_id;
}


=head2 get_all_populations

 Usage:        my $names_ref = CXGN::Phenome::Population::get_all_populations($dbh);
 Desc:         This is a static function. Selects the distinct population names and their IDs from phenome.population.
               Useful for populating a unique drop-down menu with only the population names that exist in the table.
 Ret:          Returns a 2D arrayrefs with all the
               population names  and their corresponding database ids
 Args:         a database handle
 Side Effects: none
 Example:

=cut

sub get_all_populations {
    my $dbh= shift;
    my $query = "SELECT distinct(name), population_id FROM phenome.population 
                    WHERE obsolete = 'f'";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @aoa = ();
    while (my($name, $id) = $sth->fetchrow_array()) { 
	push @aoa, [$id, $name];
    }
    return \@aoa;
}




=head2 function get_individuals

  Synopsis:  $self->get_individuals()
  Arguments: none
  Returns:	a list of individual objects
  Side effects:	none
  Description:	Finds all individuals of this population

=cut

sub get_individuals {
    my $self = shift;
    
    my $query = "SELECT individual_id FROM phenome.individual WHERE population_id=? ORDER BY individual_id";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_population_id());
    my $individual;
    my @individuals =();
    while (my ($individual_id) = $sth->fetchrow_array()) { 
	$individual = CXGN::Phenome::Individual->new($self->get_dbh(), $individual_id);
	push @individuals, $individual;
    }
    return @individuals;
}

=head2 function get_all_individual_ids

  Synopsis:	$self->get_all_individual_ids()
  Arguments:	none 
  Returns:	arrayref
  Side effects:	none
  Description:  Get a list of individual ids from this population	

=cut

sub get_all_individual_ids {
    my $self = shift;
    
    my $query = "SELECT individual_id FROM phenome.individual WHERE population_id=? ORDER BY individual_id";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_population_id());
    my @individual_ids =();
    while (my ($individual_id) = $sth->fetchrow_array()) { 
	push @individual_ids, $individual_id;
    }
    return \@individual_ids;
}


=head2 accessors available in this class (get/set_accessor_name(
    
    population_id
    name
    description
    background_accession_id

=cut

sub get_population_id { 
    my $self=shift;
    return $self->{population_id};
}

sub set_population_id { 
    my $self=shift;
    $self->{population_id}=shift;
}

sub get_name { 
    my $self=shift;
    return $self->{name};
}

sub set_name { 
    my $self=shift;
    $self->{name}=shift;
}

sub get_description { 
    my $self=shift;
    return $self->{description};
}

sub set_description { 
    my $self=shift;
    $self->{description}=shift;
}

sub get_background_accession_id { 
    my $self=shift;
    return $self->{background_accession_id};
}


sub set_background_accession_id { 
    my $self=shift;
    $self->{background_accession_id}=shift;
}


=head2 get/set_sp_person_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_sp_person_id {
  my $self=shift;
  return $self->{sp_person_id};

}

sub set_sp_person_id {
  my $self=shift;
  $self->{sp_person_id}=shift;
}
 



=head2 get/set_common_name_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_common_name_id {
  my $self=shift;
  $self->{common_name_id}=shift;
}

sub get_common_name_id {
  my $self=shift;
  return $self->{common_name_id};

}

=head2 set_common_name, get_common_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_common_name {
  my $self=shift;
  $self->{common_name}=shift;
}

sub get_common_name {
  my $self=shift;
  return $self->{common_name};
}




=head2 function set_female_parent_id, get_female_parent_id

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_female_parent_id { 
    my $self=shift;
    return $self->{female_parent_id};
}



sub set_female_parent_id { 
    my $self=shift;
    $self->{female_parent_id}=shift;
}


=head2 function set_male_parent_id, get_male_parent_id

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_male_parent_id { 
    my $self=shift;
    return $self->{male_parent_id};
}



sub set_male_parent_id { 
    my $self=shift;
    $self->{male_parent_id}=shift;
}

=head2 function set_recurrent_parent_id, get_recurrent_parent_id

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_recurrent_parent_id { 
    my $self=shift;
    return $self->{recurrent_parent_id};
}



sub set_recurrent_parent_id { 
    my $self=shift;
    $self->{recurrent_parent_id}=shift;
}

=head2 function set_donor_parent_id, get_donor_parent_id

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_donor_parent_id { 
    my $self=shift;
    return $self->{donor_parent_id};
}



sub set_donor_parent_id { 
    my $self=shift;
    $self->{donor_parent_id}=shift;
}

=head2 function set_cross_type_id, get_cross_type_id

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_cross_type_id { 
    my $self=shift;
    return $self->{cross_type_id};
}



sub set_cross_type_id { 
    my $self=shift;
    $self->{cross_type_id}=shift;
}

=head2 function set_comment, get_comment

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_comment { 
    my $self=shift;
    return $self->{comment};
}



sub set_comment { 
    my $self=shift;
    $self->{comment}=shift;
}

=head2 function set_comment, get_comment

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_web_uploaded { 
    my $self=shift;
    return $self->{web_uploaded};
}



sub set_web_uploaded { 
    my $self=shift;
    $self->{web_uploaded}=shift;
}


=head2 accessors get_stock_id, set_stock_id

 Usage: $self->get/set_stock_id
 Desc:  accessor for the FK to the chado stock table
 Property
 Side Effects:
 Example:

=cut

sub get_stock_id {
  my $self = shift;
  return $self->{stock_id};
}

sub set_stock_id {
  my $self = shift;
  $self->{stock_id} = shift;
}


=head2 get_owners

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_owners {
    my $self=shift;
    my $query = "SELECT sp_person_id FROM phenome.population
                 WHERE population_id = ? AND obsolete = 'f'";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_population_id());
    my $person;
    my @owners = ();
    while (my ($sp_person_id) = $sth->fetchrow_array()) { 
        $person = CXGN::People::Person->new($self->get_dbh(), $sp_person_id);
	push @owners, $sp_person_id;
    }
    return @owners;
}


=head2 get_pop_data_summary

 Usage: my ($min, $max, $avg, $std, $count) =$pop->get_pop_data_summary($cvterm_id)
 Desc:  returns the minimum, maximum, average, and standard deviation values of phenotype data for a cvterm and number of individuals phenotyped for  a cvterm in a population
 Ret:   $min (| 0.0) , $max ( | 0.0) , $avg, $std, $count
 Args:   cvterm id
 Side Effects: accesses database
 Example:

=cut

sub get_pop_data_summary {
    my $self=shift;
    my $term_id=shift;
    my $population_id=$self->get_population_id();
    my ($table, $table_id);
    if ($self->get_web_uploaded()) {
	$table = 'phenome.user_trait';
	$table_id = 'user_trait.user_trait_id';
	
    } else {
	$table = 'public.cvterm';
	$table_id = 'cvterm.cvterm_id';
    }
    #print STDERR "table: $table\n Table id: $table_id\n";	

    my $query = "SELECT  MIN(cast(value as numeric)), MAX(cast(value as numeric)), 
                         ROUND(AVG(cast(value as numeric)), 2), ROUND(STDDEV(cast(value as numeric)), 2), 
                         count(distinct individual_id)
                            FROM public.phenotype 
                            LEFT JOIN phenome.individual USING (individual_id)              
                            LEFT JOIN $table  ON (phenotype.observable_id = $table_id)  
                            WHERE individual.population_id =? AND $table_id =? AND cast(value as numeric) is not null
                            GROUP BY population_id";
    my $sth = $self->get_dbh()->prepare($query);
    
    $sth->execute($population_id, $term_id);
   
    my ($min, $max, $ave, $std, $count) =$sth->fetchrow_array() ;
    
    if ($min == 0) {$min = '0.0';}
    if ($max == 0) {$min = '0.0';}
    
    return $min,  $max, $ave, $std, $count;
}


=head2 get_cvterms

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_cvterms {
    my $self=shift;
    my $population_id= $self->get_population_id();
    
    my ($table, $table_id, $object, $name);
    if ($self->get_web_uploaded()) {
	$table = 'phenome.user_trait';
	$table_id = 'user_trait.user_trait_id';
	$object = 'CXGN::Phenome::UserTrait';
	$name = 'user_trait.name';
    } else {
	$table = 'public.cvterm';
	$table_id = 'cvterm.cvterm_id';
	$object = 'CXGN::Chado::Cvterm';
	$name  = 'cvterm.name';
    }
    
    #print STDERR "table: $table\n Table id: $table_id\n object: $object\n name: $name\n";
	my $query = "SELECT distinct(observable_id), $name 
                        FROM public.phenotype 
                       JOIN phenome.individual USING (individual_id) 
                       JOIN phenome.population using (population_id) 
                       JOIN $table ON (observable_id = $table_id)
                       WHERE population.population_id = ?
                       ORDER BY $name";


	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($population_id);
	my @traits;
    

	while (my ($trait_id, $trait_name) = $sth->fetchrow_array() ) {
	    my $trait= $object->new($self->get_dbh(), $trait_id);
	   	    push @traits, $trait;

	
	}
    
	return @traits;
}


=head2 get_pop_raw_data

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub get_pop_raw_data {
    my $self=shift;
    my $population_id= $self->get_population_id();

    my ($table, $table_id, $object, $name, $definition);
    if ($self->get_web_uploaded()) {
	$table = 'phenome.user_trait';
	$table_id = 'user_trait.user_trait_id';
	#$object = 'CXGN::Phenome::UserTrait';
	$name = 'user_trait.name';
	$definition = 'user_trait.definition';
    } else {
	$table = 'public.cvterm';
	$table_id = 'cvterm.cvterm_id';
	#$object = 'CXGN::Chado::Cvterm';
	$name  = 'cvterm.name';
	$definition = 'cvterm.definition';
    }
   
    my $query = "SELECT individual.population_id, population.name, individual.individual_id, individual.name, observable_id, $name, $definition, phenotype.value  
                      FROM public.phenotype 
                      LEFT JOIN phenome.individual USING (individual_id)  
                      LEFT JOIN phenome.population USING (population_id)
                      LEFT JOIN $table ON (phenotype.observable_id = $table_id)  
                      WHERE individual.population_id =? 
                      ORDER BY individual.name, $name";

    my $sth = $self->get_dbh()->prepare($query);
   
    $sth->execute($population_id);
    
    my (@pop_id, @pop_name, @ind_id, @ind_name, @obs_id, @cvterm, @definition, @value);
   
    while (my ($pop_id, $pop_name, $ind_id, $ind_name, $obs_id, $cvterm, $definition, $value) =$sth->fetchrow_array()) {

	if ($value == 0) {$value = '0.0';}
	elsif (!defined($value)) {$value = 'NA';}
	push @pop_id, $pop_id;
	push @pop_name, $pop_name;
	push @ind_id, $ind_id;
	push @ind_name, $ind_name;
	push @obs_id, $obs_id;
	push @cvterm, $cvterm;
        push @definition, $definition;
	push @value, $value;

    }
    return \@pop_id, \@pop_name, \@ind_id, \@ind_name, \@obs_id, \@cvterm, \@definition, \@value;
}

=head2 add_population_dbxref

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_population_dbxref {
    my $self=shift;
    my $dbxref=shift; #dbxref object
    my $pop_dbxref_id=shift;
    my $sp_person_id=shift;
    
    my $pop_dbxref=CXGN::Phenome::PopulationDbxref->new($self->get_dbh(), $pop_dbxref_id );
    $pop_dbxref->set_population_id($self->get_population_id() );
    $pop_dbxref->set_dbxref_id($dbxref->get_dbxref_id() );
    $pop_dbxref->set_sp_person_id($sp_person_id);
    $pop_dbxref->store();
    
    return $self->{pop_dbxref} ;
}


=head2 get_population_dbxref

 Usage: $population->get_population_dbxref($dbxref)
 Desc:  access population_dbxref object for a given population and its dbxref object
 Ret:    an PopulationDbxref object
 Args:   dbxref object
 Side Effects:
 Example:

=cut

sub get_population_dbxref {
    my $self=shift;
    my $dbxref=shift; # my dbxref object..
    my $query=$self->get_dbh()->prepare("SELECT population_dbxref_id from phenome.population_dbxref
                                        WHERE population_id=? AND dbxref_id=? ");
    $query->execute($self->get_population_id(), $dbxref->get_dbxref_id() );
    my ($pop_dbxref_id) = $query->fetchrow_array();
    my $pop_dbxref= CXGN::Phenome::PopulationDbxref->new($self->get_dbh(), $pop_dbxref_id);
    return $pop_dbxref;
}


sub get_all_population_dbxrefs {   #get an array of dbxref objects (from public dbxref):
    my $self=shift;
    my @pop_dbxrefs;
    my $dbxref_query=$self->get_dbh()->prepare("SELECT dbxref_id from phenome.population_dbxref JOIN public.dbxref USING (dbxref_id) WHERE population_id=? ORDER BY public.dbxref.accession"); 
    my @dbxref_id;
    $dbxref_query->execute($self->get_population_id() );
    while (my ($d) = $dbxref_query->fetchrow_array() ) {
	push @dbxref_id, $d;
    }
    #an array of dbxref objects
    foreach my $id (@dbxref_id) {
	my $dbxref_obj= CXGN::Chado::Dbxref->new($self->get_dbh(), $id);
	#$self->add_dbxref($dbxref_obj);
	push @pop_dbxrefs, $dbxref_obj;
    }
    return @pop_dbxrefs;
}

sub get_population_publications {
    my $self=shift;
    my $query = $self->get_dbh()->prepare("SELECT pub_id FROM pub_dbxref 
                                           JOIN dbxref USING (dbxref_id)
                                           JOIN phenome.population_dbxref USING (dbxref_id)
                                           WHERE population_id = ?");
    $query->execute($self->get_population_id());
    my $publication;
    my @publications;
    while (my ($pub_id) = $query->fetchrow_array()) { 
	$publication = CXGN::Chado::Publication->new($self->get_dbh(), $pub_id);
	push @publications, $publication;
    }
    return @publications;

}

=head2 get_all_indls_cvterm

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_all_indls_cvterm {
    my $self = shift;
    my $pop_id = $self->get_population_id();
    my $observable_id = shift;

    my ($table, $table_id, $object, $name);
    if ($self->get_web_uploaded()) {
	$table = 'phenome.user_trait';
	$table_id = 'user_trait.user_trait_id';
	#$object = 'CXGN::Phenome::UserTrait';
	$name = 'user_trait.name';
    } else {
	$table = 'public.cvterm';
	$table_id = 'cvterm.cvterm_id';
	#$object = 'CXGN::Chado::Cvterm';
	$name  = 'cvterm.name';
    }
    my $query = "SELECT phenotype.individual_id, individual.name, phenotype.value 
                 FROM public.phenotype 
                 LEFT JOIN phenome.individual USING (individual_id)
                 LEFT JOIN $table ON (observable_id = $table_id)
                 WHERE individual.population_id =? AND observable_id = ? ORDER BY CAST(value AS NUMERIC)";
    
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($pop_id, $observable_id);

    my (@indl_id, @indl_name, @value,);
    while (my ($indl_id,  $indl_name, $value ) = $sth->fetchrow_array()) {

	if ($value eq 'null') {$value = 'NA';}
	if ($value == 0) { $value = '0.0';}
	#push @obs_id, $obs_id;
	
	push @indl_name, $indl_name;
	push @value, $value;
	#push @cvterm, $cvterm;
        push @indl_id, $indl_id;
    }
    
  return \@indl_id, \@indl_name, \@value;  
    

}
=head2 plot_cvterm

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub plot_cvterm {
    my $self = shift;
    my $pop_id = $self->get_population_id();
    my $observable_id = shift;
 
    my ($table, $table_id);
    
    if ($self->get_web_uploaded()) {
	 $table = 'phenome.user_trait';
	 $table_id  = 'user_trait_id';
	 #$name = 'user_trait.name';
	 #$definition = 'user_trait.definition';
    } else {
	$table = 'public.cvterm';
	$table_id  = 'cvterm_id';
	#$name = 'cvterm.name';
	#$definition = 'cvterm.definition';


    }
    my $query = "SELECT phenotype.individual_id, individual.name, ROUND(CAST(value AS NUMERIC), 2)
                 FROM public.phenotype 
                 LEFT JOIN phenome.individual USING (individual_id)
                 LEFT JOIN $table  ON (observable_id = $table_id)
                 WHERE individual.population_id =? AND observable_id = ?";
    
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($pop_id, $observable_id);

    my (@indl_id, @indl_name, @value,);
    while (my ($indl_id,  $indl_name, $value ) = $sth->fetchrow_array()) {

	if ($value eq 'null') {$value = undef;}
	if ($value == 0) { $value = '0.0';}
	#push @obs_id, $obs_id;
	
	push @indl_name, $indl_name;
	push @value, $value;
	#push @cvterm, $cvterm;
        push @indl_id, $indl_id;
    }
    
  return \@indl_id, \@indl_name, \@value;  


}
   

=head2 indls_range_cvterm

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub indls_range_cvterm {
    my $self=shift;
    my $cvterm_id = shift;
    my $lower = shift;
    my $upper = shift;
    my $pop_id = $self->get_population_id();
    my $query;
    if ($lower == 0) {

	$query = "SELECT individual_id, individual.name, value 
                         FROM public.phenotype 
                         LEFT JOIN phenome.individual USING (individual_id) 
                         WHERE individual.population_id = $pop_id AND observable_id = $cvterm_id 
                                AND (CAST (value AS NUMERIC) <=$upper) 
                         ORDER BY CAST(value as NUMERIC)";
    } else {
	$query = "SELECT individual_id, individual.name, value 
                         FROM public.phenotype 
                         LEFT JOIN phenome.individual USING (individual_id) 
                         WHERE individual.population_id = $pop_id AND observable_id = $cvterm_id 
                               AND (CAST(value AS NUMERIC) > $lower AND Cast(value AS NUMERIC) <= $upper) 
                         ORDER BY CAST(value AS NUMERIC)";
    }

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute();

    my ($indl_id, $indl_name, $value);
    my (@indl_id, @indl_name, @value);

    while (my ($indl_id, $indl_name, $value ) = $sth->fetchrow_array()) {
	if ($value eq 'null') {$value = 'NA';}
	if ($value == 0 ) {$value = '0.0';}

	push @indl_id, $indl_id;
	push @indl_name, $indl_name;
	push @value, $value;
	
    }
    
    return \@indl_id,  \@indl_name, \@value;  

}

=head2 get_cvterm_acronyms

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut
sub get_cvterm_acronyms {
    my $self=shift;
    my $population_id=$self->get_population_id();
    
    my ($table, $table_id, $name);
    if ($self->get_web_uploaded()) {
	 $table = 'phenome.user_trait';
	 $table_id  = 'user_trait_id';
	 $name = 'user_trait.name';
	 #$definition = 'user_trait.definition';
    } else {
	$table = 'public.cvterm';
	$table_id  = 'cvterm_id';
	$name = 'cvterm.name';
	#$definition = 'cvterm.definition';


    }
    my @cvterm_acronym_pairs=();
    my $query = "SELECT DISTINCT(observable_id), $name  
                      FROM public.phenotype
                      LEFT JOIN phenome.individual USING (individual_id)  
                      LEFT JOIN phenome.population USING (population_id)
                      LEFT JOIN $table ON (phenotype.observable_id = $table_id)  
                      WHERE individual.population_id =?
                      ORDER BY $name";

    my $sth = $self->get_dbh()->prepare($query);
   
    $sth->execute($population_id);
  
    while (my ($observable_id, $cvterm) =$sth->fetchrow_array()) {
	my @words = split(/\s/, $cvterm);
	my $acronym;
	
	if (scalar(@words)== 1) {
	    my $word =shift(@words);
		my $l = substr($word,0,2,q{}); 
		$acronym .= $l;
	     $acronym = uc($acronym);
	 }  else {
	    foreach my $word (@words) {
		if ($word=~/^\D/){
		    my $l = substr($word,0,1,q{});
		    
		    $acronym .= $l;
		} else {$acronym .= $word;}
		$acronym = uc($acronym);
		$acronym =~/(\w+)/;
		$acronym = $1;
	    }
	    
	}
        push @cvterm_acronym_pairs, [$cvterm, $acronym];
    }

    return  \@cvterm_acronym_pairs;
}

=head2 cvterm_acronym

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut
sub cvterm_acronym {
    my $self=shift;
    my $cvterm = shift;
   
   
   
    my @words = split(/\s/, $cvterm);
    my $acronym;
	
    if (scalar(@words)== 1) {
	my $word =shift(@words);
	my $l = substr($word,0,2,q{}); 
	$acronym .= $l;
	$acronym = uc($acronym);
    }  else {
	foreach my $word (@words) {
	    if ($word=~/^\D/){
		my $l = substr($word,0,1,q{}); 
		$acronym .= $l;
	    } else {$acronym .= $word;}
	    $acronym = uc($acronym);
	    $acronym =~/(\w+)/;
	    $acronym = $1;
	}
	   
    }
    return $acronym;

}


=head2 get_genotype_data

 Usage:my ($ind_name, $ind_id, $marker, $marker_id, $map_version, $genotype, $lg_name, $position)=$pop_obj->get_genotype_data()
 Desc:retrieves genetic markers, their genotype values, linkage group and map location for individuals in a population study. 
 Ret: array refs for individual name, individual id, marker alias, marker_id, map_version,  genotype value, linkage name, map position
 Args: none
 Side Effects:
 Example:

=cut
 
sub get_genotype_data {
    my $self = shift;
    my $pop_id = $self->get_population_id();
    my $query = "SELECT individual.name, genotype.individual_id, marker_alias.alias, marker_alias.marker_id, map_version.map_version_id, map_version.map_id, genotype_region.zygocity_code, lg_name, position 
                         FROM phenome.genotype 
                         JOIN phenome.individual ON (genotype.individual_id = individual.individual_id)
                         JOIN phenome.genotype_region ON (genotype.genotype_id = genotype_region.genotype_id) 
                         JOIN sgn.marker_alias ON (marker_alias.marker_id=marker_id_nn) 
                         JOIN sgn.marker_experiment ON (marker_alias.marker_id=marker_experiment.marker_id) 
                         JOIN sgn.marker_location USING(location_id) 
                         JOIN sgn.linkage_group ON (linkage_group.lg_id=marker_location.lg_id) 
                         JOIN sgn.map_version ON (marker_location.map_version_id=map_version.map_version_id) 
                         WHERE genotype_experiment_id = (SELECT DISTINCT(genotype_experiment_id) 
                                    FROM phenome.genotype_experiment 
                                    JOIN phenome.genotype USING (genotype_experiment_id) 
                                    JOIN phenome.individual ON (genotype.individual_id = individual.individual_id) 
                                    WHERE individual.population_id = $pop_id)  
                         AND map_version.map_version_id = (SELECT DISTINCT(map_version_id) 
                                    FROM sgn.map_version 
                                    JOIN phenome.genotype_experiment ON (map_version.map_id = 
                                                        genotype_experiment.reference_map_id) 
                                    JOIN phenome.genotype USING (genotype_experiment_id) 
                                    JOIN phenome.individual USING (individual_id) 
                                    WHERE map_version.current_version = 't' and individual.population_id = $pop_id)
                         AND individual.population_id = $pop_id
                         ORDER BY individual.name, marker_alias.alias";

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute();
    my (@ind_name, @ind_id, @marker, @marker_id, @map_version, @map_id,  @genotype, @lg_name, @position) =();
   
 
    while (my ($ind_name, $ind_id, $marker, $marker_id, $map_version, $map_id, $genotype, $lg_name, $position) = $sth->fetchrow_array()) {
	
	push  @ind_name, $ind_name;
	push  @ind_id, $ind_id;
	push  @marker, $marker;
	push  @marker_id, $marker_id;	
	push  @map_version, $map_version;
	push  @map_id, $map_id;
	if ($genotype eq "a") {$genotype = 1;}
	elsif ($genotype eq "h") {$genotype = 2;}
	elsif ($genotype eq "b") {$genotype = 3;}
	elsif ($genotype eq "d") {$genotype = 4;}
	elsif ($genotype eq "c") {$genotype = 5;}
	push  @genotype, $genotype;
	push  @lg_name, $lg_name;
	push  @position, $position;
    }
    


    return \@ind_name, \@ind_id, \@marker, \@marker_id, \@map_version, \@map_id, \@genotype, \@lg_name, \@position;

}

=head2 get_all_markers

 Usage:my ($marker_id, $marker_alias)=$pop_obj->get_all_markers()
 Desc: useful for retrieving markers assayed on all individual accessions in a population. Not all markers are genotyped on every individual. 
 Ret: array references for marker ids and aliases.
 Args:none
 Side Effects:
 Example:

=cut



sub get_all_markers {
    my $self = shift;
    my $pop_id = $self->get_population_id();
    my $query = "SELECT DISTINCT(marker_alias.marker_id), marker_alias.alias
                        FROM phenome.genotype 
                        JOIN phenome.individual ON (genotype.individual_id = individual.individual_id)
                        JOIN phenome.genotype_region ON (genotype.genotype_id = genotype_region.genotype_id) 
                        JOIN sgn.marker_alias ON (marker_alias.marker_id=marker_id_nn) 
                        JOIN sgn.marker_experiment ON (marker_alias.marker_id=marker_experiment.marker_id) 
                        JOIN sgn.marker_location USING(location_id) 
                        JOIN sgn.linkage_group ON (linkage_group.lg_id=marker_location.lg_id) 
                        JOIN sgn.map_version ON (marker_location.map_version_id=map_version.map_version_id) 
                        WHERE genotype_experiment_id = (SELECT DISTINCT(genotype_experiment_id) 
                                   FROM phenome.genotype_experiment 
                                   JOIN phenome.genotype USING (genotype_experiment_id) 
                                   JOIN phenome.individual ON (genotype.individual_id = individual.individual_id) 
                                   WHERE individual.population_id = $pop_id)  
                        AND map_version.map_version_id = (SELECT DISTINCT(map_version_id) FROM sgn.map_version 
                                   JOIN phenome.genotype_experiment ON (map_version.map_id = genotype_experiment.reference_map_id)                                      JOIN phenome.genotype USING (genotype_experiment_id) 
                                   JOIN phenome.individual USING (individual_id) 
                                   WHERE map_version.current_version = 't' and individual.population_id = $pop_id)
                        ORDER BY marker_alias.alias";

  
  

                    
    my $sth = $self->get_dbh()->prepare($query);
    
    $sth->execute();
    my (@marker_id, @marker_alias);

    while (my ($marker_id, $marker_alias) =$sth->fetchrow_array()) {

	
        push @marker_id, $marker_id;
	push @marker_alias, $marker_alias;
    }
   
    return \@marker_id, \@marker_alias;
}

=head2 get_genotyped_indls

 Usage:my ($indls_id, $indl_name)=$pop_obj->get_genotyped_indls()
 Desc: useful for retrieving markers all individual accessions 
       genotyped for one or more markers in a population. 
       Not all markers are genotyped on every individual. 
 Ret: array references for individual ids and names.
 Args:none
 Side Effects:
 Example:

=cut



sub get_genotyped_indls {
    my $self = shift;
    my $pop_id = $self->get_population_id();
    my $query = "SELECT DISTINCT(genotype.individual_id), individual.name
                        FROM phenome.genotype 
                        JOIN phenome.individual ON (genotype.individual_id = individual.individual_id)
                        JOIN phenome.genotype_region ON (genotype.genotype_id = genotype_region.genotype_id) 
                        JOIN sgn.marker_alias ON (marker_alias.marker_id=marker_id_nn) 
                        JOIN sgn.marker_experiment ON (marker_alias.marker_id=marker_experiment.marker_id) 
                        JOIN sgn.marker_location USING(location_id) 
                        JOIN sgn.linkage_group ON (linkage_group.lg_id=marker_location.lg_id) 
                        JOIN sgn.map_version ON (marker_location.map_version_id=map_version.map_version_id) 
                        WHERE genotype_experiment_id = (SELECT DISTINCT(genotype_experiment_id) 
                                   FROM phenome.genotype_experiment 
                                   JOIN phenome.genotype USING (genotype_experiment_id) 
                                   JOIN phenome.individual ON (genotype.individual_id = individual.individual_id) 
                                   WHERE individual.population_id = $pop_id)  
                        AND map_version.map_version_id = (SELECT DISTINCT(map_version_id) FROM sgn.map_version 
                                   JOIN phenome.genotype_experiment ON (map_version.map_id = genotype_experiment.reference_map_id)                      
                                   JOIN phenome.genotype USING (genotype_experiment_id) 
                                   JOIN phenome.individual USING (individual_id) 
                                   WHERE map_version.current_version = 't' and individual.population_id = $pop_id)
                        ORDER BY individual.name";

  
  

                    
    my $sth = $self->get_dbh()->prepare($query);
    
    $sth->execute();
    my (@indl_id, @indl_name);

    while (my ($indl_id, $indl_name) =$sth->fetchrow_array()) {

	
        push @indl_id, $indl_id;
	push @indl_name, $indl_name;
    }
   
    return \@indl_id, \@indl_name;
}



sub get_ind_marker_genotype {
    my $self = shift;
    my $pop_id = $self->get_population_id();
    my $ind_id = shift;
    my $marker_id = shift;
    my ( $marker, $map_version, $genotype);
    my $query = "SELECT genotype.individual_id, marker_alias.marker_id, map_version.map_version_id,
                        genotype_region.zygocity_code
                        FROM phenome.genotype 
                        JOIN phenome.individual ON (genotype.individual_id = individual.individual_id)
                        JOIN phenome.genotype_region ON (genotype.genotype_id = genotype_region.genotype_id) 
                        JOIN sgn.marker_alias ON (marker_alias.marker_id=genotype_region.marker_id_nn) 
                        JOIN sgn.marker_experiment ON (marker_alias.marker_id=marker_experiment.marker_id) 
                        JOIN sgn.marker_location USING(location_id) 
                        JOIN sgn.linkage_group ON (linkage_group.lg_id=marker_location.lg_id) 
                        JOIN sgn.map_version ON (marker_location.map_version_id=map_version.map_version_id) 
                        WHERE genotype_experiment_id = (SELECT DISTINCT(genotype_experiment_id) 
                                   FROM phenome.genotype_experiment 
                                   JOIN phenome.genotype USING (genotype_experiment_id) 
                                   JOIN phenome.individual ON (genotype.individual_id = individual.individual_id) 
                                   WHERE individual.population_id = $pop_id)  
                        AND map_version.map_version_id = (SELECT DISTINCT(map_version_id) 
                                   FROM sgn.map_version 
                                   JOIN phenome.genotype_experiment ON (map_version.map_id = genotype_experiment.reference_map_id)                                            JOIN phenome.genotype USING (genotype_experiment_id) 
                                   JOIN phenome.individual USING (individual_id) 
                                   WHERE map_version.current_version = 't' and individual.population_id = $pop_id) 
                       AND genotype.individual_id = $ind_id
                       AND marker_alias.marker_id = $marker_id";


    my  $sth = $self->get_dbh()->prepare($query);
    $sth->execute();



    ($ind_id, $marker, $map_version, $genotype) = $sth->fetchrow_array();

    return $ind_id, $marker, $map_version, $genotype;

}


sub get_marker_chr_position {
    my $self = shift;
    my $pop_id = $self->get_population_id();
    my $marker_id = shift;
    
    my $query = "SELECT marker_alias.alias, map_version.map_version_id, lg_name, position
                        FROM phenome.genotype 
                        JOIN phenome.individual ON (genotype.individual_id = individual.individual_id)
                        JOIN phenome.genotype_region ON (genotype.genotype_id = genotype_region.genotype_id) 
                        JOIN sgn.marker_alias ON (marker_alias.marker_id=marker_id_nn) 
                        JOIN sgn.marker_experiment ON (marker_alias.marker_id=marker_experiment.marker_id) 
                        JOIN sgn.marker_location USING(location_id) 
                        JOIN sgn.linkage_group ON (linkage_group.lg_id=marker_location.lg_id) 
                        JOIN sgn.map_version ON (marker_location.map_version_id=map_version.map_version_id) 
                        WHERE genotype_experiment_id = (SELECT DISTINCT(genotype_experiment_id) 
                                   FROM phenome.genotype_experiment 
                                   JOIN phenome.genotype USING (genotype_experiment_id) 
                                   JOIN phenome.individual ON (genotype.individual_id = individual.individual_id) 
                                   WHERE individual.population_id = $pop_id)  
                        AND map_version.map_version_id = (SELECT DISTINCT(map_version_id) FROM sgn.map_version 
                                   JOIN phenome.genotype_experiment ON 
                                          (map_version.map_id = genotype_experiment.reference_map_id)   
                                   JOIN phenome.genotype USING (genotype_experiment_id) 
                                   JOIN phenome.individual USING (individual_id) 
                                   WHERE map_version.current_version = 't' and individual.population_id = $pop_id) 
                       AND marker_alias.marker_id = ?
                       ORDER BY marker_alias.alias";
                        
                      


    my  $sth = $self->get_dbh()->prepare($query);
    $sth->execute($marker_id);

    my (@marker_name, @map_version, @lg_name, @position);

    while (my ($marker_name, $map_version, $lg_name, $position) = $sth->fetchrow_array()) {
	
	
	push @marker_name, $marker_name;	
	push @map_version, $map_version;	
	push @lg_name, $lg_name;
	push @position, $position;
    }

    return  \@marker_name, \@map_version, \@lg_name, \@position;

}


sub get_marker_position {
    my $self = shift;
    my $map_version_id = shift;
    my $marker_name = shift;
    
    my $query = "SELECT  position FROM sgn.marker_alias LEFT JOIN sgn.marker_experiment USING (marker_id) LEFT JOIN sgn.marker_location USING (location_id) WHERE map_version_id = ?  and marker_alias.alias LIKE ?";
                        
    my  $sth = $self->get_dbh()->prepare($query);
    $sth->execute($map_version_id, $marker_name);

    my ($position) = $sth->fetchrow_array(); 
	

    return  $position;

}


sub phenotype_dataset {
    my $self = shift;
    my $dbh = $self->get_dbh();
    my $pop_id = $self->get_population_id();

    my $phe_dataset;

    my @individuals = $self->get_individuals();
    my $individual_obj = $individuals[1];
   
    my @cvterms = $individual_obj->get_unique_cvterms( $individual_obj->get_individual_id());
    my ($pop_name, $ind_id, $ind_name, $obs_id, $cvterm, $definition, $value);
    ($pop_id, $pop_name, $ind_id, $ind_name, $obs_id, $cvterm, $definition, $value) = $self->get_pop_raw_data($pop_id);
    
    my (@cvterms2, @cvterm_acronyms);
    my $cvterm_acronym_pairs = $self->get_cvterm_acronyms();
   
    for my $pair (@{$cvterm_acronym_pairs}) {
       push @cvterms2, $pair->[0];
       push @cvterm_acronyms, $pair->[1];
    }
          
    for (my $i = 0; $i<@cvterms; $i++){
	if  ($cvterms[$i] eq $cvterms2[$i]) { 
	 #do nothing
	} else { print  "There is a mismatch between $cvterms[$i] and $cvterms2[$i]\n";
		   exit();
		}
    }

    if (@cvterm_acronyms) {
        $phe_dataset .= "ID" . ",";
        $phe_dataset .= join (",", @cvterm_acronyms); 
  
        my $old_ind_id = "";
        my @pheno_indls=();
 
        for (my $i=0; $i<@$pop_id; $i++) { 
	
            if ($old_ind_id != $ind_id->[$i]) {
                if ($old_ind_id) {
                    $phe_dataset = substr $phe_dataset, 0, -1;
                }	
                $phe_dataset .= "\n$ind_name->[$i]" . ",";		
            }
	    
            foreach my $t (@cvterms) { 
                my $term = $cvterm->[$i];
                if ($t =~ /^$term$/i) { 
                    $phe_dataset .="$value->[$i]" . ",";
                }	    
            }
            $old_ind_id=$ind_id->[$i];
	   
        }
    
        $phe_dataset = substr $phe_dataset, 0, -1;
    }

    return \$phe_dataset;

}
=head2 genotype_dataset

 Usage:my $genodataset = $pop_obj->genotype_dataset()
 Desc:  returns a genotype dataset for the relevant population (csv format). 
        genotypes are coded in numerical format to meet a RQTL requirement. A change
        in the genotype code here must be accompanied with a matching change in the R code.
 Ret: a scalar ref to the dataset.
 Args: none
 Side Effects:
 Example:

=cut

sub genotype_dataset {
    my $self = shift;
    my $dbh = $self->get_dbh();
    
    my $pop_id = $self->get_population_id();
    my ($pop_name, $pheno_ind_id, $pheno_ind_name, $obs_id, $cvterm, $definition, $value);
    
    ($pop_id, $pop_name, $pheno_ind_id, $pheno_ind_name, $obs_id, $cvterm, $definition, $value) = $self->get_pop_raw_data($pop_id);
    
    my ($ind_name, $ind_id, $marker, $g_marker_id, $map_version, $map_id, $genotype, $lg_name, $position) = $self->get_genotype_data();
    my ($marker_ids, $marker_alias) = $self->get_all_markers();
    my ($genotyped_indls_id, $genotyped_indls_name) = $self->get_genotyped_indls();
    
    my @genotyped_indls_id = @{$genotyped_indls_id};
    my @genotyped_indls_name = @{$genotyped_indls_name};
    my @pop_marker_ids = @{$marker_ids};
    my @pop_marker_alias = @{$marker_alias};
 

    my $gen_dataset = "ID" . ",";

    for (my $i=0; $i<@pop_marker_ids; $i++) {
	$gen_dataset .= "$marker_alias->[$i]" . ",";
    }
    
    $gen_dataset = substr $gen_dataset, 0, -1;
    $gen_dataset .= "\n";
        
    my $m_marker_name;
    foreach my $m_id (@pop_marker_ids) {
	($m_marker_name, $map_version, $lg_name, $position) = $self->get_marker_chr_position($m_id);
 	$gen_dataset .= ",";
 	$gen_dataset .= $lg_name->[1];
    }
    
    $gen_dataset .= "\n";
   
    foreach my $m_id (@pop_marker_ids) {	
 	($m_marker_name, $map_version, $lg_name, $position) = $self->get_marker_chr_position($m_id);
 	$gen_dataset .= ",";		 
 	$gen_dataset .= sprintf('%0.2f',$position->[1]);
	       
    }
    my $old_ind_id = " ";
    my @ind_marker_list=();
    my %marker_genotype={};
    
    my $same_ind_id = $genotyped_indls_id->[0];
   
    my %ind_marker_genotype=();
    my $ind_name_i;
    my @ind_name_list;
    
    for (my $i=0; $i<@$ind_id; $i++) { 	 
	if ($old_ind_id != $ind_id->[$i]) {
	    $ind_name_i= "$ind_name->[$i]";
	    my $ind_name_list = $ind_name->[$i];
	    push @ind_name_list, $ind_name_list;
	}
	my ($ind_markers, $ind_genotype);
	my $j;	
	if ($i > 2) {
	    $j = $i - 1;
	}	
	if ($i == 0)  {
	    %ind_marker_genotype = ($ind_name_i => {$marker->[$i] => $genotype->[$i]});

	}elsif ($ind_name->[$j] eq $ind_name_i) {
	    $ind_marker_genotype{$ind_name_i}->{$marker->[$i]} = $genotype->[$i];
	} elsif ($ind_name->[$j] ne $ind_name_i) { 
	    $ind_marker_genotype{$ind_name_i}={$marker->[$i] => $genotype->[$i]}; 
	}

	$old_ind_id = $ind_id->[$i];
    
    }

    foreach my $genotyped_ind (@genotyped_indls_name) {    
	my @ind_markers = ( sort (keys %{$ind_marker_genotype{$genotyped_ind}}));  
	my $compare = List::Compare->new(\@ind_markers, \@pop_marker_alias);
	my @not_genotyped_m = $compare->get_complement();

	if ( @not_genotyped_m ) {
	    foreach my $not_g_m (@not_genotyped_m) {		    
		$ind_marker_genotype{$genotyped_ind}->{$not_g_m} = 'NA';		   
	    }
	}
    	
    }

    foreach my $ind_i ( sort (keys %ind_marker_genotype)) {
	$gen_dataset .= "\n$ind_i" . ",";
	foreach my $marker_i (@pop_marker_alias) {
	    my $marker_i_genotype = $ind_marker_genotype{$ind_i}{$marker_i};
	    $gen_dataset .= "$marker_i_genotype" . ",";
	}
	$gen_dataset = substr $gen_dataset, 0, -1;	
    } 
  


    
    return \$gen_dataset;

}





=head2 mapversion_id

 Usage: my $map_version_id = $pop->mapversion_id();
 Desc: a quick way to get the map version id of a genetic map for markers genotyped in a population
 Ret: map version id
 Args: none
 Side Effects: accesses database
 Example:

=cut


sub mapversion_id {
     my $self = shift;
     my $dbh = $self->get_dbh();
     my $pop_id = $self->get_population_id();
    
     my $query = "SELECT DISTINCT (map_version_id) 
                          FROM sgn.map_version 
                          JOIN phenome.genotype_experiment ON (map_version.map_id = genotype_experiment.reference_map_id) 
                          JOIN phenome.genotype USING (genotype_experiment_id) 
                          JOIN phenome.individual USING (individual_id) 
                          WHERE map_version.current_version = 't' AND individual.population_id = ?"; 

      my $sth = $dbh->prepare($query);
      $sth->execute($pop_id);

     my ( $map_version_id ) = $sth->fetchrow_array();
    
     
     return $map_version_id;

}


=head2 linkage_groups

  Usage: my @lg = $pop->linkage_groups();
 Desc: useful for getting a list of the linkage groups in a genetic map 
 Ret: an array of the linkage group names
 Args: none
 Side Effects:
 Example:

=cut

sub linkage_groups {
    my $self=shift;
    my $mapversion_id = $self->mapversion_id();
    
    my $query = "SELECT lg_name FROM sgn.linkage_group WHERE map_version_id = ?";
    
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($mapversion_id);
    
    my @lg_names;
   
    while (my $lg_name = $sth->fetchrow_array()) {
	push @lg_names, $lg_name;
    }

    return @lg_names;
	
}

=head2 store_data_privacy

 Usage: $is_public = $pop->store_data_privacy($is_public);
 Desc: sets whether the population data is for public or private use
 Ret: undef if not given a population_id; otherwise, true or false value      
 Args: true or false
 Side Effects: accesseses db
 Example:

=cut

sub store_data_privacy {
    my ($self, $is_public) = @_;  
    my $dbh                = $self->get_dbh();
    my $pop_id             = $self->get_population_id();
    my $owner_id           = $self->get_sp_person_id();
    my $sth;
    if ($pop_id) {
	$sth = $dbh->prepare("SELECT population_id 
                                    FROM phenome.is_public
                                    WHERE population_id = ?"
                           );
	
	$sth->execute($pop_id);

	if ($sth->fetchrow_array()) {
	    $sth->prepare("UPDATE phenome.is_public 
                               SET is_public = ?
                               WHERE population_id = $pop_id"
                      );
	    $sth->execute($is_public);

	} else {

	    $sth = $dbh->prepare("INSERT INTO phenome.is_public 
                                     (population_id, is_public, owner_id) 
                                     VALUES (?, ?, ?)"
                            );

	    $sth->execute($pop_id, $is_public, $owner_id);
	}
	return $is_public; 
    }
    return undef;
      
}


=head2 get_privacy_status

 Usage: my $status = $pop->get_privacy_status();
 Desc: checks if the population data is set to be private or public
 Ret: returns true value if the is_public.is_public is null or true,
     otherwise it returns false value
 Args: none
 Side Effects: access db
 Example:

=cut

sub get_privacy_status {
    my $self = shift;    
    my $dbh = $self->get_dbh();   
 
    if ($self->get_population_id()) 
    {
	my $sth = $dbh->prepare("SELECT is_public 
                                    FROM phenome.is_public
                                    WHERE population_id = ?" 
           
                               );
	$sth->execute($self->get_population_id());
	my $status = $sth->fetchrow_array();
	
	if ( !defined $status ) 
        {
            $status = 't';
            return $status;	
        }       
    }
    else 
    {
        return undef;
    }
  
}


=head2 my_populations

 Usage: my @pops = CXGN::Phenome::Population->my_populations($sp_person_id);
 Desc: returns a list of populations owned by a submitter
 Ret: an array population objects
 Args: sp_person_id
 Side Effects: accesses db
 Example:

=cut

sub my_populations { 
    my $self = shift;
    my $sp_person_id = shift;
    my $dbh = CXGN::DB::Connection->new();
    my $sth = $dbh->prepare("SELECT  population_id
                                     FROM phenome.population
                                     WHERE sp_person_id = ?"
	                   );
    $sth->execute($sp_person_id);

    my @pops;
    while (my $pop_id = $sth->fetchrow_array()) {
	my $pop = $self->new($dbh, $pop_id);
	push @pops, $pop;
    }
    
    return @pops;

}

=head2 cache_path

 Usage: my $cache_path = $population->cache_path($c);
 Desc: creates a /data/prod/tmp/r_qtl/cache directory, 
       if it does not exist. 
 Ret: absolute path to the cache directory
 Args: SGN::Context object
 Side Effects: 
 Example:

=cut

sub cache_path
{
    my $self = shift;
    my $c    = shift;
    my $pop_cache = $c->get_conf('r_qtl_temp_path');
    $pop_cache= "$pop_cache/cache";
    
    unless (-d $pop_cache) 
    {
	mkpath ($pop_cache, 0, 0755);
    }   
    return $pop_cache;
}



=head2 genotype_file

 Usage: my $geno_file = $population->genotype_file($c);
 Desc: writes the genotype data set into a file and caches it. 
 Ret: absolute path to the cached genotype file
 Args: SGN::Context object
 Side Effects: 
 Example:

=cut

sub genotype_file {
    my $self = shift;
    my $c = shift;
    my $pop_id = $self->get_population_id();
    my $cache_path = $self->cache_path($c);
    
    my $file_cache = Cache::File->new( cache_root => $cache_path );
    $file_cache->purge();

    my $key_gen          = "popid_" . $pop_id . "_genodata";
    my $gen_dataset_file = $file_cache->get($key_gen);

    unless ( -e $gen_dataset_file)
    {
        my $genodata     = $self->genotype_dataset();
        my $geno_dataset = ${$genodata};

        my $filename = "genodata_" . $pop_id . ".csv";
        my $file     = "$cache_path/$filename";

        open my $gh, ">", $file or die "can't open $file: !$\n";
        $gh->print($geno_dataset);

        $file_cache->set( $key_gen, $file, '30 days' );
        $gen_dataset_file = $file_cache->get($key_gen);
    }

    return $gen_dataset_file;
}

=head2 phenotype_file

 Usage: my $pheno_file = $population->phenotype_file($c);
 Desc: writes the phenotype data set into a file and caches it. 
 Ret: absolute path to the cached phenotype file
 Args: SGN::Context object
 Side Effects: 
 Example:

=cut

sub phenotype_file {
    my $self = shift;
    my $c = shift;
    my $pop_id = $self->get_population_id();
    my $cache_path = $self->cache_path($c);
    
    my $file_cache = Cache::File->new( cache_root => $cache_path );
    $file_cache->purge();

    my $key_gen          = "popid_" . $pop_id . "_phenodata";
    my $phe_dataset_file = $file_cache->get($key_gen);

    unless (-e $phe_dataset_file)
    {
        my $phenodata     = $self->phenotype_dataset();
        my $pheno_dataset = ${$phenodata};

        my $filename = "phenodata_" . $pop_id . ".csv";
        my $file     = "$cache_path/$filename";

        open my $gh, ">", $file or die "can't open $file: !$\n";
        $gh->print($pheno_dataset);

        $file_cache->set( $key_gen, $file, '30 days' );
        $phe_dataset_file = $file_cache->get($key_gen);
    }

    return $phe_dataset_file;
}


=head2 ci_lod_file

 Usage: my $ci_lod_file = $population->ci_lod_file($c, $trait_acronym);
 Desc: creates and  caches a file for the bayesian 
       confidence interval markers, their map positions,
       lod scores. 
 Ret: absolute path to the cached file
 Args: SGN::Context object, trait acronym name
 Side Effects: 
 Example:

=cut

sub ci_lod_file {
    my ($self, $c, $trait) = @_;
   
    my $pop_id = $self->get_population_id();
    my $cache_path = $self->cache_path($c);
    
    my $file_cache = Cache::File->new( cache_root => $cache_path );
    $file_cache->purge();

    my $key          = "popid_" . $pop_id . $trait. "_ci_lod";
    my $ci_lod_file = $file_cache->get($key);

    unless ($ci_lod_file)
    {      
        my $filename = "confidence_lod_" . $trait . "_" . $pop_id;
        my $file     = "$cache_path/$filename";        
        $file_cache->set( $key, $file, '30 days' );
        $ci_lod_file = $file_cache->get($key);
    }

    return $ci_lod_file;
}


sub qtl_effects_file {
    my ($self, $c, $trait_ac) = @_;
   
    my $pop_id = $self->get_population_id();
    my $cache_path = $self->cache_path($c);
  
    my $file_cache = Cache::File->new( cache_root => $cache_path );
    $file_cache->purge();

    my $key          = "popid_" . $pop_id . $trait_ac . "_qtl_effects";
    my $qtl_effects_file = $file_cache->get($key);

    unless ($qtl_effects_file)
    {      
        my $filename = "qtl_effects_" . $trait_ac . "_" . $pop_id;
        my $file     = "$cache_path/$filename";        
        $file_cache->set( $key, $file, '30 days' );
        $qtl_effects_file = $file_cache->get($key);
    }

    return $qtl_effects_file;
}


sub explained_variation_file {
    my ($self, $c, $trait_ac) = @_;
   
    my $pop_id = $self->get_population_id();
    my $cache_path = $self->cache_path($c);

    my $file_cache = Cache::File->new( cache_root => $cache_path );
    $file_cache->purge();

    my $key          = "popid_" . $pop_id . $trait_ac . "_explained_variation";
    my $explained_variation_file = $file_cache->get($key);

    unless ($explained_variation_file)
    {      
        my $filename = "explained_variation_" . $trait_ac . "_" . $pop_id;
        my $file     = "$cache_path/$filename";        
        $file_cache->set( $key, $file, '30 days' );
        $explained_variation_file = $file_cache->get($key);
    }

    return $explained_variation_file;
}
############# 
return  1;
############
