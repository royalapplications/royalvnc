#include "bignumshim.h"

static void bn_reverse(unsigned char* s, int len) {
	int     ix, iy;
	unsigned char t;
	
	ix = 0;
	iy = len - 1;
	
	while (ix < iy) {
		t     = s[ix];
		s[ix] = s[iy];
		s[iy] = t;
		++ix;
		--iy;
	}
}

BIGNUM* BN_bin2bn(const uint8_t* data, int len, BIGNUM* ret) {
	if (data == NULL) {
		return BN_new();
	}
	
	if (ret == NULL) {
		ret = BN_new();
	}
	
	return (mp_read_unsigned_bin(ret, data, len) == MP_OKAY)
		? ret
		: NULL;
}

int BN_bn2bin(const BIGNUM* a, unsigned char* b) {
	BIGNUM	t;
	int    	x;

	if (a == NULL ||
		b == NULL) {
		return -1;
	}
	
	if (mp_init_copy (&t, a) != MP_OKAY) {
		return -1;
	}
	
	for (x = 0; !BN_is_zero(&t) ; ) {
		b[x++] = (unsigned char) (t.dp[0] & 0xff);
		if (mp_div_2d (&t, 8, &t, NULL) != MP_OKAY) {
			mp_clear(&t);
			return -1;
		}
	}
	
	bn_reverse(b, x);
	mp_clear(&t);
	
	return x;
}

void BN_init(BIGNUM* a) {
	if (a != NULL) {
		mp_init(a);
	}
}

BIGNUM* BN_new(void) {
	BIGNUM* a;
	
	if ((a = malloc(1 * sizeof(*a))) != NULL) {
		mp_init(a);
	}
	
	return a;
}

int BN_is_zero(const BIGNUM* a) {
	return mp_iszero(a);
}

int BN_rand_range(BIGNUM* rnd, BIGNUM* range) {
	if (rnd == NULL ||
		range == NULL ||
		BN_is_zero(range)) {
		return 0;
	}
	
	if (mp_rand(rnd, BN_num_bits(range)) != MP_OKAY) {
		return MP_ERR;
	}
	
	return mp_mod(rnd, range, rnd) == MP_OKAY;
}

int BN_num_bytes(const BIGNUM* a) {
	if (a == NULL) {
		return MP_VAL;
	}
	
	return mp_unsigned_bin_size(a);
}

int BN_num_bits(const BIGNUM* a) {
	if (a == NULL) {
		return 0;
	}
	
	return mp_count_bits(a);
}

void BN_free(BIGNUM *a) {
	if (a) {
		mp_clear(a);
	}
}

int BN_mod_exp(BIGNUM* Y, BIGNUM* G, BIGNUM* X, BIGNUM* P) {
	if (Y == NULL ||
		G == NULL ||
		X == NULL ||
		P == NULL) {
		return MP_VAL;
	}
	
	return mp_exptmod(G, X, P, Y) == MP_OKAY;
}
