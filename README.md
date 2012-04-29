# irssi-prowl

[Irssi](http://www.irssi.org/) script for sending [Prowl](http://www.prowlapp.com/) notifications.

Why yet another Irssi-to-Prowl bridge, you ask?
Well, basically because I was unhappy with the lack of features in all the existing bridges, I could find.

The aim of this script is to be feature-rich while still being able to function out of the box for the casual user.
Patches and feature requests are most welcome.

## Features

* Notifications on hilights
* Notifications on private messages
* Notifications on private actions (``/me``)
* Setting for always sending notifications, never sending notifications or only sending notifications when Irssi is marked as being away (default)
* Manual notifications using the ``/prowl`` command
* Regular expressions for including/excluding channels/nicks
* Customizable priority levels for Prowl notifications
* Customizable IRC URLs for Prowl notifications (useful for quickly pointing your local iOS IRC client to the right server and channel)
* Customizable event strings for Prowl notifications

## Installation

This script depends on the
[WebService::Prowl](http://search.cpan.org/dist/WebService-Prowl/)
perl module. To install this dependency, run the following command in
your terminal (Hint: You don't need root access to install perl
modules, check out
[local::lib](http://search.cpan.org/dist/local-lib/)):

    cpan WebService::Prowl

Download
[prowl.pl](https://raw.github.com/henrikbrixandersen/irssi-prowl/master/prowl.pl)
and place it in ``~/.irssi/scripts/``.

## Usage

To activate the script, run the following commands in Irssi, replacing
``0123456789abcdef0123456789abcdef01234567`` with your desired [Prowl
API key](https://www.prowlapp.com/api_settings.php):

    /script load prowl
    /set prowl_apikey 0123456789abcdef0123456789abcdef01234567
    /save

The script will now send out Prowl notifications whenever Irssi is
marked as being away. Prowl notifications can also be sent manually
using the ``/prowl`` command:

    /help prowl
    /prowl Hello, world
    /prowl -url https://github.com/henrikbrixandersen/irssi-prowl -priority 2 Check out this cool irssi-prowl script!

## Configuration

### Settings

To change the priority level of the Prowl notifications for private
messages, hilights and the default priority for the ``/prowl``
command, use the following settings:

    /set prowl_priority_msgs 1
    /set prowl_priority_hilight 0
    /set prowl_priority_cmd -2
    /save

By default, Prowl notifications for private messages and hilights are
only sent when Irssi is marked as being away. This can be changed
using the following setting:

    /set prowl_mode ON
    /set prowl_mode OFF
    /set prowl_mode AUTO

``ON`` will always send Prowl notifications, ``OFF`` will turn off all
Prowl notifications except for the ``/prowl`` command and ``AUTO``
will only send Prowl notifications when Irssi is marked as being away.

To limit which channels/nicks will send Prowl notifications, change
the following regular expression settings:

    /set prowl_regex_include ^#
    /set prowl_regex_exclude ^#noise$

To assist in debugging, turn on the ``prowl_debug`` setting:

    /set prowl_debug on

### Theming

To change the Prowl event strings for private messages, hilights and
the ``/prowl`` command, use the following settings:

    /format prowl_event_msgs PM from $0
    /format prowl_event_hilight Mentioned in $0
    /format prowl_event_cmd Remember
    /save

For the first two, ``$0`` will be replaced with the respective nick or channel.

The format of the URLs passed to Prowl for private messages and
hilights can be controlled with the following settings:

    /format prowl_url_msgs $0://$1:$3/
    /format prowl_url_hilight $0://$1:$3/$4
    /save

For both of these, ``$0`` will be replaced with either ``irc`` or
``ircs`` depending on whether the respective server uses SSL or
not. ``$1`` will be replaced with the server address, ``$2`` with the
name of the chat network, ``$3`` with the server port number and
``$4`` with the respective nick or channel.

The default URL formats are rather conservative in order to support
the largest number of iOS IRC clients. For
[draft-butcher-irc-url-04](http://tools.ietf.org/html/draft-butcher-irc-url-04)
compliant IRC URLs, one could use the following formats:

    /format prowl_url_msgs $0://$1:$3/$4,isuser,isserver
    /format prowl_url_hilight $0://$2:$3/$4,ischannel,isnetwork
    /save

## License

This software is licensed under the 2-clause BSD license. See the
script header for the full license text.
