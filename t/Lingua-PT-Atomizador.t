# -*- cperl -*-

use Test::More tests => 1 + 1 * 11;

BEGIN { use_ok( 'Lingua::PT::Atomizador' ); }

$/ = "\n\n";

my $input = "";
my $output = "";
open T, "t/testes" or die "Cannot open tests file";
while(<T>) {
  chomp($input = <T>);
  chomp($output = <T>);

#  my $tok1 = tokeniza($input); # Diana
  # is($tok1, $output);

  my $tok2 = tokenize($input); # Braga
  is($tok2, $output);
}
close T;


1;


