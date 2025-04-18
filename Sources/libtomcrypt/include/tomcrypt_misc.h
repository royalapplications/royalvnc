/* LibTomCrypt, modular cryptographic library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#ifndef TOMCRYPT_MISC_H_
#define TOMCRYPT_MISC_H_

/* ---- LTC_BASE64 Routines ---- */
#ifdef LTC_BASE64
int base64_encode(const unsigned char *in,  unsigned long inlen,
                                 char *out, unsigned long *outlen);

int base64_decode(const char *in,  unsigned long inlen,
                        unsigned char *out, unsigned long *outlen);
int base64_strict_decode(const char *in,  unsigned long inlen,
                        unsigned char *out, unsigned long *outlen);
int base64_sane_decode(const char *in,  unsigned long inlen,
                        unsigned char *out, unsigned long *outlen);
#endif

#ifdef LTC_BASE64_URL
int base64url_encode(const unsigned char *in,  unsigned long inlen,
                                    char *out, unsigned long *outlen);
int base64url_strict_encode(const unsigned char *in,  unsigned long inlen,
                                           char *out, unsigned long *outlen);

int base64url_decode(const char *in,  unsigned long inlen,
                        unsigned char *out, unsigned long *outlen);
int base64url_strict_decode(const char *in,  unsigned long inlen,
                        unsigned char *out, unsigned long *outlen);
int base64url_sane_decode(const char *in,  unsigned long inlen,
                        unsigned char *out, unsigned long *outlen);
#endif

/* ---- BASE32 Routines ---- */
#ifdef LTC_BASE32
typedef enum {
   BASE32_RFC4648   = 0,
   BASE32_BASE32HEX = 1,
   BASE32_ZBASE32   = 2,
   BASE32_CROCKFORD = 3
} base32_alphabet;
int base32_encode(const unsigned char *in,  unsigned long inlen,
                                 char *out, unsigned long *outlen,
                        base32_alphabet id);
int base32_decode(const          char *in,  unsigned long inlen,
                        unsigned char *out, unsigned long *outlen,
                        base32_alphabet id);
#endif

/* ---- BASE16 Routines ---- */
#ifdef LTC_BASE16
int base16_encode(const unsigned char *in,  unsigned long  inlen,
                                 char *out, unsigned long *outlen,
                        unsigned int   options);
int base16_decode(const          char *in,  unsigned long  inlen,
                        unsigned char *out, unsigned long *outlen);
#endif

#ifdef LTC_BCRYPT
int bcrypt_pbkdf_openbsd(const          void *secret, unsigned long secret_len,
                         const unsigned char *salt,   unsigned long salt_len,
                               unsigned int  rounds,            int hash_idx,
                               unsigned char *out,    unsigned long *outlen);
#endif

/* ===> LTC_HKDF -- RFC5869 HMAC-based Key Derivation Function <=== */
#ifdef LTC_HKDF

int hkdf_test(void);

int hkdf_extract(int hash_idx,
                 const unsigned char *salt, unsigned long saltlen,
                 const unsigned char *in,   unsigned long inlen,
                       unsigned char *out,  unsigned long *outlen);

int hkdf_expand(int hash_idx,
                const unsigned char *info, unsigned long infolen,
                const unsigned char *in,   unsigned long inlen,
                      unsigned char *out,  unsigned long outlen);

int hkdf(int hash_idx,
         const unsigned char *salt, unsigned long saltlen,
         const unsigned char *info, unsigned long infolen,
         const unsigned char *in,   unsigned long inlen,
               unsigned char *out,  unsigned long outlen);

#endif  /* LTC_HKDF */

/* ---- MEM routines ---- */
int mem_neq(const void *a, const void *b, size_t len);
void zeromem(volatile void *out, size_t outlen);
void burn_stack(unsigned long len);

const char *error_to_string(int err);

extern const char *crypt_build_settings;

/* ---- HMM ---- */
int crypt_fsa(void *mp, ...) LTC_NULL_TERMINATED;

/* ---- Dynamic language support ---- */
int crypt_get_constant(const char* namein, int *valueout);
int crypt_list_all_constants(char *names_list, unsigned int *names_list_size);

int crypt_get_size(const char* namein, unsigned int *sizeout);
int crypt_list_all_sizes(char *names_list, unsigned int *names_list_size);

#ifdef LTM_DESC
LTC_DEPRECATED(crypt_mp_init) void init_LTM(void);
#endif
#ifdef TFM_DESC
LTC_DEPRECATED(crypt_mp_init) void init_TFM(void);
#endif
#ifdef GMP_DESC
LTC_DEPRECATED(crypt_mp_init) void init_GMP(void);
#endif
int crypt_mp_init(const char* mpi);

#ifdef LTC_ADLER32
typedef struct adler32_state_s
{
   unsigned short s[2];
} adler32_state;

void adler32_init(adler32_state *ctx);
void adler32_update(adler32_state *ctx, const unsigned char *input, unsigned long length);
void adler32_finish(const adler32_state *ctx, void *hash, unsigned long size);
int adler32_test(void);
#endif

#ifdef LTC_CRC32
typedef struct crc32_state_s
{
   ulong32 crc;
} crc32_state;

void crc32_init(crc32_state *ctx);
void crc32_update(crc32_state *ctx, const unsigned char *input, unsigned long length);
void crc32_finish(const crc32_state *ctx, void *hash, unsigned long size);
int crc32_test(void);
#endif


#ifdef LTC_PADDING

enum padding_type {
   LTC_PAD_PKCS7        = 0x0000U,
#ifdef LTC_RNG_GET_BYTES
   LTC_PAD_ISO_10126    = 0x1000U,
#endif
   LTC_PAD_ANSI_X923    = 0x2000U,
   LTC_PAD_SSH          = 0x3000U,
   /* The following padding modes don't contain the padding
    * length as last byte of the padding.
    */
   LTC_PAD_ONE_AND_ZERO = 0x8000U,
   LTC_PAD_ZERO         = 0x9000U,
   LTC_PAD_ZERO_ALWAYS  = 0xA000U,
};

int padding_pad(unsigned char *data, unsigned long length, unsigned long* padded_length, unsigned long mode);
int padding_depad(const unsigned char *data, unsigned long *length, unsigned long mode);
#endif  /* LTC_PADDING */

#ifdef LTC_PEM
/* Buffer-based API */
int pem_decode(const void *buf, unsigned long len, ltc_pka_key *k, const password_ctx *pw_ctx);
int pem_decode_pkcs(const void *buf, unsigned long len, ltc_pka_key *k, const password_ctx *pw_ctx);

#ifdef LTC_SSH
/**
   Callback function for each key in an `authorized_keys` file.

   This function takes ownership of the `k` parameter passed.
   `k` must be free'd by calling `pka_key_destroy(&k)`.

   @param k        Pointer to the PKA key.
   @param comment  Pointer to a string with the comment.
   @param ctx      The `ctx` pointer as passed to the read function.
*/
typedef int (*ssh_authorized_key_cb)(ltc_pka_key *k, const char *comment, void *ctx);

int pem_decode_openssh(const void *buf, unsigned long len, ltc_pka_key *k, const password_ctx *pw_ctx);
int ssh_read_authorized_keys(const void *buf, unsigned long len, ssh_authorized_key_cb cb, void *ctx);
#endif /* LTC_SSH */

/* FILE*-based API */
#ifndef LTC_NO_FILE
int pem_decode_filehandle(FILE *f, ltc_pka_key *k, const password_ctx *pw_ctx);
int pem_decode_pkcs_filehandle(FILE *f, ltc_pka_key *k, const password_ctx *pw_ctx);
#ifdef LTC_SSH
int pem_decode_openssh_filehandle(FILE *f, ltc_pka_key *k, const password_ctx *pw_ctx);
int ssh_read_authorized_keys_filehandle(FILE *f, ssh_authorized_key_cb cb, void *ctx);
#endif /* LTC_SSH */
#endif /* LTC_NO_FILE */

#endif /* LTC_PEM */

#ifdef LTC_SSH
typedef enum ssh_data_type_ {
   LTC_SSHDATA_EOL,
   LTC_SSHDATA_BYTE,
   LTC_SSHDATA_BOOLEAN,
   LTC_SSHDATA_UINT32,
   LTC_SSHDATA_UINT64,
   LTC_SSHDATA_STRING,
   LTC_SSHDATA_MPINT,
   LTC_SSHDATA_NAMELIST,
} ssh_data_type;

/* VA list handy helpers with tuples of <type, data> */
int ssh_encode_sequence_multi(unsigned char *out, unsigned long *outlen, ...) LTC_NULL_TERMINATED;
int ssh_decode_sequence_multi(const unsigned char *in, unsigned long *inlen, ...) LTC_NULL_TERMINATED;
#endif /* LTC_SSH */

int compare_testvector(const void* is, const unsigned long is_len, const void* should, const unsigned long should_len, const char* what, int which);

#endif /* TOMCRYPT_MISC_H_ */