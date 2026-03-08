#pragma once
#include "base.h"

#ifdef __cplusplus
extern "C" {
#endif

struct KeyPair;
struct PublicKey;
struct BiscuitBuilder;
struct Biscuit;
struct AuthorizerBuilder;
struct Authorizer;

enum SignatureAlgorithm
{
  Ed25519 = 0
};

struct KeyPair           *biscuit_key_pair_new                 (u8c *seed, uN seed_len, SignatureAlgorithm algo);
struct PublicKey         *biscuit_key_pair_public              (KeyPair const *kp);
void                      biscuit_key_pair_free                (KeyPair *kp);
void                      biscuit_public_key_free              (PublicKey *pub);

struct BiscuitBuilder    *biscuit_builder                      (void);
bool                      biscuit_builder_add_fact             (BiscuitBuilder *b, chc *f);
bool                      biscuit_builder_add_rule             (BiscuitBuilder *b, chc *r);
bool                      biscuit_builder_add_check            (BiscuitBuilder *b, chc *c);
struct Biscuit           *biscuit_builder_build                (BiscuitBuilder const *b, KeyPair const *kp, u8c *seed, uN seed_len);
void                      biscuit_builder_free                 (BiscuitBuilder *b);

void                      biscuit_free                         (Biscuit *b);

struct AuthorizerBuilder *biscuit_authorizer_builder           (void);
bool                      biscuit_authorizer_builder_add_fact  (AuthorizerBuilder *b, chc *f);
bool                      biscuit_authorizer_builder_add_rule  (AuthorizerBuilder *b, chc *r);
bool                      biscuit_authorizer_builder_add_check (AuthorizerBuilder *b, chc *c);
bool                      biscuit_authorizer_builder_add_policy(AuthorizerBuilder *b, chc *p);
struct Authorizer        *biscuit_authorizer_builder_build     (AuthorizerBuilder *b, Biscuit const *token);
void                      biscuit_authorizer_builder_free      (AuthorizerBuilder *b);

bool                      biscuit_authorizer_authorize         (Authorizer *a);
void                      biscuit_authorizer_free              (Authorizer *a);

chc                      *biscuit_error_message                (void);

#ifdef __cplusplus
}
#endif
