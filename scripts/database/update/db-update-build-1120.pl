#!/usr/bin/perl
# --
# Copyright (C) 2006-2020 c.a.p.e. IT GmbH, https://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE for license information (AGPL). If you
# did not receive this file, see https://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin).'/../../';
use lib dirname($RealBin).'/../../Kernel/cpan-lib';

use Getopt::Std;
use File::Path qw(mkpath);

use Kernel::System::ObjectManager;

use Kernel::System::VariableCheck qw(:all);

# create object manager
local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'db-update-build-1120.pl',
    },
);

use vars qw(%INC);

# remove obsolete permission type 'Object'
_ReconfigureNotificationTransports();

exit 0;


sub _ReconfigureNotificationTransports {
    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my %NotificationList = $Kernel::OM->Get('Kernel::System::NotificationEvent')->NotificationList(
        All     => 1,
        Details => 1, 
    ); 

    foreach my $NotificationID (sort keys %NotificationList) {
        my $Notification = $NotificationList{$NotificationID};

        # check and re-add transport "Email"
        if ( IsArrayRefWithData($Notification->{Data}->{Transports}) ) {
            $Notification->{Data}->{Transports} = ['Email'];
            $Kernel::OM->Get('Kernel::System::NotificationEvent')->NotificationUpdate(
                ID => $NotificationID,
                %{$Notification},
                UserID => 1
            }
        }
    }

    return 1;
}

=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<https://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
LICENSE for license information (AGPL). If you did not receive this file, see

<https://www.gnu.org/licenses/agpl.txt>.

=cut
