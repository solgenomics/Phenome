package ChadoNdChanges;
use Moose;
extends 'CXGN::Metadata::Dbpatch';

sub patch {

    shift->dbh->do(<<EOSQL);

    SET SEARCH_PATH TO public;
ALTER TABLE nd_experimentprop ALTER COLUMN value DROP NOT NULL;

ALTER TABLE nd_protocol ADD COLUMN type_id integer NOT NULL references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED;

EOSQL

    print "Done.\n";
    return 1;
}

1;
