=head1 NAME

CXGN::Chado::UserTrait
A class for handling user submitted trait objects.

It implements an object for the  'user_trait, unit, 
phenotype_user_trait' tables in the phenome schema.

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
	$self->set_user_trait_id($trait_id);
	$self->fetch();
    }

    return $self; 


}


sub fetch {
    my $self = shift;
    my $trait_id = $self->get_user_trait_id();
    my $query = "SELECT user_trait_id, cv_id, name, definition,
                        dbxref_id, sp_person_id 
                        FROM phenome.user_trait 
                        WHERE user_trait_id=?";

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($trait_id);
    
    while (my ($trait_id, $cv_id, $name, $definition, 
               $dbxref_id, $sp_person_id) = $sth->fetchrow_array()) { 
	
	$self->set_user_trait_id($trait_id);
	$self->set_cv_id($cv_id);
	$self->set_name($name);
	$self->set_definition($definition);
	$self->set_dbxref_id($dbxref_id);
	$self->set_sp_person_id($sp_person_id);
    }
       
}

sub store {
    my $self = shift;
   
    if ($self->get_user_trait_id()) { 
	
	my $query = "UPDATE phenome.user_trait SET
                     cv_id=?, name=?, definition=?, dbxref_id=?, sp_person_id=?
                     WHERE user_trait_id=?";
	my $sth = $self->get_dbh()->prepare();
	$sth->execute( $self->get_cv_id(),
	               $self->get_name(),
	               $self->get_definition(),
	               $self->get_dbxref_id(),	              
	               $self->get_sp_person_id()
                    );


	return $self->get_user_trait_id();
         
    }
    else { 

	my $query = "INSERT INTO phenome.user_trait (cv_id, name, definition, dbxref_id, sp_person_id) 
                            VALUES (?, ?, ?, ?, ?, ?)";

	my $sth = $self->get_dbh()->prepare($query);

	$sth->execute( $self->get_cv_id(),
	               $self->get_name(),
	               $self->get_definition(),
	               $self->get_dbxref_id(),
	               $self->get_sp_person_id()
	               );


		      
	my $trait_id=$self->get_currval("phenome.user_trait_user_trait_id_seq");
 	$self->set_user_trait_id($trait_id);
 	return $trait_id;
    }
}


=head2 set_user_trait_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_user_trait_id {
    my $self=shift;
    $self->{user_trait_id}=shift;

}

=head2 get_user_trait_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_user_trait_id {
    my $self=shift;
    return $self->{user_trait_id};

}
=head2 set_cv_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_cv_id {
    my $self=shift;
    $self->{cv_id}=shift;

}

=head2 get_cv_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_cv_id {
    my $self=shift;
    return $self->{cv_id};

}
=head2 set_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_name {
    my $self=shift;
    $self->{name}=shift;

}

=head2 get_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_name {
    my $self =shift;
    return $self->{name};

}

=head2 set_definition

 Usage:        
 Desc:         
 Ret:
 Args:
 Side Effects:
 Example:      

=cut

sub set_definition {
    my  $self = shift;
    $self->{definition}=shift;

}
=head2 get_definition

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_definition {
    my $self =shift;
    return $self->{definition};
}

=head2 set_unit_id

 Usage:
 Desc:            
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_unit_id {
    my $self=shift;
    $self->{unit_id}=shift;

}

=head2 get_unit_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_unit_id {
    my $self=shift;
    return $self->{unit_id};

}

=head2 set_dbxref_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_dbxref_id {
    my $self=shift;
    $self->{dbxref_id}=shift;

}

=head2 get_dbxref_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dbxref_id {
    my $self=shift;
    return $self->{dbxref_id};

}



=head2 set_sp_person_id, get_sp_person_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_sp_person_id {
    my $self=shift;
    $self->{sp_person_id}=shift;

}

sub get_sp_person_id {
    my $self =shift;
    return $self->{sp_person_id};
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

 Usage:        my @traits = CXGN::Chado::UserTrait->new_with_name($dbh, "fruit perimeter")
 Desc:         An alternate constructor that takes a trait name 
               as a parameter and returns a list of objects
               that match that name.
 Ret:          a list of CXGN::Chado::UserTrait objects
 Args:         a database handle, a trait name
 Side Effects: accesses the database.
 Example:

=cut

sub new_with_name {
    my $self = shift;
    my $dbh = shift;
    my $name = shift;
    my $query = "SELECT user_trait_id FROM phenome.user_trait WHERE name ILIKE '$name%'";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    
    my $id = $sth->fetchrow_array();  
    return CXGN::Phenome::UserTrait->new($dbh, $id);
    
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
    my $self = shift;  
    my $trait_id = shift;     
    my $unit_id = shift;
    my $pop_id = shift;

    my $dbh = $self->get_dbh();

    my $user_trait_unit_id;
    if (($trait_id) && ($pop_id) && ($unit_id)) {
	    my $sth = $dbh->prepare("INSERT INTO phenome.user_trait_unit 
                                                 (user_trait_id, unit_id, population_id) 
                                                 VALUES (?, ?, ?)"
                                   );
	    $sth->execute($trait_id, $unit_id, $pop_id);
	    	   
	    $user_trait_unit_id = $self->get_currval("phenome.user_trait_unit_user_trait_unit_id_seq");
	    print STDERR "STORED user_trait_unit: $user_trait_unit_id! \n";
    }
    else {
	    print STDERR "No point in populating this table if there 
                         is no at least unit of measurement.\n";
	}


    return $user_trait_unit_id;

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


#####  DEPRECATED #######

=head2 get_unit

 Usage: my $name = $trait_obj->get_unit($dbh, $unit_id);
 Desc: returns the unit of measurement associated with a trait
 Ret: unit name or undef
 Args: dbh and unit_id
 Side Effects: accesses database
 Example:

=cut

# sub get_unit {
#     my $self = shift;
#     my $dbh = $self->get_dbh();
#     my $unit_id = shift;
    

#     my $sth = $dbh->prepare("SELECT name FROM phenome.unit WHERE unit_id = ?");
#     $sth->execute($unit_id);

#     my $name = $sth->fetchrow_array();

#     if ($name) {
# 	return $name;
#     } else {
# 	return 0;
#     }

# }

######################


##########
return 1;
#########
