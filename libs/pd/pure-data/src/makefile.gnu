VPATH = ../obj:./
OBJ_DIR = ../obj
BIN_DIR = ../bin
PDEXEC = $(BIN_DIR)/pd
EXT= pd_linux
ALSA=true
OSS=true

prefix = /usr/local
exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin
includedir = ${prefix}/include
libdir = ${exec_prefix}/lib
mandir = ${prefix}/share/man

# varibles to match packages/Makefile.buildlayout so that they can be easily
# overridden when building Pd-extended builds. <hans@at.or.at>
libpddir = $(libdir)/pd
pddocdir = $(libpddir)/doc
libpdbindir = $(libpddir)/bin
libpdtcldir = $(libpddir)/tcl

CPPFLAGS = -DPD -DHAVE_LIBDL -DHAVE_UNISTD_H -DHAVE_ALLOCA_H \
    -DPDGUIDIR=\"tcl/\" \
    -D_LARGEFILE64_SOURCE -DINSTALL_PREFIX=\"$(prefix)\" \
    -Wall -W -Wstrict-prototypes \
    -Wno-unused -Wno-unused-parameter -Wno-parentheses -Wno-switch

MORECFLAGS = -O3 -ffast-math -funroll-loops -fomit-frame-pointer 

LDFLAGS = -Wl,-export-dynamic
LIB =   -ldl -lm -lpthread

SYSSRC = s_midi_oss.c

# conditionally add code and flags for various audio APIs
ifdef ALSA
CPPFLAGS += -DUSEAPI_ALSA
SYSSRC += s_audio_alsa.c s_audio_alsamm.c s_midi_alsa.c
LIB += -lasound
endif
ifdef JACK
CPPFLAGS += -DUSEAPI_JACK
SYSSRC += s_audio_jack.c
LIB += -ljack
endif
ifdef OSS
CPPFLAGS += -DUSEAPI_OSS
SYSSRC += s_audio_oss.c
endif
ifdef PA
CPPFLAGS += -DUSEAPI_PORTAUDIO
SYSSRC += s_audio_pa.c
LIB += -lportaudio
endif

CFLAGS = $(CPPFLAGS) $(MORECFLAGS)

SRC = g_canvas.c g_graph.c g_text.c g_rtext.c g_array.c g_template.c g_io.c \
    g_scalar.c g_traversal.c g_guiconnect.c g_readwrite.c g_editor.c \
    g_all_guis.c g_bang.c g_hdial.c g_hslider.c g_mycanvas.c g_numbox.c \
    g_toggle.c g_vdial.c g_vslider.c g_vumeter.c \
    m_pd.c m_class.c m_obj.c m_atom.c m_memory.c m_binbuf.c \
    m_conf.c m_glob.c m_sched.c \
    s_main.c s_inter.c s_file.c s_print.c \
    s_loader.c s_path.c s_entry.c s_audio.c s_midi.c s_utf8.c s_audio_paring.c \
    d_ugen.c d_ctl.c d_arithmetic.c d_osc.c d_filter.c d_dac.c d_misc.c \
    d_math.c d_fft.c d_fft_fftsg.c d_array.c d_global.c \
    d_delay.c d_resample.c d_soundfile.c \
    x_arithmetic.c x_connective.c x_interface.c x_midi.c x_misc.c \
    x_time.c x_acoustics.c x_net.c x_text.c x_gui.c x_list.c x_array.c \
    x_scalar.c \
    $(SYSSRC)

OBJ = $(SRC:.c=.o) 

# get version from m_pd.h to use in doc/1.manual/1.introduction.txt
PD_MAJOR_VERSION := $(shell grep PD_MAJOR_VERSION m_pd.h | \
	sed 's|^.define *PD_MAJOR_VERSION *\([0-9]*\).*|\1|' )
PD_MINOR_VERSION := $(shell grep PD_MINOR_VERSION m_pd.h | \
	sed 's|^.define *PD_MINOR_VERSION *\([0-9]*\).*|\1|' )
PD_BUGFIX_VERSION := $(shell grep PD_BUGFIX_VERSION m_pd.h | \
	sed 's|^.define *PD_BUGFIX_VERSION *\([0-9]*\).*|\1|' )
PD_TEST_VERSION := $(shell grep PD_TEST_VERSION m_pd.h | \
	sed 's|^.define *PD_TEST_VERSION *"\(.*\)".*|\1|' )
PD_VERSION := $(PD_MAJOR_VERSION).$(PD_MINOR_VERSION).$(PD_BUGFIX_VERSION)
ifneq ($(PD_TEST_VERSION),)
	PD_VERSION := $(PD_VERSION)-$(PD_TEST_VERSION)
endif

#
#  ------------------ targets ------------------------------------
#

.PHONY: pd externs all depend

all: pd $(BIN_DIR)/pd-watchdog $(BIN_DIR)/pdsend $(BIN_DIR)/pdreceive externs \
    makefile.dependencies

bin: pd $(BIN_DIR)/pd-watchdog $(BIN_DIR)/pdsend $(BIN_DIR)/pdreceive

$(OBJ) : %.o : %.c
	$(CC) $(CFLAGS) $(GFLAGS) $(INCLUDE) -c -o $(OBJ_DIR)/$*.o $*.c 

pd: $(PDEXEC)

pd-watchdog: $(BIN_DIR)/pd-watchdog

$(BIN_DIR)/pd-watchdog: s_watchdog.c
	test -d $(BIN_DIR) || mkdir -p $(BIN_DIR)
	$(CC) $(CFLAGS) $(STRIPFLAG) -o $(BIN_DIR)/pd-watchdog s_watchdog.c

$(BIN_DIR)/pdsend: u_pdsend.c
	test -d $(BIN_DIR) || mkdir -p $(BIN_DIR)
	$(CC) $(CFLAGS)  $(STRIPFLAG) -o $(BIN_DIR)/pdsend u_pdsend.c

$(BIN_DIR)/pdreceive: u_pdreceive.c
	test -d $(BIN_DIR) || mkdir -p $(BIN_DIR)
	$(CC) $(CFLAGS)  $(STRIPFLAG) -o $(BIN_DIR)/pdreceive u_pdreceive.c

$(PDEXEC): $(OBJ_DIR) $(OBJ)
	test -d $(BIN_DIR) || mkdir -p $(BIN_DIR)
	cd ../obj;  $(CC) $(LDFLAGS) $(DBG_CFLAGS) -o $(PDEXEC) $(OBJ) $(LIB)

externs: 
	make -C ../extra/bonk~    
	make -C ../extra/choice   
	make -C ../extra/expr~    
	make -C ../extra/fiddle~  
	make -C ../extra/loop~    
	make -C ../extra/lrshift~ 
	make -C ../extra/pique    
	make -C ../extra/sigmund~ 
	make -C ../extra/pd~      
	make -C ../extra/stdout   
	make -C ../extra/bob~  

BINARYMODE=-m755

ABOUT_FILE=$(DESTDIR)$(pddocdir)/1.manual/1.introduction.txt
install:  all
	install -d $(DESTDIR)$(libpdbindir)
	install $(BIN_DIR)/pd-watchdog $(DESTDIR)$(libpdbindir)/pd-watchdog
	install -d $(DESTDIR)$(bindir)
	install $(BINARYMODE) $(PDEXEC) $(DESTDIR)$(bindir)/pd
	install -m755 $(BIN_DIR)/pdsend $(DESTDIR)$(bindir)/pdsend
	install -m755 $(BIN_DIR)/pdreceive $(DESTDIR)$(bindir)/pdreceive 
	install -d $(DESTDIR)$(libpdtcldir)
	install ../tcl/* $(DESTDIR)$(libpdtcldir)
	for dir in $(shell ls -1 ../doc | grep -v CVS); do \
		echo "installing $$dir"; \
		install -d $(DESTDIR)$(pddocdir)/$$dir ; \
		install -m644 -p ../doc/$$dir/*.* $(DESTDIR)$(pddocdir)/$$dir ; \
	done
	for dir in $(shell ls -1 ../doc/7.stuff | grep -v CVS); do \
		echo "installing 7.stuff/$$dir"; \
		install -d $(DESTDIR)$(pddocdir)/7.stuff/$$dir ; \
		install -m644 -p ../doc/7.stuff/$$dir/*.* \
                    $(DESTDIR)$(pddocdir)/7.stuff/$$dir ; \
	done
	mv $(ABOUT_FILE) $(ABOUT_FILE).tmp
	cat $(ABOUT_FILE).tmp | sed 's|PD_VERSION|Pd version $(PD_VERSION)|' \
		> $(ABOUT_FILE)
	rm $(ABOUT_FILE).tmp
	cp -pr ../extra $(DESTDIR)$(libpddir)/
	rm -f $(DESTDIR)$(libpddir)/extra/*/*.o
	install -d $(DESTDIR)$(includedir)
	install -m644 m_pd.h $(DESTDIR)$(includedir)/m_pd.h
	install -d $(DESTDIR)$(mandir)/man1
	gzip < ../man/pd.1 >  $(DESTDIR)$(mandir)/man1/pd.1.gz
	chmod 644 $(DESTDIR)$(mandir)/man1/pd.1.gz
	gzip < ../man/pdsend.1 >  $(DESTDIR)$(mandir)/man1/pdsend.1.gz
	chmod 644 $(DESTDIR)$(mandir)/man1/pdsend.1.gz
	gzip < ../man/pdreceive.1 >  $(DESTDIR)$(mandir)/man1/pdreceive.1.gz
	chmod 644 $(DESTDIR)$(mandir)/man1/pdreceive.1.gz
	@echo "Pd install succeeded."

local-clean:
	-rm -f ../obj/* $(BIN_DIR)/pd $(BIN_DIR)/pdsend \
	    $(BIN_DIR)/pdreceive $(BIN_DIR)/pd-watchdog m_stamp.c \
            $(BIN_DIR)/*.tcl
	-rm -f `find ../portaudio -name "*.o"` 
	-rm -f *~
	-(cd ../doc/6.externs; rm -f *.pd_linux)
	-rm -f makefile.dependencies

extra-clean:
	-rm -f `find ../extra/ -name "*.pd_*"`
	-rm -f tags

clean: extra-clean local-clean

distclean: clean
	-rm -f config.cache config.log config.status makefile tags \
		autom4te.cache/output.* autom4te.cache/traces.* autom4te.cache/requests
	-rmdir autom4te.cache
	-rm -rf autom4te-*.cache

tags: $(SRC) $(GSRC); ctags *.[ch]

depend: makefile.dependencies

$(OBJ_DIR):
	test -d $(OBJ_DIR) || mkdir -p $(OBJ_DIR)

makefile.dependencies:
	$(CC) $(CPPFLAGS) -M $(SRC) > makefile.dependencies

uninstall:
	rm -f -r $(DESTDIR)$(libpddir)
	rm -f $(DESTDIR)$(bindir)/pd
	rm -f $(DESTDIR)$(bindir)/pdsend
	rm -f $(DESTDIR)$(bindir)/pdreceive
	rm -f $(DESTDIR)$(includedir)/m_pd.h
	rm -f $(DESTDIR)$(mandir)/man1/pd.1.gz
	rm -f $(DESTDIR)$(mandir)/man1/pdsend.1.gz
	rm -f $(DESTDIR)$(mandir)/man1/pdreceive.1.gz

-include makefile.dependencies







