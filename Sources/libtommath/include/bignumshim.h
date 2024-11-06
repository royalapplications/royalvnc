#ifndef bignumshim_h
#define bignumshim_h

#include <stdlib.h>
#include "tommath.h"

typedef mp_int BIGNUM;

BIGNUM* BN_new(void);
void BN_init(BIGNUM *a);
int BN_is_zero(const BIGNUM *a);
int BN_bn2bin(const BIGNUM *a, unsigned char *b);
BIGNUM* BN_bin2bn(const uint8_t *data, int len, BIGNUM *ret);
int BN_rand_range(BIGNUM *rnd, BIGNUM *range);
int BN_num_bytes(const BIGNUM *a);
int BN_num_bits(const BIGNUM *a);
void BN_free(BIGNUM *a);
int BN_mod_exp(BIGNUM *Y, BIGNUM *G, BIGNUM *X, BIGNUM *P);

#endif /* bignumshim_h */
