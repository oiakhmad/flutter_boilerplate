// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Flutter Boilerplate';

  @override
  String get navHome => 'Beranda';

  @override
  String get navAccount => 'Akun';

  @override
  String get navSettings => 'Pengaturan';

  @override
  String get homeTitle => 'Beranda';

  @override
  String get homeWelcomeTitle => 'Selamat Datang';

  @override
  String get homeWelcomeMessage =>
      'Ini adalah halaman placeholder. Ganti dengan layar pertamamu yang sesungguhnya.';

  @override
  String get accountTitle => 'Akun';

  @override
  String get accountFieldName => 'Nama';

  @override
  String get accountFieldEmail => 'Email';

  @override
  String accountMemberSince(String date) {
    return 'Bergabung sejak $date';
  }

  @override
  String get accountEditProfile => 'Ubah profil';

  @override
  String get accountChangePhoto => 'Ganti foto';

  @override
  String get accountSave => 'Simpan';

  @override
  String get accountCancel => 'Batal';

  @override
  String get accountUpdateSuccess => 'Profil berhasil diperbarui';

  @override
  String get accountEmptyTitle => 'Belum ada profil';

  @override
  String get accountEmptyMessage => 'Buat profil untuk memulai.';

  @override
  String get accountCreateProfile => 'Buat profil';

  @override
  String get splashWelcomeTitle => 'Selamat Datang';

  @override
  String get splashNameHint => 'Masukkan nama';

  @override
  String get splashNext => 'Lanjut';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsThemeLight => 'Terang';

  @override
  String get settingsThemeDark => 'Gelap';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsLanguageEnglish => 'Inggris';

  @override
  String get settingsLanguageIndonesian => 'Indonesia';

  @override
  String get validationNameRequired => 'Nama wajib diisi';

  @override
  String validationNameTooShort(int min) {
    return 'Nama minimal $min karakter';
  }

  @override
  String get validationEmailRequired => 'Email wajib diisi';

  @override
  String get validationEmailInvalid => 'Masukkan alamat email yang valid';

  @override
  String get errorGenericTitle => 'Terjadi kesalahan';

  @override
  String get errorDatabase =>
      'Tidak dapat mengakses penyimpanan lokal. Silakan coba lagi.';

  @override
  String get errorValidation => 'Mohon perbaiki kolom yang ditandai.';

  @override
  String get errorUnexpected => 'Terjadi kesalahan tak terduga.';

  @override
  String get actionRetry => 'Coba lagi';

  @override
  String get actionOk => 'OK';

  @override
  String get commonLoading => 'Memuat…';

  @override
  String get removeAccountTitle => 'Hapus akun?';

  @override
  String get removeAccountMessage =>
      'Tindakan ini akan menghapus akun dan seluruh data lokal di perangkat ini secara permanen. Tindakan ini tidak dapat dibatalkan.';

  @override
  String removeAccountConfirmLabel(String word) {
    return 'Ketik $word untuk konfirmasi';
  }

  @override
  String get removeAccountConfirmHint => 'Kata konfirmasi';

  @override
  String get removeAccountConfirmWordId => 'HAPUS';

  @override
  String get removeAccountConfirmWordEn => 'DELETE';

  @override
  String get removeAccountConfirmAction => 'Hapus akun';

  @override
  String get removeAccountCancel => 'Batal';

  @override
  String get removeAccountDeleting => 'Menghapus akun…';

  @override
  String get removeAccountSuccess => 'Akun berhasil dihapus';

  @override
  String get removeAccountFailure => 'Akun gagal dihapus. Silakan coba lagi.';

  @override
  String get removeAccountMismatch =>
      'Input tidak sesuai dengan kata konfirmasi';
}
