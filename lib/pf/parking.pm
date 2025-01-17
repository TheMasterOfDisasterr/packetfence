package pf::parking;

=head1 NAME

pf::parking - module to manage parked device.

=cut

=head1 DESCRIPTION

Contains the necessary methods to manage parked devices

=cut

use strict;
use warnings;

use pf::log;
use pf::security_event;
use pf::constants::parking qw($PARKING_SECURITY_EVENT_ID $PARKING_DHCP_GROUP_NAME);
use pf::constants;
use pf::config qw(%Config);
use pf::util;
use pf::api::unifiedapiclient;

=head2 trigger_parking

Trigger the parking actions for a device if needed
Will check if there is already a parking security_event opened, if not, will open one
Will make sure the proper parking actions are applied

=cut

sub trigger_parking {
    my ($mac) = @_;
    if(security_event_count_open_security_event_id($mac, $PARKING_SECURITY_EVENT_ID) || security_event_trigger( { mac => $mac, tid => 'parking_detected', type => 'INTERNAL' } )){
        park($mac);
    }
}

=head2 park

Park a device by making its lease higher and by pointing it to another portal

=cut

sub park {
    my ($mac) = @_;
    get_logger->debug("Setting client in parking");
    if(isenabled($Config{parking}{place_in_dhcp_parking_group})){
        pf::api::unifiedapiclient->default_client->call("POST", "/api/v1/dhcp/options/mac/".$mac, [{
            "option"      => 0 + 51,
            "value"       => "3600",
            "type"        => "int",
        }]);
    }
}

=head2 unpark

Attempt to unpark a device. The parking security_event needs to be successfully closed for the actions to be removed.

=cut

sub unpark {
    my ($mac) = @_;
    if(security_event_close($mac, $PARKING_SECURITY_EVENT_ID) != -1){
        remove_parking_actions($mac);
        return $TRUE;
    }
    else {
        get_logger->info("Device $mac cannot be unparked since the security_event cannot be closed");
        return $FALSE;
    }
}

=head2 remove_parking_actions

Remove the parking actions that were taken against an IP + MAC

=cut

sub remove_parking_actions {
    my ($mac) = @_;
    get_logger->info("Removing parking actions for $mac");
    eval {
        pf::api::unifiedapiclient->default_client->call("DELETE", "/api/v1/dhcp/options/mac/$mac",{});
    };
    if($@) {
        get_logger->error("Error while removing options from DHCP server: " . $@);
    }
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2022 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
USA.

=cut

1;
