import PiperPhonemizeC

let version = String(cString: PiperPhonemizeGetVersionStr())
print("piper-phonemize version: \(version)")
