# 📘 Panduan Deploy Streamlit di Google Colab untuk Tim DEEP

Berikut adalah panduan lengkap untuk men-deploy aplikasi **Streamlit** menggunakan **Google Colab**.  
Tim **DEEP** dapat mengikuti langkah-langkah di bawah ini untuk membuat demo online tanpa setup lokal.

---

## 📋 Prasyarat
1. Akun Google (untuk mengakses Colab)  
2. Akun ngrok gratis 👉 [https://ngrok.com/](https://ngrok.com/)  
3. File `data_uji.csv` yang sudah disiapkan  

---

## 🚀 Langkah-langkah Deployment

### 1. Buka Google Colab dan Buat Notebook Baru
- Buka [https://colab.research.google.com/](https://colab.research.google.com/)  
- Klik **"New Notebook"**  
- Beri nama: `streamlit_deploy.ipynb`  

### 2. Salin dan Jalankan Cell Berikut Secara Berurutan

**Cell 1 - Install Dependencies**
```python
!pip install -q streamlit pyngrok scikit-fuzzy pandas matplotlib
```

**Cell 2 - Setup Ngrok Authtoken**

```python
from pyngrok import ngrok

# Ganti dengan token ngrok Anda
NGROK_AUTH_TOKEN = "YOUR_NGROK_AUTHTOKEN_HERE"
ngrok.set_auth_token(NGROK_AUTH_TOKEN)
```

**Cell 3 - Buat Aplikasi Streamlit**

```python
%%writefile app.py
# isi lengkap script app.py ada di sini
# (kode aplikasi fuzzy + UI Streamlit dari panduan)
```

**Cell 4 - Jalankan Streamlit dan Ngrok**

```python
from pyngrok import ngrok
import subprocess, threading, time

def run_streamlit():
    !streamlit run app.py --server.port 8501 --server.headless true

thread = threading.Thread(target=run_streamlit, daemon=True)
thread.start()

time.sleep(5)
public_url = ngrok.connect(8501, "http")
print(f"🌐 Public URL: {public_url}")
```

**Cell 5 - Berhentikan Aplikasi (Opsional)**

```python
from pyngrok import ngrok
ngrok.kill()
print("❌ Ngrok tunnel dihentikan")
```

---

## 📸 Checklist untuk Tim DEEP

* [ ] Daftar akun ngrok dan dapatkan authtoken
* [ ] Ganti `YOUR_NGROK_AUTHTOKEN_HERE` dengan token ngrok asli
* [ ] Jalankan semua cell secara berurutan
* [ ] Buka URL publik di browser
* [ ] Test prediksi manual dengan slider
* [ ] Upload `data_uji.csv` dan verifikasi hasil prediksi
* [ ] Screenshot untuk laporan:

  * Tampilan utama aplikasi
  * Hasil prediksi manual
  * Hasil evaluasi batch dengan MSE
  * Grafik perbandingan

---

## ⚠️ Catatan Penting

1. URL ngrok bersifat **sementara** (berubah tiap run).
2. Aplikasi berhenti jika notebook ditutup.
3. Untuk deploy permanen gunakan **Streamlit Cloud / Render / Heroku**.
4. Jangan commit token ngrok ke repo publik.

---

## 🆘 Troubleshooting

* Error `Address already in use` → Restart runtime Colab.
* Tidak bisa diakses → pastikan Cell 4 sukses.
* MSE tidak muncul → cek header CSV (`Suhu, Baterai, Pemakaian, ActualRisk`).

---

✍️ Dengan panduan ini, Tim **DEEP** bisa membuat demo online yang dapat diakses dari mana saja tanpa setup lokal yang rumit.

---

👉 Tinggal kamu simpan jadi `Panduan_Streamlit_Colab.md` di repo/project.  
Mau saya rapikan sekalian dengan **versi laporan PDF** (judul, daftar isi, isi panduan, checklist, space untuk screenshot) biar bisa langsung kamu submit juga?
