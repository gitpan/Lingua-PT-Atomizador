use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME              => 'Lingua::PT::Atomizador',
	      VERSION_FROM      => 'lib/Lingua/PT/Atomizador.pm',
	      PREREQ_PM         => {
				    Test::More => 0.47
				   },
	      ($] >= 5.005 ?
	       (ABSTRACT_FROM  => 'lib/Lingua/PT/Atomizador.pm',
		AUTHOR         => 'Linguateca (http://www.linguateca.pt)') : ()),
	     );
