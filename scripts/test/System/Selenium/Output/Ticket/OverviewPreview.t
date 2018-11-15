# --
# Modified version of the work: Copyright (C) 2006-2017 c.a.p.e. IT GmbH, http://www.cape-it.de
# based on the original work of:
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get helper object
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # get sort attributes config params
        my %SortOverview = (
            Age          => 1,
            Title        => 1,
            TicketNumber => 1,
        );

        # defines from which ticket attributes the agent can select the result order
        $Helper->ConfigSettingChange(
            Key   => 'TicketOverviewMenuSort###SortAttributes',
            Value => \%SortOverview,
        );
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'TicketOverviewMenuSort###SortAttributes',
            Value => \%SortOverview,
        );
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::NewArticleIgnoreSystemSender',
            Value => 0,
        );

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get test user ID
        my $TestUserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
            UserLogin => $TestUserLogin,
        );

        # create test queue
        my $QueueName = 'Queue' . $Helper->GetRandomID();
        my $QueueID   = $Kernel::OM->Get('Kernel::System::Queue')->QueueAdd(
            Name            => $QueueName,
            ValidID         => 1,
            GroupID         => 1,
            SystemAddressID => 1,
            SalutationID    => 1,
            SignatureID     => 1,
            Comment         => 'Selenium Queue',
            UserID          => $TestUserID,
        );
        $Self->True(
            $QueueID,
            "QueueAdd() successful for test $QueueName - ID $QueueID",
        );

        my $AutoResponseObject = $Kernel::OM->Get('Kernel::System::AutoResponse');

        # create auto response
        my $AutoResponseID = $AutoResponseObject->AutoResponseAdd(
            Name        => 'TestOTRSAutoResponse',
            ValidID     => 1,
            Subject     => 'Some Subject..',
            Response    => 'Auto Response Test....',
            ContentType => 'text/plain',
            AddressID   => 1,
            TypeID      => 1,
            UserID      => 1,
        );
        $Self->True(
            $AutoResponseID,
            "Auto response created.",
        );

        my $AutoResponseSuccess = $AutoResponseObject->AutoResponseQueue(
            QueueID         => $QueueID,
            AutoResponseIDs => [$AutoResponseID],
            UserID          => 1,
        );
        $Self->True(
            $AutoResponseSuccess,
            "Auto response added for created queue.",
        );

        # get ticket object
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
        $TicketObject->{SendNoNotification} = 0;

        # create test tickets
        my @TicketIDs;
        my @TicketNumbers;
        for my $Ticket ( 1 .. 15 ) {
            my $TicketNumber = $TicketObject->TicketCreateNumber();
            my $TicketID     = $TicketObject->TicketCreate(
                TN           => $TicketNumber,
                Title        => 'Some Ticket Title',
                Queue        => $QueueName,
                Lock         => 'unlock',
                Priority     => '3 normal',
                State        => 'new',
                CustomerID   => 'TestCustomer',
                CustomerUser => 'customer@example.com',
                OwnerID      => $TestUserID,
                UserID       => $TestUserID,
            );

            $Self->True(
                $TicketID,
                "Ticket is created - $TicketID"
            );

            push @TicketIDs,     $TicketID;
            push @TicketNumbers, $TicketNumber;
        }
        my @SortTicketNumbers = sort @TicketNumbers;

        my $RandomNumber = $Helper->GetRandomNumber();

        for my $Index (qw(0 1 2)) {

            # Add articles to the tickets
            my $ArticleID1 = $TicketObject->ArticleCreate(
                TicketID         => $TicketIDs[$Index],
                ArticleType      => 'webrequest',
                SenderType       => 'customer',
                ContentType      => 'text/plain',
                From             => "Some Customer A <customer-a$RandomNumber\@example.com>",
                To               => "Some otrs system <email$RandomNumber\@example.com>",
                Subject          => "First article of the ticket # $Index",
                Body             => 'the message text',
                HistoryComment   => 'Some free text!',
                HistoryType      => 'NewTicket',
                UserID           => 1,
                AutoResponseType => 'auto reply',
                OrigHeader       => {
                    'Subject' => "First article of the ticket # $Index",
                    'Body'    => 'the message text',
                    'To'      => "Some otrs system <email$RandomNumber\@example.com>",
                    'From'    => "Some Customer A <customer-a$RandomNumber\@example.com>",
                },
            );

            $Self->True(
                $ArticleID1,
                "First article created for ticket# $Index",
            );

            # only for third ticket add agent article
            if ( $Index > 1 ) {
                my $ArticleID2 = $TicketObject->ArticleCreate(
                    TicketID       => $TicketIDs[$Index],
                    ArticleType    => 'email-external',
                    SenderType     => 'agent',
                    ContentType    => 'text/plain',
                    From           => "Some otrs system <email$RandomNumber\@example.com>",
                    To             => "Some Customer A <customer-a$RandomNumber\@example.com>",
                    Subject        => "Second article of the ticket # $Index",
                    Body           => 'agent reply',
                    HistoryComment => 'Some free text!',
                    HistoryType    => 'SendAnswer',
                    UserID         => 1,
                );
                $Self->True(
                    $ArticleID2,
                    "Second article created for ticket# $Index",
                );
            }

            if ( $Index > 0 ) {

                # mark articles seen
                my @ArticleIDs = $TicketObject->ArticleIndex(
                    TicketID => $TicketIDs[$Index],
                );

                for my $ArticleID (@ArticleIDs) {
                    my $SeenSuccess = $TicketObject->ArticleFlagSet(
                        ArticleID => $ArticleID,
                        Key       => 'Seen',
                        Value     => 1,
                        UserID    => $TestUserID,
                    );
                    $Self->True(
                        $SeenSuccess,
                        "Article $ArticleID marked as seen",
                    );
                }
            }
        }

        # go to queue ticket overview
        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketQueue;QueueID=$QueueID;View=");

        # switch to medium view
        $Selenium->find_element( "a.Large", 'css' )->VerifiedClick();

        # sort by ticket number
        $Selenium->execute_script(
            "\$('#SortBy').val('TicketNumber|Up').trigger('redraw.InputField').trigger('change');"
        );

        # wait for page reload after changing sort param
        $Selenium->WaitFor(
            JavaScript =>
                'return typeof($) === "function" && $("a[href*=\'SortBy=TicketNumber;OrderBy=Up\']").length'
        );

        # set 10 tickets per page
        $Selenium->find_element( "a#ShowContextSettingsDialog", 'css' )->VerifiedClick();
        $Selenium->execute_script(
            "\$('#UserTicketOverviewPreviewPageShown').val('10').trigger('redraw.InputField').trigger('change');"
        );
        $Selenium->find_element( "#DialogButton1", 'css' )->VerifiedClick();

        # check for ticket with lowest ticket number on first 1st page and verify that ticket
        # with highest ticket number number is not present
        $Self->True(
            index( $Selenium->get_page_source(), $SortTicketNumbers[0] ) > -1,
            "$SortTicketNumbers[0] - found on screen"
        );
        $Self->True(
            index( $Selenium->get_page_source(), $SortTicketNumbers[14] ) == -1,
            "$SortTicketNumbers[14] - not found on screen"
        );

        # switch to 2nd page to test pagination
        $Selenium->find_element( "#AgentTicketQueuePage2", 'css' )->VerifiedClick();

        # check for ticket with highest ticket number
        $Self->True(
            index( $Selenium->get_page_source(), $SortTicketNumbers[14] ) > -1,
            "$SortTicketNumbers[14] - found on screen"
        );

        # check if settings are stored when switching between view
        $Selenium->find_element( "a.Medium", 'css' )->VerifiedClick();
        $Selenium->find_element( "a.Large",  'css' )->VerifiedClick();
        $Self->True(
            index( $Selenium->get_page_source(), $SortTicketNumbers[0] ) > -1,
            "$SortTicketNumbers[0] - found on screen after changing views"
        );
        $Self->True(
            index( $Selenium->get_page_source(), $SortTicketNumbers[14] ) == -1,
            "$SortTicketNumbers[14] - not found on screen after changing views"
        );

        # delete created test tickets
        my $SelectedArticle1 = $Selenium->execute_script(
            "return \$('li#TicketID_" . $TicketIDs[0] . " .Preview li.Active').index();",
        );
        $Self->Is(
            $SelectedArticle1,
            1,
            "Selected article for First ticket is OK.",
        );

        my $SelectedArticle2 = $Selenium->execute_script(
            "return \$('li#TicketID_" . $TicketIDs[1] . " .Preview li.Active').index();",
        );
        $Self->Is(
            $SelectedArticle2,
            0,
            "Selected article for Second ticket is OK.",
        );

        my $SelectedArticle3 = $Selenium->execute_script(
            "return \$('li#TicketID_" . $TicketIDs[2] . " .Preview li.Active').index();",
        );
        $Self->Is(
            $SelectedArticle3,
            0,
            "Selected article for Third ticket is OK.",
        );

        # update Ticket::NewArticleIgnoreSystemSender
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::NewArticleIgnoreSystemSender',
            Value => 1,
        );

        # reload the page
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketQueue;QueueID=$QueueID;View=");

        # sort by ticket number
        $Selenium->execute_script(
            "\$('#SortBy').val('TicketNumber|Up').trigger('redraw.InputField').trigger('change');"
        );

        # wait for page reload after changing sort param
        $Selenium->WaitFor(
            JavaScript =>
                'return typeof($) === "function" && $("a[href*=\'SortBy=TicketNumber;OrderBy=Up\']").length'
        );

        # check which articles are selected
        $SelectedArticle1 = $Selenium->execute_script(
            "return \$('li#TicketID_" . $TicketIDs[0] . " .Preview li.Active').index();",
        );
        $Self->Is(
            $SelectedArticle1,
            0,
            "Selected article for First ticket is OK(Ticket::NewArticleIgnoreSystemSender enabled).",
        );

        $SelectedArticle2 = $Selenium->execute_script(
            "return \$('li#TicketID_" . $TicketIDs[1] . " .Preview li.Active').index();",
        );
        $Self->Is(
            $SelectedArticle2,
            0,
            "Selected article for Second ticket is OK(Ticket::NewArticleIgnoreSystemSender enabled).",
        );

        $SelectedArticle3 = $Selenium->execute_script(
            "return \$('li#TicketID_" . $TicketIDs[2] . " .Preview li.Active').index();",
        );
        $Self->Is(
            $SelectedArticle3,
            0,
            "Selected article for Third ticket is OK(Ticket::NewArticleIgnoreSystemSender enabled).",
        );

        # delete created test tickets
        my $Success;
        for my $TicketID (@TicketIDs) {
            $Success = $TicketObject->TicketDelete(
                TicketID => $TicketID,
                UserID   => $TestUserID,
            );
            $Self->True(
                $Success,
                "Delete ticket - $TicketID"
            );
        }

        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        # delete created test queue
        $Success = $DBObject->Do(
            SQL => "DELETE FROM queue_auto_response WHERE auto_response_id = $AutoResponseID",
        );
        $Self->True(
            $Success,
            "Delete auto response links - $AutoResponseID",
        );

        # delete created auto response
        $Success = $DBObject->Do(
            SQL => "DELETE FROM auto_response WHERE id = $AutoResponseID",
        );
        $Self->True(
            $Success,
            "Delete auto response - $AutoResponseID",
        );

        # delete created test queue
        $Success = $DBObject->Do(
            SQL => "DELETE FROM queue WHERE id = $QueueID",
        );
        $Self->True(
            $Success,
            "Delete queue - $QueueID",
        );

        # make sure cache is correct
        for my $Cache (qw( Ticket Queue )) {
            $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
                Type => $Cache,
            );
        }

    }
);

1;


=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<http://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
COPYING for license information (AGPL). If you did not receive this file, see

<http://www.gnu.org/licenses/agpl.txt>.

=cut
