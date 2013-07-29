use utf8;
package CXGN::Phenome::Schema::AlleleHistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::AlleleHistory

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<allele_history>

=cut

__PACKAGE__->table("allele_history");

=head1 ACCESSORS

=head2 allele_history_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'allele_history_allele_history_id_seq'

=head2 allele_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 locus_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 allele_symbol

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 allele_name

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 mode_of_inheritance

  data_type: 'varchar'
  is_nullable: 1
  size: 18

=head2 allele_phenotype

  data_type: 'text'
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 updated_by

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 sequence

  accessor: undef
  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "allele_history_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "allele_history_allele_history_id_seq",
  },
  "allele_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "locus_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "allele_symbol",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "allele_name",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "mode_of_inheritance",
  { data_type => "varchar", is_nullable => 1, size => 18 },
  "allele_phenotype",
  { data_type => "text", is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "updated_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "create_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "sequence",
  { accessor => undef, data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</allele_history_id>

=back

=cut

__PACKAGE__->set_primary_key("allele_history_id");

=head1 RELATIONS

=head2 allele_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Allele>

=cut

__PACKAGE__->belongs_to(
  "allele_id",
  "CXGN::Phenome::Schema::Allele",
  { allele_id => "allele_id" },
);

=head2 locus_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Locus>

=cut

__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GvWVfPD/zpvJJFPNQ++0+g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
