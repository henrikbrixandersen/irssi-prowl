# irssi-prowl

[Irssi](http://www.irssi.org/) script for sending
[Prowl](http://www.prowlapp.com/) notifications.

## Features

* Notifications on all hilights when away
* Notifications on private messages when away
* Notifications on private actions (``/me``) when away
* Manual notifications using ``/prowl [-url <url>] [-priority <priority>] <text>``

## Installing

This script depends on
[WebService::Prowl](http://search.cpan.org/dist/WebService-Prowl/). To
install this dependency, run the following command in your terminal:

    cpan WebService::Prowl

Hint: You don't need root access to install perl modules, check out
[local::lib](http://search.cpan.org/dist/local-lib/)

Download
[prowl.pl](https://raw.github.com/henrikbrixandersen/irssi-prowl/master/prowl.pl)
and place it in ``~/.irssi/scripts/``.

## Usage

To activate the script, run the following commands in Irssi:

    /script load prowl
    /set prowl_apikey 0123456789abcdef0123456789abcdef01234567
    /save

You can manually send Prowl notifications using the following command:

    /prowl [-url <url>] [-priority <priority>] <text>

To assist in debugging, turn on the following setting:

    /set prowl_debug on

## License

This script is licensed under the 2-clause BSD license. See the script
header for the license text.
