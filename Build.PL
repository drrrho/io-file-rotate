use 5.006;
use strict;
use warnings;
use Module::Build;

$ENV{'PERL_MB_OPT'} = '--install-base=/usr'; # I could not make this work via the parameters below :/
$ENV{'DEB_BUILD_OPTIONS'}='nocheck';

my $debian = Module::Build->subclass(
    class => "Module::Build::Debian",
    code => <<'SUBCLASS' );

sub DEBVERSION {
    return 6;
}

sub ACTION_debian {
    my $self = shift;

    $self->depends_on("distdir");

    my $version = $self->dist_version;
    my $debversion = $self->DEBVERSION;
    $self->do_system(qq{ DEB_BUILD_OPTIONS=nocheck  dh-make-perl --build --version=$version-$debversion IO-File-Rotate-$version } );
}

sub ACTION_inject {
    my $self = shift;

    $self->depends_on("debian");

    my $version = $self->dist_version;
    my $debversion = $self->DEBVERSION;
    $self->do_system(qq{ scp libio-file-rotate-perl_${version}-${debversion}_all.deb packages.devc.at:packages/ } );
    foreach (qw(bullseye squeeze wheezy jessie stretch) ) {
        $self->do_system(qq{ ssh packages.devc.at -Y -t reprepro --ask-passphrase -b /var/www/packages/data/dists/ includedeb $_ packages/libio-file-rotate-perl_${version}-${debversion}_all.deb });
    }

}
SUBCLASS

my $builder = $debian->new(
    module_name         => 'IO::File::Rotate',
    license             => 'perl',
    dist_author         => q{Robert Barta <rho@devc.at>},
    dist_version_from   => 'lib/IO/File/Rotate.pm',
    configure_requires  => { 'Module::Build' => 0 },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'IO::File' => 0,
        'File::Copy' => 0,
    },
    add_to_cleanup      => [ 'IO-File-Rotate-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
