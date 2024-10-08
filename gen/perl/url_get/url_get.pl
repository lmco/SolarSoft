#! /usr/local/bin/perl
#
# @(#)url_get.pl	1.15 27 Sep 1995
# @(#)url_get.pl	1.15 /home/magenta/cc/dc/zippy/src/perl/url_get/SCCS/s.url_get.pl
#
# url_get.pl      --- get a document given a WWW URL
#
# Modified by Kim Tolbert 11/9/2016 - changed word (... to Modified) in header so 
#  Goddard security scans wouldn't flag this as malicious
#
# Modified by Jack Lund 7/19/94 to add functionality and deal with HTTP
# 1.0 headers
#
# Modified by Stephane Bortzmeyer <bortzmeyer@cnam.cnam.fr> to add "ftp" URLs.
# 22 Jan 1994
#
# Jack Lund 9/3/93 zippy@ccwf.cc.utexas.edu
#
# from hget by:
# Oscar Nierstrasz 26/8/93 oscar@cui.unige.ch
#
# Syntax:
#
# &url_get($url, [$file])
#
# $url - URL of document you want
#
# $file - optional file you want it put into. Specify "&STDOUT" if you
#         want it to go to stdout; Leave this off if you want url_get to
#         return the document as one (possibly VERY LARGE) string
########################################################################

$home = $ENV{"HOME"};

require "URL.pl";
require "ftplib.pl";

sub url_get {
    local($url, $file) = @_;
    local($loseheader) = ($opt_h ? 0 : 1);
    local($debug) = ($opt_d ? 1 : 0);
    local($binary) = ($opt_b ? 1 : 0);
    local($dummy, $foo, $bar);

    ($protocol, $host, $port, $rest1, $rest2, $rest3) = &url'parse_url($url);

# Convert any characters in the string specified in hex by "%xx" to
# the correct character. Note we do this *after* parsing the URL!

    $rest1 =~ s/%(\w\w)/sprintf("%c", hex($1))/ge;

    if ($protocol eq "http") {
        if ($ENV{'http_proxy'}) {
            return &url_get'proxy_get($ENV{'http_proxy'},$url,
                                      $loseheader,$debug,$file);
        }
	return &url_get'http_get($host,$port,$rest1,$loseheader,$debug,$file);
    }

    if ($protocol eq "gopher") {
        if ($ENV{'gopher_proxy'}) {
            return &url_get'proxy_get($ENV{'gopher_proxy'},$url,
                                      $loseheader,$debug,$file);
        }

# Convert from hex. See above.

	$rest2 =~ s/%(\w\w)/sprintf("%c", hex($1))/ge if ($rest2);
	$rest3 =~ s/%(\w\w)/sprintf("%c", hex($1))/ge if ($rest3);

	return &url_get'gopher_get($host, $port, $rest1, $rest2, $rest3, $file);
    }

    if ($protocol eq "file" || $protocol eq "ftp") {
        if ($ENV{'ftp_proxy'}) {
            return &url_get'proxy_get($ENV{'ftp_proxy'},$url,
                                      $loseheader,$debug,$file);
        }
	return &url_get'file_get($host, $port, $rest1, $file, $binary, $debug);
    }

    if ($protocol eq "news") {
	return &url_get'news_get($host, $port, $rest1, $file);
    }

    if ($protocol eq "wais") {
        if ($ENV{'wais_proxy'}) {
            return &url_get'proxy_get($ENV{'wais_proxy'},$url,
                                      $loseheader,$debug,$file);
        } else {
            die "Error - WAIS protocol only supported through proxy server\n";
        }
    }

    die "Protocol $protocol not supported!\n";
}

package url_get;     # Everything after this is "private"

if ($] >= 5.0) {
    eval 'use Socket';
} else {
    eval 'require "sys/socket.ph"';
}

1;

# If there's a proxy defined, first we parse the environmental variable,
# then query the proxy server using http. The proxy info must be in the
# form of a URL; see http://www.w3.org/hypertext/WWW/Proxies/ClientSide.html
# for more info

sub proxy_get {
    local($proxy, $url, $loseheader, $debug, $file) = @_;
    local($dummy, $proxy_host, $proxy_port) = &url'parse_url($proxy);

    warn "Getting $url from proxy $proxy_host, port $proxy_port\n"
        if $debug;

    return &url_get'http_get($proxy_host,$proxy_port,$url,
                             $loseheader,$debug,$file);
}

sub http_get {
    local($host,$port,$request,$loseheader,$debug,$file) = @_;
    local($output) = "";
    local($redirect) = 0;
    local($location);

# Status code translation table. Key is HTTP status code (from
# http://info.cern.ch/hypertext/WWW/Protocols/HTTP/HTRESP.html),
# and value is status returned by url_get.

    %exit_status = (400,1,401,2,402,3,403,4,404,5,500,6,501,7,502,8,503,9);

    if ($file && !fileno(OUT)) { open(OUT, ">$file") || die "Error opening output file $file: $!\n"; }

    $ret = &url_get'open($host, $port);
    if (!defined($ret)) {
        if ($! && $! != "") {
            die "Error opening port $port on $host: $!\n";
        } else {
            die "Host not found: $host\n";
        }
    }
    print CMD "GET $request HTTP/1.0\r\nAccept: */*\r\n\r\n";
    $_ = <CMD>;
    if (! $_) {
	die "Server unexpectedly closed connection - exiting.\n";
    }

# First, read the HTTP header

    if (m#^HTTP/([\.0-9]*) (\d\d\d) (.+)$#) {
	$http_version = $1;
        $status = $2;
        $reason = $3;
        if (! $debug && $status > 399) {
            warn "Error returned from server: $status $reason\n";
	    return $exit_status{$status};
        }
	if ($status >= 300) {
	    $redirect = 1;
	}
    } else {
	warn "Error - bad HTTP header: $_\n";
    }
    if ($debug) {
	warn "$_";
    }
    elsif (! $loseheader && ! $redirect) {
	if ($file) { print OUT $_; }
	else { $output .= $_; }
    }

# Next, read the MIME header

    while (<CMD>) {
        last if (/^\s*$/);
	if ($redirect && /^Location: (.*)$/) {
	    $location = $1;
	}
	if ($debug) {
	    warn "$_";
	}
	elsif (!$loseheader && !$redirect) {
	    if ($file) { print OUT $_; }
            else { $output .= $_; }
	}
	else {
            if (! /^[a-zA-Z\-]+: /) {
                warn "Bad MIME header line: $_";
            }
	}
    }
    if (! $_) {
	die "Server unexpectedly closed connection - exiting.\n";
    }
    if (! $debug && ! $loseheader && ! $redirect) {
	if ($file) { print OUT $_; }
        else { $output .= $_; }
    }

# Finally, read the rest

    while (<CMD>) {
	last if ($redirect && !$debug);
	if ($file) { print OUT $_; }
        else { $output .= $_; }
    }
    close(CMD);

# If we've been redirected to another location, get it there...

    if ($redirect && $location) {
	if (!$debug) {
	    warn "The item has been moved to URL: $location.\n";
	    warn "Attempting to obtain it from there...\n";
	}
	return &main'url_get($location, $file);
    }
    close(OUT) if ($file);
    return($output) unless ($file);
}

sub gopher_get {
    local($host,$port,$gtype,$selector,$search,$file) = @_;
    local($bintypes) = "59sgI";       # Binary gopher types
    local($goodtypes) = "01579sghI";  # types we can handle
    local($output) = "";

    if ($file && !fileno(OUT)) { open(OUT, ">$file") || die "Error opening output file $file: $!\n"; }
    $request = ($search ? "$selector\t$search\t\$" : $selector);
    &url_get'open($host, $port)
        || die "Error opening port $port on $host: $!\n";
    print CMD "$request\n";

    if (index($goodtypes, $gtype) == -1) {
	die "Can't retrieve gopher type $gtype\n";
    }

# If this is a binary document, retreive it using sysreads rather
# than <CMD>

    if (index($bintypes, $gtype) > -1) {
	$done = 0;
	$rmask = "";
	vec($rmask,fileno(CMD),1) = 1;
	do {
	    ($nfound, $timeleft) =
		select($rmask, undef, undef, $timeout);
	    if ($nfound) {
		$nread = sysread(CMD, $thisbuf, 1024);
		if ($nread > 0) {
                    $output .= $thisbuf;
                    if ($file)
                    {
		        syswrite(OUT, $thisbuf, $nread)
                            || die "Syswrite: $!\n";
                    } else {
                        $output .= $thisbuf;
                    }
		} else {
		    $done++;
		}
	    } else {
		warn "Timeout\n"; $done++;
	    }
	} until $done;
    }

# This is an ASCII document, and we can get it line-by-line using <CMD>

    else {
	while (<CMD>) {
	    last if (/^\.\r\n$/);
	    chop; chop;
            if ($file) { print OUT "$_\n"; }
            else { $output .= "$_\n"; }
	}
    }
    close(CMD);
    close(OUT) if ($file);
    return($output) unless ($file);
}

sub file_get {
    local($host, $port, $path, $file, $bin_xfer, $debug) = @_;
    local($error);
    local($output) = "";

    if ($host eq "localhost" && !defined($port)) {
	open(IN, $path) || die "$path: $!\n";
	$binary = ((-B $path) ? 1 : 0);
	warn "binary = $binary\n";
	if ($file && !fileno(OUT)) { open(OUT, ">$file") || die "Error opening output file $file: $!\n"; }
	if ($binary)
	{
	    $done = 0;
	    $rmask = "";
	    vec($rmask,fileno(CMD),1) = 1;
	    do {
		($nfound, $rmask) =
		    select($rmask, undef, undef, $timeout);
		if ($nfound) {
		    $nread = sysread(CMD, $thisbuf, 1024);
		    if ($nread > 0) {
		        if ($file)
                        {
                            syswrite(OUT, $thisbuf, $nread)
                                || die "Syswrite: $!\n";
                        } else { $output .= $thisbuf; }
		    } else {
			$done++;
		    }
		} else {
		    warn "Timeout\n"; $done++;
		}
	    } until $done;
	}
	else
	{
	    while (<IN>) {
		if ($file) { print OUT "$_"; }
		else { $output .= "$_"; }
	    }
	}
	close(IN);
	close(OUT) if ($file);
    }
    else {
	&ftp'open($host) || die "Unable to open ftp connection to $host: $ftp'Error\n";
        if ($bin_xfer && ! &ftp'type("I")) {
            $error=&ftp'error;
            die "$error\n";
        }
        if ($file) { &ftp'get($path, $file)
	    || die "Unable to get file $path from $host: $ftp'Error\n"; }
	else { $output = &ftp'gets($path)
	    || die "Unable to get file $path from $host: $ftp'Error\n"; }
	&ftp'close;
    }
    return($output) unless ($file);
}

sub news_get {
    local($host, $port, $article) = @_;
    local($output) = "";

    if ($file && !fileno(OUT)) { open(OUT, ">$file") || die "Error opening output file $file: $!\n"; }
    &url_get'open($host, $port)
        || die "Error opening port $port on $host: $!\n";

    if ($article =~ /^[^<].+@.+[^>]$/) {
	$request = "article <$article>";
    }
    elsif ($article =~ /^<.+@.+>$/) {
	$request = "article $article";
    }
    elsif ($article =~ /^\*$/) {
	die "Only support URLs of the form: news:article\n";
    }
    elsif ($article) {
	die "Only support URLs of the form: news:article\n";
    }
    else {
	die "Bad url\n";
    }

# Read NNTP Connect message

    $string = <CMD>;
    $string =~ /^(\d*) (.*)$/;
    die "NNTP Error: $2\n" unless ($1 eq '200');

# Send request

    print CMD "$request\r\n";

# Read reply message

    $string = <CMD>;
    $string =~ /^(\d*) (.*)$/;
    die "NNTP Error: $2\n" unless ($1 eq '220');

# Get article

    while (<CMD>) {
	last if (/^\.\r\n$/);
	chop; chop;
        if ($file) { print OUT "$_\n"; }
        else { $output .= "$_\n"; }
    }
    print CMD "quit\n";
    close(CMD);
    close(OUT) if ($file);
    return($output) unless ($file);
}

sub open {
    local($Host, $Port) = @_;
    local($destaddr, $destproc);

# Set the socket parameters. Note that we set the defaults to be the
# BSD values if we can't get them from the required files. Also note
# that, in the 4.0 version, the routines are in package ftp, since
# it does the "require sys/socket.ph" first.

    if ($] < 5.0) {
        (eval {$Inet = &ftp'AF_INET;}) || ($Inet=2);
        (eval {$Stream = &ftp'SOCK_STREAM;}) || ($Stream=1);
    } else {
        (eval {$Inet = &AF_INET;}) || ($Inet=2);
        (eval {$Stream = &SOCK_STREAM;}) || ($Stream=1);
    } 
#    warn "Inet = $Inet, Stream = $Stream\n";

    if ($Host =~ /^(\d+)+\.(\d+)\.(\d+)\.(\d+)$/) {
	$destaddr = pack('C4', $1, $2, $3, $4);
    } else {
	local(@temp) = gethostbyname($Host);
	unless (@temp) {
           $Error = "Can't get IP address of $Host";
           return undef;
        }
	$destaddr = $temp[4];
    }

    $Proto = (getprotobyname("tcp"))[2];
    $Sockaddr = 'S n a4 x8';
    $destproc = pack($Sockaddr, $Inet, $Port, $destaddr);
    if (socket(CMD, $Inet, $Stream, $Proto)) {
       if (connect(CMD, $destproc)) {

          ### This info will be used by future data connections ###
          $Cmdaddr = (unpack ($Sockaddr, getsockname(CMD)))[2];
          $Cmdname = pack($Sockaddr, $Inet, 0, $Cmdaddr);

          select((select(CMD), $| = 1)[$[]);

          return 1;
       }
    }

    close(CMD);
    return undef;
}
