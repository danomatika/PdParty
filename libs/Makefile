# build/install the required libs
# this will slowly replace the update scripts in scripts/libs... 
# Dan Wilcox <danomatika@gmail.com> 2022

# stop on error
.SHELLFLAGS = -e

# local temp build dir
BUILD_DIR = build

.PHONY: clean clobber \
	liblo \
	liblo-download \
	liblo-build \
	liblo-clean \
	liblo-clobber

all: liblo

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean: liblo-clean
	rm -rf $(BUILD_DIR)

clobber: liblo-clobber

##### liblo

# git tag, branch, or commit
LO_VER = master

LO_META = config.h AUTHORS ChangeLog COPYING README.md

# from liblo/lo/Makefile.am
LO_HEADERS = lo_errors.h lo_lowlevel.h lo_throw.h lo_types.h \
             lo_osc_types.h lo_macros.h lo_cpp.h \
             lo.h lo_endian.h lo_serverthread.h

# from liblo/src/Makefile.am
LO_SOURCES = address.c send.c message.c server.c method.c \
             blob.c bundle.c timetag.c pattern_match.c version.c \
             server_thread.c lo_types_internal.h lo_internal.h

liblo: liblo-download liblo-build

liblo-download: $(BUILD_DIR)/liblo

# download
$(BUILD_DIR)/liblo: $(BUILD_DIR)
	cd $(BUILD_DIR)/ \
	    && git clone https://github.com/radarsat1/liblo.git \
	    && cd liblo \
	    && git checkout $(LO_VER)

# run configure to generate headers
liblo/config.h:
	cd $(BUILD_DIR)/liblo \
	    && ./autogen.sh \
	    && ./configure --disable-network-tests --enable-ipv6

# copy files for liblo.xcodeproj
liblo-build: liblo/config.h
	mkdir -p liblo/lo liblo/src
	cp -v $(BUILD_DIR)/liblo/config.h liblo/
	@for f in $(LO_META); do cp -v $(BUILD_DIR)/liblo/$${f} liblo/ ; done
	@for f in $(LO_HEADERS); do cp -v $(BUILD_DIR)/liblo/lo/$${f} liblo/lo/ ; done
	@for f in $(LO_SOURCES); do cp -v $(BUILD_DIR)/liblo/src/$${f} liblo/src/ ; done

# remove build dir
liblo-clean:
	rm -rf $(BUILD_DIR)/liblo

# remove copied files
liblo-clobber:
	rm -rf liblo/config.h liblo/lo/* liblo/src/*
