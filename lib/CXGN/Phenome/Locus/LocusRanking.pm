
=head1 NAME

CXGN::Phenome::Locus::LocusRanking 

=head1 SYNOPSIS

=head1 AUTHOR

Naama (nm249@cornell.edu)

=cut
use CXGN::DB::Connection;

use CXGN::DB::Object;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Publication;
use CXGN::Phenome::Locus;
#use CXGN::Tools::Tsearch;

package CXGN::Phenome::Locus::LocusRanking;

use base qw / CXGN::Phenome::Main CXGN::Tools::Tsearch/;

=head2 new

 Usage: my $gene = CXGN::Phenome::Locus::LocusRanking->new($dbh,$locus_id, $pub_id);
 Desc:
 Ret:    
 Args: $dbh, $locus_id, $pub_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $locus_id= shift; # the primary key in the databaes of this object
    my $pub_id=shift;
    my $args = {};  
    
    my $self = bless $args, $class;
    
    $self->set_dbh($dbh);
    $self->set_locus_id($locus_id);
    $self->set_pub_id($pub_id);
    if ($locus_id && $pub_id) {
	$self->fetch(); #get the locus details   
	$self->set_validate_status();
    }
    return $self;
}

sub fetch {
    my $self=shift;
    my $query = "SELECT rank, match_type, headline 
                    FROM phenome.locus_pub_ranking 
                    WHERE locus_id=? and pub_id=?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id(), $self->get_pub_id());
    
    my ($rank,$match_type,$headline)=$sth->fetchrow_array();
    $self->set_rank($rank);
    $self->set_match_type($match_type);
    $self->set_headline($headline);
}


=head2 store

 Usage: $self->store()
 Desc:  store a new locus_pub_ranking
 Ret:   1 if stored or 0 if locus_pub_rank_exists
 Args:  none
 Side Effects: inserts a new row in locus_pub_ranking table
 Example:

=cut

sub store {
    my $self=shift;
    my $exists=$self->locus_pub_rank_exists(); 
    my $store= 0;
    if (!$exists) {
	$store= 1;
	my $query= "INSERT INTO phenome.locus_pub_ranking (locus_id,pub_id, rank, match_type, headline)
                     VALUES (?,?,?,?,?)";
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($self->get_locus_id, $self->get_pub_id(), $self->get_rank(), $self->get_match_type(), $self->get_headline());
    }else{
	#is update necessary here? 
    }
    return $store;
}


=head2 store_validate

 Usage: $self->store_validate()
 Desc:  store a new locus_pub_rank_validate()
 Ret:   $validate
 Args:  none
 Side Effects: inserts a new row in locus_pub_ranking_validate, or updates if $self->validated()
 Example:

=cut


sub store_validate {
    my $self=shift;
    my $locus_id = $self->get_locus_id();
    my $pub_id = $self->get_pub_id();
    my $validate=$self->get_validate();
    my $exists=$self->validated();
    if (!$exists) {
	my $query= "INSERT INTO phenome.locus_pub_ranking_validate (locus_id,pub_id, validate)
                     VALUES (?,?,?)";
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($locus_id, $pub_id, $validate);
    }else{
	my $query= "UPDATE phenome.locus_pub_ranking_validate SET  validate=?
                    WHERE locus_id=? AND pub_id=?";
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($validate, $locus_id, $pub_id);
    }
    print STDERR "***validate=$validate_id, $locus_id, $pub_id***";
    return $validate;
}

=head2 validated

 Usage: $self->validated()
 Desc:  checks if locus-pub is validated (see locus_pub_ranking_validate table)
 Ret:  $validate or undef
 Args:  none
 Side Effects:
 Example:

=cut


sub validated {
    my $self=shift;
    my $query="SELECT validate FROM phenome.locus_pub_ranking_validate WHERE locus_id=? AND pub_id=?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id(), $self->get_pub_id());
    my ($validate) = $sth->fetchrow_array();
    return $validate || undef;
}


sub set_validate_status {
    my $self=shift;
    my $query="SELECT validate FROM phenome.locus_pub_ranking_validate WHERE locus_id=? AND pub_id=?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id(), $self->get_pub_id());
    my ($validate) = $sth->fetchrow_array();
    $self->set_validate($validate);
}



=head2 get_validate

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_validate {
  my $self=shift;
  return $self->{validate};

}

=head2 set_validate

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_validate {
  my $self=shift;
  $self->{validate}=shift;
}



=head2 get_locus_pub

 Usage: $locus->get_locus_pub
 Desc:  find the publications associated with the locus and the sum of the ranking 
 Ret:   a hashref $pub_id => $total_rank
 Args:  none
 Side Effects: sets cvterm_ranks ( a hashref cvterm_id => total_rank )
 Example:

=cut

sub get_locus_pub {
    
    my $locus=shift;
    my $locus_id = $locus->get_locus_id();
 
    my $query = "SELECT pub_id, rank,match_type, headline, validate
                 FROM phenome.locus_pub_ranking 
                 LEFT JOIN phenome.locus_pub_ranking_validate USING (locus_id, pub_id) 
                 WHERE locus_id =? ORDER BY rank desc";
  
    my $sth=$locus->get_dbh()->prepare($query);
    $sth->execute($locus_id);
    my $total_locus_pub_rank={};
    my $locus_pub_rank={};
   
    while (my @pub = $sth->fetchrow_array() ) {
	my $validate= $pub[4] || "";
	if ($validate ne "no") {
	    $locus_pub_rank->{$pub[0]} += $pub[1]; # total rank for this publication
	}else {  $locus_pub_rank->{$pub[0]} +=0 ; } # setting the match score to zero if match was rejected (done by curator)
    }
    my $cvterm_pub_rank={};
    my $cvterm_total_rank={};
    my $cvterm_query="SELECT cvterm_id, sum(rank) FROM phenome.cvterm_pub_ranking 
                          WHERE pub_id=? GROUP BY cvterm_id";
    foreach my $pubid (keys %$locus_pub_rank){
	if ($locus_pub_rank->{$pubid} ne 0 ) { # if the locus=pub match was rejected do not account the cvterm match
	    my $cvterm_sth = $locus->get_dbh()->prepare($cvterm_query);
	    $cvterm_sth->execute($pubid);
	    while(my @cvterm = $cvterm_sth->fetchrow_array()){
		$cvterm_pub_rank->{$cvterm[0]} +=$cvterm[1];
	    }
	}
	foreach my $cvterm_id (keys %$cvterm_pub_rank){
	    $cvterm_total_rank->{$cvterm_id} += $cvterm_pub_rank->{$cvterm_id}*$locus_pub_rank->{$pubid}; #adds the total cvterm-pub rank multiplied by the total locus-pub rank
	}
    }
    my $cvterm_combined_rank={};
    my $pub_list= join(",", keys %$locus_pub_rank);
    foreach my $cvterm_id (keys %$cvterm_pub_rank){
	my $non_match_q= "SELECT sum(rank) FROM cvterm_pub_ranking
                           WHERE cvterm_id=? AND pub_id NOT IN ($pub_list)";
	my $n_sth=$locus->get_dbh()->prepare($non_match_q);
	$n_sth->execute($cvterm_id);
	my ($n_rank) = $n_sth->fetchrow_array() || '1';
	$cvterm_combined_rank->{$cvterm_id} = ($cvterm_total_rank->{$cvterm_id} ) / $n_rank;
    }
    
    $locus->set_cvterm_ranks($cvterm_total_rank);
    
    return $locus_pub_rank;
}


=head2 add_cvterm_rank

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_cvterm_rank {
    my $locus=shift;
    my $cvterm_id=shift;
    my $rank=shift;
    push @{ $locus->{cvterm_ranks} }, $cvterm_id;
}

=head2 get_cvterm_ranks

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_cvterm_ranks {
  my $locus=shift;
  return $locus->{cvterm_ranks};

}

=head2 set_cvterm_ranks

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_cvterm_ranks {
  my $locus=shift;
  $locus->{cvterm_ranks}=shift;
}


=head2 get_rank

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_rank {
  my $self=shift;
  return $self->{rank};

}

=head2 set_rank

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_rank {
  my $self=shift;
  $self->{rank}=shift;
}

=head2 get_match_type

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_match_type {
  my $self=shift;
  return $self->{match_type};

}

=head2 set_match_type

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_match_type {
  my $self=shift;
  $self->{match_type}=shift;
}

=head2 get_headline

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_headline {
  my $self=shift;
  return $self->{headline};

}

=head2 set_headline

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_headline {
  my $self=shift;
  $self->{headline}=shift;
}

=head2 get_locus_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_locus_id {
  my $self=shift;
  return $self->{locus_id};

}

=head2 set_locus_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_locus_id {
  my $self=shift;
  $self->{locus_id}=shift;
}

=head2 get_pub_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_pub_id {
  my $self=shift;
  return $self->{pub_id};

}

=head2 set_pub_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_pub_id {
  my $self=shift;
  $self->{pub_id}=shift;
}


=head2 add_locus_pub_rank

 Usage: $self->add_locus_pub_rank() . optional argument pub_id will rank loci only against this publication.
 Desc:   take the locus name, symbol, and synonyms and find associated publications 
         by using a text indexing vector.
 Ret:    hash of match_types and number of inserted rows. 
 Args:  [optional : $pub_id ]
 Side Effects: for each matching publication (see Chado::Publication::get_abstract_rank and get_title_rank)
               calling $self->do_insert(match_type, @publications) which stores a new LocusRanking
 Example:

=cut

sub add_locus_pub_rank {
    my $locus=shift;
    my $pub_id = shift;
    my $locus_id = $locus->get_locus_id();
    
    my $self=CXGN::Phenome::Locus::LocusRanking->new($locus->get_dbh(), $locus_id, undef); #a new empty object for storing the new locus_pub_rank
    my %locus_pub=(); #hash for storing number of inserts per match_type
    print STDERR "LocusRank.pm::add_locus_pub_rank found locus_id: $locus_id, pub_id: $pub_id\n\n";
    my $name = CXGN::Tools::Tsearch::process_string($locus->get_locus_name());
    my $symbol=CXGN::Tools::Tsearch::process_string($locus->get_locus_symbol(), 1);
    my $activity = CXGN::Tools::Tsearch::process_string($locus->get_gene_activity());
    my $desc = CXGN::Tools::Tsearch::process_string($locus->get_description());
    
    my @aliases=$locus->get_locus_aliases('f', 'f');
    my @synonyms;
    foreach my $a(@aliases) {
	my $synonym=CXGN::Tools::Tsearch::process_string($a->get_locus_alias(), 1);
	if (length($synonym) >1 ) {  push @synonyms, $synonym; }
    }
    my $syn_str = join('|', @synonyms);
   
    print STDERR "*!*! LocusRanking.pm found name $name , symbol $symbol, synonym string $syn_str!\n ";
    if (length($name) > 1) {
	my $name_abstract= CXGN::Chado::Publication::get_pub_rank($locus->get_dbh(), $name, 'abstract', $pub_id);
	$locus_pub{name_abstract}= $self->do_insert('name_abstract', $name_abstract) if $name_abstract;
	
	my $name_title= CXGN::Chado::Publication::get_pub_rank($locus->get_dbh(), $name, 'title', $pub_id);
	$locus_pub{name_title}=$self->do_insert('name_title', $name_title) if $name_title;
    }
    if (length($symbol) >1) {
	my $symbol_abstract= CXGN::Chado::Publication::get_pub_rank($locus->get_dbh(), $symbol, 'abstract', $pub_id);
	$locus_pub{symbol_abstract}=$self->do_insert('symbol_abstract', $symbol_abstract) if $symbol_abstract;
	
	my $symbol_title= CXGN::Chado::Publication::get_pub_rank($locus->get_dbh(), $symbol, 'title', $pub_id);
	$locus_pub{symbol_title}=$self->do_insert('symbol_title', $symbol_title) if $symbol_title;
    }
    if ($syn_str) {
	my $synonym_abstract= CXGN::Chado::Publication::get_pub_rank($locus->get_dbh(), $syn_str, 'abstract',$pub_id);
	$locus_pub{synonym_abstract}=$self->do_insert('synonym_abstract', $synonym_abstract) if $synonym_abstract;
	
	my $synonym_title= CXGN::Chado::Publication::get_pub_rank($locus->get_dbh(), $syn_str, 'title', $pub_id);
	$locus_pub{synonym_title}=$self->do_insert('synonym_title', $synonym_title) if $synonym_title;
    }

    if (length($activity) >1) {
	my $act_abstract= CXGN::Chado::Publication::get_pub_rank($locus->get_dbh(), $activity, 'abstract', $pub_id);
	$locus_pub{activity_abstract}=$self->do_insert('activity_abstract', $act_abstract) if $act_abstract;
	
	my $act_title= CXGN::Chado::Publication::get_pub_rank($locus->get_dbh(), $activity, 'title', $pub_id);
	$locus_pub{activity_title}=$self->do_insert('activity_title', $act_title) if $act_title;
    }
    if (length($desc) >1) {
	my $desc_abstract= CXGN::Chado::Publication::get_pub_rank($locus->get_dbh(), $desc, 'abstract', $pub_id);
	$locus_pub{description_abstract}=$self->do_insert('description_abstract', $desc_abstract) if $desc_abstract;
	
	my $desc_title= CXGN::Chado::Publication::get_pub_rank($locus->get_dbh(), $desc, 'title', $pub_id);
	$locus_pub{description_title}=$self->do_insert('description_title', $desc_title) if $desc_title;
    }
    return %locus_pub;
}


=head2 locus_pub_rank_exists

 Usage: $self->locus_pub_exists()
 Desc:   check if a locus is matched with a pub 
 Ret:   number of times the match occurs
 Args:   none
 Side Effects: none
 Example:

=cut

sub locus_pub_rank_exists {
    my $self=shift;
    my $query = "SELECT count(*)  FROM phenome.locus_pub_ranking WHERE locus_id = ? AND pub_id = ? AND match_type= ?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id(), $self->get_pub_id(), $self->get_match_type());
    my ($result) = $sth->fetchrow_array();
    #print STDERR "*****EXISTS IN DATABASE... locus_id = " . $self->get_locus_id() . " pub_id= " .  $self->get_pub_id() ." match_type= " .  $self->get_match_type() . "SKIPPING!!! \n" if $result;

    return $result; 
}


###
1;#do not remove
###

