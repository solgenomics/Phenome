=head1 NAME

CXGN::Phenome::Locus ::LocusOwner


=head1 SYNOPSIS

Functions for accessing locus owners by different criteria

=head1 AUTHOR

Naama Menda <nm249@cornell.edu>

=cut

package CXGN::Phenome::Locus::LocusOwner;

use CXGN::DB::Connection;
use CXGN::People::Person;
use CXGN::Phenome::Locus;
use CXGN::Contact;

use base qw / CXGN::Phenome::Main /;

=head2 send_owners_email

 Usage: CXGN::Phenome::Locus::LocusOwner::send_owners_email
 Desc:  class function for sending a custom reminder email for all locus owners
        as stored in phenome.locus_owner table
 Ret:   nothing
 Args:  sp_person_id, locus_id (optional).
 Side Effects: 
 Example:

=cut

sub send_owners_email {
    my $owner_id= shift;
    my $locus_id=shift;
    my %owners=();
    my $dbh=CXGN::DB::Connection->new();
    
    my $query = "SELECT locus_id, locus_owner.sp_person_id FROM phenome.locus_owner 
                 JOIN sgn_people.sp_person USING (sp_person_id)
                 JOIN phenome.locus USING (locus_id) 
		 WHERE locus.obsolete = 'f' AND ";
    if ($owner_id) { $query .= " locus_owner.sp_person_id=$owner_id"; }
    if ($locus_id && $owner_id) { $query .= "  AND locus_owner.locus_id= $locus_id"; } 
    elsif ($locus_id) { $query .= " locus_id= $locus_id"; }
    if (!$owner_id && !$locus_id) { $query .= "user_type != 'curator'"; }
    $query .= " ORDER BY sp_person.sp_person_id"; 
    my $sth=$dbh->prepare($query);
    $sth->execute();
    while  (my ($locus_id, $sp_person_id) = $sth->fetchrow_array() ) {
	push @ {$owners{$sp_person_id} } , $locus_id ;
    }
    my $count=0;
    my @unsent=();
    my @sent_emails=();
    my $locus_link= "http://www.sgn.cornell.edu/phenome/locus_display.pl?locus_id=";
    foreach my $sp_person_id(sort { $a <=> $b } keys %owners) {
	$count++;
	my $person= CXGN::People::Person->new($self->get_dbh(), $sp_person_id);
	
	my $user=$person->get_salutation(). " " . $person->get_first_name()." ".$person->get_last_name();
	print STDERR "the user name is '$user' id = ". $person->get_sp_person_id() . "\n";
	my $contact_email= $person->get_contact_email() ;
	my $username=$person->get_username();
	my $password=$person->get_password();
	my $subject="[SGN] Locus owner reminder";
	print STDERR "$contact_email\n$username\n$password\n$subject\n\n";

	if (!$contact_email) { 
	    warn "User $sp_person_id ($username) has no contact email!!";
	    push @unsent, $sp_person_id;
	    next();
	}
	push @sent_emails, $sp_person_id;
	my $user_link = qq |http://www.sgn.cornell.edu/solpeople/personal-info.pl?sp_person_id=$sp_person_id|;
	
	my $fdbk_body="Dear $user, \nYou are curently assigend as locus editor for the folowing loci in the SOL Genomics Network database:\n\n";
	foreach my $locus_id( @{$owners{$sp_person_id} } ) {
	    my $locus= CXGN::Phenome::Locus->new($dbh, $locus_id);
	    my $locus_name= $locus->get_locus_name();
	    my $common_name= $locus->get_common_name();
	    $fdbk_body .="$common_name '$locus_name' ($locus_link$locus_id)\n ";
	}
	$fdbk_body .= "\n

This is a reminder that as an editor of the above locus/loci you can add or change any data (including images
and figures) on the gene pages using a simple web-interface and share
your research results in real-time with the solanaceae research community.

Just log-in using your username ('$username') and password ('$password') 
and the 'edit' links on the locus page will become active. 

Please see our annotation guidelines for reference: http://www.sgn.cornell.edu/phenome/editors_note.pl 
If need be, we will be happy to answer any questions or requests you may have (sgn-feedback\@sgn.cornell.edu).

You may be already familiar with the SGN's effort to create a
medium and tools for the solanaceae research community to annotate their
genes and phenotypes, that way ensuring the quality of data in the
database is as accurate, current  and accessible as possible.

Thank you for contributing to the SGN community driven database!\n


SGN Database team
http://www.sgn.cornell.edu
sgn-feedback\@sgn.cornell.edu
";
	
	CXGN::Contact::send_email($subject,$fdbk_body, $contact_email, 'sgn-feedback@sgn.cornell.edu');
    }
    print STDERR "Found $count locus owners!\n";
    print STDERR "Sent emails to ". scalar(@sent_emails) ." sp_person_ids: \n";
    print STDERR join("," , @sent_emails);
    print STDERR "\n";
    
    print STDERR "failed sending email to the following sp_person_ids: \n";
    print STDERR join("," , @unsent);
    print STDERR "\n";

}

return 1;
