# --
# Copyright (C) 2006-2017 c.a.p.e. IT GmbH, http://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::JWT::RemoveAll;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::JWT',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Remove all tokens.');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Removing all tokens...</yellow>\n");

    my $JWTObject = $Kernel::OM->Get('Kernel::System::JWT');

    for my $Token ( keys %{$JWTObject->GetAllTokens()} ) {
        my $Result = $JWTObject->RemoveToken(
            Token => $Token,
        );

        if ( !$Result ) {
            $Self->PrintError("Token could not be deleted.");
            return $Self->ExitCodeError();
        }

        $Self->Print("  Token deleted\n");
    }

    $Self->Print("<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;



=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<http://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
COPYING for license information (AGPL). If you did not receive this file, see

<http://www.gnu.org/licenses/agpl.txt>.

=cut