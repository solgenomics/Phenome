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

=head2 init_locus_form

 Usage:        CXGN::Phenome::Locus::LocusPage->init_locus_form()
 Desc:         includes a locus details editable form on the respective page
               by including its javascript code
 Ret:          nothing
 Args:         locus_id
 Side Effects: prints the  code to STDOUT
 Example:

=cut

sub init_locus_form {
    my $locus_id = shift || 0;
    my $script= "/jsforms/locus_ajax_form.pl";
    return <<JAVASCRIPT;
    <div id="locus_details_buttons">[loading edit links...]</div>
    <div id="locus_details">[loading...]</div>

  <script language="javascript" type="text/javascript">
	var locusForm = new CXGN.Page.Form.JSFormPage(
            $locus_id
           , 'locus'
           , '/jsforms/locus_ajax_form.pl'
           , 'locus_details'
           , 'locusForm'
           , '/phenome/locus_display.pl'
        );
    locusForm.render();
  </script>
JAVASCRIPT


}



=head2 associate_locus_form

 Usage: CXGN::Phenome::Locus::LocusPage::associate_locus_form($locus_id);
 Desc:  print an html form for associateing loci
 Ret:   html
 Args: locus_id
 Side Effects:  none
 Example:

=cut

sub associate_locus_form {
    my $locus_id=shift;
  
    return <<JAVASCRIPT;
 
      	<div id='associateLocusForm' style="display: none">
        <div id='locus_search'>
	<input type="text" 
	               style="width: 50%"
		       id="locus_input"
		       onkeyup="Tools.getLoci(this.value, $locus_id)" />
	<select id = "organism_select"  onchange="Tools.getLoci( MochiKit.DOM.getElement('locus_input').value, $locus_id)"> 
	</select> 

	<input type="button"
		       id="associate_locus_button"
		       value="Associate locus"
		       disabled="true"
		       onclick="locusPage.associateLocus('$locus_id');this.disabled=true;" />	
		 <select id="locus_select"
 	                style="width: 100%"
 			name="locus_select"
			size=10 
			onchange="Locus.getLocusRelationship()">
		 </select>
		
		<b>Relationship type:</b>
		<select id="locus_relationship_select" style="width: 100%"
		onchange="Locus.getLocusEvidenceCode()">
		</select>
		<b>Evidence code:</b>
		<select id="locus_evidence_code_select" style="width: 100%"
		onchange="Locus.getLocusReference('$locus_id');MochiKit.DOM.getElement('associate_locus_button').disabled=false">
		</select>	
		<b>Reference:</b>
		<select id="locus_reference_select" style="width: 100%">
		</select>	
		
		</div>
  	</div>

JAVASCRIPT

}



=head2 obsolete_locusgroup_member

 Usage: CXGN::Phenome::Locus::LocusPage::obsolete_locusgroup_member($lgm_id)
 Desc:  print a form for obsoleting a locus group member
 Ret:   html
 Args:  locusgroup_member_id
 Side Effects: none
 Example:

=cut

sub obsolete_locusgroup_member {
    my $lgm_id=shift;
    
    return <<JAVASCRIPT;
    <a href="javascript:locusPage.obsoleteLocusgroupMember('$lgm_id')">[Remove]</a>
	<div id='obsoleteLocusgroupMemberForm' style="display: none">
	<div id='lgm_id_hidden'>
	<input type="hidden"  value=$lgm_id id="$lgm_id"> </div></div>
    
JAVASCRIPT


}

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

=head2 associate_ontology_form

 Usage: CXGN::Phenome::Locus::LocusPage::associate_ontology_form();
 Desc:  print an html form for associateing loci
 Ret:   html
 Args: none
 Side Effects:  none
 Example:

=cut

sub associate_ontology_form {
    my $locus_id=shift;
  
    return <<JAVASCRIPT;
    <div id='associateOntologyForm' style="display: none">
	<div id='ontology_search'>
	   	    
	    Ontology term:
	        <input type="text" 
		       style="width: 50%"
		       id="ontology_input"
		       onkeyup="Tools.getOntologies(this.value)">
	        <select id = "cv_select" onchange="Tools.getOntologies(MochiKit.DOM.getElement('ontology_input').value)">
		       <option value="GO">GO (gene ontology)</option>
	               <option value="PO">PO (plant ontology)</option>
		       <option value="SP">SP (Solanaceae phenotypes)</option>
		</select><br>
	        
		<select id="ontology_select"
	                style="width: 100%"
			name="ontology_select"
			size=10 
			onchange="Tools.getRelationship()">
		</select>

                 Click <a href="javascript:Locus.getCvtermsList('$locus_id')">here</a> to see suggested term list 
	    </div>
		     
	    <div id="cvterm_list" style="display: none">
	          <select id="cvterm_list_select"
	                style="width: 100%" size=10 
			onfocus="Tools.getRelationship()">
		  </select>

		Click <a href="javascript:Locus.searchCvterms()">here</a> to go back to ontology term search
            </div>

	    <div id ="ontology_evidence">	

		<b>Relationship type:</b>
		<select id="relationship_select" style="width: 100%"
		onchange="Tools.getEvidenceCode()">
		</select>
		<b>Evidence code:</b>
		<select id="evidence_code_select" style="width: 100%"
		onchange="Tools.getEvidenceDescription();Locus.getEvidenceWith('$locus_id');Locus.getReference('$locus_id')">
		</select>
		
		<b>Evidence description:</b>
		<select id="evidence_description_select" style="width: 100%">
		</select>

		<b>Evidence with:</b>
		<select id="evidence_with_select" style="width: 100%">
		</select>
		
		<b>Reference:</b>
		<select id="reference_select" style="width: 100%">
		</select>
		<div id="ontology_select_button"> 
		<input type="button"
		       id="associate_ontology_button"
		       value="associate ontology"
		       disabled="true"
		       onclick="locusPage.associateOntology('$locus_id');this.disabled=true;">
	        </div>
	      </div>
  	</div>
JAVASCRIPT
}

  

=head2 include_locus_newtwork

 Usage:        CXGN::Phenome::Locus::LocusPage->include_locus_network()
 Desc:         includes the locus network section  on the respective page
               by including its javascript code
 Ret:          nothing
 Args:         none
 Side Effects: prints the  code to STDOUT
 Example:

=cut

sub include_locus_unigenes {
    
       
return <<JAVASCRIPT;

<table><tr><td><div id=\"locus_unigenes\" >\[loading...\]</div>
</td></tr></table>

   <script language="javascript" type="text/javascript">
    
    locusPage.printLocusUnigenes(); 

</script>  

JAVASCRIPT

}
  

=head2 associate_unigene_form

 Usage: CXGN::Phenome::Locus::LocusPage::associate_unigene_form($locus_id) 
 Desc:  print and 'associate unigene' form 
 Ret:   javascript div
 Args:  locus_id
 Side Effects:
 Example:

=cut

sub associate_unigene_form {
    my $locus_id=shift;
    
    return <<JAVASCRIPT;
	<div id='associateUnigeneForm' style="display:none">
            <div id='unigene_search'>
	        Unigene ID:
	        <input type="text" 
		        style="width: 50%"
		       id="unigene_input"
		       onkeyup="locusPage.getUnigenes(this.value, $locus_id)">
		<input type="button"
	               id="associate_unigene_button"
		       value="associate unigene"
                       disabled="true"
		       onclick="locusPage.associateUnigene('$locus_id');this.disabled=false;">
		 
	        <select id="unigene_select"
		        style="width: 100%"
			onchange= "Tools.enableButton('associate_unigene_button');"
			size=5> 
			
		</select>
 	      </div>
	   </div>

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

=head2 include_solcyc_links

 Usage:        CXGN::Phenome::Locus::LocusPage->include_solcyc_links()
 Desc:         includes the solcyc links section  on the respective page
               by including its javascript code
 Ret:          nothing
 Args:         none
 Side Effects: prints the  code to STDOUT
 Example:

=cut

sub include_solcyc_links {

        
return <<JAVASCRIPT;

<table><tr><td><div id=\"solcyc_links\" >\[loading...\]</div>
</td></tr></table>

   <script language="javascript" type="text/javascript">
    
    locusPage.printSolcycLinks(); 

</script>  

JAVASCRIPT

}


##############
return 1;#####
##############
