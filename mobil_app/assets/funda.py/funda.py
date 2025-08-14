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
        
        # Klavye olaylarını dinle
        self.master.bind("<Key>", self.klavye_kaydi_yap)

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
        
        aciklama = ttk.Label(log_cerceve, text="Aşağıdaki dosya ve klasör ağacına tıklayarak veya klavyenizle gezerek logları kaydedin.",
                             font=("Verdana", 12), foreground=self.style.colors.get("secondary"))
        aciklama.pack(pady=(0, 20))

        button_frame = ttk.Frame(log_cerceve)
        button_frame.pack(pady=10)
        
        self.start_button = ttk.Button(button_frame, text="Kayda Başla!", command=self.start_recording)
        self.start_button.pack(side=tk.LEFT, padx=10)
        
        self.stop_button = ttk.Button(button_frame, text="Kaydı Durdur!", command=self.stop_recording, state=tk.DISABLED)
        self.stop_button.pack(side=tk.LEFT, padx=10)

        self.log_status_label = ttk.Label(log_cerceve, text="Kayıt durumu: Durduruldu.", font=("Verdana", 12),
                                             foreground=self.style.colors.get("secondary"))
        self.log_status_label.pack(pady=10)
        
        # PanedWindow ile iki ayrı panel oluştur
        paned_window = ttk.PanedWindow(log_cerceve, orient=tk.HORIZONTAL)
        paned_window.pack(fill=tk.BOTH, expand=True)

        # Sol panel: Dosya Ağacı
        file_tree_frame = ttk.Frame(paned_window, padding=10)
        paned_window.add(file_tree_frame, weight=1)

        ttk.Label(file_tree_frame, text="Klasörler ve Dosyalar", font=("Verdana", 16, "bold")).pack(pady=(0, 10))

        # Dosya ağacı için Treeview widget'ı
        self.file_tree = ttk.Treeview(file_tree_frame, show="tree", selectmode="browse")
        self.file_tree.pack(fill=tk.BOTH, expand=True)

        # Ağacı doldur
        self.file_tree.heading("#0", text="Dosyalar", anchor=tk.W)
        self.populate_file_tree()
        self.file_tree.bind("<<TreeviewSelect>>", self.on_tree_select)
        
        # Sağ panel: Log Çıktısı
        log_output_frame = ttk.Frame(paned_window, padding=10)
        paned_window.add(log_output_frame, weight=1)
        
        ttk.Label(log_output_frame, text="Olay Günlüğü", font=("Verdana", 16, "bold")).pack(pady=(0, 10))
        
        self.log_output = tk.Text(log_output_frame, height=15, state=tk.DISABLED,
                                     bg=self.get_log_bg_color(), fg=self.style.colors.get("fg"),
                                     font=("Courier New", 11), wrap=tk.WORD, borderwidth=0, relief="flat")
        self.log_output.pack(fill=tk.BOTH, expand=True)

    def populate_file_tree(self):
        # Örnek dosya ve klasör yapısı
        folders_and_files = {
            "📂 Dokümanlar": {
                "📄 Rapor.docx": None,
                "📄 Sunum.pptx": None
            },
            "📂 Fotoğraflar": {
                "📂 Tatil": {
                    "🖼️ plaj.jpg": None,
                    "🖼️ dağ.jpg": None
                },
                "🖼️ profil.png": None
            },
            "📄 README.md": None
        }

        self._insert_tree_items(self.file_tree, "", folders_and_files)

    def _insert_tree_items(self, tree, parent_id, items):
        for item, children in items.items():
            new_item_id = tree.insert(parent_id, "end", text=item, open=False, tags=("folder" if children else "file",))
            if children:
                self._insert_tree_items(tree, new_item_id, children)

    def on_tree_select(self, event):
        if not self.is_recording:
            return
            
        selected_item_id = self.file_tree.focus()
        if selected_item_id:
            item_text = self.file_tree.item(selected_item_id, "text")
            item_tags = self.file_tree.item(selected_item_id, "tags")
            
            item_type = "Klasör" if "folder" in item_tags else "Dosya"
            log_entry = f"Fare Tıklaması: '{item_text}' ({item_type}) öğesine tıklandı."
            self.log_kayitlari.append(f"[{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Arayüz: {log_entry}")
            
            self.log_output.config(state=tk.NORMAL)
            self.log_output.insert(tk.END, log_entry + "\n")
            self.log_output.see(tk.END)
            self.log_output.config(state=tk.DISABLED)

    def show_settings(self):
        self.clear_content_frame()
        
        ayarlar_cerceve = ttk.Frame(self.content_frame, padding="40 40 40 40")
        ayarlar_cerceve.pack(fill=tk.BOTH, expand=True)
        
        baslik = ttk.Label(ayarlar_cerceve, text="Ayarlar", font=("Verdana", 26, "bold"),
                                 foreground=self.style.colors.get("info"))
        baslik.pack(pady=(0, 40))
        
        tema_etiketi = ttk.Label(ayarlar_cerceve, text="Uygulama Teması:", font=("Verdana", 14))
        tema_etiketi.pack(pady=(0, 10))
        
        tema_butonu = ttk.Button(ayarlar_cerceve, text=f"Temayı Değiştir ({'Koyu' if self.current_theme == 'darkly' else 'Açık'})",
                                     command=self.toggle_theme)
        tema_butonu.pack()

    def show_help(self):
        self.clear_content_frame()
        
        yardim_cerceve = ttk.Frame(self.content_frame, padding="40 40 40 40")
        yardim_cerceve.pack(fill=tk.BOTH, expand=True)

        baslik = ttk.Label(yardim_cerceve, text="Yardım", font=("Verdana", 26, "bold"),
                                 foreground=self.style.colors.get("info"))
        baslik.pack(pady=(0, 40))
        
        destek_etiketi = ttk.Label(yardim_cerceve, text="Destek için:", font=("Verdana", 14))
        destek_etiketi.pack(pady=(0, 5))
        
        email_etiketi = ttk.Label(yardim_cerceve, text="halicalix@gmail.com", font=("Verdana", 12))
        email_etiketi.pack()

    def clear_content_frame(self):
        for widget in self.content_frame.winfo_children():
            if widget is self.content_frame.winfo_children()[0]:
                continue
            widget.destroy()

    def toggle_theme(self):
        if self.current_theme == "darkly":
            self.current_theme = "litera"
        else:
            self.current_theme = "darkly"
        
        self.style.theme_use(self.current_theme)
        
        self.master.configure(bg=self.style.colors.get("bg"))
        self.style.configure("bg.TFrame", background=self.style.colors.get("bg"))

        # Buton stillerini yeniden yapılandırmak yerine, sadece menu içeriğini yeniden oluşturuyoruz
        # TButton stili zaten class içinde bir kere tanımlanmıştır.
        for widget in self.menu_frame.winfo_children():
            widget.destroy()
        self.create_menu()

        self.show_settings()

    def get_log_bg_color(self):
        return "#2c2c2c" if self.current_theme == "darkly" else "#e9ecef"
        
    def log_ekle(self, metin):
        if not self.log_kutusu:
            return
            
        self.log_kutusu.config(state=tk.NORMAL)
        self.log_kutusu.insert(tk.END, metin + "\n")
        self.log_kutusu.config(state=tk.DISABLED)
        self.log_kutusu.see(tk.END)
        
        # Log kaydedici aktifse loga ekle
        if self.is_recording:
            self.log_kayitlari.append(f"[{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Arayüz: {metin}")
            if self.log_output.winfo_exists():
                self.log_output.config(state=tk.NORMAL)
                self.log_output.insert(tk.END, f"Arayüz: {metin}\n")
                self.log_output.see(tk.END)
                self.log_output.config(state=tk.DISABLED)

    # Yeni: İşlem tamamlandığında arayüzü güncelleyen fonksiyon
    def operation_finished(self, result_message, is_error=False):
        self.is_operation_running = False
        self.islem_durumu_etiketi.config(text="")
        self.sifrele_buton.config(state=tk.NORMAL)
        self.sifre_coz_buton.config(state=tk.NORMAL)
        self.dosya_sec_buton.config(state=tk.NORMAL)
        self.klasor_sec_buton.config(state=tk.NORMAL)

        if is_error:
            messagebox.showerror("Hata", result_message)
            self.log_ekle(f"Hata: {result_message}")
        else:
            messagebox.showinfo("Başarılı", result_message)
            self.log_ekle(result_message)
        
    def dosya_sec(self):
        if self.is_operation_running:
            return # İşlem devam ediyorsa yeni seçim yapılmasını engelle
            
        self.secilen_yol = filedialog.askopenfilename()
        if self.secilen_yol:
            self.durum_etiketi.config(text=f"Seçilen dosya: {os.path.basename(self.secilen_yol)}")
            self.sifrele_buton.config(state=tk.NORMAL)
            self.sifre_coz_buton.config(state=tk.NORMAL)
            self.log_ekle(f"'{os.path.basename(self.secilen_yol)}' dosyası seçildi.")
        else:
            self.sifrele_buton.config(state=tk.DISABLED)
            self.sifre_coz_buton.config(state=tk.DISABLED)
            self.durum_etiketi.config(text="Lütfen şifrelemek veya çözmek için bir dosya veya klasör seçin.")

    def klasor_sec(self):
        if self.is_operation_running:
            return # İşlem devam ediyorsa yeni seçim yapılmasını engelle
            
        self.secilen_yol = filedialog.askdirectory()
        if self.secilen_yol:
            self.durum_etiketi.config(text=f"Seçilen klasör: {os.path.basename(self.secilen_yol)}")
            self.sifrele_buton.config(state=tk.NORMAL)
            self.sifre_coz_buton.config(state=tk.NORMAL)
            self.log_ekle(f"'{os.path.basename(self.secilen_yol)}' klasörü seçildi.")
        else:
            self.sifrele_buton.config(state=tk.DISABLED)
            self.sifre_coz_buton.config(state=tk.DISABLED)
            self.durum_etiketi.config(text="Lütfen şifrelemek veya çözmek için bir dosya veya klasör seçin.")

    # Yeni: Şifreleme işlemini bir iş parçacığında başlatan ana fonksiyon
    def sifrele(self):
        if not self.secilen_yol:
            self.log_ekle("Hata: Lütfen önce bir dosya veya klasör seçin.")
            messagebox.showerror("Hata", "Lütfen önce bir dosya veya klasör seçin.")
            return

        self.is_operation_running = True
        self.islem_durumu_etiketi.config(text="Şifreleme işlemi başlatılıyor...")
        self.sifrele_buton.config(state=tk.DISABLED)
        self.sifre_coz_buton.config(state=tk.DISABLED)
        self.dosya_sec_buton.config(state=tk.DISABLED)
        self.klasor_sec_buton.config(state=tk.DISABLED)
        
        # İşlemi arka plan iş parçacığında başlat
        threading.Thread(target=self._sifrele_threaded).start()

    # Yeni: İşlem çözme işlemini bir iş parçacığında başlatan ana fonksiyon
    def sifre_coz(self):
        if not self.secilen_yol:
            self.log_ekle("Hata: Lütfen önce şifresini çözmek istediğiniz dosya veya klasörü seçin.")
            messagebox.showerror("Hata", "Lütfen önce şifresini çözmek istediğiniz dosya veya klasörü seçin.")
            return

        self.is_operation_running = True
        self.islem_durumu_etiketi.config(text="Şifre çözme işlemi başlatılıyor...")
        self.sifrele_buton.config(state=tk.DISABLED)
        self.sifre_coz_buton.config(state=tk.DISABLED)
        self.dosya_sec_buton.config(state=tk.DISABLED)
        self.klasor_sec_buton.config(state=tk.DISABLED)
        
        # İşlemi arka plan iş parçacığında başlat
        threading.Thread(target=self._sifre_coz_threaded).start()

    # Yeni: Şifreleme iş parçacığının hedefi
    def _sifrele_threaded(self):
        try:
            password_bytes = self.encryption_password.encode()
            salt = os.urandom(16)
            kdf = PBKDF2HMAC(
                algorithm=hashes.SHA256(),
                length=32,
                salt=salt,
                iterations=100000,
            )
            key = urlsafe_b64encode(kdf.derive(password_bytes))
            
            if os.path.isdir(self.secilen_yol):
                self._sifrele_klasor_parola(self.secilen_yol, key, salt)
                result_message = f"Klasör '{os.path.basename(self.secilen_yol)}' başarıyla şifrelendi ve gizlendi!"
            else:
                self._sifrele_dosya_parola(self.secilen_yol, key, salt)
                result_message = f"Dosya '{os.path.basename(self.secilen_yol)}' başarıyla şifrelendi ve gizlendi!"

            # İşlem bittiğinde, ana iş parçacığında arayüzü güncellemek için after() metodu kullanılır
            self.master.after(0, lambda: self.operation_finished(result_message))
        except Exception as e:
            # Hata oluştuğunda, ana iş parçacığında hata mesajını göster
            self.master.after(0, lambda: self.operation_finished(f"Şifreleme sırasında bir hata oluştu: {e}", is_error=True))

    # Yeni: Şifre çözme iş parçacığının hedefi
    def _sifre_coz_threaded(self):
        try:
            password_bytes = self.encryption_password.encode()
            if os.path.isdir(self.secilen_yol):
                self._sifre_coz_klasor(self.secilen_yol, password_bytes)
                result_message = f"Klasör '{os.path.basename(self.secilen_yol)}' içindeki dosyaların şifresi başarıyla çözüldü!"
            else:
                self._sifre_coz_dosya(self.secilen_yol, password_bytes)
                result_message = f"Dosya '{os.path.basename(self.secilen_yol)}' şifresi başarıyla çözüldü!"
            
            # İşlem bittiğinde, ana iş parçacığında arayüzü güncelle
            self.master.after(0, lambda: self.operation_finished(result_message))
        except Exception as e:
            # Hata oluştuğunda, ana iş parçacığında hata mesajını göster
            self.master.after(0, lambda: self.operation_finished(f"Şifre çözme sırasında bir hata oluştu: {e}", is_error=True))

    def _sifrele_dosya_parola(self, dosya_yolu, key, salt):
        f = Fernet(key)
        
        dosya_dizini = os.path.dirname(dosya_yolu)
        gizli_klasor_yolu = os.path.join(dosya_dizini, ".funda_hidden")
        
        if not os.path.exists(gizli_klasor_yolu):
            os.makedirs(gizli_klasor_yolu)
        
        dosya_adi = os.path.basename(dosya_yolu)
        sifreli_dosya_yolu = os.path.join(gizli_klasor_yolu, dosya_adi + ".funda_enc")
        
        if os.path.exists(sifreli_dosya_yolu):
            # Dosya zaten şifrelenmişse uyarı gönder
            raise Exception("Dosya zaten şifrelenmiş. Lütfen önce şifresini çözün.")

        # İşlem sırasında durumu loga ekle
        self.master.after(0, lambda: self.log_ekle(f"-> '{dosya_adi}' dosyası şifreleniyor..."))
        
        with open(dosya_yolu, "rb") as dosya:
            dosya_verisi = dosya.read()
        sifrelenmis_veri = f.encrypt(dosya_verisi)
        
        with open(sifreli_dosya_yolu, "wb") as sifreli_dosya:
            sifreli_dosya.write(salt + sifrelenmis_veri)
            
        os.remove(dosya_yolu)
        self.master.after(0, lambda: self.log_ekle(f"-> '{dosya_adi}' şifrelendi."))

    def _sifrele_klasor_parola(self, klasor_yolu, key, salt):
        f = Fernet(key)
        for root, dirs, files in os.walk(klasor_yolu):
            for dosya in files:
                dosya_yolu = os.path.join(root, dosya)
                
                # Sadece gizli klasörü içermeyen dosyaları şifrele
                if ".funda_hidden" in dosya_yolu:
                    continue

                self.master.after(0, lambda d=dosya: self.log_ekle(f"-> '{d}' şifreleniyor..."))
                
                try:
                    dosya_dizini = os.path.dirname(dosya_yolu)
                    gizli_klasor_yolu = os.path.join(dosya_dizini, ".funda_hidden")
                    
                    if not os.path.exists(gizli_klasor_yolu):
                        os.makedirs(gizli_klasor_yolu)
                    
                    dosya_adi = os.path.basename(dosya_yolu)
                    sifreli_dosya_yolu = os.path.join(gizli_klasor_yolu, dosya_adi + ".funda_enc")
                    
                    if os.path.exists(sifreli_dosya_yolu):
                        self.master.after(0, lambda d=dosya: self.log_ekle(f"Uyarı: '{d}' zaten şifrelenmiş. Atlanıyor."))
                        continue
                    
                    with open(dosya_yolu, "rb") as d:
                        dosya_verisi = d.read()
                    sifrelenmis_veri = f.encrypt(dosya_verisi)
                    with open(sifreli_dosya_yolu, "wb") as sifreli_dosya:
                        sifreli_dosya.write(salt + sifrelenmis_veri)
                    os.remove(dosya_yolu)
                    self.master.after(0, lambda d=dosya: self.log_ekle(f"-> '{d}' şifrelendi."))
                except Exception as e:
                    self.master.after(0, lambda d=dosya, err=e: self.log_ekle(f"Hata: {d} şifrelenemedi. {err}"))
        self.master.after(0, lambda: self.log_ekle(f"'{os.path.basename(klasor_yolu)}' klasöründeki tüm dosyalar parola ile şifrelendi ve gizlendi."))


    def _sifre_coz_dosya(self, dosya_yolu, password_bytes):
        dosya_dizini = os.path.dirname(dosya_yolu)
        gizli_klasor_yolu = os.path.join(dosya_dizini, ".funda_hidden")
        dosya_adi = os.path.basename(dosya_yolu)
        sifreli_dosya_yolu = os.path.join(gizli_klasor_yolu, dosya_adi + ".funda_enc")

        if not os.path.exists(sifreli_dosya_yolu):
            raise Exception("Seçilen dosyanın şifreli versiyonu bulunamadı.")
        
        try:
            self.master.after(0, lambda: self.log_ekle(f"-> '{dosya_adi}' şifresi çözülüyor..."))
            
            with open(sifreli_dosya_yolu, "rb") as sifreli_dosya:
                salt = sifreli_dosya.read(16)
                sifrelenmis_veri = sifreli_dosya.read()
            
            kdf = PBKDF2HMAC(
                algorithm=hashes.SHA256(),
                length=32,
                salt=salt,
                iterations=100000,
            )
            key = urlsafe_b64encode(kdf.derive(password_bytes))
            f = Fernet(key)
            cozulmus_veri = f.decrypt(sifrelenmis_veri)

            with open(dosya_yolu, "wb") as dosya:
                dosya.write(cozulmus_veri)
            
            os.remove(sifreli_dosya_yolu)
            
            if not os.listdir(gizli_klasor_yolu):
                os.rmdir(gizli_klasor_yolu)

            self.master.after(0, lambda: self.log_ekle(f"-> '{dosya_adi}' şifresi çözüldü."))
        except Exception as e:
            self.master.after(0, lambda err=e: self.log_ekle(f"Hata: '{dosya_yolu}' çözülemedi. Hatalı parola veya dosya bozuk olabilir. {err}"))
            raise Exception("Hatalı Parola")

    def _sifre_coz_klasor(self, klasor_yolu, password_bytes):
        for root, dirs, files in os.walk(klasor_yolu, topdown=False):
            gizli_klasor_yolu = os.path.join(root, ".funda_hidden")
            if os.path.exists(gizli_klasor_yolu):
                for sifreli_dosya_adi in os.listdir(gizli_klasor_yolu):
                    if sifreli_dosya_adi.endswith(".funda_enc"):
                        sifreli_dosya_yolu = os.path.join(gizli_klasor_yolu, sifreli_dosya_adi)
                        
                        self.master.after(0, lambda d=sifreli_dosya_adi: self.log_ekle(f"-> '{d}' şifresi çözülüyor..."))
                        try:
                            with open(sifreli_dosya_yolu, "rb") as sifreli_dosya:
                                salt = sifreli_dosya.read(16)
                                sifrelenmis_veri = sifreli_dosya.read()
                            
                            kdf = PBKDF2HMAC(
                                algorithm=hashes.SHA256(),
                                length=32,
                                salt=salt,
                                iterations=100000,
                            )
                            key = urlsafe_b64encode(kdf.derive(password_bytes))
                            f = Fernet(key)
                            cozulmus_veri = f.decrypt(sifrelenmis_veri)
                            
                            orijinal_dosya_adi = sifreli_dosya_adi.replace(".funda_enc", "")
                            orijinal_klasor_yolu = os.path.dirname(gizli_klasor_yolu)
                            orijinal_dosya_yolu = os.path.join(orijinal_klasor_yolu, orijinal_dosya_adi)
                            
                            with open(orijinal_dosya_yolu, "wb") as d:
                                d.write(cozulmus_veri)
                            os.remove(sifreli_dosya_yolu)
                            
                            self.master.after(0, lambda d=sifreli_dosya_adi: self.log_ekle(f"-> '{d}' şifresi çözüldü."))
                            
                        except Exception as e:
                            self.master.after(0, lambda d=sifreli_dosya_adi, err=e: self.log_ekle(f"Hata: '{d}' çözülemedi. Hatalı parola veya dosya bozuk olabilir. {err}"))
                            raise Exception("Hatalı Parola")
                
                for directory in dirs:
                    if directory == ".funda_hidden":
                        gizli_klasor_yolu = os.path.join(root, directory)
                        if not os.listdir(gizli_klasor_yolu):
                            os.rmdir(gizli_klasor_yolu)

        self.master.after(0, lambda: self.log_ekle(f"'{os.path.basename(klasor_yolu)}' klasöründeki tüm dosyaların şifresi çözüldü."))

    def klavye_kaydi_yap(self, event):
        if self.is_recording and event.char and event.char.isprintable(): # isprintable() ile özel tuşları filtreledik
            log_entry = f"Klavye: Tuş basıldı: '{event.char}'"
            self.log_kayitlari.append(f"[{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Arayüz: {log_entry}")
            
            if self.log_output and self.log_output.winfo_exists():
                self.log_output.config(state=tk.NORMAL)
                self.log_output.insert(tk.END, log_entry + "\n")
                self.log_output.see(tk.END)
                self.log_output.config(state=tk.DISABLED)

    def start_recording(self):
        self.is_recording = True
        self.log_kayitlari = []
        self.log_status_label.config(text="Kayıt durumu: Başladı...")
        self.start_button.config(state=tk.DISABLED)
        self.stop_button.config(state=tk.NORMAL)
        
        self.log_output.config(state=tk.NORMAL)
        self.log_output.delete("1.0", tk.END)
        self.log_output.insert(tk.END, f"--- Log Kaydı Başlatıldı: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ---\n")
        self.log_output.config(state=tk.DISABLED)

    def stop_recording(self):
        if not self.is_recording:
            return
            
        self.is_recording = False
        self.log_status_label.config(text="Kayıt durumu: Durduruldu.")
        self.start_button.config(state=tk.NORMAL)
        self.stop_button.config(state=tk.DISABLED)
        
        # Logları dosyaya kaydet
        log_dosyasi_adi = f"log_kaydi_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        with open(log_dosyasi_adi, "w", encoding="utf-8") as f:
            f.write(f"--- Log Kaydı: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ---\n\n")
            for log in self.log_kayitlari:
                f.write(log + "\n")
        
        self.log_output.config(state=tk.NORMAL)
        self.log_output.insert(tk.END, f"\n--- Log Kaydı Durduruldu ve '{log_dosyasi_adi}' dosyasına kaydedildi. ---\n")
        self.log_output.config(state=tk.DISABLED)
        
        # Klasörü aç
        try:
            if platform.system() == "Windows":
                os.startfile(os.getcwd())
            elif platform.system() == "Darwin": # macOS
                os.system(f"open .")
            else: # Linux
                os.system(f"xdg-open .")
        except Exception as e:
            messagebox.showerror("Hata", f"Klasör açılamadı: {e}")


if __name__ == "__main__":
    root = tk.Tk()
    app = FundaApp(root)
    root.mainloop()
