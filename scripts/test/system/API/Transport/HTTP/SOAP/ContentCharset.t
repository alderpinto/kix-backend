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

use vars (qw($Self));

use Kernel::API::Debugger;
use Kernel::API::Transport::HTTP::SOAP;

my $DebuggerObject = Kernel::API::Debugger->new(
    DebuggerConfig => {
        DebugThreshold => 'error',
        TestMode       => 1,
    },
    CommunicationType => 'requester',
    WebserviceID      => 1,             # not used
);
my $SOAPObject = Kernel::API::Transport::HTTP::SOAP->new(
    DebuggerObject  => $DebuggerObject,
    TransportConfig => {
        Config => {
            MaxLength            => 100000000,
            NameSpace            => 'http://www.otrs.org/TicketConnector/',
            RequestNameFreeText  => '',
            RequestNameScheme    => 'Plain',
            ResponseNameFreeText => '',
            ResponseNameScheme   => 'Response;'
        },
        Type => 'HTTP::SOAP',
    },
);

my @Tests = (
    {
        Name        => 'UTF-8 Complex Content Type',
        Value       => 'c™',
        ContentType => 'application/soap+xml;charset=UTF-8;action="urn:MyService/MyAction"',
    },
    {
        Name        => 'UTF-8 Simple Content Type',
        Value       => 'c™',
        ContentType => 'text/xml;charset=UTF-8',
    },
    {
        Name        => 'UTF-8 Complex Content Type (Just ASCII)',
        Value       => 'cTM',
        ContentType => 'application/soap+xml;charset=UTF-8;action="urn:MyService/MyAction"',
    },
    {
        Name        => 'UTF-8 Simple Content Type (Just ASCII)',
        Value       => 'cTM',
        ContentType => 'text/xml;charset=UTF-8',
    },
    {
        Name        => 'ISO-8859-1 Complex Content Type',
        Value       => 'c™',
        ContentType => 'application/soap+xml;charset=iso-8859-1;action="urn:MyService/MyAction"',
    },
    {
        Name        => 'ISO-8859-1 Single Content Type',
        Value       => 'c™',
        ContentType => 'text/xml;charset=iso-8859-1;',
    },
    {
        Name        => 'ISO-8859-1 Complex Content Type (Just ASCII)',
        Value       => 'cTM',
        ContentType => 'application/soap+xml;charset=iso-8859-1;action="urn:MyService/MyAction"',
    },
    {
        Name        => 'ISO-8859-1 Simple Content Type (Just ASCII)',
        Value       => 'cTM',
        ContentType => 'text/xml;charset=iso-8859-1',
    },
);

for my $Test (@Tests) {

    my $Request = << "EOF";
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tic="http://www.otrs.org/TicketConnector/">
   <soapenv:Header/>
   <soapenv:Body>
      <tic:Test>
         <Test>$Test->{Value}</Test>
      </tic:Test>
   </soapenv:Body>
</soapenv:Envelope>
EOF

    # Fake STDIN and fill it with the request.
    open my $StandardInput, '<', \"$Request";    ## no critic
    local *STDIN = $StandardInput;

    # Fake environment variables as it gets it from the request.
    local $ENV{'CONTENT_LENGTH'} = length $Request;
    local $ENV{'CONTENT_TYPE'}   = $Test->{ContentType};

    my $Result = $SOAPObject->ProviderProcessRequest();

    # Convert original value to UTF-8 (if needed).
    if ( $Test->{ContentType} =~ m{UTF-8}mxsi ) {
        $Kernel::OM->Get('Kernel::System::Encode')->EncodeInput( \$Test->{Value} );
    }

    $Self->Is(
        $Result->{Data}->{Test},
        $Test->{Value},
        "$Test->{Name} Result value",
    );
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