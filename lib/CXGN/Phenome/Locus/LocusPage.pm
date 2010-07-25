package CXGN::Phenome::Locus::LocusPage;

=head1 NAME

CXGN::Phenome::Locus::LocusPage - a module that implements dynamic javascript printing of SGN locus page components.

=head1 DESCRIPTION

   Basically this module is used for printing <script> tags and calling js functions in jslib/CXGN/Phenome/Locus/LocusPage.js
   It should be used by calling first initialize($locus_id) , which will instantiate a new javascript LocusPage object.

=head1 AUTHOR(S)

Naama Menda <nm249@cornell.edu>

=head1 METHODS



=cut

use strict;
use warnings;

use JSON;
use CXGN::DB::Object;
use CXGN::Phenome::Locus;

use base qw | CXGN::DB::Object |;


=head2 unobsolete_evidence

 Usage: CXGN::Phenome::Locus::LocusPage::unobsolete_evidence($locus_dbxref_evidence_id)
 Desc:  print a form for unobsoleting locus ontology evidence 
 Ret:   html
 Args:  locusgroup_dbxref_evidence_id
 Side Effects: none
 Example:

=cut

sub unobsolete_evidence {
    my $id=shift;
    
    return <<JAVASCRIPT;
    <a href="javascript:locusPage.unobsoleteAnnotEv('locus','$id')">[unobsolete]</a>
	<div id='unobsoleteAnnotationForm' style="display: none">
	<div id='ev_dbxref_id_hidden'>
	<input type="hidden" 
	value=$id
	id="$id">
	</div>
	</div>
JAVASCRIPT

}

=head2 obsolete_evidence

 Usage: CXGN::Phenome::Locus::LocusPage::obsolete_evidence($locus_dbxref_evidence_id)
 Desc:  print a form for obsoleting locus ontology evidence 
 Ret:   html
 Args:  locusgroup_dbxref_evidence_id
 Side Effects: none
 Example:

=cut

sub obsolete_evidence {
    my $id=shift;
    
    return <<JAVASCRIPT;
    <a href="javascript:locusPage.obsoleteAnnotEv('locus','$id')">[delete]</a>
	<div id='obsoleteAnnotationForm' style="display: none">
	<div id='ev_dbxref_id_hidden'>
	<input type="hidden" 
	value=$id
	id="$id">
	</div>
	</div>
JAVASCRIPT

}


sub include_locus_unigenes {
    
       
return <<JAVASCRIPT;

<table><tr><td><div id=\"locus_unigenes\" >\[loading...\]</div>
</td></tr></table>

   <script language="javascript" type="text/javascript">
    
    locusPage.printLocusUnigenes(); 

</script>  

JAVASCRIPT

}
  
=head2 obsolete_locus_unigene

 Usage: CXGN::Phenome::Locus::LocusPage::obsolete_locus_unigene($locus_unigene_id)
 Desc:  print a form for obsoleting a locus-unigene association
 Ret:   html
 Args:  locus_unigene_id
 Side Effects: none
 Example:

=cut

sub obsolete_locus_unigene {
    my $lu_id=shift;
    
    return <<JAVASCRIPT;
    <a href="javascript:locusPage.obsoleteLocusUnigene('$lu_id')">[Remove]</a>
	<div id='obsoleteLocusUnigeneForm' style="display: none">
	<div id='locus_unigene_id_hidden'>
	<input type="hidden"  value=$lu_id id="$lu_id"> </div></div>
    
JAVASCRIPT


}

##############
return 1;#####
##############
