/*
 * AutoAgent C I/O Layer
 * Provides HTTP, file, process, and environment functions for MoonBit FFI.
 * Linked with the MoonBit-generated native binary.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>

/* ============================================================
 * HTTP stubs (no libcurl dependency for portability)
 * ============================================================ */

static char *http_post_not_available(void) {
    char *out = (char *)malloc(64);
    if (out) strcpy(out, "HTTP not available (libcurl not linked)");
    return out;
}

/* ============================================================
 * Memory helpers for MoonBit bytes interop
 * ============================================================ */

static char *mbt_empty_string(void) {
    char *out = (char *)malloc(1);
    if (out) out[0] = '\0';
    return out;
}

static char *mbt_strndup(const char *s, int len) {
    char *out = (char *)malloc(len + 1);
    if (!out) return mbt_empty_string();
    memcpy(out, s, len);
    out[len] = '\0';
    return out;
}

/* ============================================================
 * HTTP client (via libcurl, no headers needed)
 * ============================================================ */

/*
 * autoagent_http_post(url, url_len, body, body_len, auth, auth_len) -> response
 * Stub: returns error message. Caller must free.
 */
char *autoagent_http_post(const char *url, int url_len,
                          const char *body, int body_len,
                          const char *auth, int auth_len) {
    (void)url; (void)url_len; (void)body; (void)body_len; (void)auth; (void)auth_len;
    return http_post_not_available();
}

/*
 * autoagent_http_post_stream - Stub
 */
char *autoagent_http_post_stream(const char *url, int url_len,
                                 const char *body, int body_len,
                                 const char *auth, int auth_len) {
    (void)url; (void)url_len; (void)body; (void)body_len; (void)auth; (void)auth_len;
    return http_post_not_available();
}

/* ============================================================
 * File system operations
 * ============================================================ */

/*
 * autoagent_read_file(path, path_len) -> content
 * Returns null-terminated string. Caller must free.
 * On error returns NULL and sets autoagent_last_errno.
 */
int autoagent_last_errno = 0;

char *autoagent_read_file(const char *path, int path_len) {
    char *p = mbt_strndup(path, path_len);
    FILE *f = fopen(p, "rb");
    if (!f) {
        autoagent_last_errno = errno;
        free(p);
        return mbt_empty_string();
    }
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *buf = (char *)malloc(sz + 1);
    if (!buf) { fclose(f); free(p); return mbt_empty_string(); }
    long rd = fread(buf, 1, sz, f);
    buf[rd] = '\0';
    fclose(f);
    free(p);
    return buf;
}

/*
 * autoagent_write_file(path, path_len, content, content_len) -> 0 on success, -1 on error
 */
int autoagent_write_file(const char *path, int path_len,
                         const char *content, int content_len) {
    char *p = mbt_strndup(path, path_len);
    FILE *f = fopen(p, "wb");
    if (!f) {
        autoagent_last_errno = errno;
        free(p);
        return -1;
    }
    long wr = fwrite(content, 1, content_len, f);
    fclose(f);
    free(p);
    return (wr == content_len) ? 0 : -1;
}

/*
 * autoagent_mkdir(path, path_len) -> 0 on success, -1 on error
 */
int autoagent_mkdir(const char *path, int path_len) {
    char *p = mbt_strndup(path, path_len);
    int r = mkdir(p, 0755);
    if (r != 0 && errno != EEXIST) {
        autoagent_last_errno = errno;
        free(p);
        return -1;
    }
    free(p);
    return 0;
}

/*
 * autoagent_list_dir(path, path_len) -> newline-separated entries
 * Returns null-terminated string. Caller must free.
 * On error returns NULL.
 */
char *autoagent_list_dir(const char *path, int path_len) {
    char *p = mbt_strndup(path, path_len);
    DIR *d = opendir(p);
    if (!d) {
        autoagent_last_errno = errno;
        free(p);
        return mbt_empty_string();
    }
    int cap = 4096, size = 0;
    char *buf = (char *)malloc(cap);
    buf[0] = '\0';
    struct dirent *ent;
    while ((ent = readdir(d)) != NULL) {
        char *name = ent->d_name;
        if (name[0] == '.' && (name[1] == '\0' || (name[1] == '.' && name[2] == '\0')))
            continue;
        int nl = (int)strlen(name);
        if (size + nl + 2 > cap) {
            cap = (size + nl + 2) * 2;
            buf = (char *)realloc(buf, cap);
        }
        memcpy(buf + size, name, nl);
        buf[size + nl] = '\n';
        size += nl + 1;
    }
    buf[size] = '\0';
    closedir(d);
    free(p);
    return buf;
}

/*
 * autoagent_file_exists(path, path_len) -> 1 if exists, 0 if not
 */
int autoagent_file_exists(const char *path, int path_len) {
    char *p = mbt_strndup(path, path_len);
    int r = access(p, F_OK);
    free(p);
    return r == 0 ? 1 : 0;
}

/* ============================================================
 * Process execution
 * ============================================================ */

/*
 * autoagent_exec(cmd, cmd_len) -> output (stdout+stderr)
 * Returns null-terminated string. Caller must free.
 */
char *autoagent_exec(const char *cmd, int cmd_len) {
    char *full_cmd = (char *)malloc(cmd_len + 20);
    memcpy(full_cmd, cmd, cmd_len);
    memcpy(full_cmd + cmd_len, " 2>&1", 5);
    full_cmd[cmd_len + 5] = '\0';

    FILE *p = popen(full_cmd, "r");
    free(full_cmd);
    if (!p) return mbt_empty_string();

    int cap = 8192, size = 0;
    char *buf = (char *)malloc(cap);
    while (!feof(p)) {
        if (size + 1024 > cap) {
            cap *= 2;
            buf = (char *)realloc(buf, cap);
        }
        size += (int)fread(buf + size, 1, 1024, p);
    }
    buf[size] = '\0';
    pclose(p);
    return buf;
}

/* ============================================================
 * Environment variables
 * ============================================================ */

/*
 * autoagent_getenv(key, key_len) -> value or NULL
 * Returns null-terminated string. Caller must free.
 */
char *autoagent_getenv(const char *key, int key_len) {
    char *k = mbt_strndup(key, key_len);
    char *v = getenv(k);
    free(k);
    if (!v) {
        char *empty = (char *)malloc(1);
        if (empty) empty[0] = '\0';
        return empty;
    }
    return strdup(v);
}

/*
 * autoagent_setenv(key, key_len, val, val_len) -> 0 on success
 */
int autoagent_setenv(const char *key, int key_len,
                     const char *val, int val_len) {
    char *k = mbt_strndup(key, key_len);
    char *v = mbt_strndup(val, val_len);
    int r = setenv(k, v, 1);
    free(k);
    free(v);
    return r;
}

/* ============================================================
 * Misc
 * ============================================================ */

/*
 * autoagent_getcwd() -> current working directory
 * Returns null-terminated string. Caller must free.
 */
char *autoagent_getcwd_alloc(void) {
    char buf[4096];
    if (getcwd(buf, sizeof(buf))) return strdup(buf);
    return mbt_empty_string();
}

/*
 * autoagent_free(ptr) -> free memory allocated by C layer
 */
void autoagent_free(void *ptr) {
    if (ptr) free(ptr);
}

/*
 * autoagent_time_ms() -> current time in milliseconds
 * Used for tool execution timing.
 */
long long autoagent_time_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

/*
 * autoagent_read_line() -> line from stdin
 * Returns null-terminated string. Caller must free.
 * Returns NULL on EOF.
 */
char *autoagent_read_line(void) {
    int cap = 256, size = 0;
    char *buf = (char *)malloc(cap);
    if (!buf) return mbt_empty_string();

    int c;
    while ((c = fgetc(stdin)) != EOF) {
        if (c == '\n') break;
        if (size + 1 >= cap) {
            cap *= 2;
            buf = (char *)realloc(buf, cap);
            if (!buf) return mbt_empty_string();
        }
        buf[size++] = (char)c;
    }

    if (size == 0 && c == EOF) {
        free(buf);
        return mbt_empty_string();
    }

    buf[size] = '\0';
    return buf;
}

/*
 * autoagent_stdin_eof() -> 1 if stdin is at EOF, 0 otherwise
 */
int autoagent_stdin_eof(void) {
    int c = fgetc(stdin);
    if (c == EOF) return 1;
    ungetc(c, stdin);
    return 0;
}
