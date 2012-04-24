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
# - IRC URL support
# - priority verification
# - on/off/auto support
# - async $prowl->verify -- example at https://github.com/shabble/irssi-scripts/blob/master/feature-tests/pipes.pl
# - theme support for prowl event strings

our $VERSION = '1.2';
our %IRSSI = (
    authors     => 'Henrik Brix Andersen',
    contact     => 'henrik@brixandersen.dk',
    name        => 'prowl',
    description => 'Send Prowl notifications from Irssi',
    license     => '2-clause BSD',
    url         => 'https://raw.github.com/henrikbrixandersen/irssi-prowl/master/prowl.pl',
    );

my $prowl;
my %config = ( apikey => '' );

# Settings
Irssi::settings_add_str('prowl', 'prowl_apikey', '');
Irssi::settings_add_bool('prowl', 'prowl_debug', 0);
Irssi::settings_add_int('prowl', 'prowl_priority_msgs', 0);
Irssi::settings_add_int('prowl', 'prowl_priority_hilight', 0);
Irssi::settings_add_int('prowl', 'prowl_priority_cmd', 0);

# Signals
Irssi::signal_add('setup changed' => 'setup_changed_handler');
setup_changed_handler();
Irssi::signal_add('print text' => 'print_text_handler');

# Commands
Irssi::command_bind('help', 'help_command_handler');
Irssi::command_bind('prowl', 'prowl_command_handler');
Irssi::command_set_options('prowl', '-url @priority');

sub setup_changed_handler {
    $config{debug} = Irssi::settings_get_bool('prowl_debug');
    $config{priority_msgs} = Irssi::settings_get_int('prowl_priority_msgs');
    $config{priority_hilight} = Irssi::settings_get_int('prowl_priority_hilight');
    $config{priority_cmd} = Irssi::settings_get_int('prowl_priority_cmd');

    my $apikey = Irssi::settings_get_str('prowl_apikey');
    if ($apikey) {
        if ($apikey ne $config{apikey}) {
            $prowl = WebService::Prowl->new(apikey => $apikey);
            if (!$prowl->verify) {
                Irssi::print('Could not verify Prowl API key: ' . $prowl->error,
                             MSGLEVEL_CLIENTERROR);
            }
        }
    } else {
        $prowl = undef;
    }
    $config{apikey} = $apikey;
}

sub print_text_handler {
    my ($dest, $text, $stripped) = @_;
    my $server = $dest->{server};
    my $level = $dest->{level};
    my $target = $dest->{target};

    if ($level & MSGLEVEL_MSGS) {
        prowl("Private Message from $target", $stripped, $config{priority_msgs})
            if $server->{usermode_away};
    } elsif ($level & MSGLEVEL_HILIGHT && !($level & MSGLEVEL_NOHILIGHT)) {
        prowl("Hilighted in $target", $stripped, $config{priority_hilight})
            if $server->{usermode_away};
    }
}

sub help_command_handler {
    my ($data, $server, $witem) = @_;
    $data =~ s/\s+$//g;

    if (lc($data) eq 'prowl') {
        Irssi::print("\nPROWL [-url <url>] [-priority <priority>] <text>\n\n" .
                     "Send a manual Prowl notification.\n",
                     MSGLEVEL_CLIENTCRAP);
        Irssi::signal_stop;
    }
}

sub prowl_command_handler {
    my ($data, $server, $witem) = @_;
    my @options = Irssi::command_parse_options('prowl', $data);

    if (@options) {
        my $args = $options[0];
        my $text = $options[1];

        $args->{priority} = $config{priority_cmd} unless exists $args->{priority};

        if ($text) {
            prowl('Manual Message', $text, $args->{priority}, $args->{url});
        } else {
            Irssi::print('Missing text argument, see \'/help prowl\' for usage',
                         MSGLEVEL_CLIENTERROR);
        }
    }
}

sub prowl {
    my ($event, $description, $priority, $url) = @_;

    my %options = (application => 'Irssi', event => $event, description => $description);
    $options{priority} = $priority if defined $priority;
    $options{url} = $url if defined $url;

    if ($config{debug}) {
        my $debuginfo = join(', ', map { "$_ => '$options{$_}'" } sort keys %options);
        Irssi::print("Sending Prowl notication: $debuginfo", MSGLEVEL_CLIENTCRAP);
    }

    if ($config{apikey}) {
        Irssi::print('Error sending Prowl notificaton: ' . $prowl->error) unless $prowl->add(%options);
    } else {
        Irssi::print('Prowl API key not set, use \'/set prowl_apikey\' to set a valid key',
                     MSGLEVEL_CLIENTERROR);
    }
}
