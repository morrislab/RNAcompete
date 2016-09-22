#!/usr/bin/perl -w


# trash.pl is meant to be a "safer rm," which moves things to a trash can
# instead of immediately removing them. trash.pl will mangle names, so it's
# not necessarily going to be easy to restore things.

# Any slashes will be replaced with __PATH__, which means that restoring
# any directory structure will be exceedingly annoying. So be careful!



#
# Use and abuse as much as you want.
# Put it in /usr/local/bin/ or $HOME/bin/
# Daniel Cote a.k.a Novajo, dccote@novajo.ca
#
# Modified later!
#
# Most recent version of this file available at
# http://www.novajo.ca/trash.html
#
# Instead of deleting files, this script moves them to the appropriate trash folder.
# Trash folders are either private ($HOME/.Trash/) or public (/Volumes/name/.Trashes/
# and /.Trashes).  In the directory .Trashes/, each user has a trash folder named after
# its userid (501, 502, etc...).
#
# This script will simply stop if anything goes wrong. If by any chance it appears 
# that it might overwrite a file, it will let you know and ask for a confirmation.
#
# This script could be used as a replacement for rm.  The options passed as arguments
# are simply discarded.

# Usage: trash [options] file1|dir1 file2|dir2 file3|dir3 ... 
# You can use wildcards. To erase a directory, you are probably better off just naming
# the directory (e.g. trash Documents/) as opposed to trash Documents/* since the first
# case will actually keep the hierarchy and simply move Documents into the trash whereas
# the second one will move each item of the document folder into the trash individually.
#

use strict;
use warnings;

if ( scalar @ARGV == 0) {
  die "Not enough argument.\nUsage: trash file1|dir1 file2|dir2 file3|dir3 ...\n\n";
}

my $MAX_INDEX = 10000; # <-- number of duplicate-named files allowed in a directory
my $uid = `id -u`;
my $workingdir = `pwd`;
my $home = $ENV{HOME};

chomp($uid);
chomp($workingdir);

# We drop any option passed to command "trash"
# This allows to use trash as a replacement for rm
while ( $ARGV[0] =~ m|^-|i) {
  shift @ARGV;
}

foreach my $itemToDelete (@ARGV) {

  my $fullpath;
  my $name;

  if ($itemToDelete =~ m|^/(.*)|) {
	$fullpath = $itemToDelete;
	$name = $1;
  } elsif (-f $itemToDelete || -d $itemToDelete) {
	$fullpath = "$workingdir/$itemToDelete";
	$name = $itemToDelete;
  } else {
	print "trash.pl: Skipping: not a file or a directory: $itemToDelete\n";
	next;
  }

  my $username = `whoami`;
  chomp($username);


  if (!(length($username) > 0)) {
	die qq{We could not get your username! We need it to make the trash can!\n};
  }
  if ($username =~ /[\/\\"' ]/) {
	die qq{The username has a space in it, or a quotation mark, or a slash, or a backslash! We cannot reliably create a trash directory without it being dangerous!!!\n};
  }

  my $trash = qq{/tmp/${username}/Trash/};

  if (! -e $trash) {
	print qq{trash.pl: Making trash directory "$trash"\n};
	`mkdir -p $trash`;
	`chmod og-rwx $trash`; # making it so no one else can read it...
	`chmod u+rwx $trash`; # but we can read it...
	
  }

  if (!(-d $trash)) {
	die "Error: $trash is not a directory";
  }

  if (!(-e $fullpath)) {
	die "Error getting full path to file: $fullpath does not exist\n";
  }

  my $newname = $name;
  $newname    =~ s/\/$//; # <-- remove a trailing slash from the thing we're moving
  $newname =~ s/\//__PATH__/g;

  my $index = 2;

  #print "NAME: $name\n";

  while (-e "$trash/$newname") {
	$newname = "$name.$index";
	$index++;
	if ( $index == $MAX_INDEX) {
	  die "Error trying to rename file to avoid overwrite (too many files with the same name).\nYou should empty the trash.";
	}
  }

  print qq{trash.pl: Trashing "$name" -> "$trash$newname"\n};

  system(qq{mv "$fullpath" "$trash/$newname"});
}
