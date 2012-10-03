package Agora::Constant;

use strict;
use warnings;

sub new { return bless {}, $_[0]; }

use constant LOCAL_BASE => "programs";

use constant {
	REMOTE_INDEX  => "http://scienceagora.org/scienceagora/agora2012/program/",
	REMOTE_DETAIL => "http://scienceagora.org/scienceagora/agora2012/program/summary/%s.html",
};

use constant {
	LOCAL_INDEX  => LOCAL_BASE. "/index.html",
	LOCAL_DETAIL => LOCAL_BASE. "/%s.html",
};


1;
