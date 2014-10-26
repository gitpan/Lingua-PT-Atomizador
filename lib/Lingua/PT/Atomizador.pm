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
    |  \w+\.[��]                                 # ordinals
    |  <[^>]*>                                   # marcup XML SGML
    |  \d+(?:\.\d+)+                             # numbers
    |  \d+\:\d+                                  # the time
    |  ((https?|ftp|gopher)://|www)[\w_./~-]+\w  # urls
    |  \w+(-\w+)+                                # d�-lo-�
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
    s!([\�\]])!$1 !g;
    s#([\�\[])# $1#g;
    s#\"# \" #g;
    s/(\s*\b\s*|\s+)/\n/g;
    # s/(.)\n-\n/$1-/g;
    s/\n+/\n/g;
    s/\n(\.?[��])\b/$1/g;
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
    s/([.,;��])/ $1/g;

    # separa os dois pontos s� se n�o entre n�meros 9:30...
    s/:([^0-9])/ :$1/g;

    # separa os dois pontos s� se n�o entre n�meros e n�o for http:/...
    s/([^0-9]):([^\/])/$1 :$2/g;

    # was s/([�`])/$1 /g; -- mas tava a dar problemas com o emacs :|
    s!([`])!$1 !g;

    # s� separa o par�ntesis esquerdo quando n�o engloba n�meros ou asterisco
    s/\(([^1-9*])/\( $1/g;

    # s� separa o par�ntesis direito quando n�o engloba n�meros ou asterisco ou percentagem
    s/([^0-9*%])\)/$1 \)/g;

    # desfaz a separa��o dos par�nteses para B)
    s/> *([A-Za-z]) \)/> $1\)/g;

    # desfaz a separa��o dos par�nteses para (a)
    s/> *\( ([a-z]) \)/> \($1\)/g;

    # separa��o dos par�nteses para ( A4 )
    s/(\( +[A-Z]+[0-9]+)\)/ $1 \)/g;

    # separa o par�ntesis recto esquerdo desde que n�o [..
    s/\[([^.�])/[ $1/g;

    # separa o par�ntesis recto direito desde que n�o ..]
    s/([^.�])\]/$1 ]/g;

    # separa as retic�ncias s� se n�o dentro de [...]
    s/([^[])�/$1 �/g;

    # desfaz a separa��o dos http:
    s/http :/http:/g;

    # separa as aspas anteriores
    s/ \"/ \� /g;

    # separa as aspas posteriores
    s/\" / \� /g;

    # separa as aspas posteriores mesmo no fim
    s/\"$/ \�/g;

    # trata dos ap�strofes
    # trata do ap�strofe: s� separa se for pelica
    s/([^dDlL])\'([\s\',:.?!])/$1 \'$2/g;
    # trata do ap�strofe: s� separa se for pelica
    s/(\S[dDlL])\'([\s\',:.?!])/$1 \'$2/g;
    # separa d' do resto da palavra "d'amor"... "dest'�poca"
    s/([A-Z������������a-z������������])\'([A-Z������������a-z������������])/$1\' $2/;

    #Para repor PME's
    s/(\s[A-Z]+)\' s([\s,:.?!])/$1\'s$2/g;

    # isto � para o caso dos ap�strofos n�o terem sido tratados pelo COMPARA
    # separa um ap�strofe final usado como inicial
    s/ '([A-Za-z��������])/ ' $1/g;
    # separa um ap�strofe final usado como inicial
    s/^'([A-Za-z��������])/' $1/g;

    # isto � para o caso dos ap�strofes (plicas) serem os do COMPARA
    s/\`([^ ])/\` $1/g;
    s/([^ ])�/$1 �/g;

    # trata dos (1) ou 1)
    # separa casos como Rocha(1) para Rocha (1)
    s/([a-z����])\(([0-9])/$1 \($2/g;
    # separa casos como dupla finalidade:1)
    s/:([0-9]\))/ : $1/g;

    # trata dos h�fenes
    # separa casos como (It�lia)-Juventus para It�lia) -
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

Lingua::PT::Atomizador - Atomizador para a L�ngua Portuguesa

=head1 SYNOPSIS

  use Lingua::PT::Atomizador;

  my @atomos = split/\n/, atomiza($texto);

=head1 ABSTRACT

  Ferramenta de atomiza��o para a l�ngua Portuguesa.

=head1 DESCRIPTION

Este m�dulo inclui um m�todo configur�vel para a atomiza��o de corpus
na l�ngua portuguesa. No entanto, � poss�vel que possa ser usado para
outras l�nguas.

A forma simples de uso do atomizador � usando directamente a fun��o
C<atomiza> que retorna um texto em que cada linha cont�m um �tomo.

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Alberto Simoes (albie@alfarrabio.di.uminho.pt)

Diana Santos (diana.santos@sintef.no)

Jos� Jo�o Almeida (jj@di.uminho.pt)

Paulo Rocha (paulo.rocha@di.uminho.pt)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Linguateca (http://www.linguateca.pt)

(EN)
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

(PT)
Esta biblioteca � software de dom�nio p�blico; pode redistribuir e/ou
modificar este m�dulo nos mesmos termos do pr�prio Perl, quer seja a
vers�o 5.8.1 ou, na sua liberdade, qualquer outra vers�o do Perl 5 que
tenha dispon�vel.

=cut
