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

use Socket;

use Kernel::GenericInterface::Debugger;
use Kernel::GenericInterface::Operation::Session::SessionCreate;

# get config object
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# get helper object
# skip SSL certificate verification
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        SkipSSLVerify => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $RandomID = $Helper->GetRandomID();

# set user details
my $UserLogin    = $Helper->TestUserCreate();
my $UserPassword = $UserLogin;
my $UserID       = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
    UserLogin => $UserLogin,
);

# set customer user details
my $ContactLogin    = $Helper->TestContactCreate();
my $ContactPassword = $ContactLogin;
my $ContactID       = $ContactLogin;

# create webservice object
my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
$Self->Is(
    'Kernel::System::GenericInterface::Webservice',
    ref $WebserviceObject,
    "Create webservice object",
);

# set webservice name
my $WebserviceName = '-Test-' . $RandomID;

my $WebserviceID = $WebserviceObject->WebserviceAdd(
    Name   => $WebserviceName,
    Config => {
        Debugger => {
            DebugThreshold => 'debug',
        },
        Provider => {
            Transport => {
                Type => '',
            },
        },
    },
    ValidID => 1,
    UserID  => 1,
);
$Self->True(
    $WebserviceID,
    "Added Webservice",
);

# get remote host with some precautions for certain unit test systems
my $Host = $Helper->GetTestHTTPHostname();

# prepare webservice config
my $RemoteSystem =
    $ConfigObject->Get('HttpType')
    . '://'
    . $Host
    . '/'
    . $ConfigObject->Get('ScriptAlias')
    . '/nph-genericinterface.pl/WebserviceID/'
    . $WebserviceID;

my $WebserviceConfig = {

    #    Name => '',
    Description =>
        'Test for Ticket Connector using SOAP transport backend.',
    Debugger => {
        DebugThreshold => 'debug',
        TestMode       => 1,
    },
    Provider => {
        Transport => {
            Type   => 'HTTP::SOAP',
            Config => {
                MaxLength => 10000000,
                NameSpace => 'http://otrs.org/SoapTestInterface/',
                Endpoint  => $RemoteSystem,
            },
        },
        Operation => {
            SessionCreate => {
                Type => 'Session::SessionCreate',
            },
        },
    },
    Requester => {
        Transport => {
            Type   => 'HTTP::SOAP',
            Config => {
                NameSpace => 'http://otrs.org/SoapTestInterface/',
                Encoding  => 'UTF-8',
                Endpoint  => $RemoteSystem,
            },
        },
        Invoker => {
            SessionCreate => {
                Type => 'Test::TestSimple',
            },
        },
    },
};

# update webservice with real config
my $WebserviceUpdate = $WebserviceObject->WebserviceUpdate(
    ID      => $WebserviceID,
    Name    => $WebserviceName,
    Config  => $WebserviceConfig,
    ValidID => 1,
    UserID  => 1,
);
$Self->True(
    $WebserviceUpdate,
    "Updated Webservice $WebserviceID - $WebserviceName",
);

my @Tests = (
    {
        Name           => 'Empty Request',
        SuccessRequest => 1,
        SuccessGet     => 0,
        RequestData    => {},
        ExpectedData   => {
            Data => {
                Error => {
                    ErrorCode => 'TicketCreate.MissingParameter',
                    }
            },
            Success => 1
        },
        Operation => 'SessionCreate',
    },
    {
        Name           => 'UserLogin No Password',
        SuccessRequest => 1,
        SuccessGet     => 0,
        RequestData    => {
            UserLogin => $UserLogin,
        },
        ExpectedData => {
            Data => {
                Error => {
                    ErrorCode => 'TicketCreate.MissingParameter',
                    }
            },
            Success => 1
        },
        Operation => 'SessionCreate',
    },
    {
        Name           => 'ContactLogin No Password',
        SuccessRequest => 1,
        SuccessGet     => 0,
        RequestData    => {
            ContactLogin => $ContactLogin,
        },
        ExpectedData => {
            Data => {
                Error => {
                    ErrorCode => 'TicketCreate.MissingParameter',
                    }
            },
            Success => 1
        },
        Operation => 'SessionCreate',
    },
    {
        Name           => 'Password No UserLogin',
        SuccessRequest => 1,
        SuccessGet     => 0,
        RequestData    => {
            Password => $UserPassword,
        },
        ExpectedData => {
            Data => {
                Error => {
                    ErrorCode => 'TicketCreate.MissingParameter',
                    }
            },
            Success => 1
        },
        Operation => 'SessionCreate',
    },
    {
        Name           => 'UserLogin Invalid Password',
        SuccessRequest => 1,
        SuccessGet     => 0,
        RequestData    => {
            UserLogin => $UserLogin,
            Password  => $RandomID,
        },
        ExpectedData => {
            Data => {
                Error => {
                    ErrorCode => 'TicketCreate.MissingParameter',
                    }
            },
            Success => 1
        },
        Operation => 'SessionCreate',
    },
    {
        Name           => 'ContactLogin Invalid Password',
        SuccessRequest => 1,
        SuccessGet     => 0,
        RequestData    => {
            ContactLogin => $ContactLogin,
            Password          => $RandomID,
        },
        ExpectedData => {
            Data => {
                Error => {
                    ErrorCode => 'TicketCreate.MissingParameter',
                    }
            },
            Success => 1
        },
        Operation => 'SessionCreate',
    },
    {
        Name           => 'Invalid UserLogin Correct Password',
        SuccessRequest => 1,
        SuccessGet     => 0,
        RequestData    => {
            UserLogin => $RandomID,
            Password  => $UserPassword,
        },
        ExpectedData => {
            Data => {
                Error => {
                    ErrorCode => 'TicketCreate.MissingParameter',
                    }
            },
            Success => 1
        },
        Operation => 'SessionCreate',
    },
    {
        Name           => 'Invalid ContactLogin Correct Password',
        SuccessRequest => 1,
        SuccessGet     => 0,
        RequestData    => {
            ContactLogin => $RandomID,
            Password          => $ContactPassword,
        },
        ExpectedData => {
            Data => {
                Error => {
                    ErrorCode => 'TicketCreate.MissingParameter',
                    }
            },
            Success => 1
        },
        Operation => 'SessionCreate',
    },
    {
        Name           => 'Correct UserLogin and Password',
        SuccessRequest => 1,
        SuccessGet     => 1,
        RequestData    => {
            UserLogin => $UserLogin,
            Password  => $UserPassword,
        },
        Operation => 'SessionCreate',
    },
    {
        Name           => 'Correct ContactLogin and Password',
        SuccessRequest => 1,
        SuccessGet     => 1,
        RequestData    => {
            ContactLogin => $ContactLogin,
            Password          => $ContactPassword,
        },
        Operation => 'SessionCreate',
    },
);

# debugger object
my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
    DebuggerConfig => {
        DebugThreshold => 'debug',
        TestMode       => 1,
    },
    WebserviceID      => $WebserviceID,
    CommunicationType => 'Provider',
);
$Self->Is(
    ref $DebuggerObject,
    'Kernel::GenericInterface::Debugger',
    'DebuggerObject instantiate correctly',
);

for my $Test (@Tests) {

    # create local object
    my $LocalObject = "Kernel::GenericInterface::Operation::Session::$Test->{Operation}"->new(
        DebuggerObject => $DebuggerObject,
        WebserviceID   => $WebserviceID,
    );

    $Self->Is(
        "Kernel::GenericInterface::Operation::Session::$Test->{Operation}",
        ref $LocalObject,
        "$Test->{Name} - Create local object",
    );

    # start requester with our webservice
    my $LocalResult = $LocalObject->Run(
        WebserviceID => $WebserviceID,
        Invoker      => $Test->{Operation},
        Data         => {
            %{ $Test->{RequestData} },
        },
    );

    # sleep between requests to have different timestamps
    # because of failing tests on windows
    sleep 1;

    # check result
    $Self->Is(
        'HASH',
        ref $LocalResult,
        "$Test->{Name} - Local result structure is valid",
    );

    # create requester object
    my $RequesterObject = $Kernel::OM->Get('Kernel::GenericInterface::Requester');
    $Self->Is(
        'Kernel::GenericInterface::Requester',
        ref $RequesterObject,
        "$Test->{Name} - Create requester object",
    );

    # start requester with our webservice
    my $RequesterResult = $RequesterObject->Run(
        WebserviceID => $WebserviceID,
        Invoker      => $Test->{Operation},
        Data         => {
            %{ $Test->{RequestData} },
        },
    );

    # check result
    $Self->Is(
        'HASH',
        ref $RequesterResult,
        "$Test->{Name} - Requester result structure is valid",
    );

    $Self->Is(
        $RequesterResult->{Success},
        $Test->{SuccessRequest},
        "$Test->{Name} - Requester successful result",
    );

    # tests supposed to succeed
    if ( $Test->{SuccessGet} ) {

        # local results
        $Self->IsNot(
            $LocalResult->{Data}->{SessionID},
            undef,
            "$Test->{Name} - Local result SessionID",
        );

        # requester results
        $Self->IsNot(
            $RequesterResult->{Data}->{SessionID},
            undef,
            "$Test->{Name} - Requester result SessonID",
        );

        # local and remote request should be different since each time the SessionCreate is called
        # should return different SessionID
        $Self->IsNotDeeply(
            $LocalResult,
            $RequesterResult,
            "$Test->{Name} - Local SessionID is different than Remote SessionID.",
        );
    }

    # tests supposed to fail
    else {
        $Self->Is(
            $LocalResult->{SessionID},
            undef,
            "$Test->{Name} - Local SessionID",
        );

        # remove ErrorMessage parameter from direct call
        # result to be consistent with SOAP call result
        if ( $LocalResult->{ErrorMessage} ) {
            delete $LocalResult->{ErrorMessage};
        }

        # sanity check
        $Self->False(
            $LocalResult->{ErrorMessage},
            "$Test->{Name} - Local result ErrorMessage (outside Data hash) got removed to compare"
                . " local and remote tests.",
        );

        $Self->IsDeeply(
            $LocalResult,
            $RequesterResult,
            "$Test->{Name} - Local result matched with remote result.",
        );
    }
}

# clean up webservice
my $WebserviceDelete = $WebserviceObject->WebserviceDelete(
    ID     => $WebserviceID,
    UserID => 1,
);
$Self->True(
    $WebserviceDelete,
    "Deleted Webservice $WebserviceID",
);

# cleanup sessions
my $CleanUp = $Kernel::OM->Get('Kernel::System::AuthSession')->CleanUp();

1;


=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<http://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
COPYING for license information (AGPL). If you did not receive this file, see

<http://www.gnu.org/licenses/agpl.txt>.

=cut
