
# This file contains common variables used in MAP.

EMPTY     :=
SPACE     :=$(EMPTY) $(EMPTY)
COMMA     :=$(EMPTY),$(EMPTY)
TAB       :=$(EMPTY)	$(EMPTY)
# Above: TAB: A literal tab! Make sure not to change the whitespace on this line (the tab is, naturally, invisible)

# Note that the above lines use ":=" and not "=" !!
# (They can actually use either)
# IMMEDIATE EVALUATION>>  := means "set this variable to be whatever the value on the right side is at this very moment"
# LAZY EVALUATION>>   =  means "set this variable to the equation on the right side, and then evaluate the right side whenever it comes up.


THISDIR   = $(shell pwd | cut.pl -f -1 -d /)
PARENTDIR = $(shell pwd | cut.pl -f -2 -d /)
GRANDDIR  = $(shell pwd | cut.pl -f -3 -d /)
GREATDIR  = $(shell pwd | cut.pl -f -4 -d /)
GREATGREATDIR  = $(shell pwd | cut.pl -f -5 -d /)

ORGANISM  ?= $(shell get_organism.pl $(subst $(SPACE),_,$(shell pwd)))
## Note: this is "lazily" evaluated

ORG       = $(ORGANISM)
org       = $(ORGANISM)
ORGANISMS = Fly Human Mouse Rat Worm Yeast Hpylori

MAPDATA   = $(MAPDIR)/Data

GENESETS  = $(MAPDATA)/GeneSets

# Set timestamping to "ON" by default, if it was not ALREADY set.
# If it WAS already set, then ?= doesn't have any effect.
TIMESTAMPING ?= ON

ifeq ($(TIMESTAMPING),OFF)
REMOTE_FTP = wget --retr-symlinks --passive-ftp -Q 0 -nc -nd -t 1
else
REMOTE_FTP = wget --retr-symlinks --passive-ftp -Q 0 -N -nd -t 1
endif

MATLAB = matlab -nojvm -glnx86

join-with = $(subst $(SPACE),$1,$(strip $2))


