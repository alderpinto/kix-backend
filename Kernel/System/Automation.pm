# --
# Copyright (C) 2006-2021 c.a.p.e. IT GmbH, https://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-GPL3 for license information (GPL3). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Automation;

use strict;
use warnings;

use base qw(
    Kernel::System::Automation::ExecPlan
    Kernel::System::Automation::Job
    Kernel::System::Automation::Macro
    Kernel::System::Automation::MacroAction
);

our @ObjectDependencies = (
    'Config',
    'Cache',
    'DB',
    'Log',
    'User',
    'Valid',
);

=head1 NAME

Kernel::System::Automation - automation lib

=head1 SYNOPSIS

All role functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $AutomationObject = $Kernel::OM->Get('Automation');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'Automation';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    return $Self;
}

=item ExecuteEventbasedJobs()

Execute all relevant eventbased jobs for a given type

Example:
    my $Success = $Object->ExecuteEventbasedJobs(
        Type      => 'Ticket',
        Event     => 'TicketCreate',
        Data      => {
            ...
        },
        Config    => {},
        UserID    => 123,
    );

=cut

sub ExecuteJobsForEvent {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Type Event UserID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Log')->Log(
                Priority => 'error',
                Message  => "Need $_!",
            );
            return;
        }
    }

    # get all valid jobs
    my %JobList = $Self->JobList(
        Valid => 1
    );

    # sort by names to enable simple ordering by user
    foreach my $JobID ( sort { $JobList{$a} cmp $JobList{$b} } keys %JobList ) {
        my %Job = $Self->JobGet(
            ID => $JobID
        );

        # ignore jobs of non-relevant types
        next if $Job{Type} ne $Param{Type};

        my $CanExecute = $Self->JobIsExecutable(
            ID => $JobID,
            %Param,
        );

        if ( $CanExecute ) {

            # execute the job in a new Automation instance
            my $AutomationObject = $Kernel::OM->GetModuleFor('Automation')->new(%{$Self});

            my $Result = $AutomationObject->JobExecute(
                ID => $JobID,
                %Param,
            );
        }
    }

    return 1;
}

=item LogDebug()

Logs a debug message.

Example:
    my $Success = $Object->LogDebug(
        Message  => '...',
        UserID   => 123,
    );

=cut

sub LogDebug {
    my ( $Self, %Param ) = @_;

    return $Self->_Log(
        %Param,
        Priority => 'debug',
    )
}

=item LogInfo()

Logs an information message.

Example:
    my $Success = $Object->LogInfo(
        Message  => '...',
        UserID   => 123,
    );

=cut

sub LogInfo {
    my ( $Self, %Param ) = @_;

    return $Self->_Log(
        %Param,
        Priority => 'info',
    )
}

=item LogError()

Logs an error message.

Example:
    my $Success = $Object->LogError(
        Message  => '...',
        UserID   => 123,
    );

=cut

sub LogError {
    my ( $Self, %Param ) = @_;

    return $Self->_Log(
        %Param,
        Priority => 'error',
    )
}

=item _Log()

Logs a message.

Example:
    my $Success = $Object->_Log(
        Priority => '...'               # see Kernel::System::Log::LogLevel
        Message  => '...',
        UserID   => 123,
    );

=cut

sub _Log {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Message Priority UserID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Log')->Log(
                Priority => 'error',
                Message  => "Need $_!",
            );
            return;
        }
    }

    my %Reference;
    foreach my $ReferenceID ( qw(JobID RunID MacroID MacroActionID ObjectID) ) {
        $Reference{$ReferenceID} = ($Param{Referrer} ? $Param{Referrer}->{$ReferenceID} : undef) || $Self->{$ReferenceID};
    }

    return if !$Kernel::OM->Get('DB')->Do(
        SQL => 'INSERT INTO automation_log (job_id, run_id, macro_id, macro_action_id, object_id, priority, message, create_time, create_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, current_timestamp, ?)',
        Bind => [
            \$Reference{JobID}, \$Reference{RunID}, \$Reference{MacroID}, \$Reference{MacroActionID}, \$Reference{ObjectID}, \$Param{Priority}, \$Param{Message}, \$Param{UserID}
        ],
    );

    # get job info
    my $JobInfo = '-';
    if ( $Reference{JobID} ) {
        my %Job = $Self->JobGet(
            ID => $Reference{JobID}
        );
        $JobInfo = "$Job{Name} ($Reference{JobID})";
    }

    # get macro info
    my $MacroInfo = '-';
    if ( $Reference{MacroID} ) {
        my %Macro = $Self->MacroGet(
            ID => $Reference{MacroID}
        );
        $MacroInfo = "$Macro{Name} ($Reference{MacroID})";
    }

    # get macro info
    my $MacroActionInfo = '-';
    if ( $Reference{MacroActionID} ) {
        my %MacroAction = $Self->MacroActionGet(
            ID => $Reference{MacroActionID}
        );
        $MacroActionInfo = "$MacroAction{Type} ($Reference{MacroActionID})";
    }

    # log in system log
    $Kernel::OM->Get('Log')->Log(
        Priority => $Param{Priority},
        Message  => sprintf("%s (Job: %s, RunID: %s, Macro: %s, MacroAction: %s)", $Param{Message}, $JobInfo, $Reference{RunID} || '', $MacroInfo, $MacroActionInfo),
    );

    return 1;
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
