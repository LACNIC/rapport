ta.cer
	A.cer
		A.roa
	B.cer
		B.roa
	C.cer
		C1.roa
		C2.roa
	D.cer

	F.cer
		F.roa
	ta.mft

[node: ta.mft]
obj.content.encapContentInfo.eContent.manifestNumber = 2

[node: B.roa]
obj.content.certificates.0.tbsCertificate.extensions.ip.extnValue = [ 2.22.0.0/16, 222::/16 ]

[node: F.cer]
obj.tbsCertificate.extensions.ip.extnValue = [ 6.0.0.0/8, 600::/8 ]
[node: F.roa]
obj.content.certificates.0.tbsCertificate.extensions.ip.extnValue = [ 6.1.0.0/16, 601::/16 ]

[notification: https://localhost:8443/500-multi-step/notification.xml]
serial = 2
