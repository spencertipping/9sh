#include "biscuit_auth.h"
#include <sodium.h>
#include <set>
#include <sstream>

namespace
{


static St e_ = "";

void set_e(Stc &s) { e_ = s; }


}


struct KeyPair
{
  std::vector<u8> pk_;
  std::vector<u8> sk_;
};

struct PublicKey
{
  std::vector<u8> pk_;
};

struct BiscuitBuilder
{
  std::vector<St> f_;
  std::vector<St> r_;
  std::vector<St> c_;
};

struct Biscuit
{
  std::vector<St> f_;
  std::vector<St> r_;
  std::vector<St> c_;
  St              s_;
  St              p_;
};

struct AuthorizerBuilder
{
  std::vector<St> f_;
  std::vector<St> r_;
  std::vector<St> c_;
  std::vector<St> p_;
};

struct Authorizer
{
  std::vector<St> f_;
  std::vector<St> r_;
  std::vector<St> c_;
  std::vector<St> p_;
};


extern "C" {

KeyPair *biscuit_key_pair_new(u8c *seed, uN seed_len, SignatureAlgorithm algo)
{
  if (sodium_init() < 0) { let e = St("sodium_init failed"); set_e(e); return nullptr; }
  if (algo != Ed25519) { let e = St("algo != Ed25519"); set_e(e); return nullptr; }
  if (seed_len != crypto_sign_SEEDBYTES) { let e = St("bad seed length"); set_e(e); return nullptr; }

  let kp = new KeyPair();
  kp->pk_.resize(crypto_sign_PUBLICKEYBYTES);
  kp->sk_.resize(crypto_sign_SECRETKEYBYTES);

  crypto_sign_seed_keypair(kp->pk_.data(), kp->sk_.data(), seed);
  return kp;
}

PublicKey *biscuit_key_pair_public(KeyPair const *k)
{
  if (!k) { let e = St("bad kp"); set_e(e); return nullptr; }

  let p = new PublicKey();
  p->pk_ = k->pk_;
  return p;
}

void biscuit_key_pair_free(KeyPair *k)
{
  delete k;
}

void biscuit_public_key_free(PublicKey *p)
{
  delete p;
}

BiscuitBuilder *biscuit_builder()
{
  return new BiscuitBuilder();
}

bool biscuit_builder_add_fact(BiscuitBuilder *b, chc *f)
{
  if (!b) return false;
  b->f_.push_back(f);
  return true;
}

bool biscuit_builder_add_rule(BiscuitBuilder *b, chc *r)
{
  if (!b) return false;
  b->r_.push_back(r);
  return true;
}

bool biscuit_builder_add_check(BiscuitBuilder *b, chc *c)
{
  if (!b) return false;
  b->c_.push_back(c);
  return true;
}

Biscuit *biscuit_builder_build(BiscuitBuilder const *b, KeyPair const *k, u8c *seed, uN seed_len)
{
  if (!b || !k) { let e = St("bad builder/key"); set_e(e); return nullptr; }

  std::ostringstream o;
  for (let &f : b->f_) o << "F:" << f << "\n";
  for (let &r : b->r_) o << "R:" << r << "\n";
  for (let &c : b->c_) o << "C:" << c << "\n";
  let p = o.str();

  std::vector<u8> sig(crypto_sign_BYTES);
  unsigned long long sig_len = 0;

  if (crypto_sign_detached(sig.data(), &sig_len, (u8c*)p.data(), p.size(), k->sk_.data()) != 0)
  {
    let e = St("sign fail"); set_e(e); return nullptr;
  }

  let t = new Biscuit();
  t->f_ = b->f_;
  t->r_ = b->r_;
  t->c_ = b->c_;
  t->p_ = p;
  t->s_ = St((chc*)sig.data(), sig_len);
  return t;
}

void biscuit_builder_free(BiscuitBuilder *b)
{
  delete b;
}

void biscuit_free(Biscuit *b)
{
  delete b;
}

AuthorizerBuilder *biscuit_authorizer_builder()
{
  return new AuthorizerBuilder();
}

bool biscuit_authorizer_builder_add_fact(AuthorizerBuilder *b, chc *f)
{
  if (!b) return false;
  b->f_.push_back(f);
  return true;
}

bool biscuit_authorizer_builder_add_rule(AuthorizerBuilder *b, chc *r)
{
  if (!b) return false;
  b->r_.push_back(r);
  return true;
}

bool biscuit_authorizer_builder_add_check(AuthorizerBuilder *b, chc *c)
{
  if (!b) return false;
  b->c_.push_back(c);
  return true;
}

bool biscuit_authorizer_builder_add_policy(AuthorizerBuilder *b, chc *p)
{
  if (!b) return false;
  b->p_.push_back(p);
  return true;
}

Authorizer *biscuit_authorizer_builder_build(AuthorizerBuilder *b, Biscuit const *t)
{
  if (!b || !t) { let e = St("bad auth/token"); set_e(e); return nullptr; }

  let a = new Authorizer();
  a->f_ = b->f_;
  a->r_ = b->r_;
  a->c_ = b->c_;
  a->p_ = b->p_;

  for (let &f : t->f_) a->f_.push_back(f);
  for (let &r : t->r_) a->r_.push_back(r);
  for (let &c : t->c_) a->c_.push_back(c);

  return a;
}

void biscuit_authorizer_builder_free(AuthorizerBuilder *b)
{
  delete b;
}

bool biscuit_authorizer_authorize(Authorizer *a)
{
  if (!a) { let e = St("null auth"); set_e(e); return false; }

  std::set<St> fs(a->f_.begin(), a->f_.end());

  bool ok = false;
  for (let &p : a->p_)
  {
    if (p.find("allow if ") == 0)
    {
      let cond = p.substr(9);
      if (fs.count(cond))
      {
        ok = true;
        break;
      }
    }
  }

  if (!ok) { let e = St("policy failed"); set_e(e); return false; }
  return true;
}

void biscuit_authorizer_free(Authorizer *a)
{
  delete a;
}

chc *biscuit_error_message()
{
  return e_.c_str();
}

} // extern "C"
