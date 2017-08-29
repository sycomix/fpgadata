#!/usr/bin/perl -w
# 2017-08-28  William A. Hudson

# Image Stream data object.
#
# Base class?
# This class streams pixel data into an Photo image from ImTop.pm.
# Specific variants could derive from this class.
#
# Reads data from stdin, formats it into pixel values for visualization,
# and puts it into a given image.
#
#---------------------------------------------------------------------------

package ImStream;

use Tk;			# PerlTk graphics

use strict;

use Error_mixi (	# Error handling functions, mix-in
    'Error',
    'die_Error',
    'carp_Error',
);
# Use mix-in when you want error flag per object.
# Use base class when you only want top-level error flag.


#---------------------------------------------------------------------------
## Stream object structure:  (private)
#---------------------------------------------------------------------------
#
# Object data:  {ImStream}
# {
#    Error_sub    => sub {},	# Error message reporting subroutine.
#    Error_cnt    => 0,		# Number of errors reported.
#
#    ImPhoto      => {Photo},	# Image object.
#
#    Xloc         => 0,		# Current pixel X location.
#    Yloc         => 0,		# Current pixel Y location.
#
#    Npix         => 0,		# Number of pixels per burst.
#
#    Nx           => 0,		# Image N pixels wide.
#    Ny           => 0,		# Image N pixels high.
# }


#---------------------------------------------------------------------------
## Constructor
#---------------------------------------------------------------------------

# Construct a new object and set its attributes.  (public)
#    Required parameters must have a defined value.
#    Optional parameters have default values, and may explicitly be set
#    to undef (e.g. Key => undef).
# call:
#    Package->new( key=> value, ..	# class method call only
#			    # required:
#    ImPhoto      => {Photo},	# Image object.
#			    # optional:
#    Error_sub    => sub {},	# Reference to error subroutine.
#    )
# The Error_sub should print error message with appropriate prefix, e.g.:
#        Error_sub    => sub { warn( "Error:  ", @_ ) },
# return:
#    () = new object, undef on error
#
sub new
{
    my( $package, %arg ) = @_;

    my $self = {
		# required args
		# optional args, default values
	Error_sub    => sub { warn( "Error:  ", @_ ) },
		# initialize
	Error_cnt    => 0,
	ImPhoto      => undef,
	Xloc         => 0,
	Yloc         => 0,
	Npix         => undef,
	Nx           => undef,
	Ny           => undef,
    };

    bless( $self, $package );

    if ( defined( $arg{Error_sub} ) ) {
	if ( ref( $arg{Error_sub} ) eq "CODE" ) {
	    $self->{Error_sub} = delete( $arg{Error_sub} );
	}
	else {
	    $self->Error( "$package->new() 'Error_sub' is not a CODE reference\n" );
	    return( undef );
	}
    }

    # optional args, allow undef values
#    foreach my $key (
#	'',
#    ) {
#	if (                exists( $arg{$key} ) ) {
#	    $self->{$key} = delete( $arg{$key} );
#	}
#    }

    # required args, must be defined values
#    foreach my $key (
#    ) {
#	unless ( defined( $self->{$key} ) ) {
#	    $self->Error( "$package->new() required argument:  '$key'\n" );
#	}
#    }

    foreach my $key ( keys( %arg ) )
    {
	$self->Error( "$package->new() unexpected argument:  '$key'\n" );
    }

    if ( $self->Error() ) {
	return( undef );
    }

    return( $self );
}


# Initialize the object.
# call:
#    $self->Init_required( key=> value, ..
#			    # required:
#    Npix         => 0,		# Number of pixels per burst.
#    Nx           => 0,		# Image N pixels wide.
#    Ny           => 0,		# Image N pixels high.
#			    # optional:
#    )
# return:
#    () = status, true= ok, false= errors
#
sub Init_required
{
    my( $self, %arg ) = @_;
    my $ok = 1;

    # required args, must be defined values
    foreach my $key (
	'Npix',
	'Nx',
	'Ny',
    ) {
	if ( defined( $arg{$key} ) ) {
	    $self->{$key} = delete( $arg{$key} );
	}
	else {
	    $self->Error( "init() required argument:  '$key'\n" );
	    $ok = 0;
	}
    }

    foreach my $key ( keys( %arg ) )
    {
	$self->Error( "Init_required() unexpected argument:  '$key'\n" );
	$ok = 0;
    }

    return( $ok );
}


# Init object attributes.
#    Key must already exist and be undefined.
# call:
#    $self->Init_attrib( KEY=>VALUE, .. )
# return:
#    ()  = unused
#
sub Init_attrib
{
    my( $self, @args ) = @_;

    while ( @args )
    {
	my $key   = shift( @args );
	my $value = shift( @args );

	if ( exists( $self->{$key} ) ) {
	    $self->{$key} = $value;
	}
	else {
	    $self->Error( "init_attrib():  invalid key:  $key\n" );
	}
    }
    1;
}


#---------------------------------------------------------------------------
## Stream Pixel data
#---------------------------------------------------------------------------

# Stream a set of Npix pixels.
#    Intended to be called repeatedly in MainLoop as part of data pipeline.
# call:
#    $self->stream_pixels()
# return:
#    ()  = unused
#
sub stream_pixels
{
    my( $self ) = @_;

    my $iw = $self->{ImPhoto};		# image object

    for ( my $i = $self->{Npix};  $i > 0;  $i-- )
    {
	my $line = <STDIN>;
#	my $line = "#010101";

	unless ( defined( $line ) ) {
	    warn( "Warning:  EOF on stdin\n" );
	    return( 0 );
	}

	chomp( $line );

	$self->{Xloc}++;
	if ( $self->{Xloc} >= $self->{Nx} ) {
	    $self->{Xloc} = 0;
	    $self->{Yloc}++;
	    if ( $self->{Yloc} >= $self->{Ny} ) {
		$self->{Yloc} = 0;
	    }
	}

	$iw->put( $line,
	    -to      => $self->{Xloc}, $self->{Yloc},
	);
    }

    1;
}


#---------------------------------------------------------------------------
## Accessors
#---------------------------------------------------------------------------


1;
__END__
