# NAME

Iguard::Audit - extract information from an iguard finger-print scanner

# VERSION

version 0.1.0

# DESCRIPTION

This was written to meet a specific need but can fairly easily be turned into a more general use module.  In our case, we run multi-tenant data centers, and some clients request regular reports on which of their authorized users access the facility.

# SYNOPSIS
    # build a list of URL's to obtain data from
    foreach my $ip (@ips) {
        foreach my $id (@ids) {
            my %params = (
                 ip  => $ip,
                 id => $id, 
                 period => $period,
            );
            push @urls, build\_url(\\%params);
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

# TODO / Issues

The Iguard system can only have up to 128 departments; while we have fewer than 128 clients who request reports, we have more than 128 total.  So, while grabbing a report on a department would be simpler, that would require us to create departments for only some clients.  In our case, we'll just manually keep track of ID's in a configuration file instead.  We've also only had to send off daily reports.  This is all relevant because a page only lists up to 35 results.  This is typically enough for us, so dealing with paginated results hasn't yet been added.  The system's method of pagination appear strange as well.  There are parameters to request a range of results; by default the first 35 appear to be -35 to 0, the second page is 1 to 35, etc.  However, it will come up with some result no matter what numbers you put in, so care would be required to make sure the numbers used are correct.  Or, maybe it would be simpler to use WWW::Mechanize to hit each page.

Could use a lot more validation.

There are rather shamefully no tests, that should be fixed.

# AUTHOR

Kevin Phair <phair.kevin@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Kevin Phair.

This is free software, licensed under:

    The (three-clause) BSD License
