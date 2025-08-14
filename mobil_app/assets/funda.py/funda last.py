# Gerekli kütüphaneleri içe aktarın
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from base64 import urlsafe_b64encode
import os
import shutil
import platform
import datetime
from ttkbootstrap import Style
import threading # İş parçacığı (threading) kütüphanesini içe aktardık
from pynput import keyboard, mouse # Klavye ve fare dinleme için
import time
import pygetwindow as gw # Aktif pencereyi kontrol etmek için

# Ana uygulama sınıfı
class FundaApp:
    def __init__(self, master):
        self.master = master
        master.title("Funda App - Dosya ve Klasör Şifreleme")
        master.geometry("1000x650")
        master.minsize(800, 500)
        
        self.current_theme = "darkly"
        self.style = Style(theme=self.current_theme)
        
        # Varsayılan TButton stilini daha modern hale getirelim
        self.style.configure("TButton", font=("Verdana", 12), padding=10)
        self.style.configure("TFrame", padding=20)
        
        self.menu_visible = True
        self.is_recording = False
        self.log_kayitlari = []
        self.encryption_password = None
        self.secilen_yol = None
        self.log_kutusu = None
        self.is_operation_running = False # Yeni: İşlemin devam edip etmediğini takip eden bir değişken
        
        # Loglama ile ilgili yeni değişkenler
        self.keyboard_listener = None
        self.mouse_listener = None
        self.window_check_thread = None
        self.pressed_keys = set()
        self.last_active_window = ""
        self.log_output = None # Log kaydedici sayfasındaki Text widget'ı

        # Uygulama başladığında ilk olarak parola giriş ekranını göster
        self.create_login_screen()

    def create_login_screen(self):
        # Parola giriş ekranı için bir ana çerçeve oluştur
        self.login_frame = ttk.Frame(self.master, style="TFrame")
        self.login_frame.pack(fill=tk.BOTH, expand=True)

        title_label = ttk.Label(self.login_frame, text="🔑 Funda App'e Hoş Geldiniz",
                                 font=("Verdana", 24, "bold"), foreground=self.style.colors.get("info"))
        title_label.pack(pady=(50, 20))

        label = ttk.Label(self.login_frame, text="Lütfen parola girerek devam edin:",
                                 font=("Verdana", 14), foreground=self.style.colors.get("fg"))
        label.pack(pady=10)

        self.password_entry = ttk.Entry(self.login_frame, show="*", width=35, font=("Verdana", 12))
        self.password_entry.pack(pady=5)
        self.password_entry.bind("<Return>", lambda event: self.check_password())

        # Parola yanlışsa hata mesajını göstermek için bir etiket
        self.error_label = ttk.Label(self.login_frame, text="", foreground="red", font=("Verdana", 10))
        self.error_label.pack(pady=5)
        
        button_frame = ttk.Frame(self.login_frame)
        button_frame.pack(pady=20)
        
        ok_button = ttk.Button(button_frame, text="Giriş", command=self.check_password)
        ok_button.pack(side=tk.LEFT, padx=5)
        
        cancel_button = ttk.Button(button_frame, text="Çıkış", command=self.master.quit)
        cancel_button.pack(side=tk.LEFT, padx=5)

        self.password_entry.focus_set()

    def check_password(self):
        # Girilen parolayı kontrol et
        if self.password_entry.get() == "funda80":
            # Doğruysa giriş ekranını yok et ve ana uygulamayı oluştur
            self.encryption_password = self.password_entry.get()
            self.login_frame.destroy()
            self.create_main_app_interface()
        else:
            # Yanlışsa hata mesajı göster ve parolayı temizle
            self.error_label.config(text="Hatalı parola! Lütfen tekrar deneyin.")
            self.password_entry.delete(0, tk.END)
            self.password_entry.focus_set()

    def create_main_app_interface(self):
        # Ana uygulamanın arayüzünü oluştur
        self.menu_frame = ttk.Frame(self.master, width=200, style="bg.TFrame")
        self.menu_frame.pack(side=tk.LEFT, fill=tk.Y)
        
        self.content_frame = ttk.Frame(self.master, style="TFrame")
        self.content_frame.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)

        self.create_menu()
        self.create_content_header()
        self.show_main_screen()
        
    def create_menu(self):
        self.style.configure("bg.TFrame", background=self.style.colors.get("bg"))
        
        menu_title = ttk.Label(self.menu_frame, text="Funda App", font=("Verdana", 18, "bold"),
                                 foreground=self.style.colors.get("info"), background=self.style.colors.get("bg"))
        menu_title.pack(pady=(20, 40), padx=10)

        home_button = ttk.Button(self.menu_frame, text="🏡 Anasayfa", command=self.show_main_screen)
        home_button.pack(fill=tk.X, pady=5, padx=10)
        
        log_recorder_button = ttk.Button(self.menu_frame, text="📝 Log Kaydedici", command=self.show_log_recorder)
        log_recorder_button.pack(fill=tk.X, pady=5, padx=10)
        
        settings_button = ttk.Button(self.menu_frame, text="⚙️ Ayarlar", command=self.show_settings)
        settings_button.pack(fill=tk.X, pady=5, padx=10)
        
        help_button = ttk.Button(self.menu_frame, text="❓ Yardım", command=self.show_help)
        help_button.pack(fill=tk.X, pady=5, padx=10)
        
    def create_content_header(self):
        header_frame = ttk.Frame(self.content_frame, style="TFrame")
        header_frame.pack(fill=tk.X)
        
        self.menu_toggle_button = ttk.Button(header_frame, text="❮", command=self.toggle_menu, padding=5)
        self.menu_toggle_button.pack(side=tk.LEFT, padx=10, pady=10)
    
    def on_resize(self, event):
        # Bu fonksiyon kaldırıldı, çünkü arayüz elemanları zaten pack() ile dinamik olarak konumlanıyor.
        pass

    def toggle_menu(self):
        if self.menu_visible:
            self.menu_frame.pack_forget()
            self.menu_toggle_button.config(text="❯")
        else:
            self.menu_frame.pack(side=tk.LEFT, fill=tk.Y)
            self.menu_toggle_button.config(text="❮")
        self.menu_visible = not self.menu_visible

    def get_log_bg_color(self):
        """Mevcut temaya göre log kutusu arka plan rengini döndürür."""
        if self.current_theme == "darkly":
            return "#1e1e1e" # Koyu tema için koyu gri
        else:
            return "#ffffff" # Açık tema için beyaz

    def toggle_theme(self):
        """Temayı değiştirir."""
        if self.current_theme == "darkly":
            self.current_theme = "yeti"
        else:
            self.current_theme = "darkly"
        self.style.theme_use(self.current_theme)
        
        if self.log_kutusu:
            self.log_kutusu.config(bg=self.get_log_bg_color())
        if self.log_output:
            self.log_output.config(bg=self.get_log_bg_color())

        # Tema değişimini kullanıcıya bildir
        self.show_settings()


    def clear_content_frame(self):
        for widget in self.content_frame.winfo_children():
            # Menü düğmesi hariç diğer tüm widget'ları yok et
            if widget != self.menu_toggle_button.master:
                widget.destroy()

    def show_main_screen(self):
        self.clear_content_frame()
        
        ana_cerceve = ttk.Frame(self.content_frame, padding="40 40 40 40")
        ana_cerceve.pack(fill=tk.BOTH, expand=True)

        baslik = ttk.Label(ana_cerceve, text="Dosya ve Klasör Şifreleme",
                                 font=("Verdana", 26, "bold"), foreground=self.style.colors.get("info"))
        baslik.pack(pady=(0, 40))

        secim_cerceve = ttk.Frame(ana_cerceve)
        secim_cerceve.pack(pady=15)

        self.dosya_sec_buton = ttk.Button(secim_cerceve, text="📂 Dosya Seç", command=self.dosya_sec)
        self.dosya_sec_buton.pack(side=tk.LEFT, padx=15)

        self.klasor_sec_buton = ttk.Button(secim_cerceve, text="📁 Klasör Seç", command=self.klasor_sec)
        self.klasor_sec_buton.pack(side=tk.LEFT, padx=15)
        
        self.durum_etiketi = ttk.Label(ana_cerceve, text="Lütfen şifrelemek veya çözmek için bir dosya veya klasör seçin.",
                                     font=("Verdana", 12), foreground=self.style.colors.get("secondary"))
        self.durum_etiketi.pack(pady=20)
        
        # Yeni: İşlem durumu için bir etiket ekledik
        self.islem_durumu_etiketi = ttk.Label(ana_cerceve, text="", font=("Verdana", 12, "bold"),
                                               foreground=self.style.colors.get("warning"))
        self.islem_durumu_etiketi.pack(pady=(0, 10))

        islem_cerceve = ttk.Frame(ana_cerceve)
        islem_cerceve.pack(pady=30)
        
        self.sifrele_buton = ttk.Button(islem_cerceve, text="🔒 Şifrele", command=self.sifrele, state=tk.DISABLED)
        self.sifrele_buton.pack(side=tk.LEFT, padx=15)

        self.sifre_coz_buton = ttk.Button(islem_cerceve, text="🔓 Şifre Çöz", command=self.sifre_coz, state=tk.DISABLED)
        self.sifre_coz_buton.pack(side=tk.LEFT, padx=15)
        
        self.log_kutusu = tk.Text(ana_cerceve, height=10, state=tk.DISABLED, 
                                     bg=self.get_log_bg_color(), fg=self.style.colors.get("fg"),
                                     font=("Courier New", 11), wrap=tk.WORD, borderwidth=0, relief="flat")
        self.log_kutusu.pack(fill=tk.BOTH, expand=True)

    def show_log_recorder(self):
        self.clear_content_frame()
        
        log_cerceve = ttk.Frame(self.content_frame, padding="40 40 40 40")
        log_cerceve.pack(fill=tk.BOTH, expand=True)
        
        baslik = ttk.Label(log_cerceve, text="Dosya Sistemi Etkinlik Günlüğü", font=("Verdana", 26, "bold"),
                                 foreground=self.style.colors.get("info"))
        baslik.pack(pady=(0, 20))
        
        aciklama = ttk.Label(log_cerceve, text="Sistem etkinliklerini kaydetmek için aşağıdaki düğmeleri kullanın.",
                             font=("Verdana", 12), foreground=self.style.colors.get("secondary"))
        aciklama.pack(pady=(0, 20))

        button_frame = ttk.Frame(log_cerceve)
        button_frame.pack(pady=10)
        
        self.start_button = ttk.Button(button_frame, text="Kaydı Başlat", command=self.start_recording)
        self.start_button.pack(side=tk.LEFT, padx=10)
        
        self.stop_button = ttk.Button(button_frame, text="Kaydı Durdur", command=self.stop_recording, state=tk.DISABLED)
        self.stop_button.pack(side=tk.LEFT, padx=10)

        self.log_status_label = ttk.Label(log_cerceve, text="Kayıt durumu: Durduruldu.", font=("Verdana", 12),
                                             foreground=self.style.colors.get("secondary"))
        self.log_status_label.pack(pady=10)
        
        self.log_output = tk.Text(log_cerceve, height=15, state=tk.DISABLED,
                                     bg=self.get_log_bg_color(), fg=self.style.colors.get("fg"),
                                     font=("Courier New", 11), wrap=tk.WORD, borderwidth=0, relief="flat")
        self.log_output.pack(fill=tk.BOTH, expand=True)


    # --- Şifreleme/Şifre Çözme Metotları (Değişmedi) ---
    def generate_key(self, password):
        """Paroladan anahtar oluşturur."""
        password = password.encode()
        salt = b'bu-sifreleme-icin-ozel-bir-salt' 
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
        )
        return urlsafe_b64encode(kdf.derive(password))

    def sifrele(self):
        # İşlem zaten çalışıyorsa tekrar başlatma
        if self.is_operation_running:
            return

        if not self.secilen_yol:
            messagebox.showwarning("Uyarı", "Lütfen şifrelemek için bir dosya veya klasör seçin.")
            return

        self.is_operation_running = True
        self.islem_durumu_etiketi.config(text="Şifreleme işlemi başlatıldı...")
        self.sifrele_buton.config(state=tk.DISABLED)
        self.sifre_coz_buton.config(state=tk.DISABLED)

        # Threading ile şifreleme işlemini başlat
        sifrele_thread = threading.Thread(target=self._sifrele_thread)
        sifrele_thread.start()

    def _sifrele_thread(self):
        try:
            key = self.generate_key(self.encryption_password)
            f = Fernet(key)
            
            self.log_ekle(f"Şifrelenecek yol: {self.secilen_yol}")
            
            if os.path.isfile(self.secilen_yol):
                self._sifrele_dosya(self.secilen_yol, f)
            else:
                self._sifrele_klasor(self.secilen_yol, f)
                
            self.master.after(0, lambda: self.islem_durumu_etiketi.config(text="Şifreleme işlemi tamamlandı."))
            self.master.after(0, lambda: self.log_ekle("Tüm dosyalar başarıyla şifrelendi."))
        except Exception as e:
            self.master.after(0, lambda: self.islem_durumu_etiketi.config(text="Hata: Şifreleme işlemi başarısız."))
            self.master.after(0, lambda: self.log_ekle(f"Hata: {e}"))
        finally:
            self.master.after(0, lambda: self._islem_tamamlandi())

    def _sifrele_dosya(self, dosya_yolu, f):
        self.log_ekle(f"Dosya şifreleniyor: {os.path.basename(dosya_yolu)}")
        with open(dosya_yolu, "rb") as file:
            dosya_verisi = file.read()
        sifreli_veri = f.encrypt(dosya_verisi)
        with open(dosya_yolu, "wb") as file:
            file.write(sifreli_veri)

    def _sifrele_klasor(self, klasor_yolu, f):
        self.log_ekle(f"Klasör şifreleniyor: {os.path.basename(klasor_yolu)}")
        for kok, _, dosyalar in os.walk(klasor_yolu):
            for dosya in dosyalar:
                dosya_yolu = os.path.join(kok, dosya)
                self._sifrele_dosya(dosya_yolu, f)

    def sifre_coz(self):
        # İşlem zaten çalışıyorsa tekrar başlatma
        if self.is_operation_running:
            return
            
        if not self.secilen_yol:
            messagebox.showwarning("Uyarı", "Lütfen şifre çözmek için bir dosya veya klasör seçin.")
            return

        self.is_operation_running = True
        self.islem_durumu_etiketi.config(text="Şifre çözme işlemi başlatıldı...")
        self.sifrele_buton.config(state=tk.DISABLED)
        self.sifre_coz_buton.config(state=tk.DISABLED)

        # Threading ile şifre çözme işlemini başlat
        sifre_coz_thread = threading.Thread(target=self._sifre_coz_thread)
        sifre_coz_thread.start()

    def _sifre_coz_thread(self):
        try:
            key = self.generate_key(self.encryption_password)
            f = Fernet(key)
            
            self.log_ekle(f"Şifresi çözülecek yol: {self.secilen_yol}")
            
            if os.path.isfile(self.secilen_yol):
                self._sifre_coz_dosya(self.secilen_yol, f)
            else:
                self._sifre_coz_klasor(self.secilen_yol, f)

            self.master.after(0, lambda: self.islem_durumu_etiketi.config(text="Şifre çözme işlemi tamamlandı."))
            self.master.after(0, lambda: self.log_ekle("Tüm dosyaların şifresi başarıyla çözüldü."))
        except Exception as e:
            self.master.after(0, lambda: self.islem_durumu_etiketi.config(text="Hata: Şifre çözme işlemi başarısız. Parolanın doğru olduğundan emin olun."))
            self.master.after(0, lambda: self.log_ekle(f"Hata: {e}"))
        finally:
            self.master.after(0, lambda: self._islem_tamamlandi())

    def _sifre_coz_dosya(self, dosya_yolu, f):
        self.log_ekle(f"Dosyanın şifresi çözülüyor: {os.path.basename(dosya_yolu)}")
        with open(dosya_yolu, "rb") as file:
            sifreli_veri = file.read()
        sifresiz_veri = f.decrypt(sifreli_veri)
        with open(dosya_yolu, "wb") as file:
            file.write(sifresiz_veri)

    def _sifre_coz_klasor(self, klasor_yolu, f):
        self.log_ekle(f"Klasörün şifresi çözülüyor: {os.path.basename(klasor_yolu)}")
        for kok, _, dosyalar in os.walk(klasor_yolu):
            for dosya in dosyalar:
                dosya_yolu = os.path.join(kok, dosya)
                self._sifre_coz_dosya(dosya_yolu, f)

    def _islem_tamamlandi(self):
        self.is_operation_running = False
        self.sifrele_buton.config(state=tk.NORMAL)
        self.sifre_coz_buton.config(state=tk.NORMAL)

    def log_ekle(self, mesaj):
        """Log kutusuna bir mesaj ekler."""
        self.log_kutusu.config(state=tk.NORMAL)
        self.log_kutusu.insert(tk.END, f"[{datetime.datetime.now().strftime('%H:%M:%S')}] {mesaj}\n")
        self.log_kutusu.see(tk.END)
        self.log_kutusu.config(state=tk.DISABLED)

    def dosya_sec(self):
        yol = filedialog.askopenfilename()
        if yol:
            self.secilen_yol = yol
            self.durum_etiketi.config(text=f"Seçilen dosya: {yol}", foreground=self.style.colors.get("primary"))
            self.sifrele_buton.config(state=tk.NORMAL)
            self.sifre_coz_buton.config(state=tk.NORMAL)
            self.log_ekle(f"Dosya seçildi: {os.path.basename(yol)}")

    def klasor_sec(self):
        yol = filedialog.askdirectory()
        if yol:
            self.secilen_yol = yol
            self.durum_etiketi.config(text=f"Seçilen klasör: {yol}", foreground=self.style.colors.get("primary"))
            self.sifrele_buton.config(state=tk.NORMAL)
            self.sifre_coz_buton.config(state=tk.NORMAL)
            self.log_ekle(f"Klasör seçildi: {os.path.basename(yol)}")


    # --- LOG KAYDEDİCİ METOTLARI (YENİ/GÜNCELLENMİŞ) ---
    def add_log_entry_to_recorder(self, entry_text):
        """Log kaydedici arayüzüne log ekler ve belleğe kaydeder."""
        if self.is_recording and self.log_output:
            current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            full_entry = f"[{current_time}] {entry_text}"
            self.log_kayitlari.append(full_entry)

            self.log_output.config(state=tk.NORMAL)
            self.log_output.insert(tk.END, full_entry + "\n")
            self.log_output.see(tk.END)
            self.log_output.config(state=tk.DISABLED)

    def write_logs_to_file(self):
        """Tüm logları bir dosyaya yazar ve kullanıcıyı bilgilendirir."""
        log_directory = os.path.join(os.getcwd(), "log_kayitlari")
        if not os.path.exists(log_directory):
            os.makedirs(log_directory)
            try:
                if platform.system() == "Windows":
                    os.startfile(log_directory)
                elif platform.system() == "Darwin": # macOS
                    subprocess.Popen(["open", log_directory])
                else: # Linux
                    subprocess.Popen(["xdg-open", log_directory])
            except Exception as e:
                pass # Hata durumunda klasörü açma işlemi başarısız olsa da logla
                
        log_dosyasi_adi = os.path.join(log_directory, f"etkinlik_logu_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.txt")
        try:
            with open(log_dosyasi_adi, "w", encoding="utf-8") as f:
                f.write(f"--- Log Kaydı: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ---\n\n")
                for log in self.log_kayitlari:
                    f.write(log + "\n")
            messagebox.showinfo("Kayıt Tamamlandı", f"Etkinlik logu başarıyla '{log_dosyasi_adi}' dosyasına kaydedildi.")
        except Exception as e:
            messagebox.showerror("Hata", f"Log dosyası kaydedilirken bir hata oluştu: {e}")
        
    def on_key_press(self, key):
        """Klavye tuş basım olayını işler ve arayüzü günceller."""
        try:
            if key == keyboard.Key.f5:
                self.master.after(0, self.stop_recording)
                return

            if hasattr(key, 'char') and key.char is not None:
                char = key.char
                if self.pressed_keys:
                    modifiers = ' + '.join([str(k).split('.')[-1].capitalize() for k in self.pressed_keys])
                    log_entry = f"Klavye: '{modifiers} + {char}' kombinasyonu basıldı."
                else:
                    log_entry = f"Klavye: Tuş basıldı: '{char}'"
                self.master.after(0, lambda: self.add_log_entry_to_recorder(log_entry))

            else:
                key_name = str(key).split('.')[-1]
                if key not in self.pressed_keys:
                    log_entry = f"Klavye: Tuş basıldı: '[{key_name.capitalize()}]'"
                    self.master.after(0, lambda: self.add_log_entry_to_recorder(log_entry))

        except Exception as e:
            self.master.after(0, lambda: self.add_log_entry_to_recorder(f"Hata: Klavye olayını işleme hatası: {e}"))

    def on_key_release(self, key):
        """Klavye tuş bırakma olayını işler."""
        if key in self.pressed_keys:
            self.pressed_keys.remove(key)

    def on_mouse_click(self, x, y, button, pressed):
        """Fare tıklama olayını işler ve arayüzü günceller."""
        if pressed:
            log_entry = f"Fare: Tıklama: {button} tuşu ({x}, {y}) koordinatlarında basıldı."
            self.master.after(0, lambda: self.add_log_entry_to_recorder(log_entry))

    def check_active_window(self):
        """Aktif pencereyi kontrol eder ve değişirse loglar."""
        while self.is_recording:
            try:
                active_window = gw.getActiveWindow()
                if active_window and active_window.title and active_window.title != self.last_active_window:
                    self.last_active_window = active_window.title
                    log_entry = f"Etkin Pencere Değişti: {self.last_active_window}"
                    self.master.after(0, lambda: self.add_log_entry_to_recorder(log_entry))
            except Exception as e:
                pass 
            time.sleep(1)


    def start_recording(self):
        """Kayıt işlemini başlatır."""
        if self.is_recording:
            return

        self.is_recording = True
        self.log_kayitlari = []
        
        # Log kaydedici arayüzündeki butonları güncelle
        self.start_button.config(state=tk.DISABLED)
        self.stop_button.config(state=tk.NORMAL)
        self.log_status_label.config(text="Kayıt durumu: Kaydediliyor...", foreground="green")
        self.add_log_entry_to_recorder("Kayıt başlatıldı.")
        
        # Ana pencereyi gizle
        self.master.withdraw()  

        # Dinleyicileri ve thread'leri başlat
        self.keyboard_listener = keyboard.Listener(on_press=self.on_key_press, on_release=self.on_key_release)
        self.mouse_listener = mouse.Listener(on_click=self.on_mouse_click)
        self.window_check_thread = threading.Thread(target=self.check_active_window, daemon=True)
        
        self.keyboard_listener.start()
        self.mouse_listener.start()
        self.window_check_thread.start()
        
    def stop_recording(self):
        """Kayıt işlemini durdurur ve logları dosyaya kaydeder."""
        if not self.is_recording:
            return

        self.is_recording = False
        
        # Gizlenen pencereyi tekrar görünür yap
        self.master.deiconify() 
        
        # Log kaydedici arayüzündeki butonları güncelle
        self.start_button.config(state=tk.NORMAL)
        self.stop_button.config(state=tk.DISABLED)
        self.log_status_label.config(text="Kayıt durumu: Durduruldu.", foreground="red")
        
        # Dinleyicileri ve thread'i durdur
        if self.keyboard_listener and self.keyboard_listener.is_alive():
            self.keyboard_listener.stop()
        if self.mouse_listener and self.mouse_listener.is_alive():
            self.mouse_listener.stop()

        self.add_log_entry_to_recorder("Kayıt durduruldu.")
        self.write_logs_to_file()
        self.master.destroy() # Uygulamayı tamamen sonlandırır

    def show_settings(self):
        self.clear_content_frame()
        ayarlar_cerceve = ttk.Frame(self.content_frame, padding="40 40 40 40")
        ayarlar_cerceve.pack(fill=tk.BOTH, expand=True)
        baslik = ttk.Label(ayarlar_cerceve, text="Ayarlar", font=("Verdana", 26, "bold"), foreground=self.style.colors.get("info"))
        baslik.pack(pady=(0, 40))
        tema_etiketi = ttk.Label(ayarlar_cerceve, text="Uygulama Teması:", font=("Verdana", 14))
        tema_etiketi.pack(pady=(0, 10))
        tema_butonu = ttk.Button(ayarlar_cerceve, text=f"Temayı Değiştir ({'Koyu' if self.current_theme == 'darkly' else 'Açık'})", command=self.toggle_theme)
        tema_butonu.pack()

    def show_help(self):
        self.clear_content_frame()
        yardim_cerceve = ttk.Frame(self.content_frame, padding="40 40 40 40")
        yardim_cerceve.pack(fill=tk.BOTH, expand=True)
        baslik = ttk.Label(yardim_cerceve, text="Yardım", font=("Verdana", 26, "bold"), foreground=self.style.colors.get("info"))
        baslik.pack(pady=(0, 40))
        destek_etiketi = ttk.Label(yardim_cerceve, text="Destek için:", font=("Verdana", 14))
        destek_etiketi.pack(pady=(0, 5))
        email_etiketi = ttk.Label(yardim_cerceve, text="halicalix@gmail.com", font=("Verdana", 12))
        email_etiketi.pack()

if __name__ == "__main__":
    # Gerekli kütüphaneleri kurun:
    # Terminalde/Komut İsteminde 'pip install pynput pygetwindow ttkbootstrap' komutunu çalıştırın.
    
    root = tk.Tk()
    app = FundaApp(root)
    root.protocol("WM_DELETE_WINDOW", app.stop_recording)
    root.mainloop()

