package CXGN::Phenome::Locus::LinkageGroup;
use strict;
use warnings;

=head1 NAME

Functions for accessing linkage groups and their identifiers

=head1 SYNOPSIS


=head1 DESCRIPTION

This static class needs to be replace with an AJAX server side script that will choose the lg names and lg arms based on a common_name_id 

    =cut


=head2 get_all_lgs

 Usage:        my ($names_ref) = CXGN::Phenome::Locus::LinkageGroup::get_all_organisms($dbh);
 Desc:         This is a static function. Retrieves distinct linkage group names and IDs from sgn.common_nameprop
 Ret:          Returns an arrayref containing all the
               linkage group names.
 Args:         a database handle
 Side Effects:
 Example:

=cut

sub get_all_lgs {
    my $dbh = shift;
    my $query = "SELECT  distinct  value 
                 FROM sgn.common_nameprop 
                 JOIN public.cvterm on (cvterm.cvterm_id = common_nameprop.type_id)
                 WHERE cvterm.name = ? ";
                
    my $sth = $dbh->prepare($query);
    $sth->execute('linkage_group');
    my @names;
    while ((my $lg_name) = $sth->fetchrow_array()) { 
	push @names, $lg_name;
    }
    if (!(grep {/^''$/}  @names )) { push @names, ''; } #add a 'null' option
    my @sorted_names= sort{$a <=> $b} @names; 
    return \@sorted_names; 
}

=head2 get_lg_arms

 Usage:        my ($names_ref) = CXGN::Phenome::Locus::LinkageGroup::get_lg_arms($dbh);
 Desc:         This is a static function. Retrieves distinct linkage group arm names and IDs from sgn.common_nameprop
 Ret:          Returns an arrayref containing all the
               linkage group arm names.
 Args:         a database handle
 Side Effects:
 Example:

=cut

sub get_lg_arms {
    my $dbh = shift;
    my $query = "SELECT distinct value 
                   FROM sgn.common_nameprop
                  JOIN public.cvterm on (cvterm.cvterm_id = common_nameprop.type_id)
                   WHERE cvterm.name ilike ?
                   ";
    my $sth = $dbh->prepare($query);
    $sth->execute('chromosome_arm', );
    my @names = ();
    while ((my $arm) = $sth->fetchrow_array()) { 
	push @names, $arm;
    }
    if (!(grep {/^''$/}  @names )) { push @names, ''; }
    @names = sort { lc($a) cmp lc($b) } @names;
    
    return \@names;
}


return 1;
