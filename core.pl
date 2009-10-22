use strict;

my $module = 'POE';

my $core = module_is_supplied_with_perl_core( $module );

print $core, "\n";

sub module_is_supplied_with_perl_core {
        my $self = shift;
        my $ver  = shift || $];

        ### allow it to be called as a package function as well like:
        ###   CPANPLUS::Module::module_is_supplied_with_perl_core('Config')
        ### so that we can check the status of modules that aren't released
        ### to CPAN, but are part of the core.
        my $name = ref $self ? $self->module : $self;

        ### check Module::CoreList to see if it's a core package
        require Module::CoreList;

        ### Address #41157: Module::module_is_supplied_with_perl_core()
        ### broken for perl 5.10: Module::CoreList's version key for the
        ### hash has a different number of trailing zero than $] aka
        ### $PERL_VERSION.
        my $core = $Module::CoreList::version{ 0+$ver }->{ $name };

        return $core;
}
