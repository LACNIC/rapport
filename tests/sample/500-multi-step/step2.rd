ta.cer 🛡️
	A.cer 🛡️
		A.roa 🛡️
		A.mft 🛡️
		A.crl 🛡️
	B.cer 🛡️
		B.roa
		B.mft
		B.crl 🛡️
	C.cer 🛡️
		C1.roa 🛡️
		C2.roa
		C.mft
		C.crl 🛡️
	D.cer 🛡️

		D.mft
		D.crl 🛡️
	F.cer
		F.roa
	ta.mft
	ta.crl 🛡️

[node: B.roa]
obj.content.certificates.0.tbsCertificate.extensions.ip.extnValue = [ 2.22.0.0/16, 222::/16 ]

[node: F.cer]
obj.tbsCertificate.extensions.ip.extnValue = [ 6.0.0.0/8, 600::/8 ]
[node: F.roa]
obj.content.certificates.0.tbsCertificate.extensions.ip.extnValue = [ 6.1.0.0/16, 601::/16 ]
