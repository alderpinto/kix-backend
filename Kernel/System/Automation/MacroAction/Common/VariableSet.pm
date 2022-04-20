# --
# Modified version of the work: Copyright (C) 2006-2022 c.a.p.e. IT GmbH, https://www.cape-it.de
# based on the original work of:
# Copyright (C) 2001-2017 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-AGPL for license information (AGPL). If you
# did not receive this file, see https://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Automation::MacroAction::Common::VariableSet;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use base qw(Kernel::System::Automation::MacroAction::Common);

our @ObjectDependencies = (
    'Log',
);

=head1 NAME

Kernel::System::Automation::MacroAction::Common::VariableSet - A module to assign a value to a macro variable

=head1 SYNOPSIS

All VariableSet functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item Describe()

Describe this macro action module.

=cut

sub Describe {
    my ( $Self, %Param ) = @_;

    $Self->Description(Kernel::Language::Translatable('Assign a value to a macro variable.'));
    $Self->AddOption(
        Name        => 'Value',
        Label       => Kernel::Language::Translatable('Value'),
        Description => Kernel::Language::Translatable('The value to assign.'),
        Required    => 0,
    );

    $Self->AddResult(
        Name        => 'Variable',
        Description => Kernel::Language::Translatable('The variable to assign to.'),
    );

    return;
}

=item Run()

Run this module. Returns 1 if everything is ok.

Example:
    my $Success = $Object->Run(
        ObjectID => 123,
        Config   => {
            Value  => '...',
            Variable => '...'
        },
        UserID   => 123,
    );

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # check incoming parameters
    return if !$Self->_CheckParams(%Param);

    foreach my $Key (keys %{$Param{Config}}) {
        $Param{Config}->{$Key} = $Kernel::OM->Get('TemplateGenerator')->ReplacePlaceHolder(
            RichText  => 0,
            Text      => $Param{Config}->{$Key},
            Data      => {},
            UserID    => $Param{UserID},
            Translate => 0,

            # FIXME: as common action, object id could be not a ticket!
            TicketID  => $Self->{RootObjectID} || $Param{ObjectID}
        );
    }

    # set the variable
    $Self->SetResult(Name => 'Variable', Value => $Param{Config}->{Value});

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<https://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
LICENSE-AGPL for license information (AGPL). If you did not receive this file, see

<https://www.gnu.org/licenses/agpl.txt>.

=cut
