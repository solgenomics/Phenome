package CXGN::Phenome::Schema::IndividualHistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::IndividualHistory

=cut

__PACKAGE__->table("individual_history");

=head1 ACCESSORS

=head2 individual_history_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'individual_history_individual_history_id_seq'

=head2 individual_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 population_id

  data_type: 'integer'
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
  is_nullable: 1

=head2 updated_by

  data_type: 'integer'
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

=cut

__PACKAGE__->add_columns(
  "individual_history_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "individual_history_individual_history_id_seq",
  },
  "individual_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "population_id",
  { data_type => "integer", is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_nullable => 1 },
  "updated_by",
  { data_type => "integer", is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "create_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("individual_history_id");

=head1 RELATIONS

=head2 individual_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Individual>

=cut

__PACKAGE__->belongs_to(
  "individual_id",
  "CXGN::Phenome::Schema::Individual",
  { individual_id => "individual_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PFEl9jfmJRAlg5uOj2Nydg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
