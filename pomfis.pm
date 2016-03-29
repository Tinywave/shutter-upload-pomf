#! /usr/bin/env perl
###################################################
#
#  Copyright (C) <2016> <Xyoz Netsphere> <<xyoc@hotmail.de>>
#
#  This file is part of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Shutter is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Shutter; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
###################################################

package pomfis;                                                         #edit

use lib $ENV{'SHUTTER_ROOT'}.'/share/shutter/resources/modules';

use utf8;
use strict;
use POSIX qw/setlocale/;
use Locale::gettext;
use Glib qw/TRUE FALSE/;
use Data::Dumper;

use Shutter::Upload::Shared;
our @ISA = qw(Shutter::Upload::Shared);

my $d = Locale::gettext->domain("shutter-plugins");
$d->dir( $ENV{'SHUTTER_INTL'} );

my %upload_plugin_info = (
    'module'                    => "pomfis",#edit (must be the same as 'package')
    'url'                       => "https://pomf.is/",#edit (the website's url)
    'registration'              => "https://pomf.is/",#edit (a link to the registration page)
    'name'                      => "pomf.is",#edit (the provider's name)
    'description'               => "Upload screenshots to pomf.is",#edit (a description of the service)
    'supports_anonymous_upload' => TRUE,#TRUE if you can upload *without* username/password
    'supports_authorized_upload'=> FALSE,#TRUE if username/password are supported (might be in addition to anonymous_upload)
    'supports_oauth_upload'     => FALSE,#TRUE if OAuth is used (see Dropbox.pm as an example)
);

binmode( STDOUT, ":utf8" );
if ( exists $upload_plugin_info{$ARGV[ 0 ]} ) {
    print $upload_plugin_info{$ARGV[ 0 ]};
    exit;
}


#don't touch this
sub new {
    my $class = shift;

    #call constructor of super class (host, debug_cparam, shutter_root, gettext_object, main_gtk_window, ua)
    my $self = $class->SUPER::new( shift, shift, shift, shift, shift, shift );

    bless $self, $class;
    return $self;
}

#load some custom modules here (or do other custom stuff)   
sub init {
    my $self = shift;

    use JSON;               
    use LWP::UserAgent;         
    use HTTP::Request::Common;  
    
    return TRUE;    
}

#handle 
sub upload {
    my ( $self, $upload_filename) = @_;

    #store as object vars
    $self->{_filename} = $upload_filename;

    utf8::encode $upload_filename;

    #examples related to the sub 'init'
    my $json_coder = JSON::XS->new;

    my $browser = LWP::UserAgent->new(
        'timeout'    => 20,
        'keep_alive' => 10,
        'env_proxy'  => 1,
    );
    
    #upload the file
    my $client = LWP::UserAgent->new(
            'timeout'    => 20,
            'keep_alive' => 10,
            'env_proxy'  => 1,
    );
    eval{
        my $json = JSON->new();

        my %params = (
                'files[]' => [$upload_filename],
        );
        my @params = (
            "https://pomf.is/upload.php",
            'Content_Type' => 'multipart/form-data',
            'Content' => [%params]
        );
        my $req = HTTP::Request::Common::POST(@params);
        my $rsp = $client->request($req); 

        $self->{_links} = $json->decode( $rsp->content ); 
        my $direct_link = $self->{_links}->{'files'}[0]->{url};
        $self->{_links} = $self->{_links}->{'rsp'};
        
        #save all retrieved links to a hash, as an example:
        $self->{_links}->{'direct_link'} = $direct_link;

        #set success code (200)
        $self->{_links}{'status'} = 200;
        
    };
    if($@){
        $self->{_links}{'status'} = $@;
    }
    
    #and return links
    return %{ $self->{_links} };
}

1;
