// Stub cho non-web — không bao giờ được gọi vì secure_storage check kIsWeb trước.
// Tồn tại chỉ để conditional import compile trên mobile.
class LocalWebStorage {
  String? read(String key) => null;
  void write(String key, String value) {}
  void remove(String key) {}
}

LocalWebStorage get webStorage => LocalWebStorage();
