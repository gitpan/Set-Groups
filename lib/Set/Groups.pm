package Set::Groups ;

#   ======================
# 
#           Jacquelin Charbonnel - CNRS/LAREMA
#  
#   $Id: Groups.pm 145 2007-04-07 09:12:34Z jaclin $
#   
#   ----
#  
# 
# 
#   ----
#   $LastChangedDate: 2007-04-07 11:12:34 +0200 (Sat, 07 Apr 2007) $ 
#   $LastChangedRevision: 145 $
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

our $VERSION = 0.2 ;

sub new
{
  my ($type,%h) = @_ ;
  my $this = {
        "group" => {}
		} ;
  
  %h = map { /^-/ ? lc : $_ ;} %h ;

  if (exists $h{"-group"})
  {
    $this->{"group"} = $h{"-group"} ;
	delete $h{"-group"} ;
  }

  if (exists $h{"-single"})
  {
    $this->{"single"} = $h{"-single"} ;
	delete $h{"-single"} ;
  }

  $this->{"arg"} = \%h ;
  
  bless $this,$type ;
  return $this ;
}

sub newGroup
{
  my ($this,$group) = @_ ;
  if (exists $this->{"group"}{$group})
  {
    return 0 ;
  }
  else
  {
    $this->{"group"}{$group} = {} ;
	return 1 ;
  }
}

sub deleteGroup
{
  my ($this,$group) = @_ ;
  if (exists $this->{"group"}{$group})
  {
    delete $this->{"group"}{$group} ;
    return 1 ;
  }
  else
  {
	return 0 ;
  }
}

sub getGroups
{
  my ($this) = @_ ;
  return keys %{$this->{"group"}} ;
}

sub hasGroup
{
  my($this,$group) = @_ ;
  return exists $this->{"group"}{$group} ;
}

sub addSingleTo
{
  my ($this,$single,$group) = @_ ;
  $this->{"group"}{$group}{"single"}{$single} = 1 ;
}

sub addGroupTo
{
  my ($this,$mgroup,$group) = @_ ;

  $this->{"group"}{$mgroup} = {} unless (exists $this->{"group"}{$mgroup}) ;
  $this->{"group"}{$group}{"group"}{$mgroup} = 2 ;
}

sub isOwnSingleOf
{
  my ($this,$candidate,$group) = @_ ;
  
  return exists $this->{"group"}{$group}{"single"}{$candidate} ;
}

sub isGroupOf
{
  my ($this,$candidate,$group) = @_ ;
  
  return exists $this->{"group"}{$group}{"group"}{$candidate} ;
}

sub _flattenedSinglesOf
{
  my ($this,$group) = @_ ;
  
  my %flat = () ;
  %flat = %{$this->{"group"}{$group}{"single"}} if exists $this->{"group"}{$group}{"single"} ;
  #print "flat:",Dumper(\%flat) ;

  for my $k (keys %{$this->{"group"}{$group}{"group"}})
  {
  #print "k:$k\n";
    my %fs = $this->_flattenedSinglesOf($k) ;
	#print "fs:",Dumper \%fs ;
	for my $kk (keys %fs)
	{
  #print "kk:$kk\n" ;
	  $flat{$kk} = 1 ;
	}
  }
  #print "group:$group ; flat:",Dumper(\%flat) ;
  return %flat ;
}  

sub isSingleOf
{
  my ($this,$candidate,$group) = @_ ;
  my %fs = $this->_flattenedSinglesOf($group) ;
  return exists $fs{$candidate} ;
}  

sub getOwnSinglesOf
{
  my ($this,$group) = @_ ;
  return keys %{$this->{"group"}{$group}{"single"}} ;
}

sub getGroupsOf
{
  my ($this,$group) = @_ ;
  return keys %{$this->{"group"}{$group}{"group"}} ;
}

sub getSinglesOf
{
  my ($this,$group) = @_ ;
  #print "group:$group\n" ;
  my %h = $this->_flattenedSinglesOf($group) ;
  return keys %h ;
}

sub removeOwnSingleFrom
{
  my ($this,$single,$group) = @_ ;
  if ($this->isSingleOf($single,$group))
  {
    delete $this->{"group"}{$group}{"single"}{$single} ;
	return 1 ;
  }
  else { return 0 ; }
}

sub removeGroupFrom
{
  my ($this,$sub,$group) = @_ ;
  if ($this->isGroupOf($sub,$group))
  {
    delete $this->{"group"}{$group}{"group"}{$sub} ;
	return 1 ;
  }
  else { return 0 ; }
}

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

=head2 Set management

=head3 newGroup

Create a new empty group and add it in the set. 
A group is everything which can be a key of a hash.
NewGroup returns 0 if this group already exists, 1 otherwise.
  
  $groups->newGroup("a_group") ;
  $groups->newGroup(1) ;

=head3 deleteGroup

Delete a group from the set. Return 1 on success, 0 otherwise.

  $groups->deleteGroup("a_group") ;
  
=head3 getGroups

Return the list of the groups present into the set.

  @groups = $groups->getGroups() ; 

=head3 hasGroup

Check if a group is present into the set.

  $present = $groups->hasGroup("a_group") ;

=head2 Groups management

=head3 addSingleTo

Add a single member to a group. 
A single is everything which can be a key of a hash.
If the group doesn't exist in the set, it is created.

  $groups->addSingleTo("single","a_group") ;

=head3 addSinglesTo

Add a list of single members to a group. If the group doesn't exist in the set, it is created.

  $groups->addSinglesTo(["single1","single2"],"a_group") ;

=head3 addGroupTo

Add a group member to a group. 
If the embedding group doesn't exist in the set, it is created.
If the member group doesn't exist in the set, it is created as an empty group.

  $groups->addGroupTo("group_member","a_group") ;
  
=head3 addGroupsTo

Add a list of group members to a group. 
If the embedding group doesn't exist in the set, it is created.
If the member group doesn't exist in the set, it is created as an empty group.

  $groups->addGroupsTo(["group_member1","group_member2"],"a_group") ;
  
=head3 isOwnSingleOf

Check if a single is an own member of a group.

  $present = $groups->isOwnSingleOf("single","a_group") ;

=head3 isGroupOf

Check if a group is member of a group.

  $present = $groups->isGroupOf("a_group_member","a_group") ;

=head3 isSingleOf

Check if a single is a (own or not) member of a group.

  $present = $groups->isSingleOf("single","a_group") ;

=head3 getOwnSinglesOf

Return the list of own singles of a group.

  @singles = $groups->getOwnSinglesOf("a_group") ;

=head3 getGroupsOf

Return the list of groups of a group.

  @groups = $groups->getGroupsOf("a_group") ;

=head3 getSinglesOf

Return the list of (own or not) singles of a group.

  @singles = $groups->getSinglesOf("a_group") ;

=head3 removeOwnSingleFrom

Remove an own single from a group. Return 1 on success, 0 otherwise.

  $groups->removeSingleFrom("single","a_group") ;

=head3 removeGroupFrom

Remove a group member from a group. Return 1 on success, 0 otherwise.

  $groups->removeGroupFrom("a_member_group","a_group") ;

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
	print join(', ',$groups->getSinglesOf("all")) ;

gives : apache, sophie, jacquelin, lioudmila, mohammed, smmsp, nobody, adm, annette, operator, james, named, adam, halt, root, daemon, piotr

=cut

=head1 AUTHOR

Jacquelin Charbonnel, C<< <jacquelin.charbonnel at math.cnrs.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dir-which at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Set-Groups>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Set-Groups

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Set-Groups>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Set-Groups>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Set-Groups>

=item * Search CPAN

L<http://search.cpan.org/dist/Set-Groups>

=back

=head1 COPYRIGHT & LICENSE

Copyright Jacquelin Charbonnel E<lt>jacquelin.charbonnel at math.cnrs.frE<gt>

This software is governed by the CeCILL-C license under French law and
abiding by the rules of distribution of free software.  You can  use, 
modify and/ or redistribute the software under the terms of the CeCILL-C
license as circulated by CEA, CNRS and INRIA at the following URL
"http://www.cecill.info". 

As a counterpart to the access to the source code and  rights to copy,
modify and redistribute granted by the license, users are provided only
with a limited warranty  and the software's author,  the holder of the
economic rights,  and the successive licensors  have only  limited
liability. 

In this respect, the user's attention is drawn to the risks associated
with loading,  using,  modifying and/or developing or reproducing the
software by the user in light of its specific status of free software,
that may mean  that it is complicated to manipulate,  and  that  also
therefore means  that it is reserved for developers  and  experienced
professionals having in-depth computer knowledge. Users are therefore
encouraged to load and test the software's suitability as regards their
requirements in conditions enabling the security of their systems and/or 
data to be ensured and,  more generally, to use and operate it in the 
same conditions as regards security. 

The fact that you are presently reading this means that you have had
knowledge of the CeCILL-C license and that you accept its terms.

=cut

1; 
