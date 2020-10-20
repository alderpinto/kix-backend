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

When qr/I update this user$/, sub {
   ( S->{Response}, S->{ResponseContent} ) = _Patch(
      URL     => S->{API_URL}.'/system/users/'.S->{UserID},
      Token   => S->{Token},
      Content => {
        User => {
            UserEmail => "john.doe2".rand()."\@example.com",
            UserFirstname => "John",
            UserLastname => "Doe",
            UserLogin => "jdoe".rand(),
            UserPw => "secret2".rand(),
            UserTitle => "DR.",
            ValidID => 1
        }
      }
   );
};
