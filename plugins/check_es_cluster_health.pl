#!/usr/bin/perl

use strict;
use warnings;
use JSON;
use LWP;
use Nagios::Plugin;
use Nagios::Plugin::Threshold;

my $np = Nagios::Plugin->new(
    usage     => "Usage: %s [-H|--host=<host> ] [ -p|--port=<port> ]",
    shortname => 'ES Cluster',
);

$np->add_arg(
    spec     => 'host|H=s',
    help     => '-H, --host=Hostname or IP address',
    required => 1,
);

$np->add_arg(
    spec    => 'port|p=s',
    help    => '-p, --port=port',
    default => 9200,
);

$np->getopts;

my $url = sprintf('http://%s:%d/_cluster/health',
    $np->opts->host,
    $np->opts->port
);

my $ua = new LWP::UserAgent;
my $response = $ua->get($url);

$np->nagios_exit('UNKNOWN', $response->code . ": " . $response->status_line) if(!$response->is_success);

my $data = decode_json($response->decoded_content);

my %status;
# You may want to adjust this per your needs
$status{'green'}  = 'OK';
$status{'yellow'} = 'OK';
#$status{'yellow'} = 'WARNING';
$status{'red'}    = 'CRITICAL';

$np->nagios_exit(
    return_code => $status{$data->{'status'}},
    message     => sprintf('Cluster(%s) is %s', $data->{'cluster_name'}, $data->{'status'})
);
