use inc::Module::Install;

name 'CGI-ValidOp';
all_from 'lib/CGI/ValidOp.pm';

requires 'HTML::Entities' => 0;
requires 'CGI'            => 0;

test_requires 'Test::Taint' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::Exception' => 0;

repository 'https://svn.opensourcery.com/public/projects/validop/trunk';

WriteAll;
