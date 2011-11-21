=head1 NAME

CXGN::Phenome::UserTrait;

transitioning to qtl controller, new db tables and dbix class methods
   
=head1 SYNOPSIS



=head1 AUTHOR

Isaak Y Tecle (iyt2@cornell.edu)

=cut


use warnings;
use strict;



package CXGN::Phenome::UserTrait;


use CXGN::DB::Object;
use base qw /CXGN::DB::Object/;


=head2 new

 Usage:        Constructor
 Desc:
 Ret:        
 Args:         a database handle and a unique ID.
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh=shift;
    my $trait_id=shift;
   
    my $self = $class->SUPER::new($dbh);
    
    if ($trait_id) {
	$self->set_qtl_trait_id($trait_id);
    }

    return $self; 
}





=head2 set_user_trait_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_qtl_trait_id {
    my $self=shift;
    $self->{qtl_trait_id}=shift;

}

=head2 get_qtl_trait_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_qtl_trait_id {
    my $self=shift;
    return $self->{qtl_trait_id};

}



=head2 insert_phenotype_user_trait_ids

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub insert_phenotype_user_trait_ids {
    my $self=shift;    
    my $trait_id=shift;
    my $phenotype_id=shift;
    my $q = "INSERT INTO phenome.phenotype_user_trait ( user_trait_id, phenotype_id) VALUES (?,?)";
    my $sth= $self->get_dbh()->prepare($q);
    if ($phenotype_id && $trait_id) {
	$sth->execute($trait_id, $phenotype_id);
	#print STDERR"STORED user_trait_id: $trait_id and phenotype_id: $phenotype_id \n";
    }
    else { print STDERR "FAILED to store user_trait_id and $phenotype_id in phenotype_user_trait table"; }

}

=head2 new_with_name

 Usage:        my $trait = CXGN::Phenome::UserTrait->new_with_name($dbh, "fruit perimeter")
 Desc:         An alternate constructor that takes a trait name 
               as a parameter and returns an object
               for that trait.
 Ret:          a CXGN::Phenome::UserTrait object
 Args:         a database handle, a trait name
 Side Effects: accesses the database.
 Example:

=cut

sub new_with_name {
    my $self = shift;
    my $dbh = shift;
    my $name = shift;
    my $query = "SELECT user_trait_id FROM phenome.user_trait WHERE name ILIKE ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($name);
    
    my $id = $sth->fetchrow_array();  
   
    if ($id) {
	return CXGN::Phenome::UserTrait->new($dbh, $id);
    } else {return 0;}
 
    
}





=head2 insert_unit

 Usage: my $unit_id = $CV->inset_unit("kg");
 Desc:
 Ret: unit id
 Args: measurenment unit name eg "kg"
 Side Effects:
 Example:

=cut

sub insert_unit {
    my $self = shift;
    my $name = shift;
    my $dbh = $self->get_dbh();

    my $unit_id;    
	if ($name) {
	    my $q = "INSERT INTO phenome.unit (name) VALUES (?)";
	    my $sth = $dbh->prepare($q);
	    $sth->execute($name);

	    print STDERR "STORED unit! \n";
	    $unit_id = $self->get_currval("phenome.unit_unit_id_seq");	
	}
    
    return $unit_id;

}

=head2 insert_user_trait_unit

 Usage: $trait->inset_unit_trait_unit($trait_id, $unit_id, $pop_id);
 Desc: inserts unit_id, trait_id, population_id  of the unit of measurenment for a trait
       measured in a population. It is possible that a trait may be measured 
       in different units in different experiments and therefore the phenotype value
       has to be qualified accordingly.
 Ret: user_trait_unit_id
 Args:  user_trait_id,  unit_id, population_id (in the same order)
 Side Effects:
 Example:

=cut

sub insert_user_trait_unit {
    my ($self, $trait_id, $unit_id, $pop_id) = shift;      
    my $dbh = $self->get_dbh();

    my $qtl_trait_unit_id;
    if (($trait_id) && ($pop_id) && ($unit_id)) {
	    my $sth = $dbh->prepare("INSERT INTO phenome.qtl_trait_unit 
                                                 (cvterm_id, unit_id, population_id) 
                                                 VALUES (?, ?, ?)"
                                   );
	    $sth->execute($trait_id, $unit_id, $pop_id);
	    	   
	    $qtl_trait_unit_id = $self->get_currval("phenome.qtl_trait_unit_qtl_trait_unit_id_seq");
	    print STDERR "STORED qtl_trait_unit: $qtl_trait_unit_id! \n";
	    return $qtl_trait_unit_id;
    }
    else {
	    print STDERR "No point in populating this table if there 
                         is no at least unit of measurement.\n";
	}


    

}


=head2 get_unit_id

 Usage: my $unit_id = $trait_obj->get_unit_id($unit_name);
 Desc: returns the unit_id ofa unit of measurement
 Ret: unit_id or undef
 Args:  unit name
 Side Effects: accesses database
 Example:

=cut

sub get_unit_id {
    my $self = shift;   
    my $name = shift;
    my $dbh = $self->get_dbh();

    my $sth = $dbh->prepare("SELECT unit_id 
                                    FROM phenome.unit 
                                    WHERE name ILIKE ?"
                            );
    
    $sth->execute($name);

    my $unit_id = $sth->fetchrow_array();

    if ($unit_id) {
	return $unit_id;
    } else {
	return 0;
    }

}


sub get_all_populations_trait {
    my $self=shift;
    my $query = "SELECT DISTINCT(phenome.population.population_id) 
                            FROM public.phenotype 
                            LEFT JOIN phenome.individual USING (individual_id)
                            LEFT JOIN phenome.population USING (population_id)
                            WHERE observable_id = ?";
    my $sth=$self->get_dbh->prepare($query);
    $sth->execute($self->get_user_trait_id());
    my @populations;
    while (my ($pop_id) = $sth->fetchrow_array()) {
	print STDERR "trait: populations; $pop_id\n";
	my $pop = CXGN::Phenome::Population->new($self->get_dbh(), $pop_id);
	push @populations, $pop;
    }
    return @populations;

}

##########
return 1;
#########
