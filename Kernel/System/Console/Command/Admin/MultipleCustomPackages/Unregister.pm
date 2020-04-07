# --
# Copyright (C) 2006-2020 c.a.p.e. IT GmbH, https://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-GPL3 for license information (GPL3). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Admin::MultipleCustomPackages::Unregister;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'KIXUtils',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Register a custom package');

    $Self->AddArgument(
        Name        => 'package-name',
        Description => 'name of package to register',
        Required    => 1,
        ValueRegex  => qr/(.*)/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $PackageName = $Self->GetArgument('package-name');

    $Self->Print("<yellow>NOTE: start to unregister package '$PackageName'\n\n</yellow>\n");

    $Kernel::OM->Get('KIXUtils')->UnRegisterCustomPackage(
        PackageName => $PackageName
    );

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;





=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<https://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
LICENSE-GPL3 for license information (GPL3). If you did not receive this file, see

<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
