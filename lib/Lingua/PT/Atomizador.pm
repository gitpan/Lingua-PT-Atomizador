package Lingua::PT::Atomizador;

use 5.006001;
use strict;
use warnings;

use locale;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(atomiza tokenize tokeniza);

our $VERSION = '0.01';


our $abrev = join '|', qw( srt?a? dra? [A-Z] etc exa? jr profs? arq av estr?
			   et al vol no eng tv lgo pr Oliv ig mrs? min rep );
our $protect = '
       \#n\d+
    |  \w+\'\w+
    |  [\w_.-]+ \@ [\w_.-]+\w                    # emails
    |  \w+\.[ºª]                                 # ordinals
    |  <[^>]*>                                   # marcup XML SGML
    |  \d+(?:\.\d+)+                             # numbers
    |  \d+\:\d+                                  # the time
    |  ((https?|ftp|gopher)://|www)[\w_./~-]+\w  # urls
    |  \w+(-\w+)+                                # dá-lo-à
';


our ($savit_n,%savit_p);


sub savit{
  my $a=shift;
  $savit_p{++$savit_n}=$a ;
  " __MARCA__$savit_n "
}

sub loadit{
  my $a = shift;
  $a =~ s/ ?__MARCA__(\d+) ?/$savit_p{$1}/g;
  $savit_n = 0;
  $a;
}


sub atomiza {
  return tokenize(@_);
}

sub tokenize{
  my $conf = {};
  my $result = "";
  my $text = shift;

  if (ref($text) eq "HASH") {
    $conf = { %$conf, %$text };
    $text = shift;
  }

  local $/ = ">";
  my %tag=();
  my ($a,$b);
  for ($text) {
    if(/<(\w+)(.*?)>/) {
      ($a, $b) = ($1,$2);
      if ($b =~ /=/ )  { $tag{'v'}{$a}++ }
      else             { $tag{'s'}{$a}++ }
    }
    s/<\?xml.*?\?>//s;
    s/($protect)/savit($1)/xge;
    s!([\»\]])!$1 !g;
    s#([\«\[])# $1#g;
    s#\"# \" #g;
    s/(\s*\b\s*|\s+)/\n/g;
    # s/(.)\n-\n/$1-/g;
    s/\n+/\n/g;
    s/\n(\.?[ºª])\b/$1/g;
    while ( s#\b([0-9]+)\n([\,.])\n([0-9]+\n)#$1$2$3#g ){};
    s#\n($abrev)\n\.\n#\n$1\.\n#ig;
    s/\n*</\n</;
    $_=loadit($_);
    s/(\s*\n)+$/\n/;
    s/^(\s*\n)+//;
    $result.=$_;
  }

  $result =~ s/\n$//g;

  return split /\s+/, $result if wantarray;

  $result =~ s/\n/$conf->{rs}/g if defined $conf->{rs};

  return $result;
}


sub tokeniza {
  my $par = shift;

  for ($par) {
    s/([!?]+)/ $1/g;
    s/([.,;»´])/ $1/g;

    # separa os dois pontos só se não entre números 9:30...
    s/:([^0-9])/ :$1/g;

    # separa os dois pontos só se não entre números e não for http:/...
    s/([^0-9]):([^\/])/$1 :$2/g;

    # was s/([«`])/$1 /g; -- mas tava a dar problemas com o emacs :|
    s!([`])!$1 !g;

    # só separa o parêntesis esquerdo quando não engloba números ou asterisco
    s/\(([^1-9*])/\( $1/g;

    # só separa o parêntesis direito quando não engloba números ou asterisco ou percentagem
    s/([^0-9*%])\)/$1 \)/g;

    # desfaz a separação dos parênteses para B)
    s/> *([A-Za-z]) \)/> $1\)/g;

    # desfaz a separação dos parênteses para (a)
    s/> *\( ([a-z]) \)/> \($1\)/g;

    # separação dos parênteses para ( A4 )
    s/(\( +[A-Z]+[0-9]+)\)/ $1 \)/g;

    # separa o parêntesis recto esquerdo desde que não [..
    s/\[([^.§])/[ $1/g;

    # separa o parêntesis recto direito desde que não ..]
    s/([^.§])\]/$1 ]/g;

    # separa as reticências só se não dentro de [...]
    s/([^[])§/$1 §/g;

    # desfaz a separação dos http:
    s/http :/http:/g;

    # separa as aspas anteriores
    s/ \"/ \« /g;

    # separa as aspas posteriores
    s/\" / \» /g;

    # separa as aspas posteriores mesmo no fim
    s/\"$/ \»/g;

    # trata dos apóstrofes
    # trata do apóstrofe: só separa se for pelica
    s/([^dDlL])\'([\s\',:.?!])/$1 \'$2/g;
    # trata do apóstrofe: só separa se for pelica
    s/(\S[dDlL])\'([\s\',:.?!])/$1 \'$2/g;
    # separa d' do resto da palavra "d'amor"... "dest'época"
    s/([A-ZÊÁÉÍÓÚÀÇÔÕÃÂa-zôõçáéíóúâêàã])\'([A-ZÊÁÉÍÓÚÀÇÔÕÃÂa-zôõçáéíóúâêàã])/$1\' $2/;

    #Para repor PME's
    s/(\s[A-Z]+)\' s([\s,:.?!])/$1\'s$2/g;

    # isto é para o caso dos apóstrofos não terem sido tratados pelo COMPARA
    # separa um apóstrofe final usado como inicial
    s/ '([A-Za-zÁÓÚÉÊÀÂÍ])/ ' $1/g;
    # separa um apóstrofe final usado como inicial
    s/^'([A-Za-zÁÓÚÉÊÀÂÍ])/' $1/g;

    # isto é para o caso dos apóstrofes (plicas) serem os do COMPARA
    s/\`([^ ])/\` $1/g;
    s/([^ ])´/$1 ´/g;

    # trata dos (1) ou 1)
    # separa casos como Rocha(1) para Rocha (1)
    s/([a-záéãó])\(([0-9])/$1 \($2/g;
    # separa casos como dupla finalidade:1)
    s/:([0-9]\))/ : $1/g;

    # trata dos hífenes
    # separa casos como (Itália)-Juventus para Itália) -
    s/\)\-([A-Z])/\) - $1/g;
    # separa casos como 1-universidade
    s/([0-9]\-)([^0-9\s])/$1 $2/g;
  }

  #trata das barras
  #se houver palavras que nao sao todas em maiusculas, separa
  my @barras = ($par=~m%(?:[a-z]+/)+(?:[A-Za-z][a-z]*)%g);
  my $exp_antiga;
  foreach my $exp_com_barras (@barras) {
    if (($exp_com_barras !~ /[a-z]+a\/o$/) and # Ambicioso/a
        ($exp_com_barras !~ /[a-z]+o\/a$/) and # cozinheira/o
        ($exp_com_barras !~ /[a-z]+r\/a$/)) { # desenhador/a
             $exp_antiga=$exp_com_barras;
             $exp_com_barras=~s#/# / #g;
             $par=~s/$exp_antiga/$exp_com_barras/g;
	   }
  }

  for ($par) {
    s# e / ou # e/ou #g;
    s#([Kk])m / h#$1m/h#g;
    s# mg / kg# mg/kg#g;
    s#r / c#r/c#g;
    s#m / f#m/f#g;
    s#f / m#f/m#g;
  }


  if (wantarray) {
    return split /\s+/, $par
  } else {
    $par =~ s/\s+/\n/g;
    return $par
  }
}

1;
__END__

=head1 NAME

Lingua::PT::Atomizador - Atomizador para a Língua Portuguesa

=head1 SYNOPSIS

  use Lingua::PT::Atomizador;

  my @atomos = split/\n/, atomiza($texto);

=head1 ABSTRACT

  Ferramenta de atomização para a língua Portuguesa.

=head1 DESCRIPTION

Este módulo inclui um método configurável para a atomização de corpus
na língua portuguesa. No entanto, é possível que possa ser usado para
outras línguas.

A forma simples de uso do atomizador é usando directamente a função
C<atomiza> que retorna um texto em que cada linha contém um átomo.

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Alberto Simoes (albie@alfarrabio.di.uminho.pt)

Diana Santos (diana.santos@sintef.no)

José João Almeida (jj@di.uminho.pt)

Paulo Rocha (paulo.rocha@di.uminho.pt)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Linguateca (http://www.linguateca.pt)

(EN)
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

(PT)
Esta biblioteca é software de domínio público; pode redistribuir e/ou
modificar este módulo nos mesmos termos do próprio Perl, quer seja a
versão 5.8.1 ou, na sua liberdade, qualquer outra versão do Perl 5 que
tenha disponível.

=cut
