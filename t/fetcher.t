#!/usr/bin/env perl

use strict;
use Test::More tests => 6;
use Agora::Fetcher;

my $url = 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js';
my $filename = 't-jquery.min.js';

my $fetcher = Agora::Fetcher->new;
ok($fetcher, "constructor should be worked");

unlink $filename;

my $status200 = $fetcher->fetch($url, $filename);
ok($status200 == 200, "status code should be 200, but got ". $status200);
ok(-e $filename, "downloaded file should exist");

my $mtime = (stat $filename)[9];
sleep 1;

my $status304 = $fetcher->fetch($url, $filename);
ok($status304 == 304, "status code should be 304, but got ". $status304);
ok(-e $filename, "downloaded file should exist");
ok($mtime == (stat $filename)[9], "downloaded file should not be changed");

unlink $filename;
