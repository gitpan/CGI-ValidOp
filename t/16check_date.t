#!/usr/bin/perl -T
use warnings;
use strict;

use lib qw/ t lib /;

use CGI::ValidOp::Test;

use Test::More tests => 607;
use vars qw/ $one $errmsg /;
use Data::Dumper;
use Test::Taint;
use CGI::ValidOp::Check::date;

BEGIN { use_ok( 'CGI::ValidOp::Param' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check_<type>_format methods
    is(CGI::ValidOp::Check::date::check_iso_format(undef), undef);
    is(CGI::ValidOp::Check::date::check_iso_format(''), undef);
    is_deeply( [ CGI::ValidOp::Check::date::check_iso_format('2006-06-01') ], [ '2006', '06', '01'] );
    is(CGI::ValidOp::Check::date::check_iso_format('5/5/2005'), undef);

    
    is(CGI::ValidOp::Check::date::check_american_format(undef), undef);
    is(CGI::ValidOp::Check::date::check_american_format(''), undef);
    is_deeply( [ CGI::ValidOp::Check::date::check_american_format('5/6/2005') ], ['2005', '5', '6'] );
    is(CGI::ValidOp::Check::date::check_american_format('2005-05-06'), undef);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for day/month/year element check methods

    is(CGI::ValidOp::Check::date::check_year(undef), undef);
    is(CGI::ValidOp::Check::date::check_year(''), 0);
    is(CGI::ValidOp::Check::date::check_year('2000'), 1);
    #Requiring 4 digit years, otherwise we have to figure out
    #if 02 is 1902 or 2002 or the 2nd year of our lord...
    is(CGI::ValidOp::Check::date::check_year('02'), 0);

    is(CGI::ValidOp::Check::date::check_month(undef), undef);
    is(CGI::ValidOp::Check::date::check_month('-1'), 0);
    is(CGI::ValidOp::Check::date::check_month('+1'), 0);
    is(CGI::ValidOp::Check::date::check_month('0'), 0);
    is(CGI::ValidOp::Check::date::check_month('1'), 1);
    is(CGI::ValidOp::Check::date::check_month('01'), 1);
    is(CGI::ValidOp::Check::date::check_month('12'), 1);
    is(CGI::ValidOp::Check::date::check_month('13'), 0);

    is(CGI::ValidOp::Check::date::check_day(undef), undef);
    is(CGI::ValidOp::Check::date::check_day('1', undef), undef);
    is(CGI::ValidOp::Check::date::check_day('1','2',undef), undef);
    is(CGI::ValidOp::Check::date::check_day('0','1',undef), 0);
    is(CGI::ValidOp::Check::date::check_day('-1','1',undef), 0);
    is(CGI::ValidOp::Check::date::check_day('+1','1',undef), 0);
    is(CGI::ValidOp::Check::date::check_day('31','1',undef), 1);
    is(CGI::ValidOp::Check::date::check_day('32','1',undef), 0);
    is(CGI::ValidOp::Check::date::check_day('28','2','1999'), 1);
    is(CGI::ValidOp::Check::date::check_day('29','2','1991'), 0);
    is(CGI::ValidOp::Check::date::check_day('29','2','2000'), 1);
    is(CGI::ValidOp::Check::date::check_day('30','2','2000'), 0);
    is(CGI::ValidOp::Check::date::check_day('31','3',undef), 1);
    is(CGI::ValidOp::Check::date::check_day('32','3',undef), 0);
    is(CGI::ValidOp::Check::date::check_day('30','4',undef), 1);
    is(CGI::ValidOp::Check::date::check_day('31','4',undef), 0);
    is(CGI::ValidOp::Check::date::check_day('31','5',undef), 1);
    is(CGI::ValidOp::Check::date::check_day('32','5',undef), 0);
    is(CGI::ValidOp::Check::date::check_day('30','6',undef), 1);
    is(CGI::ValidOp::Check::date::check_day('31','6',undef), 0);
    is(CGI::ValidOp::Check::date::check_day('31','7',undef), 1);
    is(CGI::ValidOp::Check::date::check_day('32','7',undef), 0);
    is(CGI::ValidOp::Check::date::check_day('31','8',undef), 1);
    is(CGI::ValidOp::Check::date::check_day('32','8',undef), 0);
    is(CGI::ValidOp::Check::date::check_day('30','9',undef), 1);
    is(CGI::ValidOp::Check::date::check_day('31','9',undef), 0);
    is(CGI::ValidOp::Check::date::check_day('31','10',undef), 1);
    is(CGI::ValidOp::Check::date::check_day('32','10',undef), 0);
    is(CGI::ValidOp::Check::date::check_day('30','11',undef), 1);
    is(CGI::ValidOp::Check::date::check_day('31','11',undef), 0);
    is(CGI::ValidOp::Check::date::check_day('31','12',undef), 1);
    is(CGI::ValidOp::Check::date::check_day('32','12',undef), 0);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for date::general

    check_check( 'date::general', undef, undef, 0);
    check_check( 'date::general', '2005', undef, 0);
    check_check( 'date::general', '31-3-1999', undef, 0);
    check_check( 'date::general', '3-31', undef, 0);
    check_check( 'date::general', '10-5-2006', '2006-10-05'); 
    check_check( 'date::general', '2004-1-31',  '2004-01-31' );
    check_check( 'date::general', '2004-02-29', '2004-02-29' );
    check_check( 'date::general', '2004-3-31',  '2004-03-31' );
    check_check( 'date::general', '2004-4-30',  '2004-04-30' );
    check_check( 'date::general', '2004-5-31',  '2004-05-31' );

    check_check( 'date::general', '1-1-1999', '1999-01-01');
    check_check( 'date::general', '1-1-1900', '1900-01-01');
    check_check( 'date::general', '1-15-1945', '1945-01-15');
    check_check( 'date::general', '02-03-1345', '1345-02-03');
    check_check( 'date::general', '2/29/2000', '2000-02-29');
    check_check( 'date::general', '2/30/2000', undef, 0);
    check_check( 'date::general', '9/31/1922', undef, 0);
    check_check( 'date::general', 'a date 9/31/1922', undef, 0);
    check_check( 'date::general', '9 - 31 - 1922', undef, 0);
    check_check( 'date::general', '9/31/1922withstuff', undef, 0);
    check_check( 'date::general', '9/31/1922 other stuff', undef, 0);


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for date::american

    check_check( 'date::american', undef, undef, 0);
    check_check( 'date::american', '2005', undef, 0);
    check_check( 'date::american', '31-3-1999', undef, 0);
    check_check( 'date::american', '3-31', undef, 0);
    check_check( 'date::american', '10-5-2006', '2006-10-05'); 
    check_check( 'date::american', '1-1-1999', '1999-01-01');
    check_check( 'date::american', '1-1-1900', '1900-01-01');
    check_check( 'date::american', '1-15-1945', '1945-01-15');
    check_check( 'date::american', '02-03-1345', '1345-02-03');
    check_check( 'date::american', '2/29/2000', '2000-02-29');
    check_check( 'date::american', '2/30/2000', undef, 0);
    check_check( 'date::american', '9/31/1922', undef, 0);
    check_check( 'date::american', 'a date 9/31/1922', undef, 0);
    check_check( 'date::american', '9 - 31 - 1922', undef, 0);
    check_check( 'date::american', '9/31/1922withstuff', undef, 0);
    check_check( 'date::american', '9/31/1922 other stuff', undef, 0);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# iso
        my $errmsg = 'William Blake must include year, month, and date as YYYY-MM-DD';
    check_check( 'date::iso', undef, undef, 0 );
    check_check( 'date::iso', 10, undef, 0, $errmsg );
    check_check( 'date::iso', '2004', undef, 0, $errmsg );
    check_check( 'date::iso', '2004-10', undef, 0, $errmsg );

    check_check( 'date::iso', 'y-1-1', undef, 0, $errmsg );
    check_check( 'date::iso', '1-m-1', undef, 0, $errmsg );
    check_check( 'date::iso', '1-1-d', undef, 0, $errmsg );

    check_check( 'date::iso', '2004-13-1', undef, 0, $errmsg );
    check_check( 'date::iso', '2004-0-1', undef, 0, $errmsg );
    check_check( 'date::iso', '2004-1-0', undef, 0, $errmsg  );

    check_check( 'date::iso', '2004-1-32',  undef, 0, $errmsg );
    check_check( 'date::iso', '2004-2-30',  undef, 0, $errmsg );
    check_check( 'date::iso', '2004-3-32',  undef, 0, $errmsg );
    check_check( 'date::iso', '2004-4-31',  undef, 0, $errmsg );
    check_check( 'date::iso', '2004-5-32',  undef, 0, $errmsg );
    check_check( 'date::iso', '2004-6-31',  undef, 0, $errmsg );
    check_check( 'date::iso', '2004-7-32',  undef, 0, $errmsg );
    check_check( 'date::iso', '2004-8-32',  undef, 0, $errmsg );
    check_check( 'date::iso', '2004-9-31',  undef, 0, $errmsg );
    check_check( 'date::iso', '2004-10-32', undef, 0, $errmsg );
    check_check( 'date::iso', '2004-11-31', undef, 0, $errmsg );
    check_check( 'date::iso', '2004-12-32', undef, 0, $errmsg );

    check_check( 'date::iso', '2004-1-31',  '2004-01-31' );
    check_check( 'date::iso', '2004-2-29',  '2004-02-29' );
    check_check( 'date::iso', '2004-3-31',  '2004-03-31' );
    check_check( 'date::iso', '2004-4-30',  '2004-04-30' );
    check_check( 'date::iso', '2004-5-31',  '2004-05-31' );
    check_check( 'date::iso', '2004-6-30',  '2004-06-30' );
    check_check( 'date::iso', '2004-7-31',  '2004-07-31' );
    check_check( 'date::iso', '2004-8-31',  '2004-08-31' );
    check_check( 'date::iso', '2004-9-30',  '2004-09-30' );
    check_check( 'date::iso', '2004-10-31', '2004-10-31' );
    check_check( 'date::iso', '2004-11-30', '2004-11-30' );
    check_check( 'date::iso', '2004-12-31', '2004-12-31' );

    check_check( 'date::iso', '1900-2-28', '1900-02-28' );
    check_check( 'date::iso', '1900-2-29', undef, 0, $errmsg );

    check_check( 'date::iso', '1904-2-28', '1904-02-28' );
    check_check( 'date::iso', '1904-2-29', '1904-02-29' );

    check_check( 'date::iso', '1996-2-28', '1996-02-28' );
    check_check( 'date::iso', '1996-2-29', '1996-02-29' );

    check_check( 'date::iso', '1997-2-28', '1997-02-28' );
    check_check( 'date::iso', '1997-2-29', undef, 0, $errmsg );

    check_check( 'date::iso', '2000-2-28', '2000-02-28' );
    check_check( 'date::iso', '2000-2-29', '2000-02-29' );

    check_check( 'date::iso', '2002-2-28', '2002-02-28' );
    check_check( 'date::iso', '2002-2-29', undef, 0, $errmsg );

    check_check( 'date::iso', '2003-2-28', '2003-02-28' );
    check_check( 'date::iso', '2003-2-29', undef, 0, $errmsg );

    check_check( 'date::iso', '2005-2-28', '2005-02-28' );
    check_check( 'date::iso', '2005-2-29', undef, 0, $errmsg );

    #Not a valid time, should ignore
    check_check( 'date::iso(bob)', '2005-2-28', '2005-02-28' );

    sub format_date {
        my ( $vectors ) = @_;
        my @date = ( $vectors->{ year }, $vectors->{ month }, $vectors->{ day });
        # Make sure each section is at least 2 characters long
        @date = map { (length( "$_" ) - 1) ? $_ : "0$_" } @date;
        return join( "-", @date );
    }
    my ( $y, $m, $d ) = CGI::ValidOp::Check::date::today();

    my %time_diff = (
      past => -1,
      present => 0,
      future => 1,
    );
    for my $time ( qw/ past present future /) {
        my $diff = $time_diff{$time};
        for my $vector ( qw/ year month day /) {
            my $vectors = {
                year => $y,
                month => $m,
                day => $d,
            };
            $vectors->{ $vector } += $diff;

            # Normlize
            # Unless we are checking the present or yesterday, assume the biggest day of the month is 28
            my $maxday = (
                $time eq 'present' or  
                ( $time eq 'past' and $vector eq 'day' )
            ) ? 31 : 28;
            if ( $vectors->{ day } > $maxday ) {
                $vectors->{ day } = 1;
                $vectors->{ month }++;
            }
            if ( $vectors->{ day } < 1 ) {
                $vectors->{ day } = $maxday;
                $vectors->{ month }--;
            }
            if ( $vectors->{ month } > 12 ) {
                $vectors->{ month } = 1;
                $vectors->{ year }++;
            }
            if ( $vectors->{ month } < 1  ) {
                $vectors->{ month } = 12;
                $vectors->{ year }--;
            }

            check_check( 
                'date::iso(' . $time . ')', 
                format_date( $vectors ), 
                format_date( $vectors )
            );

            for my $check ( qw/ past present future /) {
                next if $check eq $time;
                check_check( 
                    'date::iso(' . $check . ')', 
                    format_date( $vectors ), 
                    undef, 
                    0, 
                    "William Blake cannot be in the " . $time 
                );
            }
        }
    }

# vim:ft=perl
