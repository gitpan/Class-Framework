use inc::Module::Install;
name 'Class-Framework';
all_from 'lib/Class/Framework.pm';
perl_version '5.006';

requires 'Class::Accessor::Complex';
requires 'Class::Accessor::Constructor';
requires 'Class::Factory::Enhanced';
requires 'Class::Accessor::FactoryTyped';
requires 'Class::Value';
requires 'Data::Comparable';
requires 'Data::Inherited';
requires 'Data::Miscellany';
requires 'DBI';
requires 'Error::Hierarchy';
requires 'String::FlexMatch';
requires 'Term::Shell::Enhanced';
requires 'Test::Differences';
requires 'Test::More';
requires 'Text::Table';
requires 'Time::HiRes';
requires 'YAML';
requires 'YAML::Active';

build_requires 'Test::CompanionClasses';
build_requires 'Test::More' => '0.70';

use_standard_tests(without => 'pod_coverage');
auto_include;
WriteAll;
