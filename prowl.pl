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
# - on/off/auto support
# - include/exclude channels regex
# - async $prowl->verify -- example at https://github.com/shabble/irssi-scripts/blob/master/feature-tests/pipes.pl

our $VERSION = '1.6';
our %IRSSI = (
    authors     => 'Henrik Brix Andersen',
    contact     => 'henrik@brixandersen.dk',
    name        => 'prowl',
    description => 'Send Prowl notifications from Irssi',
    license     => 'BSD',
    url         => 'https://github.com/henrikbrixandersen/irssi-prowl',
    modules     => 'WebService::Prowl',
    commands    => 'prowl',
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

# Theme
Irssi::theme_register([
    'prowl_event_msgs',    'Private Message from $0',
    'prowl_event_hilight', 'Hilighted in $0',
    'prowl_event_cmd',     'Manual Message',
    'prowl_url_msgs',      '$0://$1:$3/',
    'prowl_url_hilight',   '$0://$1:$3/$4',
                      ]);

sub setup_changed_handler {
    $config{debug} = Irssi::settings_get_bool('prowl_debug');

    for (qw/msgs hilight cmd/) {
        my $priority = Irssi::settings_get_int("prowl_priority_$_");
        if ($priority < -2 || $priority > 2) {
            $priority = -2 if ($priority < -2);
            $priority = 2 if ($priority > 2);
            Irssi::settings_set_int("prowl_priority_$_", $priority);
            Irssi::signal_emit('setup changed');
        }
        $config{"priority_$_"} = $priority;
    }

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

sub _create_url {
    my ($server, $target, $format_name) = @_;
    my $url;

    if ($server->{chat_type} eq 'IRC') {
        my $format = Irssi::current_theme()->get_format('Irssi::Script::prowl', $format_name);

        my $data = ($server->{use_ssl} ? 'ircs' : 'irc'); # $0 = irc/ircs
        $data .= ' ' . $server->{address};                # $1 = server address
        $data .= ' ' . $server->{chatnet};                # $2 = chatnet
        $data .= ' ' . $server->{port};                   # $3 = server port
        $data .= ' ' . $target;                           # $4 = channel/nick

        $url = Irssi::parse_special($format, $data);
    }

    return $url;
}

sub print_text_handler {
    my ($dest, $text, $stripped) = @_;
    my $server = $dest->{server};
    my $level = $dest->{level};

    if ($server->{usermode_away}) {
        if (($level & MSGLEVEL_MSGS) || ($level & MSGLEVEL_HILIGHT && !($level & MSGLEVEL_NOHILIGHT))) {
            my $target = $dest->{target};
            my $type = ($level & MSGLEVEL_MSGS) ? 'msgs' : 'hilight';
            my $url = _create_url($server, $target, "prowl_url_$type");
            my $format = Irssi::current_theme()->get_format('Irssi::Script::prowl', "prowl_event_$type");
            my $event = Irssi::parse_special($format, $target); # $0 = channel/nick

            _prowl($event, $stripped, $config{priority_msgs}, $url);
        }
    }
}

sub help_command_handler {
    my ($data, $server, $witem) = @_;
    $data =~ s/\s+$//g;

    if (lc($data) eq 'prowl') {
        Irssi::print("\nPROWL [-url <url>] [-priority <priority>] [text]\n\n" .
                     "Send a manual Prowl notification.\n\n" .
                     "See also: /SET PROWL, /FORMAT PROWL\n",
                     MSGLEVEL_CLIENTCRAP);
        Irssi::signal_stop;
    }
}

sub prowl_command_handler {
    my ($data, $server, $witem) = @_;
    $data =~ s/\s+$//g;

    my @options = Irssi::command_parse_options('prowl', $data);
    if (@options) {
        my $args = $options[0];
        my $text = $options[1];

        my $format = Irssi::current_theme()->get_format('Irssi::Script::prowl', 'prowl_event_cmd');
        my $event = Irssi::parse_special($format);

        $args->{priority} = $config{priority_cmd} unless exists $args->{priority};
        $args->{priority} = -2 if ($args->{priority} < -2);
        $args->{priority} = 2 if ($args->{priority} > 2);
        $text = ' ' unless $text;
        _prowl($event, $text, $args->{priority}, $args->{url});
    }
}

sub _prowl {
    my ($event, $description, $priority, $url) = @_;

    my %options = (application => 'Irssi', event => $event, description => $description);
    $options{priority} = $priority if defined $priority;
    $options{url} = $url if defined $url;

    if ($config{debug}) {
        my $debuginfo = join(', ', map { "$_ => '$options{$_}'" } sort keys %options);
        Irssi::print("Sending Prowl notification: $debuginfo", MSGLEVEL_CLIENTCRAP);
    }

    if ($config{apikey}) {
        Irssi::print('Error sending Prowl notificaton: ' . $prowl->error) unless $prowl->add(%options);
    } else {
        Irssi::print('Prowl API key not set, use \'/set prowl_apikey\' to set a valid key',
                     MSGLEVEL_CLIENTERROR);
    }
}
