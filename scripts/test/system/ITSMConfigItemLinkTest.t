# --
# Modified version of the work: Copyright (C) 2006-2022 c.a.p.e. IT GmbH, https://www.cape-it.de
# based on the original work of:
# Copyright (C) 2001-2017 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-AGPL for license information (AGPL). If you
# did not receive this file, see https://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars qw($Self);

# get needed objects
my $ConfigObject         = $Kernel::OM->Get('Config');
my $GeneralCatalogObject = $Kernel::OM->Get('GeneralCatalog');
my $ConfigItemObject     = $Kernel::OM->Get('ITSMConfigItem');
my $LinkObject           = $Kernel::OM->Get('LinkObject');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $Helper = $Kernel::OM->Get('UnitTest::Helper');

# define needed variable
my $RandomID = $Helper->GetRandomID();

my $ConfigItemName = 'UnitTestConfigItemTest' . $RandomID;

my @ConfigItemIDs;

my $CheckExpectedResults = sub {

    # get parameters
    my (%Param) = @_;

    my %ExpectedIncidentStates = %{ $Param{ExpectedIncidentStates} };
    my %ObjectNameSuffix2ID    = %{ $Param{ObjectNameSuffix2ID} };

    # check the results
    for my $Object ( sort keys %ExpectedIncidentStates ) {

        if ( $Object eq 'ITSMConfigItem' ) {

            for my $NameSuffix ( sort keys %{ $ExpectedIncidentStates{$Object} } ) {

                # get config item data
                my $ConfigItem = $ConfigItemObject->ConfigItemGet(
                    ConfigItemID => $ObjectNameSuffix2ID{$Object}->{$NameSuffix},
                );

                # check the result
                $Self->Is(
                    $ConfigItem->{CurInciState},
                    $ExpectedIncidentStates{$Object}->{$NameSuffix},
                    "Check incident state of config item $NameSuffix.",
                );
            }
        }
    }

    return 1;
};

# get class list
my $ClassList = $GeneralCatalogObject->ItemList(
    Class => 'ITSM::ConfigItem::Class',
);
my %ClassListReverse = reverse %{$ClassList};

# get deployment state list
my $DeplStateList = $GeneralCatalogObject->ItemList(
    Class => 'ITSM::ConfigItem::DeploymentState',
);
my %DeplStateListReverse = reverse %{$DeplStateList};

# get incident state list
my $InciStateList = $GeneralCatalogObject->ItemList(
    Class => 'ITSM::Core::IncidentState',
);
my %InciStateListReverse = reverse %{$InciStateList};

# get definition for 'Hardware' class
my $DefinitionRef = $ConfigItemObject->DefinitionGet(
    ClassID => $ClassListReverse{Hardware},
);

my %ObjectNameSuffix2ID;

# create config items
for my $NameSuffix ( 1 .. 7, qw(A B C D E F G) ) {

    # add a configitem
    my $ConfigItemID = $ConfigItemObject->ConfigItemAdd(
        ClassID => $ClassListReverse{Hardware},
        UserID  => 1,
    );

    $Self->True(
        $ConfigItemID,
        "Added configitem id $ConfigItemID.",
    );

    # remember the config item id
    $ObjectNameSuffix2ID{ITSMConfigItem}->{$NameSuffix} = $ConfigItemID;

    push @ConfigItemIDs, $ConfigItemID;

    # set a name for each configitem
    my $VersionID = $ConfigItemObject->VersionAdd(
        ConfigItemID => $ConfigItemID,
        Name         => $ConfigItemName . '_Hardware_' . $NameSuffix,
        DefinitionID => $DefinitionRef->{DefinitionID},
        DeplStateID  => $DeplStateListReverse{Production},
        InciStateID  => $InciStateListReverse{Operational},
        XMLData      => [
            undef,
            {
                Version => [
                    undef,
                    {
                        Vendor => [
                            undef,
                            {
                                Content => 'TestVendor',
                            },
                        ],
                    },
                ],
            },
        ],
        UserID => 1,
    );

    $Self->True(
        $VersionID,
        "Added a version for the configitem id $ConfigItemID",
    );
}

# read the original setting for IncidentLinkTypeDirection
my $OrigIncidentLinkTypeDirectionSetting = $ConfigObject->Get('ITSM::Core::IncidentLinkTypeDirection');

# set new config for IncidentLinkTypeDirection
$ConfigObject->Set(
    Key   => 'ITSM::Core::IncidentLinkTypeDirection',
    Value => {
        DependsOn => 'Source',
        Includes  => 'Source',
    },
);

# ################################################################################################################
#                                            Link Diagram
# ################################################################################################################
#
#
#
#                     6                         Service 1
#                     |                             ^
#                     |                             |
#                     |                             |
#                     v                             |
#         C <******** 5 ------> 4 ------> 3 ------> 1 *********> A *******> F **********> G
#         *           ^                   |                      ^          ^
#         *           |                   |                      *          *
#         *           |                   |                      *          *
#         *           |                   |                      *          *
#         *           |                   |         B            *          *
#         *           |                   |         *            *          *
#         *           |                   |         *            *          *
#         *           |                   |         *            *          *
#         v           |                   |         v            *          *
#         D ********> 7                   +-------> 2 ************          E
#                                                   ^
#                                                   |
#                                                   |
#                                                   |
#                                                Service 2
#
#
#
#
#  Explanation:
#               1 .. 7 and A .. G are ITSMConfigItems
#
#               DependsOn Links are shown as ----->
#               Includes  Links are shown as *****>
#
# ################################################################################################################

# define the links between CIs and Services
my %Links = (
    DependsOn => {
        ITSMConfigItem => {
            '7' => {
                ITSMConfigItem => ['5'],
            },
            '6' => {
                ITSMConfigItem => ['5'],
            },
            '5' => {
                ITSMConfigItem => ['4'],
            },
            '4' => {
                ITSMConfigItem => ['3'],
            },
            '3' => {
                ITSMConfigItem => [ '1', '2' ],
            },
            '1' => {
                Service => ['1'],
            },
        },
        Service => {
            '2' => {
                ITSMConfigItem => ['2'],
                }
        },
    },
    Includes => {
        ITSMConfigItem => {
            '5' => {
                ITSMConfigItem => ['C'],
            },
            'C' => {
                ITSMConfigItem => ['D'],
            },
            'D' => {
                ITSMConfigItem => ['7'],
            },
            'B' => {
                ITSMConfigItem => ['2'],
            },
            '2' => {
                ITSMConfigItem => ['A'],
            },
            '1' => {
                ITSMConfigItem => ['A'],
            },
            'A' => {
                ITSMConfigItem => ['F'],
            },
            'F' => {
                ITSMConfigItem => ['G'],
            },
            'E' => {
                ITSMConfigItem => ['F'],
            },
        },
    },
);

# link the config items and services as shown in the diagram
for my $LinkType ( sort keys %Links ) {
    for my $TargetObject ( sort keys %{ $Links{$LinkType} } ) {
        for my $TargetKey ( sort keys %{ $Links{$LinkType}->{$TargetObject} } ) {
            for my $SourceObject ( sort keys %{ $Links{$LinkType}->{$TargetObject}->{$TargetKey} } )
            {
                for my $SourceKey (
                    @{ $Links{$LinkType}->{$TargetObject}->{$TargetKey}->{$SourceObject} }
                    )
                {

                    # add the links
                    my $Success = $LinkObject->LinkAdd(
                        SourceObject => $SourceObject,
                        SourceKey    => $ObjectNameSuffix2ID{$SourceObject}->{$SourceKey},
                        TargetObject => $TargetObject,
                        TargetKey    => $ObjectNameSuffix2ID{$TargetObject}->{$TargetKey},
                        Type         => $LinkType,
                        State        => 'Valid',
                        UserID       => 1,
                    );

                    $Self->True(
                        $Success,
                        "LinkAdd() - $SourceObject:$SourceKey linked with $TargetObject:$TargetKey with LinkType '$LinkType'.",
                    );
                }
            }
        }
    }
}

# ------------------------------------------------------------ #
# set CI6 to "Incident" and check the results
# ------------------------------------------------------------ #

{

    my $NameSuffix    = 6;
    my $IncidentState = 'Incident';

    # change incident state
    my $VersionID = $ConfigItemObject->VersionAdd(
        ConfigItemID => $ObjectNameSuffix2ID{ITSMConfigItem}->{$NameSuffix},
        Name         => $ConfigItemName . '_Hardware_' . $NameSuffix,
        DefinitionID => $DefinitionRef->{DefinitionID},
        DeplStateID  => $DeplStateListReverse{Production},
        InciStateID  => $InciStateListReverse{$IncidentState},
        UserID       => 1,
    );

    $Self->True(
        $VersionID,
        "Set config item id $NameSuffix to state '$IncidentState'.",
    );

    $CheckExpectedResults->(
        ExpectedIncidentStates => {
            ITSMConfigItem => {
                '1' => 'Warning',
                '2' => 'Warning',
                '3' => 'Warning',
                '4' => 'Warning',
                '5' => 'Warning',
                '6' => 'Incident',
                '7' => 'Operational',
                'A' => 'Operational',
                'B' => 'Operational',
                'C' => 'Operational',
                'D' => 'Operational',
                'E' => 'Operational',
                'F' => 'Operational',
                'G' => 'Operational',
            },
            Service => {
                '1' => 'Warning',
                '2' => 'Operational',
            },
        },
        ObjectNameSuffix2ID => \%ObjectNameSuffix2ID,
    );

}

# ------------------------------------------------------------ #
# set CI6 back to "Operational" and check the results
# ------------------------------------------------------------ #

{

    my $NameSuffix    = 6;
    my $IncidentState = 'Operational';

    # change incident state
    my $VersionID = $ConfigItemObject->VersionAdd(
        ConfigItemID => $ObjectNameSuffix2ID{ITSMConfigItem}->{$NameSuffix},
        Name         => $ConfigItemName . '_Hardware_' . $NameSuffix,
        DefinitionID => $DefinitionRef->{DefinitionID},
        DeplStateID  => $DeplStateListReverse{Production},
        InciStateID  => $InciStateListReverse{$IncidentState},
        UserID       => 1,
    );

    $Self->True(
        $VersionID,
        "Set config item id $NameSuffix to state '$IncidentState'.",
    );

    $CheckExpectedResults->(
        ExpectedIncidentStates => {
            ITSMConfigItem => {
                '1' => 'Operational',
                '2' => 'Operational',
                '3' => 'Operational',
                '4' => 'Operational',
                '5' => 'Operational',
                '6' => 'Operational',
                '7' => 'Operational',
                'A' => 'Operational',
                'B' => 'Operational',
                'C' => 'Operational',
                'D' => 'Operational',
                'E' => 'Operational',
                'F' => 'Operational',
                'G' => 'Operational',
            },
            Service => {
                '1' => 'Operational',
                '2' => 'Operational',
            },
        },
        ObjectNameSuffix2ID => \%ObjectNameSuffix2ID,
    );

}

# ------------------------------------------------------------ #
# set CI1 to "Incident" and check the results
# ------------------------------------------------------------ #

{

    my $NameSuffix    = 1;
    my $IncidentState = 'Incident';

    # change incident state
    my $VersionID = $ConfigItemObject->VersionAdd(
        ConfigItemID => $ObjectNameSuffix2ID{ITSMConfigItem}->{$NameSuffix},
        Name         => $ConfigItemName . '_Hardware_' . $NameSuffix,
        DefinitionID => $DefinitionRef->{DefinitionID},
        DeplStateID  => $DeplStateListReverse{Production},
        InciStateID  => $InciStateListReverse{$IncidentState},
        UserID       => 1,
    );

    $Self->True(
        $VersionID,
        "Set config item id $NameSuffix to state '$IncidentState'.",
    );

    $CheckExpectedResults->(
        ExpectedIncidentStates => {
            ITSMConfigItem => {
                '1' => 'Incident',
                '2' => 'Operational',
                '3' => 'Operational',
                '4' => 'Operational',
                '5' => 'Operational',
                '6' => 'Operational',
                '7' => 'Operational',
                'A' => 'Warning',
                'B' => 'Operational',
                'C' => 'Operational',
                'D' => 'Operational',
                'E' => 'Operational',
                'F' => 'Warning',
                'G' => 'Warning',
            },
            Service => {
                '1' => 'Incident',
                '2' => 'Operational',
            },
        },
        ObjectNameSuffix2ID => \%ObjectNameSuffix2ID,
    );

}

# ------------------------------------------------------------------------ #
# set CI5 to "Incident" and check the results (CI1 is still in "Incident")
# ------------------------------------------------------------------------ #

{

    my $NameSuffix    = 5;
    my $IncidentState = 'Incident';

    # change incident state
    my $VersionID = $ConfigItemObject->VersionAdd(
        ConfigItemID => $ObjectNameSuffix2ID{ITSMConfigItem}->{$NameSuffix},
        Name         => $ConfigItemName . '_Hardware_' . $NameSuffix,
        DefinitionID => $DefinitionRef->{DefinitionID},
        DeplStateID  => $DeplStateListReverse{Production},
        InciStateID  => $InciStateListReverse{$IncidentState},
        UserID       => 1,
    );

    $Self->True(
        $VersionID,
        "Set config item id $NameSuffix to state '$IncidentState'.",
    );

    $CheckExpectedResults->(
        ExpectedIncidentStates => {
            ITSMConfigItem => {
                '1' => 'Incident',
                '2' => 'Warning',
                '3' => 'Warning',
                '4' => 'Warning',
                '5' => 'Incident',
                '6' => 'Operational',
                '7' => 'Warning',
                'A' => 'Warning',
                'B' => 'Operational',
                'C' => 'Warning',
                'D' => 'Warning',
                'E' => 'Operational',
                'F' => 'Warning',
                'G' => 'Warning',
            },
            Service => {
                '1' => 'Incident',
                '2' => 'Operational',
            },
        },
        ObjectNameSuffix2ID => \%ObjectNameSuffix2ID,
    );

}

# -------------------------------------------------------------------------- #
# set CI1 to "Operational" and check the results (CI5 is still in "Incident")
# -------------------------------------------------------------------------- #

{

    my $NameSuffix    = 1;
    my $IncidentState = 'Operational';

    # change incident state
    my $VersionID = $ConfigItemObject->VersionAdd(
        ConfigItemID => $ObjectNameSuffix2ID{ITSMConfigItem}->{$NameSuffix},
        Name         => $ConfigItemName . '_Hardware_' . $NameSuffix,
        DefinitionID => $DefinitionRef->{DefinitionID},
        DeplStateID  => $DeplStateListReverse{Production},
        InciStateID  => $InciStateListReverse{$IncidentState},
        UserID       => 1,
    );

    $Self->True(
        $VersionID,
        "Set config item id $NameSuffix to state '$IncidentState'.",
    );

    $CheckExpectedResults->(
        ExpectedIncidentStates => {
            ITSMConfigItem => {
                '1' => 'Warning',
                '2' => 'Warning',
                '3' => 'Warning',
                '4' => 'Warning',
                '5' => 'Incident',
                '6' => 'Operational',
                '7' => 'Warning',
                'A' => 'Operational',
                'B' => 'Operational',
                'C' => 'Warning',
                'D' => 'Warning',
                'E' => 'Operational',
                'F' => 'Operational',
                'G' => 'Operational',
            },
            Service => {
                '1' => 'Warning',
                '2' => 'Operational',
            },
        },
        ObjectNameSuffix2ID => \%ObjectNameSuffix2ID,
    );

}

# -------------------------------------------------------------------------- #
# set CI5 to "Operational" and check the results
# -------------------------------------------------------------------------- #

{

    my $NameSuffix    = 5;
    my $IncidentState = 'Operational';

    # change incident state
    my $VersionID = $ConfigItemObject->VersionAdd(
        ConfigItemID => $ObjectNameSuffix2ID{ITSMConfigItem}->{$NameSuffix},
        Name         => $ConfigItemName . '_Hardware_' . $NameSuffix,
        DefinitionID => $DefinitionRef->{DefinitionID},
        DeplStateID  => $DeplStateListReverse{Production},
        InciStateID  => $InciStateListReverse{$IncidentState},
        UserID       => 1,
    );

    $Self->True(
        $VersionID,
        "Set config item id $NameSuffix to state '$IncidentState'.",
    );

    $CheckExpectedResults->(
        ExpectedIncidentStates => {
            ITSMConfigItem => {
                '1' => 'Operational',
                '2' => 'Operational',
                '3' => 'Operational',
                '4' => 'Operational',
                '5' => 'Operational',
                '6' => 'Operational',
                '7' => 'Operational',
                'A' => 'Operational',
                'B' => 'Operational',
                'C' => 'Operational',
                'D' => 'Operational',
                'E' => 'Operational',
                'F' => 'Operational',
                'G' => 'Operational',
            },
            Service => {
                '1' => 'Operational',
                '2' => 'Operational',
            },
        },
        ObjectNameSuffix2ID => \%ObjectNameSuffix2ID,
    );

}

# reset the enabled setting for IncidentLinkTypeDirection to its original value
$ConfigObject->Set(
    Key   => 'ITSM::Core::IncidentLinkTypeDirection',
    Value => $OrigIncidentLinkTypeDirectionSetting,
);

# cleanup is done by RestoreDatabase

1;



=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<https://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
LICENSE-AGPL for license information (AGPL). If you did not receive this file, see

<https://www.gnu.org/licenses/agpl.txt>.

=cut
