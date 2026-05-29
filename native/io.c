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

/* ============================================================
 * libcurl forward declarations (no headers required)
 * ============================================================ */

typedef void CURL;
typedef int CURLcode;
typedef int CURLoption;

#define CURLOPT_URL 10002
#define CURLOPT_WRITEFUNCTION 20011
#define CURLOPT_WRITEDATA 10001
#define CURLOPT_POST 47
#define CURLOPT_POSTFIELDS 10015
#define CURLOPT_POSTFIELDSIZE 60
#define CURLOPT_HTTPHEADER 10023
#define CURLOPT_TIMEOUT 13
#define CURLOPT_CUSTOMREQUEST 10036
#define CURLOPT_HTTPGET 80
#define CURLE_OK 0

extern CURL *curl_easy_init(void);
extern CURLcode curl_easy_setopt(CURL *curl, CURLoption option, ...);
extern CURLcode curl_easy_perform(CURL *curl);
extern void curl_easy_cleanup(CURL *curl);
extern void *curl_slist_append(void *list, const char *data);
extern void curl_slist_free_all(void *list);

/* ============================================================
 * Memory helpers for MoonBit bytes interop
 * ============================================================ */

static char *mbt_strndup(const char *s, int len) {
    char *out = (char *)malloc(len + 1);
    if (!out) return NULL;
    memcpy(out, s, len);
    out[len] = '\0';
    return out;
}

/* ============================================================
 * HTTP client (via libcurl, no headers needed)
 * ============================================================ */

struct curl_write_buf {
    char *data;
    int size;
    int cap;
};

static size_t curl_write_cb(void *ptr, size_t size, size_t nmemb, void *ud) {
    struct curl_write_buf *buf = (struct curl_write_buf *)ud;
    int total = (int)(size * nmemb);
    if (buf->size + total + 1 > buf->cap) {
        buf->cap = (buf->size + total + 1) * 2;
        buf->data = (char *)realloc(buf->data, buf->cap);
    }
    memcpy(buf->data + buf->size, ptr, total);
    buf->size += total;
    buf->data[buf->size] = '\0';
    return total;
}

/*
 * autoagent_http_post(url, url_len, body, body_len, auth, auth_len) -> response
 * Returns a null-terminated string. Caller must free.
 */
char *autoagent_http_post(const char *url, int url_len,
                          const char *body, int body_len,
                          const char *auth, int auth_len) {
    CURL *curl = curl_easy_init();
    if (!curl) return NULL;

    char *url_s = mbt_strndup(url, url_len);
    char *body_s = mbt_strndup(body, body_len);

    struct curl_write_buf buf = {NULL, 0, 0};
    void *headers = NULL;
    headers = curl_slist_append(headers, "Content-Type: application/json");

    if (auth && auth_len > 0) {
        char hdr[512];
        int n = auth_len < 480 ? auth_len : 480;
        memcpy(hdr, "Authorization: Bearer ", 22);
        memcpy(hdr + 22, auth, n);
        hdr[22 + n] = '\0';
        headers = curl_slist_append(headers, hdr);
    }

    curl_easy_setopt(curl, CURLOPT_URL, url_s);
    curl_easy_setopt(curl, CURLOPT_POST, 1L);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body_s);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, (long)body_len);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_write_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &buf);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 60L);

    CURLcode res = curl_easy_perform(curl);
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    free(url_s);
    free(body_s);

    if (res != CURLE_OK) {
        if (buf.data) free(buf.data);
        return NULL;
    }
    return buf.data;
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
        return NULL;
    }
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *buf = (char *)malloc(sz + 1);
    if (!buf) { fclose(f); free(p); return NULL; }
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
        return NULL;
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
    if (!p) return NULL;

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
    if (!v) return NULL;
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
    return NULL;
}

/*
 * autoagent_free(ptr) -> free memory allocated by C layer
 */
void autoagent_free(void *ptr) {
    if (ptr) free(ptr);
}
