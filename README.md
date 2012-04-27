# irssi-prowl

[Irssi](http://www.irssi.org/) script for sending
[Prowl](http://www.prowlapp.com/) notifications.

## Features

* Notifications on all hilights when away
* Notifications on private messages when away
* Notifications on private actions (``/me``) when away
* Manual notifications using the ``/prowl`` command
* Customizable priority levels for Prowl notifications
* Customizable IRC URLs for Prowl notifications
* Customizable event strings for Prowl notifications

## Planned Features

* On/off/auto setting
* Include/exclude channel/nick regular expressions setting

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
