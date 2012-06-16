

package CXGN::Genotype::Search;

use Moose;

has 'dbh' => ( isa=>'CXGN::DB::Connection', is=>'rw' );
has 'schema' => (is => 'rw');

sub genotype_by_marker { 

    my $self = shift;
    my $marker = shift;

    # perform the query using tsvector. The StartSel and StopSel options
    # define how the match will be highlighted. We set it to the empty string
    # (no highlighting). MaxWords=6 ensures that not too much context is shown.
    # 

    my $q = "select genotype_id , ts_headline(value, q, 'StartSel=\"\", StopSel=\"\", MaxWords=6, MinWords=1, ShortWord=2' ) from genotypeprop , to_tsquery(?) q where q @@ value_tsvector";

     my $sth = $self->dbh()->prepare($q);

     $sth->execute($marker);

     my @data = ();
     while (my ($genotype_id, $ts_headline) = $sth->fetchrow_array()) { 
	 print "RAW TS_HEADLINE: $ts_headline\n";
	 if ($ts_headline =~ m/($marker)\s*\"\:\"(.*?)\".*/) { 
	     my $marker = $1;
	     my $genotype = $2;
	     push @data, [ $genotype_id, $marker, $genotype ];
	 }
     }
     return @data;
 }

 1;
