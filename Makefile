#
# Makefile for a Video Disk Recorder plugin
#
# $Id: Makefile 3.1 2014/01/01 13:29:54 kls Exp $

# The official name of this plugin.
# This name will be used in the '-P...' option of VDR to load the plugin.
# By default the main source file also carries this name.

PLUGIN = live

### The version number of this plugin (taken from the main source file):

VERSION = $(shell grep '\#define LIVEVERSION ' setup.h | awk '{ print $$3 }' | sed -e 's/[";]//g')

### The directory environment:

# Use package data if installed...otherwise assume we're under the VDR source directory:
PKGCFG = $(if $(VDRDIR),$(shell pkg-config --variable=$(1) $(VDRDIR)/vdr.pc),$(shell PKG_CONFIG_PATH="$$PKG_CONFIG_PATH:../../.." pkg-config --variable=$(1) vdr))
LIBDIR = $(call PKGCFG,libdir)
LOCDIR = $(call PKGCFG,locdir)
PLGCFG = $(call PKGCFG,plgcfg)
PLGRES = $(call PKGCFG,resdir)/plugins/$(PLUGIN)
#
TMPDIR ?= /tmp

### The compiler options:

ECPPC    ?= ecppc
export CXXFLAGS = $(call PKGCFG,cxxflags) $(shell tntnet-config --cxxflags)
export LIBS     = $(shell tntnet-config --libs)

### The version number of VDR's plugin API:

APIVERSION      = $(call PKGCFG,apiversion)
TNTVERSION      = $(shell tntnet-config --version | sed -e's/\.//g' | sed -e's/pre.*//g' | awk '/^..$$/ { print $$1."000"} /^...$$/ { print $$1."00"} /^....$$/ { print $$1."0" } /^.....$$/ { print $$1 }')
CXXTOOLVER      = $(shell cxxtools-config --version | sed -e's/\.//g' | sed -e's/pre.*//g' | awk '/^..$$/ { print $$1."000"} /^...$$/ { print $$1."00"} /^....$$/ { print $$1."0" } /^.....$$/ { print $$1 }')

### Allow user defined options to overwrite defaults:

-include $(PLGCFG)

### The name of the distribution archive:

ARCHIVE = $(PLUGIN)-$(VERSION)
PACKAGE = vdr-$(ARCHIVE)

### The name of the shared object file:

SOFILE = libvdr-$(PLUGIN).so

### Includes and Defines (add further entries here):

INCLUDES += -I$(shell pwd) -Ipages

DEFINES += -DPLUGIN_NAME_I18N='"$(PLUGIN)"' -DTNTVERSION=$(TNTVERSION) -DCXXTOOLVER=$(CXXTOOLVER)

### Optional configuration features
HAVE_LIBPCRECPP = $(shell pcre-config --libs-cpp)
ifneq ($(HAVE_LIBPCRECPP),)
	DEFINES   += -DHAVE_LIBPCRECPP
	CXXFLAGS  += $(shell pcre-config --cflags)
	LIBS      += $(HAVE_LIBPCRECPP)
endif

### The name of the distribution archive:

ARCHIVE = $(PLUGIN)-$(VERSION)
PACKAGE = vdr-$(ARCHIVE)

### The object files (add further files here):

OBJS =    $(PLUGIN).o thread.o tntconfig.o setup.o i18n.o timers.o \
	  tools.o recman.o tasks.o status.o epg_events.o epgsearch.o \
	  grab.o md5.o filecache.o livefeatures.o preload.o timerconflict.o \
	  users.o

OBJS   += javascript/treeview.o css/styles.o

OBJS   += pages/menu.o pages/recordings.o pages/schedule.o pages/multischedule.o pages/screenshot.o \
	  pages/timers.o pages/whats_on.o pages/switch_channel.o pages/keypress.o pages/remote.o \
	  pages/channels_widget.o pages/edit_timer.o pages/error.o pages/pageelems.o pages/tooltip.o \
	  pages/vlc.o pages/searchtimers.o pages/edit_searchtimer.o pages/searchresults.o \
	  pages/searchepg.o pages/login.o pages/ibox.o pages/xmlresponse.o pages/play_recording.o \
	  pages/pause_recording.o pages/stop_recording.o pages/ffw_recording.o \
	  pages/rwd_recording.o pages/setup.o pages/content.o pages/epginfo.o pages/timerconflicts.o \
	  pages/recstream.o pages/users.o pages/edit_user.o pages/edit_recording.o

### The main target:

all:$(SOFILE) i18n

### Implicit rules:

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $(DEFINES) $(INCLUDES) -o $@ $<

%.cpp: %.ecpp
	$(ECPPC) $(ECPPFLAGS) $(INCLUDES) $<

%.cpp: %.css
	$(ECPPC) $(ECPPFLAGS) $(INCLUDES) -b -m "text/css" $<

%.cpp: %.js
	$(ECPPC) $(ECPPFLAGS) $(INCLUDES) -b -m "text/javascript" $<
### Dependencies:

MAKEDEP = $(CXX) -MM -MG
DEPFILE = .dependencies
$(DEPFILE): Makefile $(OBJS:%.o=%.cpp)
	@$(MAKEDEP) $(CXXFLAGS) $(DEFINES) $(INCLUDES) $(OBJS:%.o=%.cpp) > $@

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPFILE)
endif

### Internationalization (I18N):

PODIR     = po
I18Npo    = $(wildcard $(PODIR)/*.po)
I18Nmo    = $(addsuffix .mo, $(foreach file, $(I18Npo), $(basename $(file))))
I18Nmsgs  = $(addprefix $(DESTDIR)$(LOCDIR)/, $(addsuffix /LC_MESSAGES/vdr-$(PLUGIN).mo, $(notdir $(foreach file, $(I18Npo), $(basename $(file))))))
I18Npot   = $(PODIR)/$(PLUGIN).pot

%.mo: %.po
	msgfmt -c -o $@ $<

$(I18Npot): $(wildcard *.cpp)
	xgettext -C -cTRANSLATORS --no-wrap --no-location -k -ktr -ktrNOOP pages/*.cpp setup.h epg_events.h --package-name=vdr-$(PLUGIN) --package-version=$(VERSION) --msgid-bugs-address='<see README>' -o $@ `ls $^`

%.po: $(I18Npot)
	msgmerge -U --no-wrap --no-location --backup=none -q -N $@ $<
	@touch $@

$(I18Nmsgs): $(DESTDIR)$(LOCDIR)/%/LC_MESSAGES/vdr-$(PLUGIN).mo: $(PODIR)/%.mo
	install -D -m644 $< $@

.PHONY: i18n
i18n: $(I18Nmo) $(I18Npot)

install-i18n: $(I18Nmsgs)

### Targets:

$(SOFILE): $(OBJS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -shared $(OBJS) $(LIBS) -o $@

install-lib: $(SOFILE)
	install -D $^ $(DESTDIR)$(LIBDIR)/$^.$(APIVERSION)

install-resources:
	mkdir -p $(DESTDIR)$(PLGRES)
	cp -r live/* $(DESTDIR)$(PLGRES)

install: install-lib install-i18n install-resources

dist: $(I18Npo) clean
	@-rm -rf $(TMPDIR)/$(ARCHIVE)
	@mkdir $(TMPDIR)/$(ARCHIVE)
	@cp -a * $(TMPDIR)/$(ARCHIVE)
	@tar czf $(PACKAGE).tgz -C $(TMPDIR) $(ARCHIVE)
	@-rm -rf $(TMPDIR)/$(ARCHIVE)
	@echo Distribution package created as $(PACKAGE).tgz

clean:
	@-rm -f $(PODIR)/*.mo $(PODIR)/*.pot
	@-rm -f $(OBJS) $(DEPFILE) *.so *.tgz core* *~
	@-rm -f css/*.cpp javascript/*.cpp pages/*.cpp
