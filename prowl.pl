# Copyright (c) 2012 Henrik Brix Andersen <henrik@brixandersen.dk>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

use strict;
use warnings;

use Irssi;
use WebService::Prowl;

# TODO:
# - manual prowl command with automatic URL detection
# - customizable prowl levels
# - customizable URL support
# - on/off/auto support
# - async $ws->verify -- example at https://github.com/shabble/irssi-scripts/blob/master/feature-tests/pipes.pl
# - $ws->add return value check
# - respond to /help prowl -- example at https://github.com/shabble/irssi-docs/wiki/Guide
# - theme support for prowl event strings

our $VERSION = '1.0';
our %IRSSI = (
    authors     => 'Henrik Brix Andersen',
    contact     => 'henrik@brixandersen.dk',
    name        => 'prowl',
    description => 'Send Prowl notifications from Irssi',
    license     => '2-clause BSD',
    url         => 'https://raw.github.com/henrikbrixandersen/irssi-prowl/master/prowl.pl',
    );

my $prowl;

Irssi::settings_add_str('prowl', 'prowl_apikey', '');
Irssi::signal_add('setup changed' => 'setup_changed_handler');
setup_changed_handler();

sub setup_changed_handler {
    my $apikey = Irssi::settings_get_str('prowl_apikey');

    if ($apikey) {
        $prowl = WebService::Prowl->new(apikey => $apikey);

        if ($prowl->verify) {
            Irssi::signal_add('print text' => 'print_text_handler');
        } else {
            Irssi::print('Invalid Prowl API key, use \'/set prowl_apikey\' to set a valid key',
                         MSGLEVEL_CLIENTERROR);
            Irssi::signal_remove('print text' => 'print_text_handler');
            $prowl = undef;
        }
    }
}

sub print_text_handler {
    my ($dest, $text, $stripped) = @_;
    my $server = $dest->{server};
    my $level = $dest->{level};
    my $target = $dest->{target};

    if ($level & MSGLEVEL_MSGS) {
#        Irssi::print("msg: $stripped", MSGLEVEL_CLIENTCRAP & MSGLEVEL_NOHILIGHT);
        prowl("Private Message from $target", $stripped) if $server->{usermode_away};
    } elsif ($level & MSGLEVEL_HILIGHT && !($level & MSGLEVEL_NOHILIGHT)) {
#        Irssi::print("hilight: $stripped", MSGLEVEL_CLIENTCRAP & MSGLEVEL_NOHILIGHT);
        prowl("Hilighted in $target", $stripped) if $server->{usermode_away};
    }
}

sub prowl {
    my ($event, $text) = @_;

    if ($prowl) {
        $prowl->add(application => 'Irssi', event => $event, description => $text);
    } else {
        Irssi::print('Invalid Prowl API key, use \'/set prowl_apikey\' to set a valid key',
                     MSGLEVEL_CLIENTERROR);
    }
}
