# --
# Modified version of the work: Copyright (C) 2006-2021 c.a.p.e. IT GmbH, https://www.cape-it.de
# based on the original work of:
# Copyright (C) 2001-2017 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-AGPL for license information (AGPL). If you
# did not receive this file, see https://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Automation::MacroAction::Common::CreateReport;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use base qw(Kernel::System::Automation::MacroAction::Common);

our @ObjectDependencies = (
    'Log',
);

=head1 NAME

Kernel::System::Automation::MacroAction::Common::CreateReport - A module to create a report

=head1 SYNOPSIS

All functions to create a report.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item Describe()

Describe this macro action module.

=cut

sub Describe {
    my ( $Self, %Param ) = @_;

    $Self->Description(Kernel::Language::Translatable('Create a report from a report definition.'));
    $Self->AddOption(
        Name        => 'DefinitionID',
        Label       => Kernel::Language::Translatable('Report Definition'),
        Description => Kernel::Language::Translatable('The ID of the report definition.'),
        Required    => 1,
    );
    $Self->AddOption(
        Name        => 'Parameters',
        Label       => Kernel::Language::Translatable('Parameters'),
        Description => Kernel::Language::Translatable('The parameters of the report as a HashRef.'),
        Required    => 0,
    );
    $Self->AddOption(
        Name        => 'OutputFormat',
        Label       => Kernel::Language::Translatable('Output Format'),
        Description => Kernel::Language::Translatable('The requested output format.'),
        Required    => 1,
    );

    $Self->AddResult(
        Name        => 'Report',
        Description => Kernel::Language::Translatable('The report object including the result.'),
    );

    return;
}

=item Run()

Run this module. Returns 1 if everything is ok.

Example:
    my $Success = $Object->Run(
        ObjectID => 123,
        Config   => {
            DefinitionID => 123,
            Parameters   => {
                Param1 => "abc",
                Param2 => 123,
                Param3 =>  ["abc", "def"]
            },
        },
        UserID   => 123,
    );

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # check incoming parameters
    return if !$Self->_CheckParams(%Param);

    # check the given DefinitionID
    my %Definition = $Kernel::OM->Get('Reporting')->ReportDefinitionGet(
        ID => $Param{Config}->{DefinitionID},
    );
    if ( !%Definition ) {
        $Kernel::OM->Get('Automation')->LogError(
            Referrer => $Self,
            Message  => "Couldn't create report - can't find report definition with ID $Param{Config}->{DefinitionID}!",
            UserID   => $Param{UserID}
        );
        return;
    }

    # replace placeholders - atm only for ticket
    foreach my $Parameter ( sort keys %{$Param{Config}->{Parameters} ||{}} ) {
        $Param{Config}->{Parameters}->{$Parameter} = $Kernel::OM->Get('TemplateGenerator')->ReplacePlaceHolder(
            RichText => 0,
            Text     => $Param{Config}->{Parameters}->{$Parameter},
            TicketID => $Param{ObjectID},
            Data     => {},
            UserID   => $Param{UserID},
            Language => 'en' # to not translate values
        );
    }

    # check output format
    my %OutputFormats;
    if ( IsHashRefWithData($Kernel::OM->Get('Config')->Get('Reporting::OutputFormat')) ) {
        %OutputFormats = map { $_ => 1 } sort keys %{ $Kernel::OM->Get('Config')->Get('Reporting::OutputFormat') };
    }
    if ( !$OutputFormats{$Param{Config}->{OutputFormat}} ) {
        $Kernel::OM->Get('Automation')->LogError(
            Referrer => $Self,
            Message  => "Couldn't create report - output format \"$Param{Config}->{OutputFormat}\" not supported!",
            UserID   => $Param{UserID}
        );
        return;
    }
    if ( IsHashRefWithData($Definition{Config}->{OutputFormats}) && !exists $Definition{Config}->{OutputFormats}->{$Param{Config}->{OutputFormat}} ) {
        $Kernel::OM->Get('Automation')->LogError(
            Referrer => $Self,
            Message  => "Output format \"$Param{Config}->{OutputFormat}\" isn't supported for the given report definition \"$Definition{Name}\"!",
            UserID   => $Param{UserID}
        );
        return;
    }

    # create Report
    my $ReportID = $Kernel::OM->Get('Reporting')->ReportCreate(
        DefinitionID => $Param{Config}->{DefinitionID},
        Config       => {
            Parameters    => $Param{Config}->{Parameters},
            OutputFormats => [ $Param{Config}->{OutputFormat} ]
        },
        UserID => $Param{UserID}
    );

    if ( !$ReportID ) {
        $Kernel::OM->Get('Automation')->LogError(
            Referrer => $Self,
            Message  => "Couldn't create report!",
            UserID   => $Param{UserID}
        );
        return;
    }

    my %Report = $Kernel::OM->Get('Reporting')->ReportGet(
        ID                   => $ReportID,
        IncludeResults       => 1,
        IncludeResultContent => 1
    );
    if ( !%Report ) {
        $Kernel::OM->Get('Automation')->LogError(
            Referrer => $Self,
            Message  => "Couldn't load report with ID $ReportID!",
            UserID   => $Param{UserID}
        );
        return;
    }

    # return the report
    $Self->SetResult(Name => 'Report', Value => \%Report);

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
