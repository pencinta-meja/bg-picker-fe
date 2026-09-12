# ``bg-picker``

Jika ini adalah pertama kali anda melakukan clone atau anda baru saja melakukan pull dari perubahan Secrets ini.. Mohon untuk membuat Secrets.xcconfig yang berisi

```xcconfig
BGG_API_KEY = <Minta pada admin>     
MY_BUNDLE_ID = <Bundle ID milik anda sendiri>
MY_DEVELOPMENT_TEAM = <Team ID milik anda sendiri>
```

Ada baiknya file ini diletak di folder Credentials dan gunakan SecretVariableShow Screen di ViewTest folder untuk melakukan testing secrets api key berhasil terbaca.

## Kenapa Bundle ID dan Team ID ikut di sini

Kita berdua memakai akun **Apple Developer Program Individual**, dan setiap akun individual hanya berisi satu orang — tidak bisa menambahkan anggota tim (hanya akun Organization yang bisa, dan itu butuh D-U-N-S number serta badan usaha resmi).

Masalahnya, satu App ID hanya boleh dimiliki oleh **satu tim** di seluruh Apple. Dulu `PRODUCT_BUNDLE_IDENTIFIER` di-hardcode menjadi `matthew.bg-picker` dan `DEVELOPMENT_TEAM` di-hardcode ke Team ID Matthew. Akibatnya siapa pun selain Matthew akan gagal signing ("Failed to register bundle identifier"), dan setiap kali salah satu dari kita membuka project, Xcode mengubah `project.pbxproj` lagi sehingga sering bentrok saat merge.

Sekarang kedua nilai itu diambil dari `Secrets.xcconfig` yang tidak ikut ter-commit (`*.xcconfig` sudah ada di `.gitignore`). Jadi:

- Setiap developer memakai Bundle ID dan Team ID miliknya sendiri.
- `project.pbxproj` tidak perlu diubah lagi hanya untuk urusan signing.
- Team ID tidak ikut masuk ke repository, sesuai aturan di `AGENTS.md` yang melarang commit data akun developer.

Team ID (10 karakter) bisa dilihat di [developer.apple.com](https://developer.apple.com/account) pada halaman **Membership**.

Kalau `MY_BUNDLE_ID` tidak diisi, nilainya otomatis kembali ke `matthew.bg-picker` supaya project tetap bisa di-compile. Tapi untuk menjalankan di device sendiri, isi dengan Bundle ID anda sendiri (contoh: `com.danniel.bgpicker`).

## Catatan untuk testing Game Center

Mengganti Bundle ID saja belum cukup untuk menjalankan fitur room. Dengan Bundle ID sendiri, anda juga perlu menyiapkan di App Store Connect **akun anda sendiri**:

1. App record baru memakai Bundle ID anda (gratis, tidak perlu submit ke App Store).
2. Game Activity dengan identifier `boardgameroom`, dengan party code aktif, synchronous play, dan range 2–6 pemain. Identifier ini harus sama persis dengan `GameKitManager.activityDefinitionID`.
3. Dua akun Game Center sandbox dan dua device untuk tes multiplayer.

**Penting:** karena app record kita berbeda, Danniel dan Matthew berada di namespace Game Center yang berbeda dan **tidak bisa saling match**. Masing-masing hanya bisa tes multiplayer di dalam build-nya sendiri. Untuk bisa main bareng, keduanya harus berada dalam satu tim Apple Developer yang sama — dan itu tidak mungkin dengan dua akun Individual.

Selama belum ada setup di atas, `GameKitManager` akan berhenti di state `.failed` dengan pesan bahwa activity `boardgameroom` tidak ditemukan. Itu perilaku yang benar, bukan bug.

## Build tanpa signing

Untuk sekadar memastikan code-nya compile (tidak butuh tim, profile, atau Game Center sama sekali), pakai perintah yang ada di `AGENTS.md`:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project bg-picker.xcodeproj \
  -scheme bg-picker \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/bg-picker-derived \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Untuk mengecek nilai Bundle ID dan Team ID anda sudah terbaca dengan benar, ganti `build` menjadi `-showBuildSettings` lalu cari `PRODUCT_BUNDLE_IDENTIFIER` dan `DEVELOPMENT_TEAM`.
