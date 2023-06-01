#!/usr/bin/perl

INIT {
    our %nocap;
    for (
        qw(
        a an the and but or as at but by for from in into of off on onto per to with
        )
      )
    {
        $nocap{$_}++;
    }
}

sub tc {
    local $_ = shift;

    # put into lowercase if on stop list, else titlecase
    s/(\pL[\pL']*)/$nocap{$1} ? lc($1) : ucfirst(lc($1))/ge;
    s/^(\pL[\pL']*) /\u\L$1/x;

    # last word guaranteed to cap s/ (\pL[\pL']*)$/\u\L$1/x;
    # first word guaranteed to cap
    # treat parenthesized portion as a complete title
    s/\( (\pL[\pL']*) /(\u\L$1/x;
    s/(\pL[\pL']*) \) /\u\L$1)/x;

    # capitalize first word following colon or semi-colon
    s/ ( [:;] \s+ ) (\pL[\pL']* ) /$1\u\L$2/x;
    return $_;
}
