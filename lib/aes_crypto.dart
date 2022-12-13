import 'dart:convert';
import 'package:cryptography/cryptography.dart';

Future<String> aesEncrypt(String password, List<int> data, {String comment="", int iteration = 48000}) async {
  
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha512(),
    iterations: iteration,
    bits: 256, // 256 bit == 32 bytes
  );

  final salt = SecretKeyData.random(length: 16).bytes;

  final secertKey = await pbkdf2.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: salt,
  );

  // AES-CBC with 256 bit keys
  final encryptAlgorithm = AesCbc.with256bits(
    macAlgorithm: MacAlgorithm.empty
  );
  
  final iv = encryptAlgorithm.newNonce();

  // Encrypt
  final secretBox = await encryptAlgorithm.encrypt(
    data,
    secretKey: secertKey,
    nonce: iv,
  );
  
  final dump = {
    "comment": base64Encode(utf8.encode(comment)),
    "bytes": base64Encode(salt+secretBox.cipherText+secretBox.nonce)
  };
  
  return base64Encode(ascii.encode(jsonEncode(dump)));
}

Future<List<int>> aesDecrypt(String password, String data, {int iteration = 48000}) async {
  try{
    final dump = jsonDecode(ascii.decode(base64Decode(data.replaceAll(RegExp(r'[\n ]'), ""))));
    final bytes = base64Decode(dump["bytes"]);

    final salt = bytes.sublist(0, 16);
    final cipherText = bytes.sublist(16, bytes.length-16);
    final iv = bytes.sublist(bytes.length-16);
    
    final pbkdf2_ = Pbkdf2(
      macAlgorithm: Hmac.sha512(),
      iterations: iteration,
      bits: 256, // 256 bit == 32 bytes
    );

    final secertKey = await pbkdf2_.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    // Splits the bytes into nonce, ciphertext, and MAC.
    final secretBox = SecretBox(cipherText, nonce: iv, mac: Mac.empty);

    final decryptAlgorithm = AesCbc.with256bits(
      macAlgorithm: MacAlgorithm.empty
    );
    
    // Decrypt
    final dataDecrypted = await decryptAlgorithm.decrypt(
      secretBox,
      secretKey: secertKey,
    );
    return dataDecrypted;
  }catch(e){
    return [];
  }
}

String getComment(String data){
  try{
    final dump = jsonDecode(ascii.decode(base64Decode(data.replaceAll(RegExp(r'[\n ]'), ""))));
    return utf8.decode(base64Decode(dump["comment"]));
  }catch(e){
    return "";
  }
}