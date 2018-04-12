convert: convert.c generated
	gcc -I generated -o $@ $< generated/*.c

generated: rfc3279.asn rfc5915.asn
	mkdir -p $@
	asn1c -D generated $^

