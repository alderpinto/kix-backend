#!/usr/bin/perl
# --
# Copyright (C) 2006-2022 c.a.p.e. IT GmbH, https://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE for license information (AGPL). If you
# did not receive this file, see https://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

use File::Basename;
use FindBin qw($Bin);
use lib dirname($Bin);
use lib dirname($Bin) . '/Kernel/cpan-lib';

use Kernel::System::ObjectManager;
use Kernel::System::VariableCheck qw(:all);

# create object manager
local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Log' => {
        LogPrefix => 'framework_update-to-build-1581',
    },
);

use vars qw(%INC);

# update reopen job
_UpdateReopenJob();

sub _UpdateReopenJob {
    my ( $Self, %Param ) = @_;

    my $AutomationObject = $Kernel::OM->Get('Automation');

    my $JobID = $AutomationObject->JobLookup(
        Name => 'Customer Response - reopen from pending',
    );

    if ($JobID) {
        my %Job = $AutomationObject->JobGet(
            ID => $JobID
        );

        if (
            IsHashRefWithData(\%Job) &&
            IsHashRefWithData($Job{Filter}) &&
            IsArrayRefWithData($Job{Filter}->{AND}) &&
            !(grep { $_->{Field} eq 'CreateTime' } @{$Job{Filter}->{AND}})
        ) {
            push(
                @{$Job{Filter}->{AND}},
                {Field => 'CreateTime', Operator => 'LT', Type => 'DATETIME', Value => '-5m'}
            );

            my $Result = $AutomationObject->JobUpdate(
                %Job,
                UserID => 1,
            );

            if (!$Result) {
                $Kernel::OM->Get('Log')->Log(
                    Priority => 'error',
                    Message  => "Unable to update filter for \"Customer Response - reopen from pending\" job!"
                );
            }
        }
    }

    return 1;
}

exit 0;

=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<https://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
LICENSE for license information (AGPL). If you did not receive this file, see

<https://www.gnu.org/licenses/agpl.txt>.

=cut
