package MetadataDelete;
use Moose;
extends 'CXGN::Metadata::Dbpatch';

sub patch {

    shift->dbh->do(<<EOSQL);

SET search_path=metadata,phenome;

    GRANT delete ON  md_metadata TO web_usr;
    DROP TABLE phenotype_term;
    DROP TABLE phenome.phenotype;
EOSQL

    print "Done.\n";
    return 1;
}

1;
