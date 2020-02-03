/** \mainpage midifile.c An external for Pure Data that reads and writes MIDI files
*
*	Copyright (C) 2005-2017  Martin Peach
* \section license
*	This program is free software; you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation; either version 2 of the License, or
*	any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program; if not, write to the Free Software
*	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*
*	Latest version of this file can be found at:
*	http://pure-data.svn.sourceforge.net/viewvc/pure-data/trunk/externals/mrpeach/midifile/
*
*/

#include "m_pd.h"
#include <stdio.h>
#include <string.h>

/* support older Pd versions without sys_open(), sys_fopen(), sys_fclose() */
#if PD_MAJOR_VERSION == 0 && PD_MINOR_VERSION < 44
#define sys_open open
#define sys_fopen fopen
#define sys_fclose fclose
#endif

#define NO_MORE_ELEMENTS 0xFFFFFFFF

static t_class *midifile_class;

#define PATH_BUF_SIZE 1024
#define MAX_TRACKS 128
/* track data is allocated as needed but we need to preallocate space for the pointers */
#define ALL_TRACKS MAX_TRACKS
/** [midifile] can be in one of three states:
- mfReset: set by midifile_new() and midifile_clode()
- mfReading: set by midifile_new() and midifile_read() if a file has been opened
- mfWriting: set by midifile_write() if a file has been opened
*/
typedef enum {mfReset, mfReading, mfWriting} mfstate;

typedef struct mf_header_chunk
{
    char            chunk_type[4]; /* each chunk begins with a 4-character ASCII type.*/
    size_t          chunk_length ; /* followed by a 32-bit length */
    int             chunk_format;
    int             chunk_ntrks;
    int             chunk_division;
} mf_header_chunk;

typedef struct mf_track_chunk
{
    char            chunk_type[4]; /* each chunk begins with a 4-character ASCII type. */
    size_t          chunk_length ; /* followed by a 32-bit length */
    size_t          delta_time ; /* current delta_time of latest track_data element */
    size_t          total_time ; /* sum of delta_times so far */
    size_t          track_index ; /* current byte offset to next track_data element */
    unsigned char   running_status;
    unsigned char   *track_data;
} mf_track_chunk;

typedef struct t_midifile
{
    t_object            x_obj;
 /** current time for this MIDI file in delta_time units */
    size_t              total_time;
 /** one MIDI packet as a list */
    t_atom              midi_data[3];
    t_outlet            *midi_list_outlet;
    t_outlet            *status_outlet;
    t_outlet            *total_time_outlet;
 /** a file for reading or writing */
    FILE                *fP;
 /** potentially lots of tracks may be written */
    FILE                *tmpFP[MAX_TRACKS];
 /** current directory for relative file paths */
    t_symbol            *our_directory;
 /** absolute path to file at fP */
    char                fPath[PATH_BUF_SIZE];
 /** character offset into the file fP */
    size_t              offset;
 /** play this track, or all tracks if negative. Write to this track */
    int                 track;
 /** nonzero for text output to console */
    int                 verbosity;
 /** nonzero if all tracks have finished */
    int                 ended;
 /** mfReset, mfReading, or mfWriting */
    mfstate             state;
 /** First chunk in the midi file */
    mf_header_chunk     header_chunk;
 /** Subsequent track chunks. Other kinds of chunk are ignored. */
    mf_track_chunk      track_chunk[MAX_TRACKS];
} t_midifile;

static void midifile_skip_next_track_chunk_data(t_midifile *x, int mfindex);
static void midifile_get_next_track_chunk_data(t_midifile *x, int mfindex);
static size_t midifile_get_next_track_chunk_delta_time(t_midifile *x, int mfindex);
static void midifile_output_long_list (t_outlet *outlet, unsigned char *cP, size_t len, unsigned char first_byte);
static void midifile_dump_track_chunk_data(t_midifile *x, int mfindex);
static unsigned char *midifile_read_var_len (unsigned char *cP, size_t *delta);
static int midifile_write_variable_length_value (FILE *fP, size_t value);
static unsigned short midifile_combine_bytes(unsigned char data1, unsigned char data2);
static unsigned short midifile_get_multibyte_2(unsigned char*n);
static unsigned long midifile_get_multibyte_3(unsigned char*n);
static unsigned long midifile_get_multibyte_4(unsigned char*n);
static int midifile_read_track_chunk(t_midifile *x, int mfindex);
static int midifile_read_header_chunk(t_midifile *x);
static void midifile_rewind (t_midifile *x);
static void midifile_rewind_tracks(t_midifile *x);
static int midifile_read_chunks(t_midifile *x);
static void midifile_close(t_midifile *x);
static void midifile_free_file(t_midifile *x);
static void midifile_free(t_midifile *x);
static int midifile_open_path(t_midifile *x, char *path, char *mode);
static void midifile_flush(t_midifile *x);
static size_t midifile_write_header(t_midifile *x, int nTracks);
static void midifile_read(t_midifile *x, t_symbol *path);
static void midifile_write(t_midifile *x, t_symbol *s, int argc, t_atom *argv);
static void midifile_bang(t_midifile *x);
static size_t midifile_write_end_of_track(t_midifile *x, size_t end_time, int trackNr);
static void midifile_float(t_midifile *x, t_float ticks);
static void midifile_list(t_midifile *x, t_symbol *s, int argc, t_atom *argv);
static void *midifile_new(t_symbol *s, int argc, t_atom *argv);
static void midifile_verbosity(t_midifile *x, t_floatarg verbosity);
static void midifile_set_track(t_midifile *x, t_floatarg track);
static void midifile_dump(t_midifile *x, t_floatarg track);
static t_symbol *midifile_key_name(int sf, int mi);
void midifile_setup(void);

/** midifile_setup instantiates an instance of [midifile]
- calls class_new() to register midifile_new() as the constructor and midifile_free() as the destructor
*
Registers methods:
- midifile_bang()
- midifile_float()
- midifile_list()
- midifile_read()
- midifile_flush()
- midifile_write()
- midifile_dump()
- midifile_set_track()
- midifile_rewind()
- midifile_verbosity()
*/
void midifile_setup(void)
{
    const char aStr[] = "midifile v0.2 20170320 by Martin Peach";

    midifile_class = class_new (gensym("midifile"),
        (t_newmethod) midifile_new,
        (t_method)midifile_free, sizeof(t_midifile),
        CLASS_DEFAULT,
        A_GIMME, 0);

    class_addbang(midifile_class, midifile_bang);
    class_addfloat(midifile_class, midifile_float);
    class_addlist(midifile_class, midifile_list);
    class_addmethod(midifile_class, (t_method)midifile_read, gensym("read"), A_DEFSYMBOL, 0);
    class_addmethod(midifile_class, (t_method)midifile_flush, gensym("flush"), 0);
    class_addmethod(midifile_class, (t_method)midifile_write, gensym("write"), A_GIMME, 0);
    class_addmethod(midifile_class, (t_method)midifile_dump, gensym("dump"), A_DEFFLOAT, 0);
    class_addmethod(midifile_class, (t_method)midifile_set_track, gensym("track"), A_DEFFLOAT, 0);
    class_addmethod(midifile_class, (t_method)midifile_rewind, gensym("rewind"), 0);
    class_addmethod(midifile_class, (t_method)midifile_verbosity, gensym("verbose"), A_DEFFLOAT, 0);
    class_sethelpsymbol(midifile_class, gensym("midifile-help"));
#if PD_MAJOR_VERSION==0 && PD_MINOR_VERSION<43
    post(aStr);
#else
    logpost(NULL, 3, aStr);
#endif
}

/** midifile_new is called from Pd when a new [midifile] is being instantiated.
*
- Initializes the state of this [midifile].
- An optional argument is a file name that will be opened here.
- Adds outlets for midi_list, total_time, and status.
*/
static void *midifile_new(t_symbol *s, int argc, t_atom *argv)
{
    t_midifile  *x = (t_midifile *)pd_new(midifile_class);
    t_symbol    *pathSymbol;
    int         i;

    if (x == NULL)
    {
        error("midifile: Could not create...");
        return x;
    }
    x->fP = NULL;
    x->fPath[0] = '\0';
    x->our_directory = canvas_getcurrentdir();/* get the current directory to use as the base for relative file paths */
//#if PD_MAJOR_VERSION==0 && PD_MINOR_VERSION<43
//    post(x->our_directory->s_name);
//#else
//    logpost(NULL, 3, x->our_directory->s_name);
//#endif
    x->track = ALL_TRACKS; /* startup playing anything */
    x->midi_data[0].a_type = x->midi_data[1].a_type = x->midi_data[2].a_type = A_FLOAT;
    x->state = mfReset;
    x->verbosity = 1; /* default to posting all */

    x->midi_list_outlet = outlet_new(&x->x_obj, &s_list);
    x->total_time_outlet = outlet_new(&x->x_obj, &s_float); /* current total_time */
    x->status_outlet = outlet_new(&x->x_obj, &s_anything);/* last outlet for everything else */

    for (i = 0; i < MAX_TRACKS; ++i)
    {
        x->track_chunk[i].track_data = NULL;
    }
    /* find the first string in the arg list and interpret it as a path to a midi file */
    for (i = 0; i < argc; ++i)
    {
        if (argv[i].a_type == A_SYMBOL)
        {
            pathSymbol = atom_getsymbol(&argv[i]);
            if (pathSymbol != NULL)
            {
                if (midifile_open_path(x, pathSymbol->s_name, "rb"))
                {
                    if (x->verbosity) post("midifile: opened %s", x->fPath);
                    x->state = mfReading;
                    if (midifile_read_chunks(x) == 0) midifile_free_file(x);
                }
                else error("midifile: unable to open %s", pathSymbol->s_name);
                break;
            }
        }
    }

    return (void *)x;
}

/** midifile_close closes the file and its associated temp files.
- calls sys_fclose and sets x->fP and all x->tmpFp[]s to NULL
- clears x->fPath[0]
- sets x->state to mfReset
- resets x->totalTime and x->offset
- outputs new totalTime from x->total_time_outlet
*/
static void midifile_close(t_midifile *x)
{
    int i;
    if (x->fP != NULL)
    {
        sys_fclose (x->fP);
        x->fP = NULL;
    }
    for (i = 0; i < MAX_TRACKS; ++i)
    {
        if (x->tmpFP[i] != NULL)
        {
          sys_fclose(x->tmpFP[i]);
          x->tmpFP[i] = NULL;
        }
    }
    x->fPath[0] = '\0';
    x->state = mfReset;
    x->total_time = 0L;
    x->offset = 0L;
    outlet_float(x->total_time_outlet, x->total_time);
}

/** midifile_free_file closes the file and its associated tracks.
- calls midifile_close() and frees all track data
*/
static void midifile_free_file(t_midifile *x)
{
    int i;

    midifile_close(x);

    for (i = 0; i < MAX_TRACKS; ++i)
    {
        if (x->track_chunk[i].track_data != NULL)
            freebytes(x->track_chunk[i].track_data, x->track_chunk[i].chunk_length);
        x->track_chunk[i].track_data = NULL;
    }
}

/** midifile_free closes all files and frees all allocated memory.
- calls midifile_free_file().
*/
static void midifile_free(t_midifile *x)
{
    midifile_free_file(x);
}

/** midifile_open_path attempts to open a file.
- path is a string.
- Up to PATH_BUF_SIZE-1 characters will be copied into x->fPath.
- mode should be "rb" or "wb".
- x->fPath will be used as a file name to open.
- Returns 1 if successful, else 0.
*/
static int midifile_open_path(t_midifile *x, char *path, char *mode)
{
    FILE    *fP = NULL;
    char    tryPath[PATH_BUF_SIZE];
    char    slash[] = "/";

    /* If the first character of the path is a slash then the path is absolute */
    /* On MSW if the second character of the path is a colon then the path is absolute */
    if ((path[0] == '/') || (path[0] == '\\') || (path[1] == ':'))
    {
        strncpy(tryPath, path, PATH_BUF_SIZE-1); /* copy path into a length-limited buffer */
        /* ...if it doesn't work we won't mess up x->fPath */
        tryPath[PATH_BUF_SIZE-1] = '\0'; /* just make sure there is a null termination */
        if (x->verbosity > 1)post("midifile_open_path (absolute): %s\n", tryPath);
        fP = sys_fopen(tryPath, mode);
    }
    if (fP == NULL)
    {
        /* Then try to open the path from the current directory */
        strncpy(tryPath, x->our_directory->s_name, PATH_BUF_SIZE-1); /* copy path into a length-limited buffer */
        strncat(tryPath, slash, PATH_BUF_SIZE-1); /* copy path into a length-limited buffer */
        strncat(tryPath, path, PATH_BUF_SIZE-1); /* copy path into a length-limited buffer */
        /* ...if it doesn't work we won't mess up x->fPath */
        tryPath[PATH_BUF_SIZE-1] = '\0'; /* just make sure there is a null termination */
        if (x->verbosity > 1)post("midifile_open_path (relative): %s\n", tryPath);
        fP = sys_fopen(tryPath, mode);
    }
    if (fP == NULL) return 0;
    x->fP = fP;
    strncpy(x->fPath, tryPath, PATH_BUF_SIZE);
    return 1;
}

/** midifile_flush writes the header to x->fP, copies the contents of x->tmpFP[] into it, and closes both files.
- flush ends the track.
- returns immediately unless x->state is mfWriting.
- sends a bang to status_outlet so tick count can be captured.
- calls midifile_write_header()
- calls midifile_write_end_of_track() for each active track.
- calls midifile_close().
*/
static void midifile_flush(t_midifile *x)
{
    size_t  written = 0L;
    size_t  end_time = x->total_time;
    size_t  len;
    int     c, i, k, nTracks = 0;

    if(x->state != mfWriting) return; /* only if we're writing */

    outlet_bang(x->status_outlet); /* bang so tick count can be saved externally */
    /* First count the active tracks*/
    for (i = 0; i < MAX_TRACKS; ++i) if (x->tmpFP[i] != NULL) ++nTracks;
    /* Next write the header for the entire file */
    written += midifile_write_header(x, nTracks);
    for (i = 0; i < MAX_TRACKS; ++i)
    {
        if (x->tmpFP[i] != NULL) {
            ++nTracks;
            written += midifile_write_end_of_track(x, end_time, i);
            /* now copy the MIDI data from tmpFP[i] to fP */
            rewind (x->tmpFP[i]);
            /* write track chunk header followed by the track data */
            fprintf (x->fP, "MTrk");
            len = x->track_chunk[i].chunk_length; /* length of MIDI data */
            for (k = 0; k < 4; ++k)
            { /* msb first */
                c = (char)((len & 0xFF000000)>>24);
                putc(c, x->fP);
                len <<= 8;
            }
            while ((c = getc(x->tmpFP[i])) != EOF)
            {
                putc(c, x->fP);
                ++written;
            }
        }
    }
    if (x->verbosity) post ("midifile: wrote %lu to %s", written, x->fPath);
    midifile_close(x);
}

/** midifile_write_header writes the MThd and MTrk headers to x->fP.
- returns the number of bytes written to x->fP.
*/
static size_t midifile_write_header(t_midifile *x, int nTracks)
{
    size_t  j, written = 0L;
    int     i;
    char    c;

    rewind (x->fP);
    fprintf (x->fP, "MThd");
    j = 6; /* length of header data */
    for (i = 0; i < 4; ++i)
    { /* msb first */
        c = (char)((j & 0xFF000000)>>24);
        putc(c, x->fP);
        j <<= 8;
    }
    j = (nTracks > 1)?1:0; /* type of file */
    /* msb first */
    c = (char)((j & 0xFF00)>>8);
    putc(c, x->fP);
    c = (char)(j & 0x0FF);
    putc(c, x->fP);
    j = nTracks; /* number of tracks */
    /* msb first */
    c = (char)((j & 0xFF00)>>8);
    putc(c, x->fP);
    c = (char)(j & 0x0FF);
    putc(c, x->fP);
    j = x->header_chunk.chunk_division; /* ticks per quarter note */
    /* msb first */
    c = (char)((j & 0xFF00)>>8);
    putc(c, x->fP);
    c = (char)(j & 0x0FF);
    putc(c, x->fP);
//    fprintf (x->fP, "MTrk"); // TODO this is in the wrong place
//    j = x->track_chunk[0].chunk_length; /* length of MIDI data */
//    for (i = 0; i < 4; ++i)
//    { /* msb first */
//        c = (char)((j & 0xFF000000)>>24);
//        putc(c, x->fP);
//        j <<= 8;
//    }
    written = 18L;//22L;
    return written;
}

/** midifile_write implements the write message.
*
- opens the file for writing and writes the header.
- first element of list must be a pathname symbol
- optional second argument: ticks_per_frame or frames_per_second
- optional third argument: ticks_per_frame

- calls midifile_free_file() to clear any previous file data
- calls midifile_open_path()
- calls midifile_rewind_tracks()
*/
static void midifile_write(t_midifile *x, t_symbol *s, int argc, t_atom *argv)
{
    char        *path = NULL;
    int         frames_per_second = 0;/* default */
    int         ticks_per_frame = 90; /* default*/

    if ((argc >= 1) && (argv[0].a_type == A_SYMBOL)) path = argv[0].a_w.w_symbol->s_name;
    else pd_error(x, "midifile_write: No valid path name");
    if (argc == 2)
    {
        if (argv[1].a_type == A_FLOAT) ticks_per_frame = (int)argv[1].a_w.w_float;
        else pd_error (x, "midifile_write: second argument is not a float");
    }
    else if (argc >= 3) /* ignore extra arguments */
    {
        if (argv[2].a_type == A_FLOAT) ticks_per_frame = (int)argv[2].a_w.w_float;
        else pd_error (x, "midifile_write: third argument is not a float");
        if (argv[1].a_type == A_FLOAT) frames_per_second = (int)argv[1].a_w.w_float;
        else pd_error (x, "midifile_write: second argument is not a float");
    }
    post("midifile_write: path = %s, fps = %d, tpf = %d", path, frames_per_second, ticks_per_frame);
    midifile_free_file(x);
    if (midifile_open_path(x, path, "wb"))
    {
        if (x->verbosity) post("midifile: opened %s", x->fPath);
        x->state = mfWriting;
        x->track = 0; /* write to first track */
        x->tmpFP[0] = tmpfile (); /* a temporary file for the MIDI data while we don't know how long it is */
        strncpy (x->header_chunk.chunk_type, "MThd", 4L);/* track header chunk */
        x->header_chunk.chunk_length = 6L; /* 3 ints to follow */
        x->header_chunk.chunk_format = 0; /* single-track file so far */
        x->header_chunk.chunk_ntrks = 1; /* one track for type 0 file */
        x->header_chunk.chunk_division = (((-frames_per_second)<<8)|ticks_per_frame);
        strncpy (x->track_chunk[0].chunk_type, "MTrk", 4L);
        x->track_chunk[0].chunk_length = 0L; /* for now */
        midifile_rewind_tracks(x);
    }
    else pd_error(x, "midifile_write: Unable to open %s", path);
}

/** midifile_read attempts to open a MIDI file at path.
*
- calls midifile_open_path()
- calls midifile_read_chunks()
*/
static void midifile_read(t_midifile *x, t_symbol *path)
{
    midifile_free_file(x);
    if (midifile_open_path(x, path->s_name, "rb"))
    {
        if (x->verbosity) post("midifile: opened %s", x->fPath);
        x->state = mfReading;
        if (midifile_read_chunks(x) == 0) midifile_free_file(x); //
    }
    else error("midifile: Unable to open %s", path->s_name);
}

/** midifile_bang steps forward one tick and processes all tracks for that tick.
*
- calls midifile_get_next_track_chunk_delta_time()
- calls midifile_get_next_track_chunk_data()
- calls midifile_skip_next_track_chunk_data()
*/
static void midifile_bang(t_midifile *x)
{
    int     j, result = 1, ended = 0;
    size_t  total_time;

    switch (x->state)
    {
        case mfReading:
            if (x->verbosity > 2) post("midifile_bang: total_time %lu", x->total_time);
            for (j = 0; ((j < x->header_chunk.chunk_ntrks)&&(result != 0)); ++j)
            {
                if (x->track_chunk[j].total_time != NO_MORE_ELEMENTS)
                {
                    while
                    (
                        (
                            total_time = midifile_get_next_track_chunk_delta_time(x, j)
                                + x->track_chunk[j].total_time
                        )
                        == x->total_time
                    )
                    {
                        if ((x->track == j) ||(x->track == ALL_TRACKS)) midifile_get_next_track_chunk_data(x, j);
                        else midifile_skip_next_track_chunk_data(x, j);
                    }
                    x->ended = 0;
                }
                if (x->track_chunk[j].delta_time == NO_MORE_ELEMENTS) ++ended;
            }
            if ((ended == x->header_chunk.chunk_ntrks)&&(x->ended == 0))
            { /* set ended flag, only bang once */
                if (x->verbosity > 1)
                    post ("ended = %d x->header_chunk.chunk_ntrks = %d", ended, x->header_chunk.chunk_ntrks);
                outlet_bang(x->status_outlet);
                ++x->ended;
            }
            /* fall through into mfWriting */
        case mfWriting:
            ++x->total_time;
            outlet_float(x->total_time_outlet, x->total_time);
            break;
        default:
            break;/* don't change time when no files are open */
    }
}

/* The arguments of the ``list''-method
* a pointer to the class-dataspace
* a pointer to the selector-symbol (always &s_list)
* the number of atoms and a pointer to the list of atoms:
*/

/** midifile_list adds a list containing time and midi packet to the temporary file in MIDI file format.
*
- current track is used to select the temp file.
*
- calls midifile_write_variable_length_value()
*/
static void midifile_list(t_midifile *x, t_symbol *s, int argc, t_atom *argv)
{
    int         i, j, k, m = 0, dt_written = 0;
    size_t      len, written = 0L;
    static int  warnings = 0;

    if (x->state != mfWriting) return;/* list only works for writing */
    if (x->tmpFP[x->track] == NULL)
    {
        if (0 == warnings++) error ("midifile: no file is open for writing");
        return;
    }
    for (i = 0; i < argc; ++i)
    {
        if (A_FLOAT == argv[i].a_type)
        {
            j = atom_getint(&argv[i]);
            if (x->verbosity > 2) post ("midifile_list. j[%d]	= 0x%lX", i, j);
            if (j < 0x100)
            {
                if (!dt_written)
                { /* deltatime */
                    x->track_chunk[x->track].delta_time = x->total_time - x->track_chunk[x->track].total_time;
                    x->track_chunk[x->track].total_time = x->total_time;
                    written = midifile_write_variable_length_value(x->tmpFP[x->track], x->track_chunk[x->track].delta_time);
                    dt_written = 1;
                }
                //if (j == x->track_chunk[0].running_status) continue;/* don't save redundant status byte */
                if (j >= 0x80 && j <= 0xEF)x->track_chunk[x->track].running_status = j;/* new running status */
                else if (j >= 0xF0 && j <= 0xF7)
                {
                    x->track_chunk[x->track].running_status = 0;/* clear running status */
                    if (j == 0xF0)
                    { /* system exclusive: */
                        /* find length */
                        for (k = i+1, len = 0L; k < argc; ++k, ++len)
                        {
                            if (argv[k].a_type != A_FLOAT)
                            {
                                error ("midifile: sysex list must be all floats");
                                x->track_chunk[x->track].chunk_length += written;
                                return;
                            }
                            m = atom_getint(&argv[k]);
                            if (m & 0x80) break;/* take any non-data as end of exclusive */
                        }
                        if (m != 0xF7)
                        {
                            error ("midifile: sysex list terminator is 0x%X", m);
                            x->track_chunk[x->track].chunk_length += written;
                            return;
                        }
                        ++len;
                        if (x->verbosity) post ("midifile: sysex length %lu. j = 0x%X", len, j);
                        putc (j, x->tmpFP[x->track]);
                        ++written;
                        /* write length as variable length */
                        written += midifile_write_variable_length_value (x->tmpFP[x->track], len);
                        /* write the rest of the sysex message */
                        for (k = i+1; j != 0xF7; ++k)
                        {
                            j = atom_getint(&argv[k]);
                            putc (j, x->tmpFP[x->track]);
                            ++written;
                        }
                        x->track_chunk[x->track].chunk_length += written;
                        return;
                    }
                }
                if (x->verbosity > 1) post ("midifile: j = 0x%X", j);
                putc (j, x->tmpFP[x->track]);
                ++written;
            }
        }
    }
    x->track_chunk[x->track].chunk_length += written;
}

/** midifile_write_end_of_track writes an End of Track event to x->tmpFP[x->track].
- calls midifile_write_variable_length_value()
- adds number of bytes written to x->track_chunk[trackNr].chunk_length.
- returns number of bytes written.
*/
static size_t midifile_write_end_of_track(t_midifile *x, size_t end_time, int trackNr)
{
    size_t written = 0;

    x->track_chunk[trackNr].delta_time = end_time - x->track_chunk[trackNr].total_time;
    x->track_chunk[trackNr].total_time = x->total_time;
    written = midifile_write_variable_length_value (x->tmpFP[trackNr], x->track_chunk[trackNr].delta_time);
    putc (0xFF, x->tmpFP[trackNr]);
    putc (0x2F, x->tmpFP[trackNr]);
    putc (0x00, x->tmpFP[trackNr]);
    written += 3L;
    x->track_chunk[trackNr].chunk_length += written;
    return written;
}

/** midifile_float: Go to a total time of ticks.
*
if state is mfReading
- calls midifile_rewind_tracks()
- calls midifile_get_next_track_chunk_delta_time
- calls midifile_skip_next_track_chunk_data()

if state is mfWriting
- sets total_time to ticks

If mfReading or mfWriting, outputs new total_time
*/
static void midifile_float(t_midifile *x, t_float ticks)
{
    long  cTime = (long) ticks;
    size_t  total_time;
    int     j, ended = 0;

    if (cTime < 0) return;

    switch (x->state)
    {
        case mfReading: /* cue to ticks */
            midifile_rewind_tracks(x);
            for (j = 0; j < x->header_chunk.chunk_ntrks; ++j)
            {
                if (x->track_chunk[j].total_time != NO_MORE_ELEMENTS)
                {
                    while
                    (
                        (
                            total_time = midifile_get_next_track_chunk_delta_time(x, j)
                                + x->track_chunk[j].total_time
                        )
                        < cTime
                    )
                        midifile_skip_next_track_chunk_data(x, j);
                }
                if (x->track_chunk[j].delta_time == NO_MORE_ELEMENTS) ++ended;
            }
            x->total_time = cTime;
            outlet_float(x->total_time_outlet, x->total_time);
            if (ended == x->header_chunk.chunk_ntrks)
            {
                if (x->verbosity)
                    post ("midifile: ended = %d x->header_chunk.chunk_ntrks = %d", ended, x->header_chunk.chunk_ntrks);
                outlet_bang(x->status_outlet);
            }
            break;
        case mfWriting: /* add ticks to current time */
            x->total_time += cTime;
            outlet_float(x->total_time_outlet, x->total_time);
            break;
        case mfReset: /* do nothing */
            break;
    }
}

/** midifile_read_chunks reads in the MIDI file chunks.
*
- calls midifile_read_header_chunk() and then
- calls midifile_read_track_chunk() for each track
*/
static int midifile_read_chunks(t_midifile *x)
{
    int     j, result;

    result = midifile_read_header_chunk(x);
    midifile_rewind_tracks(x);
    for (j = 0; ((j < x->header_chunk.chunk_ntrks)&&(result != 0)); ++j)
        midifile_read_track_chunk(x, j);
    return result;
}

/** midifile_read_header_chunk reads the header chunk from an open MIDI file into x->header_chunk.
*
- calls midifile_get_multibyte_2()
- calls midifile_get_multibyte_4()
- outputs various file info on the status outlet
- Returns 1 on success, else 0
*/
static int midifile_read_header_chunk(t_midifile *x)
{
    unsigned char   *cP = (unsigned char *)x->header_chunk.chunk_type;
    char            *sP;
    char            buf[4];
    size_t          n;
    int             div, smpte, ticks;
    t_atom          output_atom;

    if (x->fP == NULL)
    {
        error("midifile: no open file");
        return 0;/* no open file */
    }
    rewind(x->fP);
    x->offset = 0L;
    n = fread(cP, 1L, 4L, x->fP);
    x->offset += n;
    if (n != 4L)
    {
        error("midifile: read %zu instead of 4", n);
        return 0;
    }
    if (x->verbosity) post("midifile: Header chunk type: %c%c%c%c", cP[0], cP[1], cP[2], cP[3]);
    if (!(cP[0] == 'M' && cP[1] == 'T' && cP[2] == 'h' && cP[3] == 'd'))
    {
        error ("midifile: bad file format: bad header chunk type");
        return 0;
    }
    cP = (unsigned char *)buf;
    n = fread(cP, 1L, 4L, x->fP);
    x->offset += n;
    if (n != 4L)
    {
        error("midifile: read %zu instead of 4", n);
        return 0;
    }
    x->header_chunk.chunk_length = midifile_get_multibyte_4(cP);
    if (x->verbosity) post("midifile: Header chunk length: %lu", x->header_chunk.chunk_length);
    if (x->header_chunk.chunk_length != 6L)
    {
        error ("midifile: bad file format: bad header chunk length");
        return 0;
    }
    n = fread(cP, 1L, 2L, x->fP);
    x->offset += n;
    if (n != 2L)
    {
        error("midifile: read %zu instead of 2", n);
        return 0;
    }
    x->header_chunk.chunk_format = midifile_get_multibyte_2(cP);
    switch (x->header_chunk.chunk_format)
    {
        case 0:
            sP = "Single multichannel track";
            break;
        case 1:
            sP = "One or more simultaneous tracks";
            break;
        case 2:
            sP = "One or more sequentially independent single tracks";
            break;
        default:
            sP = "Unknown format";
    }
    if (x->verbosity) post("midifile: Header chunk format: %d (%s)", x->header_chunk.chunk_format, sP);
    SETFLOAT(&output_atom, x->header_chunk.chunk_format);
    outlet_anything( x->status_outlet, gensym("format"), 1, &output_atom);

    n = fread(cP, 1L, 2L, x->fP);
    x->offset += n;
    if (n != 2L)
    {
        error("midifile: read %zu instead of 2", n);
        return 0;
    }
    x->header_chunk.chunk_ntrks = midifile_get_multibyte_2(cP);
    if (x->verbosity) post("midifile: Header chunk ntrks: %d", x->header_chunk.chunk_ntrks);
    SETFLOAT(&output_atom, x->header_chunk.chunk_ntrks);
    outlet_anything( x->status_outlet, gensym("tracks"), 1, &output_atom);
    if (x->header_chunk.chunk_ntrks > MAX_TRACKS)
    {
        error ("midifile: Header chunk ntrks (%d) exceeds midifile MAX_TRACKS, set to %d",
            x->header_chunk.chunk_ntrks, MAX_TRACKS);
        x->header_chunk.chunk_ntrks = MAX_TRACKS;
    }
    n = fread(cP, 1L, 2L, x->fP);
    x->offset += n;
    if (n != 2L)
    {
        error("midifile: read %zu instead of 2", n);
        return 0;
    }
    x->header_chunk.chunk_division = midifile_get_multibyte_2(cP);
    div = x->header_chunk.chunk_division;
    if(div & 0x8000)
    {
        smpte = (-(div>>8)) & 0x0FF;
        ticks = div & 0x0FF;
        if (x->verbosity)
            post("midifile: Header chunk division: 0x%X: %d frames per second, %d ticks per frame", div, smpte, ticks);
        SETFLOAT(&output_atom, smpte);
        outlet_anything( x->status_outlet, gensym("frames_per_sec"), 1, &output_atom);
        SETFLOAT(&output_atom, ticks);
        outlet_anything( x->status_outlet, gensym("ticks_per_frame"), 1, &output_atom);
    }
    else
    {
        if (x->verbosity)
            post("midifile: Header chunk division: 0x%X: %d ticks per quarter note", div, div);
        SETFLOAT(&output_atom, div);
        outlet_anything( x->status_outlet, gensym("ticks_per_quarternote"), 1, &output_atom);
    }
    return 1;
}

/** midifile_read_track_chunk reads the data part of a track chunk into x->track_chunk[mfindex].track_data
* after allocating the space for it.
*
- calls midifile_get_multibyte_4()
- returns 1 on success, else 0
*/
static int midifile_read_track_chunk(t_midifile *x, int mfindex)
{
    unsigned char   *cP = (unsigned char *)x->track_chunk[mfindex].chunk_type;
    char            buf[4];
    char            type[5];
    size_t          n, len;

    if (x->fP == NULL)
    {
        error("midifile: no open file");
        return 0;/* no open file */
    }
    n = fread(cP, 1L, 4L, x->fP);
    x->offset += n;
    if (n != 4L)
    {
        error("midifile: read %zu instead of 4", n);
        return 0;
    }
    if (!(cP[0] == 'M' && cP[1] == 'T' && cP[2] == 'r' && cP[3] == 'k'))
    {
        error ("midifile: bad file format: bad track chunk type");
        return 0;
    }
    type[0] = cP[0];
    type[1] = cP[1];
    type[2] = cP[2];
    type[3] = cP[3];
    type[4] = '\0';
    cP = (unsigned char *)buf;
    n = fread(cP, 1L, 4L, x->fP);
    x->offset += n;
    if (n != 4L)
    {
        error("midifile: read %zu instead of 4", n);
        return 0;
    }
    len = midifile_get_multibyte_4(cP);
    x->track_chunk[mfindex].chunk_length = len;
    if (x->verbosity) post("midifile: Track chunk %d type: %s, length %zu", mfindex, type, len);
    if ((cP = getbytes(len)) == NULL)
    {
        error ("midifile: Unable to allocate %zu bytes for track data", len);
        return 0;
    }
    x->track_chunk[mfindex].track_data = (unsigned char*)cP;
    n = fread(cP, 1L, len, x->fP);

    return 1;
}

static unsigned short midifile_combine_bytes(unsigned char data1, unsigned char data2)
/** make a short from two 7bit MIDI data bytes
*/
{
/*
    unsigned short value = (unsigned short)data2;
    value <<= 7;
    value |= (unsigned short)data1;
    return value;
*/
    return ((((unsigned short)data2)<< 7) | ((unsigned short)data1));
}

static unsigned long midifile_get_multibyte_4(unsigned char*n)
/** make a long from 4 consecutive bytes in big-endian format
*/
{
    unsigned long a, b, c, d, e;
    a = (*(unsigned long *)(&n[0])) & 0x0FF;
    b = (*(unsigned long *)(&n[1])) & 0x0FF;
    c = (*(unsigned long *)(&n[2])) & 0x0FF;
    d = (*(unsigned long *)(&n[3])) &0x0FF;
    e = (a<<24) + (b<<16) + (c<<8) + d;
    return e;
}

static unsigned long midifile_get_multibyte_3(unsigned char*n)
/** make a long from 3 consecutive bytes in big-endian format
*/
{
    unsigned long   a, b, c, d;
    a = (*(unsigned long *)(&n[0])) & 0x0FF;
    b = (*(unsigned long *)(&n[1])) & 0x0FF;
    c = (*(unsigned long *)(&n[2])) & 0x0FF;
    d = (a<<16) + (b<<8) + c;
    return d;
}

static unsigned short midifile_get_multibyte_2(unsigned char*n)
/** make a short from 2 consecutive bytes in big-endian format
*/
{
    unsigned short  a, b, c;
    a = (*(unsigned long *)(&n[0])) & 0x0FF;
    b = (*(unsigned long *)(&n[1])) & 0x0FF;
    c = (a<<8) + b;
    return c;
}


/** midifile_write_variable_length_value writes an integer to the file in variable-length format
- returns number of characters written to fP
*/
static int midifile_write_variable_length_value (FILE *fP, size_t value)
{
    size_t  buffer;
    int     i;
    char    c;

    buffer = value & 0x07F;
    while ((value >>= 7) > 0)
    {
        buffer <<= 8;
        buffer |= 0x80;
        buffer += (value & 0x07F);
    }
    i = 0;
    while (1)
    {
        c = (char)(buffer & (0x0FF));
        putc(c, fP);
        ++i;
        if (buffer & 0x80) buffer >>= 8;
        else break;
    }
    return i;
}

/** midifile_read_var_len reads a variable-length value from cP into delta.
- enter with cP pointing to deltatime.
- sets delta to deltatime.
- returns pointer to following data.
*/
static unsigned char *midifile_read_var_len (unsigned char *cP, size_t *delta)
{
    unsigned long   value;
    char            c;

    if (((value = *(cP++))) & 0x80)
    {
        value &= 0x7f;
        do
        {
            value = (value << 7) + ((c = *(cP++)) & 0x7f);
        } while (c & 0x80);
    }
    *delta = value;
    return cP;
}


/** midifile_verbosity sets the verbosity level of console output.
- verbosity can be 0 to 3
- default is 1
*/
static void midifile_verbosity(t_midifile *x, t_floatarg verbosity)
{
    x->verbosity = (int)verbosity;
    post ("midifile verbosity is %d", x->verbosity);
}

/** midifile_set_track implements the track message.
*
- sets x->track.
*
- When reading, play only this track or all tracks if out of range.
- When writing, select the track to write to and open a temp file for it unless one is already open.
*/
static void midifile_set_track(t_midifile *x, t_floatarg track)
{
    if(x->state == mfReading)
    {
      /* only if we're reading */
      /* anything out of range will be interpreted as all tracks */
      if ((track < 0) || (track >= x->header_chunk.chunk_ntrks))
        x->track = ALL_TRACKS;
      else x->track = track;
    }
    else if(x->state == mfWriting)
    {
      /* only if we're writing */
      /* anything out of range will be rejected */
      if ((track < 0) || (track >= MAX_TRACKS))
      {
        post ("midifile track not between 0 and %d; using %d.", MAX_TRACKS, x->track);
        return;
      }
      else
      {
        x->track = track; // possibly update x->header_chunk.chunk_ntrks
        if (x->track_chunk[x->track].track_data == NULL)
        {
            /* this track is being used for the first time */
            x->tmpFP[x->track] = tmpfile (); /* a temporary file for the MIDI data while we don't know how long it is */
            strncpy (x->track_chunk[x->track].chunk_type, "MTrk", 4L);
            x->track_chunk[x->track].chunk_length = 0L; /* for now */
        }
      }
    }
}

/** midifile_dump implements the dump message.
*
- dumps track to console
- if track is out of range, dumps all tracks.
- calls midifile_dump_track_chunk_data()

*/
static void midifile_dump(t_midifile *x, t_floatarg track)
{
    int mfindex = (int)track;

    if(x->state != mfReading) return; /* only if we're reading */
    if ((mfindex < x->header_chunk.chunk_ntrks) && (mfindex >= 0))
        midifile_dump_track_chunk_data(x, mfindex);
    else /* anything out of range will be interpreted as all tracks */
        for (mfindex = 0; mfindex < x->header_chunk.chunk_ntrks; ++mfindex)
            midifile_dump_track_chunk_data(x, mfindex);
}

/** midifile_rewind implements the rewind message.
*
- calls midifile_rewind_tracks()
*/
static void midifile_rewind (t_midifile *x)
{
    if(x->state != mfReading) return; /* only if we're reading */
    midifile_rewind_tracks(x);
}

/** For all tracks, point to start of track_data
*/
static void midifile_rewind_tracks(t_midifile *x)
{
    int i;
    for (i = 0; i < MAX_TRACKS; ++i)
    {
        x->track_chunk[i].delta_time = 0L;
        x->track_chunk[i].track_index = 0L;
        x->track_chunk[i].total_time = 0L;
        x->track_chunk[i].running_status = 0;
    }
    x->total_time = 0L;
    x->ended = 0L;
    outlet_float(x->total_time_outlet, x->total_time);
}

static size_t midifile_get_next_track_chunk_delta_time(t_midifile *x, int mfindex)
/** return the delta_time of the next event in track[mfindex]
*/
{
    unsigned char   *cP, *last_cP;
    size_t          delta_time;

    cP = x->track_chunk[mfindex].track_data + x->track_chunk[mfindex].track_index;
    last_cP = x->track_chunk[mfindex].track_data + x->track_chunk[mfindex].chunk_length;

    delta_time = NO_MORE_ELEMENTS;
    if ((cP != NULL) && (cP < last_cP) && (x->track_chunk[mfindex].delta_time != NO_MORE_ELEMENTS))
        cP = midifile_read_var_len(cP, &delta_time);
    return delta_time;
}

/** output a long MIDI message as a list of floats
* first_byte is followed by len bytes at cP
*/
static void midifile_output_long_list (t_outlet *outlet, unsigned char *cP, size_t len, unsigned char first_byte)
{
    size_t          slen;
    unsigned int    si;
    t_atom          *slist;

    slen = (len+1L)*sizeof(t_atom);
    slist = getbytes (slen);
    if (slist == NULL)
    {
        error ("midifile: no memory for long list");
        return;
    }
    slist[0].a_type = A_FLOAT;
    slist[0].a_w.w_float = first_byte;//0xF0;
    for (si = 0; si < len; ++si)
    {
        slist[si+1].a_type = A_FLOAT;
        slist[si+1].a_w.w_float = cP[si];
    }
    outlet_list(outlet, &s_list, len+1L, slist);
    freebytes(slist, slen);
}

/** parse entire track chunk and output it to the main window
*/
static void midifile_dump_track_chunk_data(t_midifile *x, int mfindex)
{
    unsigned char   *cP, *last_cP, *str;
    size_t          total_time, delta_time, len;
    unsigned long   time_sig;
    unsigned char   status, running_status = 0, c, d, nn, dd, cc, bb, mi, mcp, ch;
    char            sf;
    unsigned short  sn;
    unsigned char   tt[3];
    char            *msgPtr;
    char            msg[256];

    cP = x->track_chunk[mfindex].track_data;
    last_cP = x->track_chunk[mfindex].track_data + x->track_chunk[mfindex].chunk_length;
    total_time = 0L;

    post("midifile: Parsing track[%d]...", mfindex);
    while ((cP != NULL) && (cP < last_cP) && (x->track_chunk[mfindex].delta_time != NO_MORE_ELEMENTS))
    {
        msgPtr = msg;
        cP = midifile_read_var_len(cP, &delta_time);
        status = *cP++;
        total_time += delta_time;
        msgPtr += sprintf (msgPtr, "tick %zu delta %zu status %02X ", total_time, delta_time, status);
        if ((status & 0xF0) == 0xF0)
        {
            switch (status)
            {
                case 0xF0:
                case 0xF7:
                    cP = midifile_read_var_len(cP, &len);/* not a time but the same variable length format */
                    msgPtr += sprintf(msgPtr, "Sysex: %02X length %zu ", status, len);
                    cP += len;
                    break;
                case 0xF3: /* song select */
                    c = *cP++;
                    msgPtr += sprintf(msgPtr, "Song Select: %d ", c);
                    break;
                case 0xF2: /* song position */
                    c = *cP++;
                    d = *cP++;
                    msgPtr += sprintf(msgPtr, "Song Position %d ", midifile_combine_bytes(c, d));
                    break;
                case 0xF1: /* quarter frame */
                    msgPtr += sprintf(msgPtr, "MIDI Quarter Frame");
                    break;
                case 0xF6: /* tune request */
                    msgPtr += sprintf(msgPtr, "MIDI Tune Request");
                    break;
                case 0xF8: /* MIDI clock */
                    msgPtr += sprintf(msgPtr, "MIDI Clock");
                    break;
                case 0xF9: /* MIDI tick */
                    msgPtr += sprintf(msgPtr, "MIDI Tick");
                    break;
                case 0xFA: /* MIDI start */
                    msgPtr += sprintf(msgPtr, "MIDI Start");
                    break;
                case 0xFB: /* MIDI continue */
                    msgPtr += sprintf(msgPtr, "MIDI Continue");
                    break;
                case 0xFC: /* MIDI stop */
                    msgPtr += sprintf(msgPtr, "MIDI Stop");
                    break;
                case 0xFE: /* active sense */
                    msgPtr += sprintf(msgPtr, "MIDI Active Sense");
                    break;
                case 0xFF:
                    c = *cP++;
                    cP = midifile_read_var_len(cP, &len);/* not a time but the same variable length format */
                    msgPtr += sprintf(msgPtr, "Meta 0x%02X length %zu \n", c, len);
                    switch (c)
                    {
                        case 0x58:
                            nn = *cP++;
                            dd = *cP++;
                            dd = 1<<(dd);
                            cc = *cP++;
                            bb = *cP++;
                            msgPtr += sprintf(
                                msgPtr, "Time Signature %d/%d %d clocks per tick, %d 32nd notes per quarter note",
                                nn, dd, cc, bb);
                            break;
                        case 0x59:
                            sf = *(signed char*)cP++;
                            mi = *cP++;
                            msgPtr += sprintf(
                                msgPtr, "Key Signature: %d %s, %s",
                                sf, (sf<0)?"flats":"sharps", (mi)?"minor":"major");
                            break;
                        case 0x51:
                            tt[0] = *cP++;
                            tt[1] = *cP++;
                            tt[2] = *cP++;
                            time_sig = midifile_get_multibyte_3(tt);
                            msgPtr += sprintf(msgPtr, "%lu microseconds per MIDI quarter-note", time_sig);
                            break;
                        case 0x2F:
                            msgPtr += sprintf(msgPtr, "========End of Track %d==========", mfindex);
                            cP += len;
                            break;
                        case 0x21:
                            tt[0] = *cP++;
                            msgPtr += sprintf(msgPtr, "MIDI port or cable number (unofficial): %d", tt[0]);
                            break;
                        case 0x20:
                            mcp = *cP++;
                            msgPtr += sprintf(msgPtr, "MIDI Channel Prefix: %d", mcp);
                            break;
                        case 0x06:
                            str = cP;
                            c = cP[len];
                            cP[len] = '\0'; /* null terminate temporarily */
                            msgPtr += sprintf(msgPtr, "Marker %s", str);
                            cP[len] = c;
                            cP += len;
                            break;
                        case 0x05:
                            str = cP;
                            c = cP[len];
                            cP[len] = '\0'; /* null terminate temporarily */
                            msgPtr += sprintf(msgPtr, "Lyric %s", str);
                            cP[len] = c;
                            cP += len;
                            break;
                        case 0x04:
                            str = cP;
                            c = cP[len];
                            cP[len] = '\0'; /* null terminate temporarily */
                            msgPtr += sprintf(msgPtr, "Instrument Name %s", str);
                            cP[len] = c;
                            cP += len;
                            break;
                        case 0x03:
                            str = cP;
                            c = cP[len];
                            cP[len] = '\0'; /* null terminate temporarily */
                            msgPtr += sprintf(msgPtr, "Sequence/Track Name %s", str);
                            cP[len] = c;
                            cP += len;
                            break;
                        case 0x02:
                            str = cP;
                            c = cP[len];
                            cP[len] = '\0'; /* null terminate temporarily */
                            msgPtr += sprintf(msgPtr, "Copyright Notice %s", str);
                            cP[len] = c;
                            cP += len;
                            break;
                        case 0x01:
                            str = cP;
                            c = cP[len];
                            cP[len] = '\0'; /* null terminate temporarily */
                            msgPtr += sprintf(msgPtr, "Text %s", str);
                            cP[len] = c;
                            cP += len;
                            break;
                        case 0x00:
                            tt[0] = *cP++;
                            tt[1] = *cP++;
                            sn = midifile_get_multibyte_2(tt);
                            msgPtr += sprintf(msgPtr, "Sequence Number %d", sn);
                            break;
                        default:
                            msgPtr += sprintf(msgPtr, "Unknown: 0x%02X", c);
                            cP += len;
                            break;
                    }
                    break;
                default: /* 0xF4, 0xF5, 0xF9, 0xFD are not defined */
                    msgPtr += sprintf(msgPtr, "Undefined: 0x%02X", status);
                    break;
            }
        }
        else
        {
            if (status & 0x80)
            {
                running_status = status;
                c = *cP++;
            }
            else
            {
                c = status;
                status = running_status;
            }
            ch = (status & 0x0F) + 1; /* MIDI channel number */
            switch (status & 0xF0)
            {
                case 0x80:
                    d = *cP++; /* 2 data bytes */
                    msgPtr += sprintf(msgPtr,
                        "MIDI 0x%02X %02X %02X : channel %d Note %d Off velocity %d",
                        status, c, d, ch, c, d);
                    break;
                case 0x90:
                    d = *cP++; /* 2 data bytes */
                    if (d == 0)
                        msgPtr += sprintf(msgPtr,"MIDI 0x%02X %02X %02X : channel %d Note %d Off", status, c, d, ch, c);
                    else
                        msgPtr += sprintf(msgPtr,
                            "MIDI 0x%02X %02X %02X : channel %d Note %d On velocity %d", status, c, d, ch, c, d);
                    break;
                case 0xA0:
                    d = *cP++; /* 2 data bytes */
                    msgPtr += sprintf(msgPtr,
                        "MIDI: 0x%02X %02X %02X : channel %d Note %d Aftertouch %d", status, c, d, ch, c, d);
                    break;
                case 0xB0:
                    d = *cP++; /* 2 data bytes */
                    msgPtr += sprintf(msgPtr,
                        "MIDI: 0x%02X %02X %02X : channel %d Controller %d: %d", status, c, d, ch, c, d);
                    break;
                case 0xC0:	/* 1 data byte */
                    msgPtr += sprintf(msgPtr,"MIDI: 0x%02X %02X: channel %d Program Change: %d", status, c, ch, c);
                    break;
                case 0xD0: /* 1 data byte */
                    msgPtr += sprintf(msgPtr,"MIDI: 0x%02X %02X: channel %d Channel Pressure: %d", status, c, ch, c);
                    break;
                case 0xE0: /* 2 data bytes */
                    d = *cP++; /* 2 data bytes */
                    msgPtr += sprintf(msgPtr,
                        "MIDI: 0x%02X %02X %02X : channel %d Pitch Wheel %d",
                        status, c, d, ch, midifile_combine_bytes(c, d));
                    break;
            }
        }
        post("midifile: %s", msg);
    }
}

static void midifile_get_next_track_chunk_data(t_midifile *x, int mfindex)
/** parse the next track chunk data element and output via the appropriate outlet or post to main window
* Sets the delta_time of the element or NO_MORE_ELEMENTS if no more elements
*/
{
    unsigned char   *cP, *last_cP, *str;
    size_t          delta_time, time_sig, len;
    unsigned char   status, c, d=0, nn, dd, cc, bb, mi, mcp, n=0;
    char            sf;
    char            fps, hour, min, sec, frame, subframe;

    unsigned short  sn;
    unsigned char   tt[3];
    t_atom          output_atom[6];

    cP = x->track_chunk[mfindex].track_data + x->track_chunk[mfindex].track_index;
    last_cP = x->track_chunk[mfindex].track_data + x->track_chunk[mfindex].chunk_length;

    delta_time = NO_MORE_ELEMENTS;
    if ((cP != NULL) && (cP < last_cP) && (x->track_chunk[mfindex].delta_time != NO_MORE_ELEMENTS))
    {
        cP = midifile_read_var_len(cP, &delta_time);
        status = *cP++;
        if ((status & 0xF0) == 0xF0)
        {
        switch (status)
        { /* system message */
                case 0xF0:
                case 0xF7:
                    cP = midifile_read_var_len(cP, &len); /* packet length */
                    if (x->verbosity) post("midifile: Sysex: %02X length %zu", status, len);
                    midifile_output_long_list(x->midi_list_outlet, cP, len, 0xF0);
                    cP += len;
                    x->track_chunk[mfindex].running_status = 0;
                    break;
                case 0xF1: /* quarter frame */
                    x->midi_data[0].a_w.w_float = status;
                    outlet_list(x->midi_list_outlet, &s_list, 1, x->midi_data);
                    x->track_chunk[mfindex].running_status = 0;
                    break;
                case 0xF3: /* song select */
                    c = *cP++;
                    x->midi_data[0].a_w.w_float = status;
                    x->midi_data[1].a_w.w_float = c;
                    outlet_list(x->midi_list_outlet, &s_list, 2, x->midi_data);
                    x->track_chunk[mfindex].running_status = 0;
                    break;
                case 0xF2: /* song position */
                    c = *cP++;
                    x->midi_data[0].a_w.w_float = status;
                    x->midi_data[1].a_w.w_float = c;
                    c = *cP++;
                    x->midi_data[2].a_w.w_float	= c;
                    outlet_list(x->midi_list_outlet, &s_list, 3, x->midi_data);
                    x->track_chunk[mfindex].running_status = 0;
                    break;
                case 0xF6: /* tune request */
                    x->midi_data[0].a_w.w_float = status;
                    outlet_list(x->midi_list_outlet, &s_list, 1, x->midi_data);
                    x->track_chunk[mfindex].running_status = 0;
                    break;
                case 0xF8: /* MIDI clock */
                case 0xF9: /* MIDI tick */
                case 0xFA: /* MIDI start */
                case 0xFB: /* MIDI continue */
                case 0xFC: /* MIDI stop */
                case 0xFE: /* active sense */
                    x->midi_data[0].a_w.w_float = status;
                    outlet_list(x->midi_list_outlet, &s_list, 1, x->midi_data);
                    break;
                case 0xFF: /* meta event */
                    c = *cP++;
                    cP = midifile_read_var_len(cP, &len);/* meta length */
                    if (x->verbosity) post("midifile: Track %d Meta: %02X length %zu", mfindex, c, len);
                    switch (c)
                    {
                        case 0x59: /* key signature */
                            sf = *(signed char *)cP++;
                            mi = *cP++;
                            if (x->verbosity)
                                post ("midifile: Key Signature: %d %s, %s",
                                    sf, (sf<0)?"flats":"sharps", (mi)?"minor":"major");
                            SETFLOAT(&output_atom[0], sf);
                            SETFLOAT(&output_atom[1], mi);
                            SETSYMBOL(&output_atom[2], midifile_key_name(sf, mi));
                            outlet_anything( x->status_outlet, gensym("key_sig"), 3, output_atom);
                            break;
                        case 0x58: /* time signature */
                            nn = *cP++;
                            dd = *cP++;
                            dd = 1<<(dd);
                            cc = *cP++;
                            bb = *cP++;
                            if (x->verbosity)
                                post ("midifile: Time Signature: %d/%d %d clocks per tick, %d 32nd notes per quarternote",
                                    nn, dd, cc, bb);
                            SETFLOAT(&output_atom[0], nn);
                            SETFLOAT(&output_atom[1], dd);
                            SETFLOAT(&output_atom[2], cc);
                            SETFLOAT(&output_atom[3], bb);
                            outlet_anything( x->status_outlet, gensym("time_sig"), 4, output_atom);
                            break;
                        case 0x54: /* smpte  offset */
                            hour = *cP++; /* hour is mixed with fps as 0ffhhhhhh */
                            switch (hour>>6)
                            {
                                case 0:
                                    fps = 24;
                                    break;
                                case 1:
                                    fps = 25;
                                    break;
                                case 2:
                                    fps = 29;/* 30 fps dropframe */
                                    break;
                                case 3:
                                    fps = 30;
                                default:
                                    fps = 0; /* error */
                            }
                            hour = hour & 0x3F;
                            min = *cP++;
                            sec = *cP++;
                            frame = *cP++;
                            subframe = *cP++;
                            if (x->verbosity) post ("midifile: SMPTE offset: %d:%d:%d:%d:%d, %d fps", hour, min, sec, frame, subframe, fps);
                            SETFLOAT(&output_atom[0], hour);
                            SETFLOAT(&output_atom[1], min);
                            SETFLOAT(&output_atom[2], sec);
                            SETFLOAT(&output_atom[3], frame);
                            SETFLOAT(&output_atom[4], subframe);
                            SETFLOAT(&output_atom[5], fps);
                            outlet_anything( x->status_outlet, gensym("smpte"), 6, output_atom);
                            break;
                        case 0x51: /* set tempo */
                            tt[0] = *cP++;
                            tt[1] = *cP++;
                            tt[2] = *cP++;
                            time_sig = midifile_get_multibyte_3(tt);
                            if (x->verbosity) post ("midifile: %lu microseconds per MIDI quarter-note", time_sig);
                            SETFLOAT(&output_atom[0], time_sig);
                            outlet_anything( x->status_outlet, gensym("microsec_per_quarternote"), 1, output_atom);
                            break;
                        case 0x2F: /* end of track */
                            if (x->verbosity) post ("midifile: End of Track %d", mfindex);
                            delta_time = NO_MORE_ELEMENTS;
                            SETFLOAT(&output_atom[0], mfindex);
                            SETFLOAT(&output_atom[1], x->total_time);
                            outlet_anything( x->status_outlet, gensym("end"), 2, output_atom);
                            cP += len;
                            break;
                        case 0x21:
                            tt[0] = *cP++;
                            if (x->verbosity) post ("midifile: MIDI port or cable number (unofficial): %d", tt[0]);
                            break;
                        case 0x20: /* MIDI channel prefix */
                            mcp = *cP++;
                            if (x->verbosity) post ("midifile: MIDI Channel Prefix: %d", mcp);
                            SETFLOAT(&output_atom[0], mfindex);
                            SETFLOAT(&output_atom[1], mcp);
                            outlet_anything( x->status_outlet, gensym("channel"), 2, output_atom);
                            break;
                        case 0x07: /* cue point */
                            str = cP;
                            c = cP[len];
                            cP[len] = '\0'; /* null terminate temporarily */
                            if (x->verbosity) post ("midifile: Cue Point: %s", str);
                            SETSYMBOL(&output_atom[0], gensym((char *)str));
                            outlet_anything( x->status_outlet, gensym("cue"), 1, output_atom);
                            cP[len] = c;
                            cP += len;
                            break;
                        case 0x06: /* marker */
                            str = cP;
                            c = cP[len];
                            cP[len] = '\0'; /* null terminate temporarily */
                            if (x->verbosity) post ("midifile: Marker: %s", str);
                            SETSYMBOL(&output_atom[0], gensym((char *)str));
                            outlet_anything( x->status_outlet, gensym("marker"), 1, output_atom);
                            cP[len] = c;
                            cP += len;
                            break;
                        case 0x05: /* lyrics */
                            str = cP;
                            c = cP[len];
                            cP[len] = '\0'; /* null terminate temporarily */
                            if (x->verbosity) post ("midifile: Lyric: %s", str);
                            SETSYMBOL(&output_atom[0], gensym((char *)str));
                            outlet_anything( x->status_outlet, gensym("lyrics"), 1, output_atom);
                            cP[len] = c;
                            cP += len;
                            break;
                        case 0x04: /* instrument name */
                            str = cP;
                            c = cP[len];
                            cP[len] = '\0'; /* null terminate temporarily */
                            if (x->verbosity) post ("midifile: Instrument Name: %s", str);
                            SETSYMBOL(&output_atom[0], gensym((char *)str));
                            outlet_anything( x->status_outlet, gensym("instr_name"), 1, output_atom);
                            cP[len] = c;
                            cP += len;
                            break;
                        case 0x03: /* sequence/track name */
                            str = cP;
                            c = cP[len];
                            cP[len] = '\0'; /* null terminate temporarily */
                            if (x->verbosity) post ("midifile: Sequence/Track Name: %s", str);
                            SETFLOAT(&output_atom[0], mfindex);
                            SETSYMBOL(&output_atom[1], gensym((char *)str));
                            outlet_anything( x->status_outlet, gensym("name"), 2, output_atom);
                            cP[len] = c;
                            cP += len;
                            break;
                        case 0x02:/* copyright notice */
                            str = cP;
                            c = cP[len];
                            cP[len] = '\0'; /* null terminate temporarily */
                            if (x->verbosity) post ("midifile: Copyright Notice: %s", str);
                            SETSYMBOL(&output_atom[0], gensym((char *)str));
                            outlet_anything( x->status_outlet, gensym("copyright"), 1, output_atom);
                            cP[len] = c;
                            cP += len;
                            break;
                        case 0x01: /* text event */
                            str = cP;
                            c = cP[len];
                            cP[len] = '\0'; /* null terminate temporarily */
                            if (x->verbosity) post ("midifile: Text Event: %s", str);
                            SETSYMBOL(&output_atom[0], gensym((char *)str));
                            outlet_anything( x->status_outlet, gensym("text"), 1, output_atom);
                            cP[len] = c;
                            cP += len;
                            break;
                        case 0x00: /* sequence number */
                            tt[0] = *cP++;
                            tt[1] = *cP++;
                            sn = midifile_get_multibyte_2(tt);
                            if (x->verbosity) post ("midifile: Sequence Number %d", sn);
                            SETFLOAT(&output_atom[0], sn);
                            outlet_anything( x->status_outlet, gensym("seq_num"), 1, output_atom);
                            break;
                        default:
                            if (x->verbosity) post ("midifile: Unknown: %02X", c);
                            cP += len;
                            break;
                    }
                    break;
                default: /* 0xF4, 0xF5, 0xF9, 0xFD are not defined */
                    break;
            }
        }
        else
        {
            if (status & 0x80)
            {
                x->track_chunk[mfindex].running_status = status;/* status is true status */
                c = *cP++;
            }
            else
            {
                c = status; /* status is actually 1st data byte */
                status = x->track_chunk[mfindex].running_status; /* current status */
            }
            switch (status & 0xF0)
            {
                case 0x80:
                case 0x90:
                case 0xA0:
                case 0xB0:
                case 0xE0:
                    n = 3;
                    d = *cP++; /* 2 data bytes */
                    break;
                case 0xC0: /* 1 data byte */
                case 0xD0:
                    n = 2;
                    break;
            }
            x->midi_data[0].a_w.w_float = status;
            x->midi_data[1].a_w.w_float = c;
            x->midi_data[2].a_w.w_float	= (n == 3)?d:0;
            if (x->midi_data[0].a_w.w_float != 0) outlet_list(x->midi_list_outlet, &s_list, n, x->midi_data);
            if (x->track_chunk[mfindex].running_status == 0)
                error ("midifile: No running status on track %d at %zu",
                    mfindex, x->track_chunk[mfindex].total_time + delta_time);
        }
    }
    x->track_chunk[mfindex].track_index = (char *)cP - (char *)x->track_chunk[mfindex].track_data;
    x->track_chunk[mfindex].delta_time = delta_time;
    if (delta_time == NO_MORE_ELEMENTS) x->track_chunk[mfindex].total_time = delta_time;
    else x->track_chunk[mfindex].total_time += delta_time;
}

/** parse the next track chunk data element and skip it without any output
* Sets the delta_time of the element or NO_MORE_ELEMENTS if no more elements
*/
static void midifile_skip_next_track_chunk_data(t_midifile *x, int mfindex)
{
    unsigned char   *cP, *last_cP;
    size_t          delta_time, len;
    unsigned char   status, c, n;

    cP = x->track_chunk[mfindex].track_data + x->track_chunk[mfindex].track_index;
    last_cP = x->track_chunk[mfindex].track_data + x->track_chunk[mfindex].chunk_length;

    delta_time = NO_MORE_ELEMENTS;

    if ((cP != NULL) && (cP < last_cP) && (x->track_chunk[mfindex].delta_time != NO_MORE_ELEMENTS))
    {
        cP = midifile_read_var_len(cP, &delta_time);
        status = *cP++;
        if ((status & 0xF0) == 0xF0)
        {
            switch (status)
            { /* system message */
                case 0xF0:
                case 0xF7:
                    cP = midifile_read_var_len(cP, &len); /* packet length */
                    cP += len;
                    break;
                case 0xF1: /* quarter frame */
                    break;
                case 0xF3: /* song select */
                    cP += 1;
                    break;
                case 0xF2: /* song position */
                    cP += 2;
                    break;
                case 0xF6: /* tune request */
                case 0xF8: /* MIDI clock */
                case 0xF9: /* MIDI tick */
                case 0xFA: /* MIDI start */
                case 0xFB: /* MIDI continue */
                case 0xFC: /* MIDI stop */
                case 0xFE: /* active sense */
                    break;
                case 0xFF:
                    c = *cP++;
                    cP = midifile_read_var_len(cP, &len);/* meta length */
                    switch (c)
                    {
                        case 0x2F:
                            if (x->verbosity) post ("midifile: End of Track %d", mfindex);
                            delta_time = NO_MORE_ELEMENTS;
                            /* fall through to default....*/
                        default:
                            cP += len;
                            break;
                    }
                    break;
                default: /* 0xF4, 0xF5, 0xF9, 0xFD are not defined */
                    break;
            }
        }
        else
        {
            if (status & 0x80)
            {
                x->track_chunk[mfindex].running_status = status;
                n = 1;
            }
            else
            {
                n = 0; /* no status in this message */
                status = x->track_chunk[mfindex].running_status;
            }
            switch (status & 0xF0)
            {
                case 0x80:
                case 0x90:
                case 0xA0:
                case 0xB0:
                case 0xE0:
                    n += 1; /* data bytes */
                    break;
                case 0xC0:
                case 0xD0: /* only one data byte */
                    break;
            }
            cP += n;
        }
    }
    x->track_chunk[mfindex].track_index = (char *)cP - (char *)x->track_chunk[mfindex].track_data;
    x->track_chunk[mfindex].delta_time = delta_time;
    if (delta_time == NO_MORE_ELEMENTS) x->track_chunk[mfindex].total_time = delta_time;
    else x->track_chunk[mfindex].total_time += delta_time;
}

/** set a symbol to the key name based on
* sf= number of sharps if positive, else flats
* mi = 0=major 1= minor
*/
static t_symbol *midifile_key_name(int sf, int mi)
{
    char    *maj_key[15]={"B",  "Gb", "Db", "Ab", "Eb", "Bb", "F", "C", "G", "D", "A",  "E",  "B",  "F#", "Db"};
    char    *min_key[15]={"G#", "Eb", "Bb", "F",  "C",  "G",  "D", "A", "E", "B", "F#", "C#", "G#", "D#", "Bb"};
    char    buf[8] = {"no_key."};
    int     i;

    if ((sf >= -7)&&(sf <= 7))
    {
        if (mi == 1)
        {
            i = sprintf(buf, "%s", min_key[sf+7]);
            sprintf(buf+i, "%s", "Minor");
        }
        else if (mi == 0)
        {
            i = sprintf(buf, "%s", maj_key[sf+7]);
            sprintf(buf+i, "%s", "Major");
        }
    }
    return gensym(buf);
}
/* fin midifile.c */
