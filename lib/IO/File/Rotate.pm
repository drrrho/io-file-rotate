package IO::File::Rotate;

use strict;
use warnings;

=head1 NAME

IO::File::Rotate - File Handle with rotation on close

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

   use IO::File::Rotate;
   my $fh = IO::File::Rotate->new();
   print $fh ("foo");
   $fh->close ($file, delete_horizon => 4);

=cut

use IO::File;

require Exporter;
our @ISA = qw(IO::File);


=pod

=head1 INTERFACE

=head2 Constructor

The constructor takes B<NO> parameters. Instead of a specified file a temporary file will be
generated, actually only the file handle to it.

=cut

sub new {
    my $class = shift;
    die "cannot interpret any parameters" if @_;
    my $fh = $class->SUPER::new_tmpfile();
    return bless $fh, $class;
}

=pod

=head2 Methods

All methods are inherited from L<IO::File>.

=over

=item B<close>

It is actually this method which takes care of

=over

=item * storing the temporary file content into a specified location

=item * before that, rotating away until a specified horizon

=back

Example:

     $fh->close ('/tmp/file', delete_horizon => 3);

Any file C</tmp/file.1> will be moved to C</tmp/file.2>, but only after that has been moved to
C</tmp/file.3>. Only then the content in I<$fh> will be stored into C</tmp/file>.

=cut

sub close {
    my $fh     = shift;
    my $target = shift;
    my %options = @_;
    $options{delete_horizon}       //= 5;
#    $options{non_compress_horizon} //= 2;
#-- first rotate away according to the horizon
    foreach my $h (reverse (1..$options{delete_horizon}-1)) {
        my $from = "$target".($h == 1 ? '' : '.'.($h-1));
        if (-e $from) {
#            warn "rotating $from";
            rename $from, "$target.$h" or warn "cannot rotate '$from'";
        }
    }
#-- then effectively write target
    $fh->seek (0, 0);                                   # reset file handle to beginning
    my $fh2 = IO::Handle->new_from_fd ($fh, 'r');       # create a readable file handle from that
    use File::Copy;
#    warn "moving from $fh2 to $target";
    copy ($fh2, $target)
        or warn "cannot copy to $target";
}

=pod

=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-io-file-rotate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-File-Rotate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Robert Barta.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
