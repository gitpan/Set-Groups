package Set::Groups ;

#   ======================
# 
#           Jacquelin Charbonnel - CNRS/LAREMA
#  
#   $Id: Groups.pm 162 2007-04-20 20:56:21Z jaclin $
#   
#   ----
#  
# 
# 
#   ----
#   $LastChangedDate: 2007-04-20 22:56:21 +0200 (Fri, 20 Apr 2007) $ 
#   $LastChangedRevision: 162 $
#   $LastChangedBy: jaclin $
#   $URL: https://svn.math.cnrs.fr/jaclin/src/pm/Set-Groups/Groups.pm $
#  
#   ======================

require Exporter ;
@ISA = qw(Exporter);
@EXPORT=qw() ;
@EXPORT_OK = qw( );

use 5.006;
use Carp;
use warnings;
use strict;

our $VERSION = 0.4 ;
my $hfmt = "Set::Groups: HORROR: group '%s' is cyclic, the walk is infinite... Bye"  ;

sub new()
{
	my ($type) = @_ ;
	my $this = {
		"group" => {}
		, "debug" => 0
	} ;
  
	bless $this,$type ;
	return $this ;
}

sub setDebug($)
{
	my ($this,$level) = @_ ;
	$this->{"debug"} = $level ;
}

# -----------------
# Set management
# -----------------

sub newGroup($)
{
	my ($this,$group) = @_ ;

	if (exists $this->{"group"}{$group})
	{
		return 0 ;
	}
	else
	{
		$this->{"group"}{$group} = {} ;
		delete $this->{"partition"} if exists $this->{"partition"} ; 
		return 1 ;
	}
}

sub deleteGroup($)
{
	my ($this,$group) = @_ ;
	
	if (exists $this->{"group"}{$group})
	{
		delete $this->{"group"}{$group} ;
		delete $this->{"partition"} if exists $this->{"partition"} ;
		return 1 ;
	}
	else
	{
		return 0 ;
	}
}

sub getGroups()
{
	my ($this) = @_ ;
	return keys %{$this->{"group"}} ;
}

sub getCyclicGroups
{
	my($this) = @_ ;

	$this->_walk() unless exists $this->{"partition"} ;
	return keys(%{$this->{"partition"}{"cyclic"}}) ;
}

sub getAcyclicGroups
{
	my($this) = @_ ;

	$this->_walk() unless exists $this->{"partition"} ;
	return keys(%{$this->{"partition"}{"acyclic"}}) ;
}

sub hasGroup($)
{
	my($this,$group) = @_ ;
	return exists $this->{"group"}{$group} ;
}

# -----------------
# Group management
# -----------------

sub addSingleTo($$)
{
	my ($this,$single,$group) = @_ ;

	return 0 if exists $this->{"group"}{$group}{"single"}{$single} ;
	$this->{"group"}{$group}{"single"}{$single} = 1 ;
	return 1 ;
}

sub addGroupTo($$)
{
	my ($this,$mgroup,$group) = @_ ;

	return 0 if exists $this->{"group"}{$group}{"group"}{$mgroup} ;
	$this->{"group"}{$mgroup} = {} unless (exists $this->{"group"}{$mgroup}) ;
	$this->{"group"}{$group}{"group"}{$mgroup} = 2 ;
	delete $this->{"partition"} if exists $this->{"partition"} ;
	return 1 ;
}

sub removeOwnSingleFrom($$)
{
	my ($this,$single,$group) = @_ ;

	if ($this->isSingleOf($single,$group))
	{
		delete $this->{"group"}{$group}{"single"}{$single} ;
		return 1 ;
	}
	else { return 0 ; }
}

sub removeGroupFrom($$)
{
	my ($this,$sub,$group) = @_ ;

	if ($this->isGroupOf($sub,$group))
	{
		delete $this->{"group"}{$group}{"group"}{$sub} ;
		delete $this->{"partition"} if exists $this->{"partition"} ;
		return 1 ;
	}
	else { return 0 ; }
}

# This function performs a total walk, if needeed
# At exit, the partition is always complete
sub isAcyclic
{
	my ($this,$group) = @_ ;

	$this->_walk() unless exists($this->{"partition"}) ;
	return exists($this->{"partition"}{"acyclic"}{$group}) ;
}  

sub isOwnSingleOf($$)
{
	my ($this,$candidate,$group) = @_ ;
	return exists $this->{"group"}{$group}{"single"}{$candidate} ;
}

sub isGroupOf($$)
{
	my ($this,$candidate,$group) = @_ ;
	return exists $this->{"group"}{$group}{"group"}{$candidate} ;
}

sub isSingleOf($$)
{
	my ($this,$candidate,$group) = @_ ;

	carp sprintf($hfmt,$group) if $this->{"debug"}>0 && !$this->isAcyclic($group) ;
	my %fs = $this->_flattenedSinglesOf($group) ;
	return exists $fs{$candidate} ;
}  

sub getOwnSinglesOf($)
{
	my ($this,$group) = @_ ;
	return keys %{$this->{"group"}{$group}{"single"}} ;
}

sub getGroupsOf($)
{
	my ($this,$group) = @_ ;
	return keys %{$this->{"group"}{$group}{"group"}} ;
}

sub getSinglesOf($)
{
	my ($this,$group) = @_ ;

	carp sprintf($hfmt,$group) if $this->{"debug"}>0 && !$this->isAcyclic($group) ;
	my %h = $this->_flattenedSinglesOf($group) ;
	return keys %h ;
}

# -----------------
# private methods
# -----------------

sub _flattenedSinglesOf()
{
	my ($this,$group) = @_ ;

	my %flat = () ;
	%flat = %{$this->{"group"}{$group}{"single"}} 
	  if exists $this->{"group"}{$group}{"single"} ;

	for my $k (keys %{$this->{"group"}{$group}{"group"}})
	{
		my %fs = $this->_flattenedSinglesOf($k) ;
		for my $kk (keys %fs)
		{
			$flat{$kk} = 1 ;
		}
	}
	return %flat ;
}  

# This function don't perform a total walk
# At exit, the partition is incomplete
sub _isAcyclic($$)
{
	my ($this,$group,$passed) = @_ ;

	if (exists $passed->{$group})
	{
		$this->{"partition"}{"cyclic"}{$group} = 1 ;
		return 0 ;
	}
	my %passed = ( %$passed, $group => 1 ) ;

	for my $k (keys %{$this->{"group"}{$group}{"group"}})
	{
		next if exists $this->{"partition"}{"acyclic"}{$k} ;
		if (exists $this->{"partition"}{"cyclic"}{$k})
		{
			$this->{"partition"}{"cyclic"}{$group} = 1 ;
			return 0 ;
		}
		if ($this->_isAcyclic($k,\%passed)==1)
		{
			$this->{"partition"}{"acyclic"}{$k} = 1 ;
		}
		else
		{
			$this->{"partition"}{"cyclic"}{$k} = 1 ;
			$this->{"partition"}{"cyclic"}{$group} = 1 ;
			return 0 ;
		}  
	}
	$this->{"partition"}{"acyclic"}{$group} = 1 ;
	return 1 ;
}  

# Perform an inconditionnal walk on the graph
sub _walk()
{
	my ($this) = @_ ;

	carp "Set::Groups: DEBUG: walking on the graph to find cycles..." if $this->{"debug"}>0 ;
	delete $this->{"partition"} if exists $this->{"partition"} ;
	for my $group ($this->getGroups())  
	{
		$this->_isAcyclic($group,{}) ;
	}
}  

1; 




=head1 NAME

Set::Groups - A set of groups.

=head1 SYNOPSIS

  use Set::Groups ;

  # create a set of groups
  $groups = new Set::Groups ;
  
  # create a group MyGroup with a single member
  $groups->addSingleTo("single1","MyGroup") ;

  # add 2 singles members into MyGroup
  $groups->addSinglesTo(["single2","single3"],"MyGroup") ;
  
  # add a group member into MyGroup
  $groups->addGroupTo("Member1Group","MyGroup") ; 

  # add 2 group members into MyGroup
  $groups->addGroupsTo(["Member2Group","Member3Group"],"MyGroup") ; 

  # add a single members into the previous member groups
  $groups->addSingleTo("single4","Member1Group") ;
  $groups->addSingleTo("single5","Member2Group") ;
  $groups->addSingleTo("single6","Member3Group") ;
  
  # flatten the group MyGroup
  @singles = $groups->getSinglesOf("MyGroup") ;  
  $present = $groups->isSingleOf("single4","MyGroup") ; 
  
=head1 DESCRIPTION

The Groups object implements a set of groups. 
Each group can own single members and group members.
A group can be flattened, i.e. expansed until each of his members is a single one.

=cut

=head1 CONSTRUCTORS

=head3 new

Create a new group set.

  my $groups = new Set::Groups

=head1 INSTANCE METHODS

=head3 setDebug

Set a debug level.

  $groups->setDebug(1) ;
  
=head2 Set management

=head3 newGroup

Create a new empty group and add it into the set. 
A group is everything which can be a key of a hash.
Returns 1 on success, 0 otherwise.
  
  $groups->newGroup("a_group") ;
  $groups->newGroup(1) ;

=head3 deleteGroup

Delete a group from the set. Return 1 on success, 0 otherwise.

  $groups->deleteGroup("a_group") ;
  
=head3 getGroups

Return the list of the groups present into the set.

  @groups = $groups->getGroups() ; 

=head3 getCyclicGroups

Return the list of the cyclic groups (i.e. self-contained) present into the set.

  @groups = $groups->getGroups() ; 

=head3 getAcyclicGroups

Return the list of the acyclic groups (i.e. not self-contained) present into the set.

  @groups = $groups->getGroups() ; 

=head3 hasGroup

Check if a group is present into the set.

  $present = $groups->hasGroup("a_group") ;

=head2 Groups management

=head3 addSingleTo

Add a single member to a group. 
A single is everything which can be a key of a hash.
If the group doesn't exist in the set, it is created.
Return 1 on success, 0 otherwise.

  $groups->addSingleTo("single","a_group") ;

=head3 addGroupTo

Add a group member to a group. 
If the embedding group doesn't exist in the set, it is created.
If the member group doesn't exist in the set, it is created as an empty group.
Return 1 on success, 0 otherwise.

  $groups->addGroupTo("group_member","a_group") ;
  
=head3 removeOwnSingleFrom

Remove an own single from a group. Return 1 on success, 0 otherwise.

  $groups->removeSingleFrom("single","a_group") ;

=head3 removeGroupFrom

Remove a group member from a group. Return 1 on success, 0 otherwise.

  $groups->removeGroupFrom("a_member_group","a_group") ;

=head3 isAcyclic

Check if a group is acyclic.

  $is_acyclic = $groups->isAcyclic("a_group") ;
  
=head3 isOwnSingleOf

Check if a single is an own member of a group.

  $present = $groups->isOwnSingleOf("single","a_group") ;

=head3 isGroupOf

Check if a group is member of a group.

  $present = $groups->isGroupOf("a_group_member","a_group") ;

=head3 isSingleOf

Check if a single is a (own or not) member of a group.

  $present = $groups->isSingleOf("single","an_acyclic_group") ;

Warning - Calling this method wich a cyclic group as argument gives a infinite recursion.

=head3 getOwnSinglesOf

Return the list of own singles of a group.

  @singles = $groups->getOwnSinglesOf("a_group") ;

=head3 getGroupsOf

Return the list of groups of a group.

  @groups = $groups->getGroupsOf("a_group") ;

=head3 getSinglesOf

Return the list of (own or not) singles of an acyclic group.

  @singles = $groups->getSinglesOf("an_acyclic_group") ;

Warning - Calling this method wich a cyclic group as argument gives a infinite recursion.

=head1 EXAMPLES

Suppose a group file like :

	admin:root,adm
	team:piotr,lioudmila,adam,annette,jacquelin
	true-users:james,sophie,@team,mohammed
	everybody:@admin,operator,@true-users
	daemon:apache,smmsp,named,daemon
	virtual:nobody,halt,@daemon
	all:@everybody,@virtual

where C<@name> means I<group name>, then the following code :

	use Set::Groups ;

	$groups = new Set::Groups ;
	while(<F>)
	{
	  ($group,$members) = /^(\S+):(.*)$/ ;
	  @members = split(/,/,$members) ;
	  for $member (@members)
	  {
	    if ($member=~/^@/)
	    {
	      $member=~s/^@// ;
	      $groups->addGroupTo($member,$group) ;
	    }
	    else
	    {
	      $groups->addSingleTo($member,$group) ;
	    }
	  }
	}
	die "some groups are cyclic" if scalar($groups->getCyclicGroups())>0 ;
	print join(', ',$groups->getSinglesOf("all")) ;

gives : apache, sophie, jacquelin, lioudmila, mohammed, smmsp, nobody, adm, annette, operator, james, named, adam, halt, root, daemon, piotr

=cut
