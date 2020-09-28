use utf8;
package CXGN::Phenome::Schema::PolymorphicFragment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::PolymorphicFragment

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<polymorphic_fragment>

=cut

__PACKAGE__->table("polymorphic_fragment");

=head1 ACCESSORS

=head2 polymorphic_fragment_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'polymorphic_fragment_polymorphic_fragment_id_seq'

=head2 phenome_genotype_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 flanking_marker1_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 flanking_marker2_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 zygocity

  data_type: 'varchar'
  is_nullable: 1
  size: 15

=head2 linkage_group

  data_type: 'text'
  is_nullable: 1

=head2 type

  data_type: 'text'
  is_nullable: 1

=head2 sp_person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 modified_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "polymorphic_fragment_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "polymorphic_fragment_polymorphic_fragment_id_seq",
  },
  "phenome_genotype_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "flanking_marker1_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "flanking_marker2_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "zygocity",
  { data_type => "varchar", is_nullable => 1, size => 15 },
  "linkage_group",
  { data_type => "text", is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 1 },
  "sp_person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "create_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</polymorphic_fragment_id>

=back

=cut

__PACKAGE__->set_primary_key("polymorphic_fragment_id");

=head1 RELATIONS

=head2 phenome_genotype_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::PhenomeGenotype>

=cut

__PACKAGE__->belongs_to(
  "phenome_genotype_id",
  "CXGN::Phenome::Schema::PhenomeGenotype",
  { phenome_genotype_id => "phenome_genotype_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-09-15 17:55:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gB82S89ggZ7YVPaO9Cp1gg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
