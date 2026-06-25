ta.cer 🛡️
	A.cer 🛡️
		A1.roa 🛡️
		A2.roa 🛡️
		A.mft 🛡️
		A.crl 🛡️
	C.cer			# 2/8
		C1.roa		# 2.1/16
		C2.roa		# 2.2/16
	ta.mft
	ta.crl 🛡️

[node: C1.roa]
obj.content.encapContentInfo.eContent.ipAddrBlocks = [ 2.1.111.0/24 ]

[node: C2.roa]
obj.content.encapContentInfo.eContent.ipAddrBlocks = [ 202::AAAA:0/112 ]

[notification: https://localhost:8443/$TEST/notification.xml]
session = cafe-2
serial = 1
