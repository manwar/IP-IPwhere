package IP::IPwhere;

use 5.006;
use strict;
use warnings;
use Data::Dumper;
use LWP::Simple;
use JSON;
use Encode;

our @ISA = qw(Exporter);
our @EXPORT =
  qw(squery query getTbeIParea getSinaIParea getBaiduIParea getPcoIParea);

=head1 NAME

IP::IPwhere - IP address search whith baidu,taobao,sina,pconlie public IP API!

批量ip归属地查询，调用阿里新浪、百度和pconline ip库api接口,也可以增加纯真库，单独
查询，没有整合到本模块中。

试用方法： ./ipwhere.pl 8.8.8.8 8.8.8.6

需要安装perl及扩展LWP::Simple；use JSON;

建议通过cpanm LWP::Simple JSON 一键安装。

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

use IP::IPwhere; 
print query(\@ARGV);


=head1 EXPORT


=cut

my %ipcache;
my $DEBUG = 0;

sub squery {

    my $ip = shift;
    my $result;
    $result .= getTbeIParea($ip);
    $result .= getSinaIParea($ip);
    $result .= getBaiduIParea($ip);
    $result .= getPcoIParea($ip);
    return $result;

}

sub query {

    my $ip = shift;
    my $result;

    for ( validIP( @{$ip} ) ) {

        $result .= getTbeIParea($_);
        $result .= getSinaIParea($_);
        $result .= getBaiduIParea($_);
        $result .= getPcoIParea($_);
    }
    return $result;
}

sub validIP() {
    my @ip  = @_;
    my $re  = qr([0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]);
    my @oip = grep { /^($re\.){3}$re$/ } @_;
    return @oip;
}

sub gbk2utf {

    my $str = shift;
    return encode( "utf-8", decode( "gbk", $str ) );
    return;

}

sub cached {
    my $ip = shift;
    print "DEBUG\::cached\::IN $ip\n" if $DEBUG;
    return $ipcache{$ip} ? 1 : 0;
}

sub clear {

    my $ip = shift;
    print "DEBUG\::clear\::IN $ip\n" if $DEBUG;
    if ($ip) {
        undef $ipcache{$ip};
    }
    else {
        undef %ipcache;
    }
}

sub getBaiduIParea() {

    my $ip  = shift;
    my $key = "BD_" . $ip;
    return decode( "gbk", $ipcache{$key} ) if exists( $ipcache{$key} );

    my $url =
qq(http://opendata.baidu.com/api.php?query=$ip&co=&resource_id=6006&t=1433920989928&ie=utf8&oe=gbk&format=json);
    my $code = get($url);

    #my $jso=$1 if $code =~/var remote_ip_info =(.*);$/;
    print $code, "\n" if $DEBUG;
    my $json = new JSON;
    my $obj = $json->decode($code) if $code;
    print Dumper($obj), "\n" if $DEBUG;
    print "baidu $_:$obj->{msg}\n" if $DEBUG;
    my $ipArea = "baidu $ip:$obj->{data}->[0]->{location}\n";
    $ipcache{$key} = $ipArea;
    return decode( "gbk", $ipArea );
}

sub getPcoIParea() {

    my $ip  = shift;
    my $key = "pco_" . $ip;
    return $ipcache{$key} if exists( $ipcache{$key} );

    #print $ip,"\n";
    my $url  = qq(http://whois.pconline.com.cn/ipJson.jsp?callback=YSD&ip=$ip);
    my $code = get($url);

    #print $code,"\n";
    my $jso = $1 if $code =~ /\{YSD\((.*)\)\;\}$/ms;

    #print $jso,"\n";
    my $json = new JSON;
    my $obj = $json->decode($jso) if $jso;

    #print Dumper($obj),"\n";
    #print "pconline $_:$obj->{msg}\n if $DEBUG";
    my $ipArea =
      "pconline $ip:$obj->{pro},$obj->{city},$obj->{region},$obj->{addr}\n";
    $ipcache{$key} = $ipArea;
    return $ipArea;
}

sub getSinaIParea() {
    my $ip  = shift;
    my $key = "SL_" . $ip;
    return $ipcache{$key} if exists( $ipcache{$key} );
    my $url =
      qq(http://int.dpool.sina.com.cn/iplookup/iplookup.php?format=js&ip=$ip);
    my $code = get($url);
    my $jso = $1 if $code =~ /var remote_ip_info =(.*);$/;

    #print $jso,"\n";
    my $json = new JSON;
    my $obj  = $json->decode($jso);

    #print Dumper($obj),"\n";
    my $ipArea =
      "sina $ip:$obj->{country},$obj->{province},$obj->{city},$obj->{isp}\n";
    $ipcache{$key} = $ipArea;
    return $ipArea;
}

sub getTbeIParea() {
    my $ip  = shift;
    my $key = "TB_" . $ip;
    unless ( exists( $ipcache{$key} ) ) {
        my $url  = qq(http://ip.taobao.com/service/getIpInfo.php?ip=$ip);
        my $code = get($url);

        #print Dumper($code),"\n";
        my $json = new JSON;
        if ($code) {
            my $obj = $json->decode($code);
            my $ipArea =
"taobao $obj->{data}->{ip}:$obj->{data}->{country},$obj->{data}->{region},$obj->{data}->{city},$obj->{data}->{isp}\n";
            $ipcache{$key} = $ipArea;

            return $ipArea;
        }
        else { return }
    }
    else {

        return $ipcache{$key};

    }

}

=head1 AUTHOR

Orange, C<< <bollwarm at ijz.me> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ip-ipwhere at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IP-IPwhere>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IP::IPwhere


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IP-IPwhere>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IP-IPwhere>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IP-IPwhere>

=item * Search CPAN

L<http://search.cpan.org/dist/IP-IPwhere/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Orange.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
=cut

1