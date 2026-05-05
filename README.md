## Struktur Board Game Picker Repository (SwiftUI)

### Model 
Semua mengenai template/struktur data akan diletak pada direktori ini

- RemoteModel akan berisi struct/class yang menyimpan data yang diambil dari BE server
Cek this: [How to use Decodable to turn Json into Struct type](https://www.youtube.com/watch?v=LoRhAEf050E)

- Entities akan berisi struct/class yang hanya dipergunakan dalam ranah aplikasi saja (Tidak terintegrasi dengan BE)

### View
Screen & Component disimpan disini. Semua yang berhubungan dengan View. 

- Screen mendefinisikan 1 screen, beri nama yang baik dengan suffix Screen seperti HomeScreen, HostScreen, etc

- Component mendefinisikan komponen yang sering dipakai. Misalnya button, anda bisa mendefinisikan custom function yang mengenerate button dengan parameter yang dapat di ubah-ubah sesuai kebutuhan

### Design System
Untuk sementara, typography saja yang masuk disini. Untuk color dan image bisa dimasukkan ke asset Xcode dulu :3

### Services & & Networking
WebSocket, guest session, room logic (We will se as we fck up)
