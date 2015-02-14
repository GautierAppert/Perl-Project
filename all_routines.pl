###################################################################
####----------------Projet Base de Données---------------------####	
####-----------------------------------------------------------####
####------------------Programmmation Perl----------------------####
####-----------------------------------------------------------####
####--Agnes Nkouma Essogo, Man Zhang, Gautier Appert-----------####
####-----------------------------------------------------------####
###################################################################


#########################################
# Forcer la déclaration des variables
use strict;
# Affichage des erreurs et explications
use warnings;
# Affichage du repertoire courant
use Cwd;
########################################

#-----------------------changement du repertoire courant--------------------------------#
chdir('C:\\Users\\gautier\\Documents\\Desktop\\web-mining') or die ("Erreur chdir \n");
my $dir = getcwd;
print "Le repertoire courant est : $dir\n";



##############################################################################################################
#######################---------------------------------------------------------##############################
#######################--------Routines pour la Construction des données--------##############################
#######################---------------------------------------------------------##############################
##############################################################################################################


sub CREATE_TABLE_Connexion
{

#---------------------------------------------------------------------------------------------------------------------------------------------------------------#
#-Objectif : Création de la table "connexion" en fichier csv----------------------------------------------------------------------------------------------------#
#-Objectif : Retourne une table contenant toutes les connexions possibles entre les utilisateurs, ainsi que le type de cercle si possible-----------------------#
#-Input    : NULL
#-Output   : Creation d'un fichier csv contenant toutes les connexions (avec le type de cercle si renseigné) 
#---------------------------------------------------------------------------------------------------------------------------------------------------------------#

	##----------Initialisation------------##
	# On récupère tous les utilisateurs grace à la fonction "all_users()"
	my @users = all_users();
	#my @users = (1,2,3,71,107,89,0);
	
	# On recupere tous les ego-nodes
	my @egonode = (0,107,348,414,686,698,1684,1912,3437,3980);

	# Ouverture du fichier en ecriture. Ecriture de la table connexion en csv.
	my $fichier = "TR\\connexion.csv";
	open(my $fh,'>',$fichier) or die "impossible d'ouvrir le fichier '$fichier' en écriture";

	
	#-----Pour chaque utilisateur on récupère tous leurs amis (connexions)-----#
	foreach my $user (@users)
		{
				
				# On teste si l'utilisateur est un egonode ou pas
				my $test = IN($user,@egonode);
				
				if($test == 1)  #----------l'utilisateur est un egonode !----------# 
					{
						
						# on peut obtenir le type de liaison (le type de cercle)		
						my %ami = circle_friend($user);  # tableau associatif contenant les amis des egonodes par type de cercles
						foreach my $cle (keys %ami)
							{
								my @connexion = split("\t",$ami{$cle}); # On récupere les connexions associé à l'egonode
								foreach my $friend (@connexion)
										{
											
											print $fh join(";",($user,$friend,$cle))."\n";
											
										}
									
								
							}
						
						
					}
										
				else		#---------------C'est un node !---------------------#
					{
						# On récupère toutes les connexions (amis) associées à $user
						my @connexion = all_friends($user);
						
						# On parcours tous les amis de $user
						foreach my $friend (@connexion)
							{	
								
										print $fh join(";",($user,$friend))."\n";
									
							}

					}
		
		
		}
	
	
	
	
	# Fermeture du fichier
	close $fh;
}

## jeu d'essaie
#CREATE_TABLE_Connexion();

######################################################################################################################################################################


sub CREATE_TABLE_Users
{

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#-Objectif : Création de la table "Users" en fichier csv--------------------------------------------------------------------------------------------------------------------#
#-Objectif : Retourne une table contenant toutes les caractéristiques (features) pour chaque utilisateurs-------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#-Input    : NULL
#-Output   : Creation d'un fichier csv contenant les utilisateurs avec leurs caractéristiques
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

	##----------Initialisation------------##
	# On récupère tous les utilisateurs grace à la fonction "all_users()"
	my @users = all_users();
	#my @users = (1,2,3,71,107,89,0);
	
	# On recupere tous les ego-nodes
	my @egonode = (0,107,348,414,686,698,1684,1912,3437,3980);
	# Tableau des caractéristiques des utilisateurs
	my @users_features = ("locale","last_name","birthday","gender","religion","middle_name","political","first_name");
	
	#--Ouverture du fichier en ecriture => Ecriture de la table "Users" en csv.
	my $fichier = "TR\\Users.csv";
	open(my $fh,'>',$fichier) or die "impossible d'ouvrir le fichier '$fichier' en écriture";

	#--Ecriture de l'entete dans le fichier csv---#
	my @header = map { local $_ = $_; s/;/:/g; $_ } @users_features;
	#my @header = map ( {=~s/;/:/g} @features ); 
	#print join("\n",@header);
	push(@header,"indicator_egonode");
	unshift(@header,"users");
	print $fh join(";",@header)."\n";
	
	#----On récupère le profil pour chaque utilisateur----#
	foreach my $user (@users)
		{
			
				# On teste si l'utilisateur est un egonode ou pas
				my $test = IN($user,@egonode);
				
				#----Initialisation----# 
				my @print_profile;
				
				# On recupere le profile de l'utilisateur
				#my @profil = map { local $_ = $_; s/;/:/g; $_ } profile($user);	
				my @profil = profile($user);
				
					
				foreach my $feature (@users_features)
					{
						my @t = grep(/$feature/, @profil);
						if(scalar(@t)==0)
							{
								push(@print_profile,"\t");
							}
						else
							{
								
								my @matching = split(/$feature;anonymized feature\s/,$t[0]);
								push(@print_profile,$matching[1]);
								
							}
							
					}
				
				push(@print_profile,$test);
				unshift(@print_profile,$user);
				print $fh join(";",@print_profile)."\n";
				
	
				
		}
	
	
	#---Fermeture du fichier---#
	close $fh;
}


# jeu d'essaie
#CREATE_TABLE_Users();

################################################################################################################################################################

#---------Initialisation du tableau des caractéristiques possédant plusieurs valeurs au sein d'un meme profil------------###
my @others_features = ("education:classes:id","education:concentration:id","education:degree:id","education:school:id","education:type","education:with:id","education:year:id","languages:id","locale","location:id","work:employer:id","work:end_date","work:location:id","work:position:id","work:start_date");                                


sub CREATE_TABLE_Feature
{

#-----------------------------------------------------------------------------------------------------------------------------------------------------------#
# Objectif :  Créer une table pour une caractéristique du tableau @others_features
#-----------------------------------------------------------------------------------------------------------------------------------------------------------#
# Input : Une caractéristique (élément) du tableau : @others_features
# Output : Une Table csv possédant les colonnes ("feature","users") ou le champ "feature" correspond à la caractéristique donnée en input
#-----------------------------------------------------------------------------------------------------------------------------------------------------------#
	
	
	
	#-----Argument de la fonction = une caractéristique du tableau @others_features-----#
	my ($feature) = @_;
	
	##----------Initialisation------------##
	# On récupère tous les utilisateurs grace à la fonction "all_users()"
	my @users = all_users();
	#my @users = (1,2,3,71,107,89,0);
	
	# Creation du nom du fichier
	my $file_name = $feature;
	$file_name =~ s/:/_/g; ; #On rempace les ":" par "_" 
	
	#--Ouverture du fichier en ecriture => Ecriture de la table "Users" en csv.
	my $fichier = "TR\\$file_name.csv";
	open(my $fh,'>',$fichier) or die "impossible d'ouvrir le fichier '$fichier' en écriture";

	#---Ecriture de l'entete dans le fichier csv---#
	print $fh join(";",("$feature","users"))."\n";
	
	
	#----On récupère le profil pour chaque utilisateur et on test les matching => on boucle sur les users----#
	foreach my $user (@users)
		{
			

			# On recupere le profile de l'utilisateur et on remplace ";" par ":"
			my @profil = map { local $_ = $_; s/;/:/g; $_ } profile($user);	
			#print join("\n",@profil);
			
			# On recupere la correspondance des caractérsitiques => matching features
			my @match_features = grep(/^$feature/, @profil);
			#print scalar(@match_features)."\n";
			if(scalar(@match_features)==1)
				{	
					
					my @matching = split(/$feature:anonymized feature\s/,$match_features[0]);
					print $fh join(";",($matching[1],$user))."\n"; # On print dans le csv !
					
					
				
				}
			if(scalar(@match_features)>1) # Plusieurs correspondances au sein d'un meme utilisateur
				{
					
					foreach my $elt (@match_features)
						{
							
							my @matching = split(/$feature:anonymized feature\s/,$elt);
							print $fh join(";",($matching[1],$user))."\n"; # On print dans le csv! 
							
							
						}
					
					
				}
					
					
				
	
				
		}
	
	#---Fermeture du fichier---#
	close $fh;


}

# jeu d'essaie
#CREATE_TABLE_Feature($others_features[7]);


########################################################################################################################################################################


sub CREATE_All_TABLES_Features
{

#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Objectif : Creation de toutes les tables pour chaque caractéristique du tableau @others_features => boucle sur le tableau @others_features
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Input : Null
# Output : Toutes les tables en csv de la sortie de la fonction "Create_Table_Feature()". Les tables possèdent les champs suivant :("feature","users") 
# Remarque : utilisation de la fonction 'CREATE_TABLE_Feature()'
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
	
		foreach my $feature (@others_features)
			{
				CREATE_TABLE_Feature($feature);
				
								
			}		
}

# Jeu d'essai
# CREATE_All_TABLES_Features();

##################################################################################################################################################################

sub CREATE_SUB_Graph
{
	
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Objectif : Creation d'un tableau csv représentant une partie des connexions entre utilisateurs => utilisation de cette table pour la représentation d'un sous graphe sur R	
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Input : Un ensemble d'utilisateur
# Output : Une table csv contenant les connexions entre utilisateurs => deux colonnes 'user1' et 'user2'
# Remarque : Utilisation de la table csv sur R à l'aide du package igraph
# Remarque :  Cette fonction est très semblable à la fonction 'CREATE_TABLE_Connexion()'	
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#	
	
	##----------Initialisation------------##
	my @users = @_;
	
	# Ouverture du fichier en ecriture. Ecriture de la table connexion en csv.
	my $fichier = "TR\\graph.csv";
	open(my $fh,'>',$fichier) or die "impossible d'ouvrir le fichier '$fichier' en écriture";

	
	#-----Pour chaque utilisateur on récupère tous leurs amis (connexions)-----#
	foreach my $user (@users)
		{
						# On récupère toutes les connexions (amis) associées à $user
						my @connexion = all_friends($user);
						
						# On parcours tous les amis de $user
						foreach my $friend (@connexion)
							{	
								
								print $fh join(";",($user,$friend))."\n";
									
							}
		
		}
	
	
	# Fermeture du fichier
	close $fh;	
		
}

#jeu d'essaie
#CREATE_SUB_Graph((1,2,45,10,71,3,69,24,62,175));

###########################################################################################################################
##########################---------------------------------------------------------------##################################
##########################------Routines intermediaire ou demandées dans le projet ------##################################
##########################---------------------------------------------------------------##################################
###########################################################################################################################



sub ego_node_friends
{

#--------------------------------------------------------------------------------------#
# Objectif : Retourner tous les amis (connexions) d'un ego-node fixé (!=node)
#--------------------------------------------------------------------------------------#
# Input : Fichier source d'un ego-node dont l'extension est ".circles"
# Output : @amigo =  tableau contenant toutes les connexions associée à l'ego-node fixé
#--------------------------------------------------------------------------------------#

	# Déclaration du fichier source : Argument de la fonction
	my ($fichier) = @_;
	# Déclaration du tableau ami
	my @amigo;
	# Ouverture des fichiers source 
	open(my $fh,'<',$fichier) or die "impossible d'ouvrir le fichier '$fichier' en lecture";
		 
	# Lecture du fichier source
	while (my $line = <$fh>)
		{
			chop($line);  # oter le "\n"       
			my @ligne = split("\t",$line) ; # decouper la ligne suivant tabulation
			shift @ligne; # extraction du nom "circle"
			push(@amigo,@ligne); # construction du tableau "ami"
		}
		
		# Fermeture des fichiers
	close $fh;
	return @amigo;
}


###############################################################################################################


sub Tableau_Unique 
{ 

#---------------------------------------------------------------------------------------------#
# Objectif : Retourner toutes les valeurs uniques d'un tableau (suppression des doublons)
#---------------------------------------------------------------------------------------------#
# Input : Tableau contenant potentiellement des doublons
# Output : Tableau contenant que des valeurs uniques (sans doublon) 
#---------------------------------------------------------------------------------------------#	
		
			
	my @t = @_;  
	# Création d'un tableau associatif (hash) : les clés représenterons les éléments du tableau
	my %new_t; 
		foreach(@t) 
		{ 
		  $new_t{$_} = 1;
		} 
	return (keys(%new_t)); 
}



###########################################################################################################


sub all_users
{
	
#---------------------------------------------------------------------------------------#
# Objectif : Retourne tous les utilisateurs appartenant au cercle de tous les ego-nodes
#---------------------------------------------------------------------------------------#
# Input  : NULL 
# Output : @user = tableau des utilisateurs appartenant aux cercles de tous les ego-nodes
#----------------------------------------------------------------------------------------#	
	
	#-------On recupere tous les fichiers avec l'extension ".circles"-------#
	my @files = glob("*.circles");
	my @user;
		 foreach (@files)
			{
				
				push(@user,ego_node_friends($_));
		 
			}
	      
	      
	    return Tableau_Unique(@user);
}

# jeu dessaie
# my @t = all_users();
# print join("\n",@t)."\n";

##############################################################################################################

sub node_friends_edges
{
#----------------------------------------------------------------------------------------------------------------------------------#
# Objectif : Retourner tous les amis d'un node (qui n'est pas un ego-node) au sein des cercles d'amis d'un ego-node fixé 
#----------------------------------------------------------------------------------------------------------------------------------#
# Input : Un utilisateur (node) et un fichier dont l'extension est ".edges"
# Output : @ami = tableau retournant tous les amis du node en question au sein des cercles d'amis d'un ego-node fixé
# Remarque : Utilisation de la fonction "Tableau_Unique(  )"
#----------------------------------------------------------------------------------------------------------------------------------#
	
	my ($user,$fichier) = @_;	
	#-------Initialisation------#
	my @ami;	
		
			# Ouverture du fichier en lecture 
			open(my $fh,'<',$fichier) or die "Impossible d'ouvrir le fichier $fichier";
			
			#lecture du fichier
			while (my $line = <$fh>)
				{
					chop($line);  # oter le "\n"  
					my @ligne = split(" ",$line) ; # decouper la ligne suivant " " => retourne un tableau
					
					 # if(grep(/\b$user\b/, @ligne) )# On test si la ligne contient le motif '$user'
					 if(grep {$_ == $user} @ligne)
					 {
							foreach my $elt (@ligne) 
							{ 
								
								if($elt != $user)
									{
										push(@ami,$elt);
									}
								
								
							}
								
					}
					
				}	
			
			# On retire les doublons dans le tableau @ami
			@ami = Tableau_Unique(@ami); 
			
			# On récupère l'identifiant de l'ego-node ssi l'utilisateur possède au moins 1 ami ( c a d si le tableau @ami est non vide)
			if(scalar(@ami) !=0)
			{	
				# On recupere l'ego-node correpondant au fichier
				my @t = split(/\./,$fichier);
				unshift (@ami,$t[0]);
			}
			# Fermeture du fichier
			close $fh;
		return @ami;
}


#######################################################################################################


sub node_all_friends
{
#----------------------------------------------------------------------------------------------------------------------------------#	
# Objectif : Retourner tous les amis d'un node (!= ego-node) 
#----------------------------------------------------------------------------------------------------------------------------------#
# Input : Un utilisateurs (node) 
# Output : @ami = tableau retournant tous les amis du node en question 
# Remarque : Cette fonction utilise la routine "node_friends_edges(   )"
#----------------------------------------------------------------------------------------------------------------------------------#
	
	#-----Numero de l'utilisateur en argument-----#
	my ($user) = @_;
	my @files = glob("*.edges") ;
	#------Initialisation-------#
	my @ami;

	# Parcour de tous les fichiers edges
	foreach my $fichier (@files)
		{
			
			 push(@ami,node_friends_edges($user,$fichier));
			
		}
		
		
		
	return Tableau_Unique(@ami);	

}



#######################################################################################################

sub IN
{

#---------------------------------------------------------------------------------------------------#		
# Objectif : Tester si un element appartient à un tableau
#---------------------------------------------------------------------------------------------------#
# Input : un élément ($user) et un tableau (@t)
# Output : 1 ou 0 (l'élement appartient ou n'appartient pas au tableau)
#---------------------------------------------------------------------------------------------------#	
	my ($user,@t) = @_;
	# Test si l'utilisateur appartient bien au tableau
	if(grep {$_ == $user} @t)
	{

		return "1";
	
	}
	else
	{
		return "0";
			
	}
		
}

###########################################################################################################

sub all_friends
{

#---------------------------------------------------------------------------------------------------#	
# Objectif : Retourner toutes les amis (connexions) d'un utilisateur (node ou ego-node)
#---------------------------------------------------------------------------------------------------#
# Input : un élément ($user) 
# Output : Un tableau contenant toutes les connexions associées à l'utilisateur
#---------------------------------------------------------------------------------------------------#	

	#------Passage en argument d'un utilisateur-----#
	my ($user) = @_;

	##----------Initialisation------------##
	# On récupère tous les utilisateurs
	my @users = all_users();
	# On recupere tous les ego-nodes
	my @ego_node = (0,107,348,414,686,698,1684,1912,3437,3980);


	#-------On verifie si l'utilisateur ($user) appartient à la liste de tous les utilisateurs (@users)--------#
	my $test = IN($user, @users);
		if ($test == 0)
			{
				die " '$user' n'est pas un utilisateur !";   ### Ce n'est pas un utilisateur de notre base!
				#return 0;
			}
		else 
			{
				#--------On vérifie si l'utilisateur est un ego-node-------#
				my $test = IN($user, @ego_node);
				if($test == 1)	### C'est un ego-node !
					{
						
						my $fch = ".circles";  ### On récupère l'extension ".circle"
						$fch = $user.$fch;     ### Concaténation des chaines de characteres 
						return ego_node_friends($fch);	 	
						
					}
				else	#---------------C'est un node !---------------------#
					{
					
						return node_all_friends($user);
					
					}
			 }

}

# jeu d'essai
# my @sol = all_friends(107);
# print join(" ",@sol);
# my @sol = all_friends(9);
# print join(" ",@sol);


########################################################################################################################


sub circle_friend
{
	
	
#----------------------------------------------------------------------------------------------------------------------------#
# Objectif : ce programme permet de retourner la liste des amis d'un ego-node par "cercle"
#----------------------------------------------------------------------------------------------------------------------------#
# Input : un identifiant ego-node (numero)
# Output : un tableau associatif (%ami) retournant la liste des amis de l'ego-node par "cercle"
# Remarque : %ami est un tableau associatif dont les clés représentent les "cercles" et les amis représentent les "valeurs"
# Remarque : Cette fonction est très similaire à la fonction "ego_node_friends()"
#----------------------------------------------------------------------------------------------------------------------------#

	my ($user) = @_;

	##----------Initialisation------------##
	my %ami;
	# On recupere tous les ego-nodes
	my @ego_node = (0,107,348,414,686,698,1684,1912,3437,3980);

	# On doit vérifier que l'utilisateur est bien un ego-node 
	my $test = IN($user, @ego_node);
	if ($test == 0)
		{
			die " L'utilisateur '$user' n'est pas un ego-node !";   ### Ce n'est pas un egonode!
			#return 0;
		}
	else
		{

			my $fichier = $user.".circles" ;
			# Ouverture du fichier "user.circle" en mode lecture
			open(my $fh,'<',$fichier) or die "Impossible d'ouvrir le fichier '$fichier' en lecture";

			#lecture du fichier
			while (my $line = <$fh>)
				{
					chop($line);  # oter le "\n"       
					my @ligne = split("\t",$line) ; # decoupe la ligne suivant le caractère tabulation "\t"
					my $cle = shift @ligne; # la cle du tableau associatif représente le type de cercle => extraction du nom "circle" = premier élément du tableau
					$ami{$cle} = join("\t",@ligne); # Extraction des amis. Les valeurs du tableau associatif représentents les amis

				}
			# Fermeture du fichier
			close $fh;
		 }
	
	
	
	return %ami;

}

# jeu d'essai
# my %sol = circle_friend(107);
# print_hash(\%sol);




##########################################################################################################################

sub print_hash
{

#--------------------------------------------------------------------------------------#
# Objectif : afficher les valeurs d'un tableau associatif
#--------------------------------------------------------------------------------------#
# Input : Pointeur sur un tableau associatif
# Output : null
#--------------------------------------------------------------------------------------#

	#--------Passage en argument d'un pointeur sur un hash-------# 
	my ($p) = @_;
	my @cles = keys %$p;
	foreach (@cles)
		{
			print $_."\n";  #Affichage des clées du tableau
			print  $$p{$_}."\n"; # Affichage des valeurs du tableau
			print "\n";
		}

}


##################################################################################################################################



sub profile_egonode
{

#-------------------------------------------------------------------------------------------------------------------------#
# Objectif : Retourner toutes les caractéristiques du profil d'un ego-node
#-------------------------------------------------------------------------------------------------------------------------#
# Input : numero d'un ego-node  
# Output : @profile = tableau contenant tous les informations disponibles (caractéristiques) concernant l'ego-node choisi
#-------------------------------------------------------------------------------------------------------------------------#	   


	my ($user)=@_;

	#-----Initialisation-----#
	my $egofeat = $user.".egofeat"; # fichier "egofeat"
	my $featnames = $user.".featnames"; # fichier "featnames"
	my @find_feature; # tableau d'indicatrices 0 ou 1
	my @profile; # profile de l'ego-node choisi


	# Ouverture du fichier "egofeat"
	open(my $ef,'<',$egofeat) or die "impossible d'ouvrir le fichier '$egofeat' en lecture";
	#---lecture du fichier  "egofeat"----# 
	while (my $line = <$ef>)
		{
			@find_feature = split(" ",$line); # On découpe la ligne
			 
		}

	
	#-------------fermeture du fichier "egofeat"--------------#
	close $ef;
	
	
	#------------Ouverture du fichier featnames---------------#
	open(my $fn,'<',$featnames) or die "impossible d'ouvrir le fichier '$featnames' en lecture";

	#----lecture du fichier "featnames"----#
	my $compteur = 0; # Compteur pour parcourir les elements du tableau @find_feature et compter les lignes du fichier featnames
	while (my $line = <$fn>)
		{ 
			if($find_feature[$compteur] == 1)  # Lorsque l'indicatrice vaut 1, on récupère les caractéristiques
				{
					my @ligne = split(" ",$line);
					shift @ligne;            # On retire le numero figurant en début de ligne (numero de ligne du fichier featnames)
					my $lig = join(" ",@ligne);
					push(@profile,$lig);
					
				}

			$compteur++;
		}  

	#----------Fermeture du fichier "featnames"----------#
	close $fn;
	
	
	return @profile;

}



######################################################################################################################################

sub profile_node
{

#----------------------------------------------------------------------------------------------------------------------#
# Objectif : Retourner toutes les caractéristiques du profil d'un node (!=egonode)
#----------------------------------------------------------------------------------------------------------------------#
# Input : numero d'utilisateur d'un node
# Output : @profile = tableau contenant tous les informations disponibles (caractéristiques) concernant le node choisi
#----------------------------------------------------------------------------------------------------------------------#	  


	my ($user)=@_;
	    


	#----------------------Initialisation------------------------#
	my $egonode_file;  # fichier du type "ego-node.circles" contenant le node ($user) 
	my @files = glob("*.circles") ; # On recupère tous les fichiers ".circles"
	my @profile; # Profil de l'utilisateur node
	my @find_feature; # tableau d'indicatrices 0 ou 1


	foreach my $file (@files)  # On parcours les fichiers tant que l'utilisateur ($user) n'est pas dedans
		{
			
			#ouverture d'un fichier
			open(my $fh,'<',$file) or die "Impossible d'ouvrir le fichier $file";

			while (my $line = <$fh>)
				{
					chop($line); #oter le \n
					my @ligne = split("\t",$line);
					shift @ligne;
					if(grep {$_ == $user} @ligne)
						{
							$egonode_file = $file; 
							last; # le fichier est trouvé on quitte la boucle while !
						}

				}
			close $fh;

			if(defined($egonode_file))  # Si un fichier est trouvé, on quite la boucle foreach !
				{

					last ;

				}

		}


	# On recupere l'ego-node
	my @egonode = split(/\./,$egonode_file);
	my $egonode = $egonode[0];

	# Fichier dans lequels il faut chercher le profile
	my $featnames = $egonode.".featnames";
	my $feat = $egonode.".feat";




	#----------------------------------Ouverture du fichier "feat"------------------------------------------#
	open(my $f,'<',$feat) or die "Impossible d'ouvrir le fichier $feat";
	# Lecture du fichier "feat"
	while (my $line = <$f>)
		{
			chop($line);
			my @ligne = split(" ",$line);
			my $num_user = shift @ligne; 

			if ($num_user == $user) # Lorsque le numero utilisateur est le meme que le $user on récupere la ligne
				{
					@find_feature = @ligne;
					last;
				}      

		}

	#----------------------------------Fermeture du fichier "feat"------------------------------------------#
	close $f;


	#---------------------------------Ouverture du fichier featnames----------------------------------------#
	open(my $fn,'<',$featnames) or die "impossible d'ouvrir le fichier '$featnames' en lecture";

	#----lecture du fichier "featnames"----#
	my $compteur = 0; # Compteur pour parcourir les elements du tableau @find_feature
	while (my $line = <$fn>)
		{ 
			if($find_feature[$compteur] == 1)  # Lorsque l'indicatrice vaut 1, on récupère les caractéristiques !
				{
					
					my @ligne = split(" ",$line);
					shift @ligne;
					my $lig = join(" ",@ligne);
					push(@profile,$lig);
				}

			$compteur++;
		}  

	#--------------------------------Fermeture du fichier "featnames"------------------------------------------#
	close $fn;


	return @profile;
   
}



################################################################################################################################

sub profile
{

#-----------------------------------------------------------------------------------------------------------------------------------------#
# Objectif : Retourner toutes les caractéristiques du profil d'un node ou d'un ego-node
#-----------------------------------------------------------------------------------------------------------------------------------------#
# Input : numero d'utilisateur d'un node ou egonode
# Output : @profile = tableau contenant tous les informations disponibles (caractéristiques) concernant le node ou l'ego_node choisi
#-----------------------------------------------------------------------------------------------------------------------------------------#	  

	
	
	
	# Passage en argument d'un utilisateur
	my ($user) = @_;

	##----------Initialisation------------##
	# On récupère tous les utilisateurs
	my @users = all_users();
	# On recupere tous les ego-nodes
	my @ego_node = (0,107,348,414,686,698,1684,1912,3437,3980);


	#-------On verifie si l'utilisateur ($user) appartient à la liste de tous les utilisateurs (@users)--------#
	my $test = IN($user, @users);
		if ($test == 0)
			{
				die " '$user' n'est pas un utilisateur !";   ### Ce n'est pas un utilisateur de notre base!
				#return 0;
			}
		else 
			{
				#--------On vérifie si l'utilisateur est un ego-node-------#
				my $test = IN($user, @ego_node);
				if($test == 1)	### C'est un ego-node !
					{
						
						return profile_egonode($user);	 	
						
					}
				else	### C'est un node !
					{
					
						return profile_node($user);
					
					}
			 }
	
	
	
	
}

# jeu d'essaie
# my @sol = profile(107);
# print join("\n",@sol)."\n";
# my @sol = profile(10);
# print join("\n",@sol)."\n";

################################################################################################################################

sub intersect_two_arrays
{

#-----------------------------------------------------------------------------------------------------------------------------------------#
# Objectif : Retourner la liste des éléments communs entre deux tableaux
#-----------------------------------------------------------------------------------------------------------------------------------------#
# Input : deux pointeurs (références) de deux tableaux
# Output : Tableau d'élément commun
#-----------------------------------------------------------------------------------------------------------------------------------------#	  


	# On donne en argument à la fonction les pointeurs des deux tableaux
	my ($ref1,$ref2) = @_;
	my %hash_test;
	my %intersect;

	## Creation d'un hash (hash_test) dont les clés sont les éléments du premier tableau
	foreach my $e (@{$ref1}) 
		{ 
			$hash_test{$e} = 1; 
		}

	foreach my $e (@{$ref2})
		{
			if ( $hash_test{$e} )   # si le test est vrai alors l'élément $e appartient au premier tableau
				{ 
					$intersect{$e} = 1; 
				}

		}

	
	return keys %intersect;

}


#####################################################################################################################################

sub intersect_two_profiles
{
	
#-----------------------------------------------------------------------------------------------------------------------------------------#
# Objectif : Retourner la listes des caractéristiques communes entre deux utilisateurs
#-----------------------------------------------------------------------------------------------------------------------------------------#
# Input : deux numeros d'utilisateurs
# Output : @intersect = Tableau des caractéristiques communes
#-----------------------------------------------------------------------------------------------------------------------------------------#	
	
	my ($user1,$user2)=@_;
	
	#-----Initialisation-----#
	# On récupère les deux profiles des deux utilisateurs
	my @t1 = profile($user1);  # profil $user1
	my @t2 = profile($user2);  # profil $user2
	
	#-------On récupere les caractéristiques communes----------#
	my @intersect =  intersect_two_arrays(\@t1,\@t2);
	
	if(scalar(@intersect)==0)
		{
			die "Il n'y a aucune caractéristiques communes";
		}
	else
		{
			return @intersect; # tableau d'intersection des profiles 1 et 2
		}

}		

# jeu d'essai
# my @sol = intersect_two_profiles(107,10);
# print join("\n",@sol)."\n";

###############################################################################################################################################


sub intersect_all_arrays
{

#-----------------------------------------------------------------------------------------------------------------------------------------#
# Objectif : Retourner la listes des éléments communs entre plusieurs tableaux
#-----------------------------------------------------------------------------------------------------------------------------------------#
# Input : Tableau de pointeurs sur des tableaux
# Output : @intersect = Tableau des éléments communs
#-----------------------------------------------------------------------------------------------------------------------------------------#	

	#-------Tableau de pointeurs sur des tableaux-------#
	my @arrays = @_;


	#------On test si la taille du tableau est égale à 2------#
	if(scalar(@arrays)==2)
		{
			
			return intersect_two_arrays($arrays[0],$arrays[1]);
		
		}
	else
		{
			
			#-------Initialisation du tableau d'intersection------#
			my @intersect = @{$arrays[0]};
			for(my $i=1;$i<scalar(@arrays);$i++)
				{
						my $p = \@intersect;  #-------pointeur sur le tableau @intersect----------#
						@intersect = intersect_two_arrays($p,$arrays[$i]);
							
				}
			
			
			return @intersect;			
		}

}

##########################################################################################################################################################

sub intersect_all_profiles
{
	
#-----------------------------------------------------------------------------------------------------------------------------------------#
# Objectif : Retourner la listes des caractéristiques communes entre plusieurs utilisateurs
#-----------------------------------------------------------------------------------------------------------------------------------------#
# Input : Tableau d'utilisateurs (numero identifiant)
# Output : @intersect = Tableau des caractéristiques communes entre les utilisateurs
# Remarque : Cette fonction utilise la fonction "intersect_all_arrays()"
#-----------------------------------------------------------------------------------------------------------------------------------------#	


	#--------Passage en argument du tableau contenant les numéros des utilisateurs------------#	
	my @users = @_;

	#--------Creation des tableaux de profils pour chaque utilisateurs (tableau de pointeurs sur des profils)----------# 
	my @profiles;

	for(my $i=0;$i<=$#users;$i++)
		{
			# @tmp = profile($users[$i]);
			$profiles[$i] = [  profile($users[$i]) ];  # Création d'une référence anonyme pour le tableau profile
		}

	#print join("\n",@profiles);
	return intersect_all_arrays(@profiles);
			
}

# jeu d'essai
# my @sol = intersect_all_profiles(140,52,698);
# print join("\n",@sol)."\n";

#############################################################################################################################################

sub all_features
{
	
	
#-----------------------------------------------------------------------------------------------------#
# Objectif : Routine permettant de retourner toutes les caractéristiques possibles distinctes---------#
#-----------------------------------------------------------------------------------------------------#
# Input : NULL
# Output : Tableau contenant toutes les caractéristiques possibles (features)
#-----------------------------------------------------------------------------------------------------#

	
#-------On recupere tous les fichiers avec l'extension ".featnames"-------#
	my @files = glob("*.featnames");
#------Initialisation du tableau qui contiendra toutes les caractérisitques (features) distinctes existantes
	my @featnames; 
# On parcours tous les fichiers "featnames"
	foreach my $file (@files)
		{
			#----Ouverture du fichier en lecture
			open(my $fh,'<',$file) or die "Impossible d'ourir le fichier en mode lecture";
			#---Lecture du fichier
			while(my $line = <$fh>)
				{
					# lecture des lignes et split
					chomp($line); # oter \n
					my @ligne = split(/;anonymized feature \d+/,$line);  # split afin de récuperer seulement l'élément intéressant (feature)
					my @feature = split(/^\d+ /,$ligne[0]);              # suppression du character numerique
					push(@featnames,$feature[1]); # On stocke les features
				}
						
			#---fermeture du fichier
			close $fh;
			
			
		}
		
		
	# On récupère les valeurs uniques (suppression des doublons)
	 return(Tableau_Unique(@featnames));
		
}		

# jeu d'essai
# my @features = all_features();
# print join("\n",@features)."\n";

##################################################################################################################################################################################################"

sub frequence_features
{

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Objectif : Savoir quelles caractéristiques possèdent plusieurs valeurs au sein d'un même profil
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Creation d'un hash dont les clés représentent ttes les caractéristiques possibles (features) et dont les valeurs indiquent si la caractéristique possède une ou plusieurs modalités
# Input : NULL
# Output : %hash dont les clés représentens ttes les caractéristiques possibles (features) et dont les valeurs indique si oui ou non la caractéristiques possèle plusieurs valeurs (1 ou 0)
# au sein d'un meme profil.----------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Remarque : utilisation de la fonction "all_features()"
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

#------initialisation-----#	
my %modal_features;
my @features = all_features();
my @users = all_users;

	foreach my $cle (@features)
	{
		
		print $cle."\n";
		# my $compteur1 = 0;
		# my $compteur2 = 0;
		foreach my $user (@users)
			{	
					
					my @profil = profile($user);
					my @frequency = grep(/$cle/, @profil);
					# print scalar(@frequency)."\n";
					if(scalar(@frequency)>0)
						{
						
							if(scalar(@frequency)>1)
								{
									$modal_features{$cle} = 1;
									last;
									
								}
							else
								{
									$modal_features{$cle} = 0;
									# $compteur1++;
														
								}
								
							# if($compteur1 == 5)
								# {
									# last;
								# }					
						}
					# else
						# {

							# $compteur2++;
							# if($compteur2 == 50){last};
							
						# }
					
					
			}
			
	}

	return %modal_features;
}


##########################################################################################################################################################


sub separate_features
{


#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Objectif : Routine permettant la construction de deux tableaux : @users_features et @others_features. Le premier tableau représente toutes les caractéristiques possédant qu'une modalité par utilisateur.
# Le deuxieme tableau possède toute les caractéristiques à plusieurs modalités.
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Input : NULL
# Output : Deux pointeurs sur les deux tableaux @users_features, @others_features
# Remarque : utilisation de la routine "frequence_features()" => cela peut être long...
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#


	#-----initialisation------#
	my %frequencies = frequence_features();
	my @users_features;
	my @others_features;

	#---On parcours le hash----#
	while ( my ( $clef, $valeur ) = each %frequencies ) 
	{
		
		if($valeur==0)  # on test si la caractéristiques présente qu'une modalité par utilisateur
			{
				push(@users_features,$clef);
				
			}
		else
			{

				push(@others_features,$clef);
				
			}
	  
	}
	
	
	return(\@users_features,\@others_features);


}



############################################################################################################################################################


sub all_featnames
{
	

#-------------------------------------------------------------------------------------------------------------------------------#
# Objectif : Routine permettant de retourner toutes les caractéristiques possibles distinctes avec la valeur anonimisée---------#
# Input : NULL
# Output : Tableau contenant toutes les caractéristiques possibles
# Remarque : Attention de ne pas confondre avec la fonction "All_features()"
#-------------------------------------------------------------------------------------------------------------------------------#
	
		
#-------On recupere tous les fichiers avec l'extension ".featnames"-------#
	my @files = glob("*.featnames");
#------Initialisation du tableau qui contiendra toutes les caractérisitques (features) distinctes exisantes
	my @featnames; 
# On parcours tous les fichiers featnames
	foreach my $file (@files)
		{
			#----Ouverture du fichier en lecture
			open(my $fh,'<',$file) or die "Impossible d'ourir le fichier en mode lecture";
			#---Lecture du fichier
			while(my $line = <$fh>)
				{
					my @ligne = split(/^\d+ /,$line);# split afin de récuperer seulement l'élément intéressant
					push(@featnames,$ligne[1]);
					
				}
						
			#---fermeture du fichier
			close $fh;
			
			
		}
		
		
	# On récupère les valeurs uniques (suppression des doublons)
	return(Tableau_Unique(@featnames));
		
}		
	
# jeu d'essaie
my @featnames = all_featnames();
#print scalar(@featnames);

#########################################################################################################################################################


sub Create_Table_Feature2
{

#--------------------------------------------------------------------------------------------------------------------------------------------------#
# Objectif :  Creation de deux tableaux : @print_profile et @features 
#--------------------------------------------------------------------------------------------------------------------------------------------------#
# Input : Une caractéristique (élément) du tableau : @others_features
# Output : Pouteurs  \@print_profile et \@features
#--------------------------------------------------------------------------------------------------------------------------------------------------#
	
	
	#-----Argument de la fonction = une caractéristique du tableau @others_features-----#
	my ($feature) = @_;
	
	##----------Initialisation------------##
	# On récupère tous les utilisateurs grace à la fonction "all_users()"
	my @users = all_users();
	#my @users = (1,2,3,71,107,89,0);
	
	# Creation du nom du fichier
	my $file_name = $feature;
	$file_name =~ s/:/_/g; ; #On rempace les : par _ 
	
	#--Ouverture du fichier en ecriture => Ecriture de la table "Users" en csv.
	# my $fichier = "TR\\$file_name.csv";
	# open(my $fh,'>',$fichier) or die "impossible d'ouvrir le fichier '$fichier' en écriture";

	#---Ecriture de l'entete dans le fichier csv---#
	# print $fh join(";",("id","$feature","users"))."\n";
	
	#-----Initialisation de l'identifiant------#
	# my $id = 1;
	
	my @print_profile;
	my @features;
	#----On récupère le profil pour chaque utilisateur et on test les matching => on boucle sur les users----#
	foreach my $user (@users)
		{
			

			# On recupere le profile de l'utilisateur et on remplace ";" par ":"
			my @profil = map { local $_ = $_; s/;/:/g; $_ } profile($user);	
			
			
			# On recupere la correspondance des caractérsitiques => matching features
			my @match_features = grep(/$feature/, @profil);
			
			if(scalar(@match_features)==1)
				{	
					
					push(@print_profile,join("::",($match_features[0],$user)));
					push(@features,$match_features[0]);
					# print $fh join(";",($id,$match_features[0],$user))."\n"; # On print dans le csv !
					# $id++; # Incrementation de l'id
					
					
				
				}
			if(scalar(@match_features)>1) # Plusieurs correspondances au sein d'un meme utilisateur
				{
					
					foreach my $elt (@match_features)
						{
							
							push(@print_profile,join("::",($elt,$user)));
							push(@features,$elt);
							# print $fh join(";",($id,$elt,$user))."\n"; # On print dans le csv! 
							# $id++; # Incrementation de l'id
							
						}
					
					
				}
					
					
				
	
				
		}
	
	return (\@print_profile,\@features);
	#---Fermeture du fichier---#
	# close $fh;


}

# jeu dessaie
# my ($t,$tt) = Create_Table_Feature2($others_features[9]);
# #print join("\n",@{$t})."\n";
# print scalar(@{$tt})."\n";
# print scalar(Tableau_Unique(@{$tt}));



