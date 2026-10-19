// Helper kecil untuk membaca nilai dari JSON hasil API secara aman.
//
// Nilai dari backend bisa datang sebagai String, angka, atau null
// tergantung tenant/sekolah. Meng-cast paksa ke String akan melempar
// TypeError, dan karena parsing dilakukan saat map list, satu field yang
// tipenya meleset bisa menggagalkan seluruh response (daftar jadi kosong).

/// Ambil nilai teks pertama yang tersedia dari [keys] (dicek berurutan).
///
/// Nilai dikonversi dengan `toString()` sehingga angka tetap terbaca
/// (mis. NISN `61234567` tetap tampil, tidak error).
/// Mengembalikan `null` kalau semua key absen atau isinya kosong/spasi.
String? readText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}
