# --
# Copyright (C) 2006-2023 KIX Service Software GmbH, https://www.kixdesk.com
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-GPL3 for license information (GPL3). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ObjectSearch::Database::Ticket::ArticleAttachment;

use strict;
use warnings;

use base qw(
    Kernel::System::ObjectSearch::Database::Common
);

our @ObjectDependencies = qw(
    Config
    Log
);

=head1 NAME

Kernel::System::ObjectSearch::Database::Ticket::ArticleAttachment - attribute module for database object search

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=over 4

=cut

=item GetSupportedAttributes()

defines the list of attributes this module is supporting

    my $AttributeList = $Object->GetSupportedAttributes();

    $Result = {
        Search => [ ],
        Sort   => [ ],
    };

=cut

sub GetSupportedAttributes {
    my ( $Self, %Param ) = @_;

    $Self->{SupportedSearch} = {
        'AttachmentName' => ['EQ','NE','STARTSWITH','ENDSWITH','CONTAINS','LIKE']
    };

    $Self->{SupportedSort} = [];

    return {
        Search => $Self->{SupportedSearch},
        Sort   => $Self->{SupportedSort}
    };
}


=item Search()

run this module and return the SQL extensions

    my $Result = $Object->Search(
        BoolOperator => 'AND' | 'OR',
        Search       => {}
    );

    $Result = {
        SQLJoin    => [ ],
        SQLWhere   => [ ],
    };

=cut

sub Search {
    my ( $Self, %Param ) = @_;
    my @SQLJoin;
    my @SQLWhere;

    # check params
    if ( !$Param{Search} ) {
        $Kernel::OM->Get('Log')->Log(
            Priority => 'error',
            Message  => "Need Search!",
        );
        return;
    }

    my $StorageModule = $Kernel::OM->Get('Config')->Get('Ticket::StorageModule');
    if ( $StorageModule !~ /::ArticleStorageDB$/ ) {
        # we can only search article attachments if they are stored in the DB
        $Kernel::OM->Get('Log')->Log(
            Priority => 'notice',
            Message  => "Attachments cannot be searched if articles are not stored in the database!",
        );

        return;
    }

    # check if we have to add a join
    if ( !$Self->{ModuleData}->{AlreadyJoined} || !$Self->{ModuleData}->{AlreadyJoined}->{$Param{BoolOperator}} ) {
        if ( $Param{BoolOperator} eq 'OR') {
            push( @SQLJoin, 'LEFT OUTER JOIN article art_for_att_left ON st.id = art_for_att_left.ticket_id' );
            push( @SQLJoin, 'RIGHT OUTER JOIN article art_for_att_right ON st.id = art_for_att_right.ticket_id' );
            push( @SQLJoin, 'INNER JOIN article_attachment att ON att.article_id = art_for_att_left.id OR att.article_id = art_for_att_right.id' );
        } else {
            push( @SQLJoin, 'INNER JOIN article art_for_att ON st.id = art_for_att.ticket_id' );
            push( @SQLJoin, 'INNER JOIN article_attachment att ON att.article_id = art_for_att.id' );
        }
        $Self->{ModuleData}->{AlreadyJoined}->{$Param{BoolOperator}} = 1;
    }

    my @Where = $Self->GetOperation(
        Operator  => $Param{Search}->{Operator},
        Column    => 'att.filename',
        Value     => $Param{Search}->{Value},
        Prepare   => 1,
        Supported => $Self->{SupportedSearch}->{$Param{Search}->{Field}}
    );

    return if !@Where;

    push( @SQLWhere, @Where);

    # restrict search from customers to only customer articles
    if ( $Param{UserType} eq 'Customer' ) {
        if ( $Param{BoolOperator} eq 'OR') {
            push( @SQLWhere, 'art_for_att_left.customer_visible = 1' );
            push( @SQLWhere, 'art_for_att_right.customer_visible = 1' );
        } else {
            push( @SQLWhere, 'art_for_att.customer_visible = 1' );
        }
    }

    return {
        SQLJoin  => \@SQLJoin,
        SQLWhere => \@SQLWhere,
    };
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
