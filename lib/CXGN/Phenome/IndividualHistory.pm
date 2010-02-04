=head1 NAME

CXGN::Phenome::IndividualHistory 

A subclass of Phenome::Individual for accessing the history edits of an individual object 

=head1 SYNOPSIS

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut

use CXGN::DB::Connection;
use CXGN::Phenome::Individual;


package CXGN::Phenome::IndividualHistory;

use base qw / CXGN::Phenome::Individual /;

=head2 new

 Usage: my $history = CXGN::Phenome::IndividualHistory->new($dbh,$individual_history_id);
 Desc:
 Ret:    
 Args: $dbh, $individual_history_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id= shift; # the primary key in the databaes of this object

    my $args = {};  
    
    my $self=$class->SUPER::new($dbh);   
   
    $self->set_individual_history_id($id);  
  
    if ($id) {
	$self->fetch($id); #get the individual_history  details   
    }
    
    return $self;
}


sub fetch {
    my $self=shift;
    
    my $history_query = $self->get_dbh()->prepare("SELECT individual_history_id, individual_id,name, description, population_id,  sp_person_id, updated_by, obsolete, create_date
 FROM phenome.individual_history 
 WHERE individual_history_id=? ");

    $history_query->execute($self->get_individual_history_id());

    my ($individual_history_id, $individual_id, $name, $description, $population_id, $sp_person_id, $updated_by, $obsolete, $create_date)=$history_query->fetchrow_array();
    
    $self->set_individual_history_id($individual_history_id);
    $self->set_individual_id($individual_id);
    $self->set_name($name);
    $self->set_description($description);
    $self->set_population_id($population_id);
    $self->set_sp_person_id($sp_person_id);
    $self->set_updated_by($updated_by);
    $self->set_obsolete($obsolete);
    $self->set_create_date($create_date);
}

sub store { 

}


=head2 get_individual_history_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_individual_history_id {
  my $self=shift;
  return $self->{individual_history_id};

}

=head2 set_individual_history_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_individual_history_id {
  my $self=shift;
  $self->{individual_history_id}=shift;
}


sub delete { 
}




### Do not remove
1;#
###
