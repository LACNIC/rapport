ta.cer
	A.cer
		A1.roa
		A2.roa
	C.cer			# 2/8
		C1.roa		# 2.1/16
		C2.roa		# 2.2/16
	ta.mft

[node: ta.mft]
obj.content.encapContentInfo.eContent.manifestNumber = 2

[node: C1.roa]
obj.content.encapContentInfo.eContent.ipAddrBlocks = [ 2.1.111.0/24 ]

[node: C2.roa]
obj.content.encapContentInfo.eContent.ipAddrBlocks = [ 202::AAAA:0/112 ]

[notification: https://localhost:8443/multi-step/notification.xml]
serial = 2
