# --
# Copyright (C) 2006-2022 c.a.p.e. IT GmbH, https://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-GPL3 for license information (GPL3). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);
use vars (qw($Self));

# get ReportDefinition object
my $ReportingObject = $Kernel::OM->Get('Reporting');

#
# log tests
#

# get helper object
$Kernel::OM->ObjectParamAdd(
    'UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $Helper = $Kernel::OM->Get('UnitTest::Helper');

# create definition
my $DefinitionID = $ReportingObject->ReportDefinitionAdd(
    DataSource => 'GenericSQL',
    Name       => 'Testreport 123',
    Config     => {
        DataSource => {
            SQL => {
                any => 'SELECT id, name, change_time, change_by, create_time, create_by FROM valid'
            }
        },
        OutputFormats => {
            CSV => {
                Columns => ['id', 'name', 'valid_id']
            },
        }
    },
    UserID => 1,
);

$Self->True(
    $DefinitionID,
    'ReportDefinitionAdd()',
);

# create report
my $ReportID = $ReportingObject->ReportCreate(
    DefinitionID => $DefinitionID,
    Config   => {
        OutputFormats => ['CSV']
    },
    UserID => 1,
);

$Self->True(
    $ReportID,
    'ReportCreate()',
);

my @ResultList = $ReportingObject->ReportResultList(
    ReportID => $ReportID,
);

$Self->Is(
    scalar @ResultList,
    1,
    'ReportResultList()',
);

my %Result = $ReportingObject->ReportResultGet(
    ID => $ResultList[0],
);

$Self->Is(
    $Result{ContentType},
    'text/csv',
    'ReportResultGet() - without content',
);

%Result = $ReportingObject->ReportResultGet(
    ID             => $ResultList[0],
    IncludeContent => 1,
);

$Self->True(
    $Result{Content},
    'ReportResultGet() - with content',
);

my $Success = $ReportingObject->ReportResultDelete(
    ID => $ResultList[0],
);

$Self->True(
    $Success,
    'ReportResultDelete()',
);

@ResultList = $ReportingObject->ReportResultList(
    ReportID => $ReportID,
);

$Self->Is(
    scalar @ResultList,
    0,
    'ReportResultList() - after delete',
);

# cleanup is done by RestoreDatabase

1;



=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<https://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
LICENSE-GPL3 for license information (GPL3). If you did not receive this file, see

<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
