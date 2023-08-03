# --
# Copyright (C) 2006-2023 KIX Service Software GmbH, https://www.kixdesk.com 
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-GPL3 for license information (GPL3). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::API::Validator::ContentTypeValidator;

# get validator object
my $ValidatorObject = Kernel::API::Validator::ContentTypeValidator->new();

# get helper object
$Kernel::OM->ObjectParamAdd(
    'UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $Helper = $Kernel::OM->Get('UnitTest::Helper');

my $ValidData = {
    ContentType => 'text/html; charset=utf8'
};

my @InvalidDataArray = (
    {
        ContentType => 'invalid-ContentType'
    },
    {
        ContentType => "text/html; charset=utf8;\nHost: www.kixdesk.com"
    },
    {
        ContentType => 'text/html; charset=utf08'
    },
    {
        ContentType => 'text /html; charset=utf8'
    },
);

# validate valid ContentType
my $Result = $ValidatorObject->Validate(
    Attribute => 'ContentType',
    Data      => $ValidData,
);
$Self->True(
    $Result->{Success},
    'Validate() - valid ContentType',
);

# validate invalid ContentType
for my $InvalidData ( @InvalidDataArray ) {
    $Result = $ValidatorObject->Validate(
        Attribute => 'ContentType',
        Data      => $InvalidData,
    );
    $Self->False(
        $Result->{Success},
        'Validate() - invalid ContentType',
    );
}

# validate invalid attribute
$Result = $ValidatorObject->Validate(
    Attribute => 'InvalidAttribute',
    Data      => {},
);
$Self->False(
    $Result->{Success},
    'Validate() - invalid attribute',
);

# cleanup is done by RestoreDatabase.

1;



=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<https://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
LICENSE-GPL3 for license information (GPL3). If you did not receive this file, see

<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
