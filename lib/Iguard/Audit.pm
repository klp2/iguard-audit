package Iguard::Audit;
# ABSTRACT: extract information from an iguard finger-print scanner

use strict;
use warnings;

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(build_url get_entries clean_entries);

use HTML::Strip;
use Params::Validate qw(:all);
use WWW::Mechanize;

use namespace::clean;

sub build_url {
    my %v = validate(
        @_, {
            ip => 1,
            id         => { default => '' },
            department => { default => '' },
            period     => { default => '' },
            datefrom   => { default => '' },
            dateto     => { default => '' },
            database   => { default => 'TMLG' },
            formtype   => { default => 'list' },
            oid        => { default => '' },
            formname   => { default => 'AccLog.vtml' },
        }
    );

    my $url = "http://$v{ip}/Admins/database.cgi?ID=$v{id}&DEPARTMENTSELECT=$v{department}&INOUTSEL=ALL&Period=$v{period}&DateFrom=$v{datefrom}&DateTo=$v{dateto}&database=$v{database}&formtype=$v{formtype}&oid=$v{oid}&formname=$v{formname}";

    return $url;
}

sub get_entries {
    validate_pos( @_, 1);
    my $url = shift;

    my $mech = WWW::Mechanize->new();
    $mech->get($url);
    my $page = $mech->content();

    my @lines = split /\n/, $page;
    my $all_entries;
    for (@lines) {
        next unless /^<!--VIKING-->/;
        $all_entries = $_;
    }
    return $all_entries;
}


sub clean_entries {
    my $all_entries = shift;

    return if ($all_entries =~ /No Record Found/);

    my @entries = split '<tr>', $all_entries;
    my $clean;
    foreach my $entry (@entries) {
        next if $entry =~ /Total [0-9]+ Record\(s\)/;
        my $stripper = HTML::Strip->new( decode_entities => 0 );
        $entry = $stripper->parse($entry);
        $entry =~ s/^&nbsp;\s+//;
        $entry =~ s/&nbsp; /\n/g;
        $clean .= $entry . "\n";
    }
    return $clean;
}

1;

__END__

=head1 SYNOPSIS
    # build a list of URL's to obtain data from
    foreach my $ip (@ips) {
        foreach my $id (@ids) {
            my %params = (
                 ip  => $ip,
                 id => $id, 
                 period => $period,
            );
            push @urls, build_url(\%params);
        }
    }

    # grab the data
    my @user_entries;
    foreach my $url (@urls) {
            push @user_entries, get_entries($url);
    }

    # clean the data up for email or what have you
    my $report;
    foreach my $entry_list (@user_entries) {
            $report .= clean_entries($entry_list) || '';
    }

=head1 DESCRIPTION

This was written to meet a specific need but can fairly easily be turned into a more general use module.  In our case, we run multi-tenant data centers, and some clients request regular reports on which of their authorized users access the facility.

=head1 TODO / Issues

The Iguard system can only have up to 128 departments; while we have fewer than 128 clients who request reports, we have more than 128 total.  So, while grabbing a report on a department would be simpler, that would require us to create departments for only some clients.  In our case, we'll just manually keep track of ID's in a configuration file instead.  We've also only had to send off daily reports.  This is all relevant because a page only lists up to 35 results.  This is typically enough for us, so dealing with paginated results hasn't yet been added.  The system's method of pagination appear strange as well.  There are parameters to request a range of results; by default the first 35 appear to be -35 to 0, the second page is 1 to 35, etc.  However, it will come up with some result no matter what numbers you put in, so care would be required to make sure the numbers used are correct.  Or, maybe it would be simpler to use WWW::Mechanize to hit each page.

Could use a lot more validation.

There are rather shamefully no tests, that should be fixed.
