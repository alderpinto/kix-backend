use warnings;

use Cwd;
use lib cwd();
use lib cwd() . '/Kernel/cpan-lib';
use lib cwd() . '/plugins';
use lib cwd() . '/scripts/test/api/Cucumber';

use LWP::UserAgent;
use HTTP::Request;
use JSON::MaybeXS qw(encode_json decode_json);
use JSON::Validator;

use Test::More;
use Test::BDD::Cucumber::StepFile;

use Data::Dumper;

use Kernel::System::ObjectManager;

$Kernel::OM = Kernel::System::ObjectManager->new();

# require our helper
require '_Helper.pl';

# require our common library
require '_StepsLib.pl';

# feature specific steps 

When qr/I query the cmdb collection of configitems$/, sub {
   ( S->{Response}, S->{ResponseContent} ) = _Get(
      Token => S->{Token},
      URL   => S->{API_URL}.'/cmdb/configitems',
   );
};

When qr/I query the cmdb collection of configitems with filter of DeplStateID (\d+)$/, sub {
   ( S->{Response}, S->{ResponseContent} ) = _Get(
      Token => S->{Token},
      URL   => S->{API_URL}.'/cmdb/configitems',
      Filter => '{"ConfigItem": {"AND": [{"Field": "CurDeplStateID","Operator": "EQ","Value": "'.$1.'"}]}}',
   );
};

When qr/I query the cmdb collection of configitems with filter in of DeplStateID (\d+)$/, sub {
   ( S->{Response}, S->{ResponseContent} ) = _Get(
      Token => S->{Token},
      URL   => S->{API_URL}.'/cmdb/configitems',
      Filter => '{"ConfigItem": {"AND": [{"Field": "CurDeplStateID","Operator": "EQ","Value": "'.$1.'"}]}}',
   );
};

When qr/I query the cmdb collection of configitems with limit (\d+)$/, sub {
   ( S->{Response}, S->{ResponseContent} ) = _Get(
      Token => S->{Token},
      URL   => S->{API_URL}.'/cmdb/configitems',
      Limit => $1,
   );
};

When qr/I query the cmdb collection of configitems with offset (\d+)$/, sub {
   ( S->{Response}, S->{ResponseContent} ) = _Get(
      Token => S->{Token},
      URL   => S->{API_URL}.'/cmdb/configitems',
      Offset => $1,
   );
};

When qr/I query the cmdb collection of configitems with limit (\d+) and offset (\d+)$/, sub {
   ( S->{Response}, S->{ResponseContent} ) = _Get(
      Token => S->{Token},
      URL   => S->{API_URL}.'/cmdb/configitems',
      Limit  => $1,
      Offset => $2,
   );
};
   
When qr/I query the cmdb collection of configitems with sorted by "(.*?)"$/, sub {
   ( S->{Response}, S->{ResponseContent} ) = _Get(
      Token => S->{Token},
      URL   => S->{API_URL}.'/cmdb/configitems',
      Sort => $1,
   );
};
   
   

