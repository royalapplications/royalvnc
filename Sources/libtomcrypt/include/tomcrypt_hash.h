/* LibTomCrypt, modular cryptographic library -- Tom St Denis
 *
 * LibTomCrypt is a library that provides various cryptographic
 * algorithms in a highly modular and flexible manner.
 *
 * The library is free for all purposes without any express
 * guarantee it works.
 */

#include <stdlib.h>
#include <stdint.h>
#include <stddef.h>
#include <limits.h>
#include <stdio.h>
#include <signal.h>
#include <string.h>

#ifndef LTC_EXPORT
   #define LTC_EXPORT
#endif

#if defined(_WIN32) || defined(_MSC_VER)
   #define LTC_CALL __cdecl
#elif !defined(LTC_CALL)
   #define LTC_CALL
#endif

#if defined(__clang__) || defined(__GNUC_MINOR__)
#define LTC_NORETURN __attribute__ ((noreturn))
#elif defined(_MSC_VER)
#define LTC_NORETURN __declspec(noreturn)
#else
#define LTC_NORETURN
#endif

LTC_NORETURN void crypt_argchk(const char *v, const char *s, int d);
#define LTC_ARGCHK(x) do { if (!(x)) { crypt_argchk(#x, __FILE__, __LINE__); } }while(0)
#define LTC_ARGCHKVD(x) do { if (!(x)) { crypt_argchk(#x, __FILE__, __LINE__); } }while(0)

/* ulong32: "32-bit at least" data type */
#if defined(__x86_64__) || defined(_M_X64) || defined(_M_AMD64) || \
    defined(__powerpc64__) || defined(__ppc64__) || defined(__PPC64__) || \
    defined(__s390x__) || defined(__arch64__) || defined(__aarch64__) || \
    defined(__sparcv9) || defined(__sparc_v9__) || defined(__sparc64__) || \
    defined(__ia64) || defined(__ia64__) || defined(__itanium__) || defined(_M_IA64) || \
    defined(__LP64__) || defined(_LP64) || defined(__64BIT__) || defined(_M_ARM64)
   typedef unsigned ulong32;
   #if !defined(ENDIAN_64BITWORD) && !defined(ENDIAN_32BITWORD)
     #define ENDIAN_64BITWORD
   #endif
#else
   typedef unsigned long ulong32;
   #if !defined(ENDIAN_64BITWORD) && !defined(ENDIAN_32BITWORD)
     #define ENDIAN_32BITWORD
   #endif
#endif

/* ulong64: 64-bit data type */
#ifdef _MSC_VER
   #define CONST64(n) n ## ui64
   typedef unsigned __int64 ulong64;
   typedef __int64 long64;
#else
   #define CONST64(n) n ## uLL
   typedef unsigned long long ulong64;
   typedef long long long64;
#endif

/* error codes [will be expanded in future releases] */
enum {
   CRYPT_OK=0,             /* Result OK */
   CRYPT_ERROR,            /* Generic Error */
   CRYPT_NOP,              /* Not a failure but no operation was performed */

   CRYPT_INVALID_KEYSIZE,  /* Invalid key size given */
   CRYPT_INVALID_ROUNDS,   /* Invalid number of rounds */
   CRYPT_FAIL_TESTVECTOR,  /* Algorithm failed test vectors */

   CRYPT_BUFFER_OVERFLOW,  /* Not enough space for output */
   CRYPT_INVALID_PACKET,   /* Invalid input packet given */

   CRYPT_INVALID_PRNGSIZE, /* Invalid number of bits for a PRNG */
   CRYPT_ERROR_READPRNG,   /* Could not read enough from PRNG */

   CRYPT_INVALID_CIPHER,   /* Invalid cipher specified */
   CRYPT_INVALID_HASH,     /* Invalid hash specified */
   CRYPT_INVALID_PRNG,     /* Invalid PRNG specified */

   CRYPT_MEM,              /* Out of memory */

   CRYPT_PK_TYPE_MISMATCH, /* Not equivalent types of PK keys */
   CRYPT_PK_NOT_PRIVATE,   /* Requires a private PK key */

   CRYPT_INVALID_ARG,      /* Generic invalid argument */
   CRYPT_FILE_NOTFOUND,    /* File Not Found */

   CRYPT_PK_INVALID_TYPE,  /* Invalid type of PK key */

   CRYPT_OVERFLOW,         /* An overflow of a value was detected/prevented */

   CRYPT_PK_ASN1_ERROR,    /* An error occurred while en- or decoding ASN.1 data */

   CRYPT_INPUT_TOO_LONG,   /* The input was longer than expected. */

   CRYPT_PK_INVALID_SIZE,  /* Invalid size input for PK parameters */

   CRYPT_INVALID_PRIME_SIZE, /* Invalid size of prime requested */
   CRYPT_PK_INVALID_PADDING, /* Invalid padding on input */

   CRYPT_HASH_OVERFLOW,     /* Hash applied to too many bits */
   CRYPT_PW_CTX_MISSING,    /* Password context to decrypt key file is missing */
   CRYPT_UNKNOWN_PEM,       /* The PEM header was not recognized */
};

#define STORE32L(x, y)                                                                     \
  do { (y)[3] = (unsigned char)(((x)>>24)&255); (y)[2] = (unsigned char)(((x)>>16)&255);   \
       (y)[1] = (unsigned char)(((x)>>8)&255); (y)[0] = (unsigned char)((x)&255); } while(0)

#define LOAD32L(x, y)                            \
  do { x = ((ulong32)((y)[3] & 255)<<24) | \
           ((ulong32)((y)[2] & 255)<<16) | \
           ((ulong32)((y)[1] & 255)<<8)  | \
           ((ulong32)((y)[0] & 255)); } while(0)

#define STORE64L(x, y)                                                                     \
  do { (y)[7] = (unsigned char)(((x)>>56)&255); (y)[6] = (unsigned char)(((x)>>48)&255);   \
       (y)[5] = (unsigned char)(((x)>>40)&255); (y)[4] = (unsigned char)(((x)>>32)&255);   \
       (y)[3] = (unsigned char)(((x)>>24)&255); (y)[2] = (unsigned char)(((x)>>16)&255);   \
       (y)[1] = (unsigned char)(((x)>>8)&255); (y)[0] = (unsigned char)((x)&255); } while(0)

#ifndef MAX
   #define MAX(x, y) ( ((x)>(y))?(x):(y) )
#endif

#ifndef MIN
   #define MIN(x, y) ( ((x)<(y))?(x):(y) )
#endif

/* rotates the hard way */
#define ROL(x, y) ( (((ulong32)(x)<<(ulong32)((y)&31)) | (((ulong32)(x)&0xFFFFFFFFUL)>>(ulong32)((32-((y)&31))&31))) & 0xFFFFFFFFUL)
#define ROR(x, y) ( ((((ulong32)(x)&0xFFFFFFFFUL)>>(ulong32)((y)&31)) | ((ulong32)(x)<<(ulong32)((32-((y)&31))&31))) & 0xFFFFFFFFUL)
#define ROLc(x, y) ( (((ulong32)(x)<<(ulong32)((y)&31)) | (((ulong32)(x)&0xFFFFFFFFUL)>>(ulong32)((32-((y)&31))&31))) & 0xFFFFFFFFUL)
#define RORc(x, y) ( ((((ulong32)(x)&0xFFFFFFFFUL)>>(ulong32)((y)&31)) | ((ulong32)(x)<<(ulong32)((32-((y)&31))&31))) & 0xFFFFFFFFUL)

#ifndef XMEMCPY
#define XMEMCPY  memcpy
#endif

/* ---- HASH FUNCTIONS ---- */
#ifdef LTC_SHA3
struct sha3_state {
    ulong64 saved;                  /* the portion of the input message that we didn't consume yet */
    ulong64 s[25];
    unsigned char sb[25 * 8];       /* used for storing `ulong64 s[25]` as little-endian bytes */
    unsigned short byte_index;      /* 0..7--the next byte after the set one (starts from 0; 0--none are buffered) */
    unsigned short word_index;      /* 0..24--the next word to integrate input (starts from 0) */
    unsigned short capacity_words;  /* the double size of the hash output in words (e.g. 16 for Keccak 512) */
    unsigned short xof_flag;
};
#endif

#ifdef LTC_SHA512
struct sha512_state {
    ulong64  length, state[8];
    unsigned long curlen;
    unsigned char buf[128];
};
#endif

#ifdef LTC_SHA256
struct sha256_state {
    ulong64 length;
    ulong32 state[8], curlen;
    unsigned char buf[64];
};
#endif

#ifdef LTC_SHA1
struct sha1_state {
    ulong64 length;
    ulong32 state[5], curlen;
    unsigned char buf[64];
};
#endif

//#ifdef LTC_MD5
struct md5_state {
    ulong64 length;
    ulong32 state[4], curlen;
    unsigned char buf[64];
};
//#endif

#ifdef LTC_MD4
struct md4_state {
    ulong64 length;
    ulong32 state[4], curlen;
    unsigned char buf[64];
};
#endif

#ifdef LTC_TIGER
struct tiger_state {
    ulong64 state[3], length;
    unsigned long curlen;
    unsigned char buf[64];
};
#endif

#ifdef LTC_MD2
struct md2_state {
    unsigned char chksum[16], X[48], buf[16];
    unsigned long curlen;
};
#endif

#ifdef LTC_RIPEMD128
struct rmd128_state {
    ulong64 length;
    unsigned char buf[64];
    ulong32 curlen, state[4];
};
#endif

#ifdef LTC_RIPEMD160
struct rmd160_state {
    ulong64 length;
    unsigned char buf[64];
    ulong32 curlen, state[5];
};
#endif

#ifdef LTC_RIPEMD256
struct rmd256_state {
    ulong64 length;
    unsigned char buf[64];
    ulong32 curlen, state[8];
};
#endif

#ifdef LTC_RIPEMD320
struct rmd320_state {
    ulong64 length;
    unsigned char buf[64];
    ulong32 curlen, state[10];
};
#endif

#ifdef LTC_WHIRLPOOL
struct whirlpool_state {
    ulong64 length, state[8];
    unsigned char buf[64];
    ulong32 curlen;
};
#endif

#ifdef LTC_CHC_HASH
struct chc_state {
    ulong64 length;
    unsigned char state[MAXBLOCKSIZE], buf[MAXBLOCKSIZE];
    ulong32 curlen;
};
#endif

#ifdef LTC_BLAKE2S
struct blake2s_state {
    ulong32 h[8];
    ulong32 t[2];
    ulong32 f[2];
    unsigned char buf[64];
    unsigned long curlen;
    unsigned long outlen;
    unsigned char last_node;
};
#endif

#ifdef LTC_BLAKE2B
struct blake2b_state {
    ulong64 h[8];
    ulong64 t[2];
    ulong64 f[2];
    unsigned char buf[128];
    unsigned long curlen;
    unsigned long outlen;
    unsigned char last_node;
};
#endif

typedef union Hash_state {
    char dummy[1];
#ifdef LTC_CHC_HASH
    struct chc_state chc;
#endif
#ifdef LTC_WHIRLPOOL
    struct whirlpool_state whirlpool;
#endif
#ifdef LTC_SHA3
    struct sha3_state sha3;
#endif
#ifdef LTC_SHA512
    struct sha512_state sha512;
#endif
#ifdef LTC_SHA256
    struct sha256_state sha256;
#endif
#ifdef LTC_SHA1
    struct sha1_state   sha1;
#endif
//#ifdef LTC_MD5
    struct md5_state    md5;
//#endif
#ifdef LTC_MD4
    struct md4_state    md4;
#endif
#ifdef LTC_MD2
    struct md2_state    md2;
#endif
#ifdef LTC_TIGER
    struct tiger_state  tiger;
#endif
#ifdef LTC_RIPEMD128
    struct rmd128_state rmd128;
#endif
#ifdef LTC_RIPEMD160
    struct rmd160_state rmd160;
#endif
#ifdef LTC_RIPEMD256
    struct rmd256_state rmd256;
#endif
#ifdef LTC_RIPEMD320
    struct rmd320_state rmd320;
#endif
#ifdef LTC_BLAKE2S
    struct blake2s_state blake2s;
#endif
#ifdef LTC_BLAKE2B
    struct blake2b_state blake2b;
#endif

    void *data;
} hash_state;

/** hash descriptor */
extern  struct ltc_hash_descriptor {
    /** name of hash */
    const char *name;
    /** internal ID */
    unsigned char ID;
    /** Size of digest in octets */
    unsigned long hashsize;
    /** Input block size in octets */
    unsigned long blocksize;
    /** ASN.1 OID */
    unsigned long OID[16];
    /** Length of DER encoding */
    unsigned long OIDlen;

    /** Init a hash state
      @param hash   The hash to initialize
      @return CRYPT_OK if successful
    */
    int (*init)(hash_state *hash);
    /** Process a block of data
      @param hash   The hash state
      @param in     The data to hash
      @param inlen  The length of the data (octets)
      @return CRYPT_OK if successful
    */
    int (*process)(hash_state *hash, const unsigned char *in, unsigned long inlen);
    /** Produce the digest and store it
      @param hash   The hash state
      @param out    [out] The destination of the digest
      @return CRYPT_OK if successful
    */
    int (*done)(hash_state *hash, unsigned char *out);
    /** Self-test
      @return CRYPT_OK if successful, CRYPT_NOP if self-tests have been disabled
    */
    int (*test)(void);

    /* accelerated hmac callback: if you need to-do multiple packets just use the generic hmac_memory and provide a hash callback */
    int  (*hmac_block)(const unsigned char *key, unsigned long  keylen,
                       const unsigned char *in,  unsigned long  inlen,
                             unsigned char *out, unsigned long *outlen);

} hash_descriptor[];

#ifdef LTC_CHC_HASH
int chc_register(int cipher);
int chc_init(hash_state * md);
int chc_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int chc_done(hash_state * md, unsigned char *hash);
int chc_test(void);
extern const struct ltc_hash_descriptor chc_desc;
#endif

#ifdef LTC_WHIRLPOOL
int whirlpool_init(hash_state * md);
int whirlpool_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int whirlpool_done(hash_state * md, unsigned char *hash);
int whirlpool_test(void);
extern const struct ltc_hash_descriptor whirlpool_desc;
#endif

#ifdef LTC_SHA3
int sha3_512_init(hash_state * md);
int sha3_512_test(void);
extern const struct ltc_hash_descriptor sha3_512_desc;
int sha3_384_init(hash_state * md);
int sha3_384_test(void);
extern const struct ltc_hash_descriptor sha3_384_desc;
int sha3_256_init(hash_state * md);
int sha3_256_test(void);
extern const struct ltc_hash_descriptor sha3_256_desc;
int sha3_224_init(hash_state * md);
int sha3_224_test(void);
extern const struct ltc_hash_descriptor sha3_224_desc;
/* process + done are the same for all variants */
int sha3_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int sha3_done(hash_state *md, unsigned char *hash);
/* SHAKE128 + SHAKE256 */
int sha3_shake_init(hash_state *md, int num);
#define sha3_shake_process(a,b,c) sha3_process(a,b,c)
int sha3_shake_done(hash_state *md, unsigned char *out, unsigned long outlen);
int sha3_shake_test(void);
int sha3_shake_memory(int num, const unsigned char *in, unsigned long inlen, unsigned char *out, unsigned long *outlen);
#endif

#ifdef LTC_SHA512
int sha512_init(hash_state * md);
int sha512_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int sha512_done(hash_state * md, unsigned char *hash);
int sha512_test(void);
extern const struct ltc_hash_descriptor sha512_desc;
#endif

#ifdef LTC_SHA384
#ifndef LTC_SHA512
   #error LTC_SHA512 is required for LTC_SHA384
#endif
int sha384_init(hash_state * md);
#define sha384_process sha512_process
int sha384_done(hash_state * md, unsigned char *hash);
int sha384_test(void);
extern const struct ltc_hash_descriptor sha384_desc;
#endif

#ifdef LTC_SHA512_256
#ifndef LTC_SHA512
   #error LTC_SHA512 is required for LTC_SHA512_256
#endif
int sha512_256_init(hash_state * md);
#define sha512_256_process sha512_process
int sha512_256_done(hash_state * md, unsigned char *hash);
int sha512_256_test(void);
extern const struct ltc_hash_descriptor sha512_256_desc;
#endif

#ifdef LTC_SHA512_224
#ifndef LTC_SHA512
   #error LTC_SHA512 is required for LTC_SHA512_224
#endif
int sha512_224_init(hash_state * md);
#define sha512_224_process sha512_process
int sha512_224_done(hash_state * md, unsigned char *hash);
int sha512_224_test(void);
extern const struct ltc_hash_descriptor sha512_224_desc;
#endif

#ifdef LTC_SHA256
int sha256_init(hash_state * md);
int sha256_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int sha256_done(hash_state * md, unsigned char *hash);
int sha256_test(void);
extern const struct ltc_hash_descriptor sha256_desc;

#ifdef LTC_SHA224
#ifndef LTC_SHA256
   #error LTC_SHA256 is required for LTC_SHA224
#endif
int sha224_init(hash_state * md);
#define sha224_process sha256_process
int sha224_done(hash_state * md, unsigned char *hash);
int sha224_test(void);
extern const struct ltc_hash_descriptor sha224_desc;
#endif
#endif

#ifdef LTC_SHA1
int sha1_init(hash_state * md);
int sha1_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int sha1_done(hash_state * md, unsigned char *hash);
int sha1_test(void);
extern const struct ltc_hash_descriptor sha1_desc;
#endif

#ifdef LTC_BLAKE2S
extern const struct ltc_hash_descriptor blake2s_256_desc;
int blake2s_256_init(hash_state * md);
int blake2s_256_test(void);

extern const struct ltc_hash_descriptor blake2s_224_desc;
int blake2s_224_init(hash_state * md);
int blake2s_224_test(void);

extern const struct ltc_hash_descriptor blake2s_160_desc;
int blake2s_160_init(hash_state * md);
int blake2s_160_test(void);

extern const struct ltc_hash_descriptor blake2s_128_desc;
int blake2s_128_init(hash_state * md);
int blake2s_128_test(void);

int blake2s_init(hash_state * md, unsigned long outlen, const unsigned char *key, unsigned long keylen);
int blake2s_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int blake2s_done(hash_state * md, unsigned char *hash);
#endif

#ifdef LTC_BLAKE2B
extern const struct ltc_hash_descriptor blake2b_512_desc;
int blake2b_512_init(hash_state * md);
int blake2b_512_test(void);

extern const struct ltc_hash_descriptor blake2b_384_desc;
int blake2b_384_init(hash_state * md);
int blake2b_384_test(void);

extern const struct ltc_hash_descriptor blake2b_256_desc;
int blake2b_256_init(hash_state * md);
int blake2b_256_test(void);

extern const struct ltc_hash_descriptor blake2b_160_desc;
int blake2b_160_init(hash_state * md);
int blake2b_160_test(void);

int blake2b_init(hash_state * md, unsigned long outlen, const unsigned char *key, unsigned long keylen);
int blake2b_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int blake2b_done(hash_state * md, unsigned char *hash);
#endif

//#ifdef LTC_MD5
int md5_init(hash_state * md);
int md5_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int md5_done(hash_state * md, unsigned char *hash);
int md5_test(void);
extern const struct ltc_hash_descriptor md5_desc;
//#endif

#ifdef LTC_MD4
int md4_init(hash_state * md);
int md4_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int md4_done(hash_state * md, unsigned char *hash);
int md4_test(void);
extern const struct ltc_hash_descriptor md4_desc;
#endif

#ifdef LTC_MD2
int md2_init(hash_state * md);
int md2_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int md2_done(hash_state * md, unsigned char *hash);
int md2_test(void);
extern const struct ltc_hash_descriptor md2_desc;
#endif

#ifdef LTC_TIGER
int tiger_init(hash_state * md);
int tiger_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int tiger_done(hash_state * md, unsigned char *hash);
int tiger_test(void);
extern const struct ltc_hash_descriptor tiger_desc;
#endif

#ifdef LTC_RIPEMD128
int rmd128_init(hash_state * md);
int rmd128_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int rmd128_done(hash_state * md, unsigned char *hash);
int rmd128_test(void);
extern const struct ltc_hash_descriptor rmd128_desc;
#endif

#ifdef LTC_RIPEMD160
int rmd160_init(hash_state * md);
int rmd160_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int rmd160_done(hash_state * md, unsigned char *hash);
int rmd160_test(void);
extern const struct ltc_hash_descriptor rmd160_desc;
#endif

#ifdef LTC_RIPEMD256
int rmd256_init(hash_state * md);
int rmd256_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int rmd256_done(hash_state * md, unsigned char *hash);
int rmd256_test(void);
extern const struct ltc_hash_descriptor rmd256_desc;
#endif

#ifdef LTC_RIPEMD320
int rmd320_init(hash_state * md);
int rmd320_process(hash_state * md, const unsigned char *in, unsigned long inlen);
int rmd320_done(hash_state * md, unsigned char *hash);
int rmd320_test(void);
extern const struct ltc_hash_descriptor rmd320_desc;
#endif


int find_hash(const char *name);
int find_hash_id(unsigned char ID);
int find_hash_oid(const unsigned long *ID, unsigned long IDlen);
int find_hash_any(const char *name, int digestlen);
int register_hash(const struct ltc_hash_descriptor *hash);
int unregister_hash(const struct ltc_hash_descriptor *hash);
int register_all_hashes(void);
int hash_is_valid(int idx);

//LTC_MUTEX_PROTO(ltc_hash_mutex)

int hash_memory(int hash,
                const unsigned char *in,  unsigned long inlen,
                      unsigned char *out, unsigned long *outlen);
int hash_memory_multi(int hash, unsigned char *out, unsigned long *outlen,
                      const unsigned char *in, unsigned long inlen, ...);

#ifndef LTC_NO_FILE
//int hash_filehandle(int hash, FILE *in, unsigned char *out, unsigned long *outlen);
int hash_file(int hash, const char *fname, unsigned char *out, unsigned long *outlen);
#endif

/* a simple macro for making hash "process" functions */
#define HASH_PROCESS(func_name, compress_name, state_var, block_size)                       \
int func_name (hash_state * md, const unsigned char *in, unsigned long inlen)               \
{                                                                                           \
    unsigned long n;                                                                        \
    int           err;                                                                      \
    LTC_ARGCHK(md != NULL);                                                                 \
    LTC_ARGCHK(in != NULL);                                                                 \
    if (md-> state_var .curlen > sizeof(md-> state_var .buf)) {                             \
       return CRYPT_INVALID_ARG;                                                            \
    }                                                                                       \
    if ((md-> state_var .length + inlen) < md-> state_var .length) {                        \
      return CRYPT_HASH_OVERFLOW;                                                           \
    }                                                                                       \
    while (inlen > 0) {                                                                     \
        if (md-> state_var .curlen == 0 && inlen >= block_size) {                           \
           if ((err = compress_name (md, (unsigned char *)in)) != CRYPT_OK) {               \
              return err;                                                                   \
           }                                                                                \
           md-> state_var .length += block_size * 8;                                        \
           in             += block_size;                                                    \
           inlen          -= block_size;                                                    \
        } else {                                                                            \
           n = MIN(inlen, (block_size - md-> state_var .curlen));                           \
           XMEMCPY(md-> state_var .buf + md-> state_var.curlen, in, (size_t)n);             \
           md-> state_var .curlen += n;                                                     \
           in             += n;                                                             \
           inlen          -= n;                                                             \
           if (md-> state_var .curlen == block_size) {                                      \
              if ((err = compress_name (md, md-> state_var .buf)) != CRYPT_OK) {            \
                 return err;                                                                \
              }                                                                             \
              md-> state_var .length += 8*block_size;                                       \
              md-> state_var .curlen = 0;                                                   \
           }                                                                                \
       }                                                                                    \
    }                                                                                       \
    return CRYPT_OK;                                                                        \
}
