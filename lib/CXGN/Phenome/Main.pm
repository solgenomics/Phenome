
=head1 NAME

CXGN::Phenome::Main 
package for the main methods used by Phenome objects (locus, allele, dbxref, )  

=head1 SYNOPSIS

=head1 AUTHOR

Naama

=cut 

package CXGN::Phenome::Main;

use base qw / CXGN::DB::Object /;

=head2 new

 Usage: 
 Desc:
 Ret:    
 Args:
 Side Effects:
 Example:

=cut

sub new {
    my $class=shift;
    my $dbh= shift; 
   
    my $args = {};  
    my $self = bless $args, $class;

   $self->set_dbh($dbh);
  
    return $self;
}
=head2 get_dbh

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dbh {
  my $self=shift;
  return $self->{dbh};

}

=head2 set_dbh

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_dbh {
  my $self=shift;
  $self->{dbh}=shift;
}

=head2 get_person_details

 Usage: $self->get_person_details($sp_person_id)
 Desc:  find the first and last name, and a link to personal-info.pl
         of a person using the sp_person_id
 Ret:  an html link to personal_info.pl
 Args:  $sp_person_id
 Side Effects:
 Example:

=cut

sub get_person_details {
    my $self=shift;
    my $sp_person_id=shift;
    my $person = CXGN::People::Person->new($self->{dbh}, $sp_person_id);
    my $first_name = $person->get_first_name();
    my $last_name = $person->get_last_name();
    my $person_html .=qq |<a href="/solpeople/personal-info.pl?sp_person_id=$sp_person_id">$first_name $last_name</a> |;
    return $person_html;
}

###
1;# do not remove
###
