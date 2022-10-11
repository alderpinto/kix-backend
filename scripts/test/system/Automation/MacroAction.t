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

use vars (qw($Self));

# get MacroAction object
my $AutomationObject = $Kernel::OM->Get('Automation');

#
# MacroAction tests
#

# get helper object
$Kernel::OM->ObjectParamAdd(
    'UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $Helper = $Kernel::OM->Get('UnitTest::Helper');

my $NameRandom  = $Helper->GetRandomID();
my %MacroActions = (
    'test-macroaction-' . $NameRandom . '-1' => {
        Type => 'TitleSet',
        NewType => 'StateSet',
        Parameters => {
            Title => 'test',
        }
    },
    'test-macroaction-' . $NameRandom . '-2' => {
        Type => 'StateSet',
        Parameters => {
            State => 'open',
        }
    },
    'test-macroaction-' . $NameRandom . '-3' => {
        Type => 'PrioritySet',
        Parameters => {
            Priority => '3 normal'
        }
    },
);

# create macro
my $MacroID = $AutomationObject->MacroAdd(
    Name    => 'test-macro-' . $NameRandom,
    Type    => 'Ticket',
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $MacroID,
    'MacroAdd() for new macro.',
);

# try to add macroactions
for my $Name ( sort keys %MacroActions ) {
    my $MacroActionID = $AutomationObject->MacroActionAdd(
        MacroID => $MacroID,
        Type    => $MacroActions{$Name}->{Type},
        Parameters => $MacroActions{$Name}->{Parameters},
        ValidID => 1,
        UserID  => 1,
    );

    $Self->True(
        $MacroActionID,
        'MacroActionAdd() for new macro action ' . $Name,
    );

    if ($MacroActionID) {
        $MacroActions{$Name}->{ID} = $MacroActionID;
    }
    my %MacroAction = $AutomationObject->MacroActionGet( 
        ID => $MacroActionID 
    );

    $Self->Is(
        $MacroAction{Type},
        $MacroActions{$Name}->{Type},
        'MacroActionGet() for macro action ' . $Name,
    );
}

# list MacroActions
my %MacroActionList = $AutomationObject->MacroActionList(
    MacroID => $MacroID
);
for my $Name ( sort keys %MacroActions ) {
    my $MacroActionID = $MacroActions{$Name}->{ID};

    $Self->True(
        exists $MacroActionList{$MacroActionID} && $MacroActionList{$MacroActionID} eq $MacroActions{$Name}->{Type},
        'MacroActionList() contains macro action ' . $Name . ' with ID ' . $MacroActionID,
    );
}

# change type of a single MacroAction
my $NameToChange = 'test-macroaction-' . $NameRandom . '-1';
my $IDToChange   = $MacroActions{$NameToChange}->{ID};

my $MacroActionUpdateResult = $AutomationObject->MacroActionUpdate(
    ID      => $IDToChange,
    Type    => $MacroActions{$NameToChange}->{NewType},
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $MacroActionUpdateResult,
    'MacroActionUpdate() for changing type of macro action ' . $NameToChange . ' to ' . $MacroActions{$NameToChange}->{NewType},
);

# update parameters of a single MacroAction
$MacroActionUpdateResult = $AutomationObject->MacroActionUpdate(
    ID      => $IDToChange,
    Type    => $MacroActions{$NameToChange}->{NewType},
    Parameters => {
        State => 'new'
    },
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $MacroActionUpdateResult,
    'MacroActionUpdate() for changing parameters of macro action.',
);

my %MacroAction = $AutomationObject->MacroActionGet( ID => $IDToChange );

$Self->True(
    $MacroAction{Parameters},
    'MacroActionGet() for macro action with parameters.',
);

# delete an existing macroaction
my $MacroActionDelete = $AutomationObject->MacroActionDelete(
    ID      => $IDToChange,
    UserID  => 1,
);

$Self->True(
    $MacroActionDelete,
    'MacroActionDelete() delete existing macroaction',
);

# delete a non existent macroaction
$MacroActionDelete = $AutomationObject->MacroActionDelete(
    ID      => 9999,
    UserID  => 1,
);

$Self->False(
    $MacroActionDelete,
    'MacroActionDelete() delete non existent macroaction',
);

# check variable replacement
my @Tests = (
    {
        Name => 'simple',
        MacroResults => {
            Test1 => 'test1_value',
        },
        Data => {
            Dummy => '${Test1}',
        },
        Expected => {
            Dummy => 'test1_value',
        }
    },
    {
        Name => 'simple as part of a string',
        MacroResults => {
            Test1 => 'test1_value',
        },
        Data => {
            Dummy => '${Test1}/dummy',
        },
        Expected => {
            Dummy => 'test1_value/dummy',
        }
    },
    {
        Name => 'array',
        MacroResults => {
            Test1 => [
                1,2,3
            ]
        },
        Data => {
            Dummy => '${Test1:1}',
        },
        Expected => {
            Dummy => '2',
        }
    },
    {
        Name => 'hash',
        MacroResults => {
            Test1 => {
                Test2 => 'test2'
            }
        },
        Data => {
            Dummy => '${Test1.Test2}',
        },
        Expected => {
            Dummy => 'test2',
        }
    },
    {
        Name => 'array of hashes with arrays of hashes',
        MacroResults => {
            Test1 => [
                {},
                {
                    Test2 => [
                        {
                            Test3 => 'test3'
                        }
                    ]
                }
            ]
        },
        Data => {
            Dummy => '${Test1:1.Test2:0.Test3}',
        },
        Expected => {
            Dummy => 'test3',
        }
    },
    {
        Name => 'array of hashes with arrays of hashes in text',
        MacroResults => {
            Test1 => [
                {},
                {
                    Test2 => [
                        {
                            Test3 => 'test'
                        }
                    ]
                }
            ]
        },
        Data => {
            Dummy => 'this is a ${Test1:1.Test2:0.Test3}. a good one',
        },
        Expected => {
            Dummy => 'this is a test. a good one',
        }
    },
    {
        Name => 'array of hashes with arrays of hashes direct assignment of structure',
        MacroResults => {
            Test1 => [
                {},
                {
                    Test2 => [
                        {
                            Test3 => 'test'
                        }
                    ]
                }
            ]
        },
        Data => {
            Dummy => '${Test1:1.Test2}',
        },
        Expected => {
            Dummy => [
                {
                    Test3 => 'test'
                }
            ]
        }
    },
    {
        Name => 'nested variables (2 levels)',
        MacroResults => {
            Test1 => {
                Test2 => {
                    Test3 => 'found!'
                }
            },
            Indexes => {
                '1st' => 'Test2',
                '2nd' => 'Test3'
            }
        },
        Data => {
            Dummy => '${Test1.${Indexes.1st}.${Indexes.2nd}}',
        },
        Expected => {
            Dummy => 'found!'
        }
    },
    {
        Name => 'nested variables (4 levels)',
        MacroResults => {
            Test1 => {
                Test2 => {
                    Test3 => 'found!'
                }
            },
            Indexes => {
                '1st' => 'Test2',
                '2nd' => 'Test3'
            },
            Which => {
                'the first one' => '1st',
                Index => {
                    Should => {
                        I => {
                            Use => [
                                'none',
                                '2nd',
                                'the first one',
                                '3rd'
                            ]
                        }
                    }
                }
            },
        },
        Data => {
            Dummy => '${Test1.${Indexes.${Which.${Which.Index.Should.I.Use:2}}}.${Indexes.2nd}}',
        },
        Expected => {
            Dummy => 'found!'
        }
    },
);

my $TestCount = 0;
foreach my $Test ( @Tests ) {
    $TestCount++;

    $AutomationObject->{MacroResults} = $Test->{MacroResults};

    my %Data = %{$Test->{Data}};

    $AutomationObject->_ReplaceResultVariables(
        Data => \%Data,
    );

    $Self->IsDeeply(
        \%Data,
        $Test->{Expected},
        '_ReplaceResultVariables() Test "'.$Test->{Name}.'"',
    );
}

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
