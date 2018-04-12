#include <assert.h>
#include <unistd.h>

#include <asn_codecs.h>
#include <ECPrivateKey.h>

#define KEY_BUF_SIZE 100
#define OUT_BUF_SIZE 10000

int main() {
    char pk[KEY_BUF_SIZE];
    ssize_t pks = read(0, pk, KEY_BUF_SIZE);
    assert(pks != KEY_BUF_SIZE);

    fprintf(stderr, "keysize: %d\n", pks);

    ECPrivateKey_t* p = (ECPrivateKey_t*)calloc(sizeof(*p), 1);
    p->version = 1;

    int ret;
    ret = OCTET_STRING_fromBuf(&p->privateKey, pk, pks);
    assert(ret == 0);

    p->parameters =
        (struct EcpkParameters*)calloc(sizeof(struct EcpkParameters), 1);
    p->parameters->present = EcpkParameters_PR_namedCurve;

    int oid[] = {1,3,132,0,10};
    ret = OBJECT_IDENTIFIER_set_arcs(
        &p->parameters->choice,
        oid, sizeof(oid) / sizeof(oid[0]));
    assert(ret == 0);
    
    char buf[OUT_BUF_SIZE];
    asn_enc_rval_t er =
        der_encode_to_buffer(&asn_DEF_ECPrivateKey, p,
                             buf, OUT_BUF_SIZE);
    assert(er.encoded >= 0);

    ssize_t w = write(1, buf, er.encoded);
    assert(w >= 0);

    return 0;
}
