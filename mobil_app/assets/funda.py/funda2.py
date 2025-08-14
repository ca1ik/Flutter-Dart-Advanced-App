import sys
import os
import datetime
import threading
import tkinter as tk
from tkinter import ttk, messagebox
from pynput import keyboard, mouse
import time
import pygetwindow as gw

# Logları saklamak için bir dosya adı belirleyin
LOG_FILE = "desktop_activity_log.txt"

class SystemLoggerApp:
    def __init__(self, master):
        self.master = master
        master.title("Sistem Geneli Etkinlik Loglayıcısı")
        master.geometry("800x500")
        master.resizable(True, True)

        # Durum ve Thread değişkenleri
        self.is_recording = False
        self.keyboard_thread = None
        self.mouse_thread = None
        self.window_check_thread = None
        self.log_entries = [] # Logları bellekte tutmak için yeni liste
        self.pressed_keys = set()
        self.last_active_window = ""
        self.last_log_time = datetime.datetime.now()

        # Arayüzü oluştur
        self.main_frame = ttk.Frame(master, padding="10")
        self.main_frame.pack(fill=tk.BOTH, expand=True)

        self.title_label = ttk.Label(self.main_frame, text="Sistem Etkinlik Kaydedici", font=("Verdana", 18, "bold"))
        self.title_label.pack(pady=(10, 20))

        self.button_frame = ttk.Frame(self.main_frame)
        self.button_frame.pack(pady=10)

        self.start_button = ttk.Button(self.button_frame, text="Kaydı Başlat", command=self.start_recording)
        self.start_button.pack(side=tk.LEFT, padx=10)

        self.stop_button = ttk.Button(self.button_frame, text="Kaydı Durdur", command=self.stop_recording, state=tk.DISABLED)
        self.stop_button.pack(side=tk.LEFT, padx=10)

        self.status_label = ttk.Label(self.main_frame, text="Durum: Bekliyor...", font=("Verdana", 12))
        self.status_label.pack(pady=(10, 5))
        
        self.log_header = ttk.Label(self.main_frame, text="Etkinlik Günlüğü", font=("Verdana", 14, "bold"))
        self.log_header.pack(pady=(10, 5))

        self.log_text = tk.Text(self.main_frame, wrap=tk.WORD, state=tk.DISABLED,
                                 bg="#2c2c2c", fg="white", font=("Courier New", 10),
                                 borderwidth=0, relief="flat")
        self.log_text.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Log dosyasını başlat
        self.add_log_entry("Program başlatıldı. Kaydı başlatmak için 'Kaydı Başlat' düğmesine tıklayın.")

    def add_log_entry(self, entry_text):
        """Log girişini arayüze ekler ve belleğe kaydeder."""
        current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        full_entry = f"[{current_time}] {entry_text}"
        self.log_entries.append(full_entry)

        self.log_text.config(state=tk.NORMAL)
        self.log_text.insert(tk.END, full_entry + "\n")
        self.log_text.see(tk.END)
        self.log_text.config(state=tk.DISABLED)
        
    def write_logs_to_file(self):
        """Tüm logları bir dosyaya yazar ve kullanıcıyı bilgilendirir."""
        log_directory = os.path.join(os.getcwd(), "log_kayitlari")
        if not os.path.exists(log_directory):
            os.makedirs(log_directory)

        log_dosyasi_adi = os.path.join(log_directory, f"etkinlik_logu_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.txt")
        try:
            with open(log_dosyasi_adi, "w", encoding="utf-8") as f:
                f.write(f"--- Log Kaydı: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ---\n\n")
                for log in self.log_entries:
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
                self.master.after(0, lambda: self.add_log_entry(log_entry))

            else:
                key_name = str(key).split('.')[-1]
                if key not in self.pressed_keys:
                    log_entry = f"Klavye: Tuş basıldı: '[{key_name.capitalize()}]'"
                    self.master.after(0, lambda: self.add_log_entry(log_entry))

        except Exception as e:
            self.master.after(0, lambda: self.add_log_entry(f"Hata: Klavye olayını işleme hatası: {e}"))

    def on_key_release(self, key):
        """Klavye tuş bırakma olayını işler."""
        if key in self.pressed_keys:
            self.pressed_keys.remove(key)

    def on_mouse_click(self, x, y, button, pressed):
        """Fare tıklama olayını işler ve arayüzü günceller."""
        if pressed:
            log_entry = f"Fare: Tıklama: {button} tuşu ({x}, {y}) koordinatlarında basıldı."
            self.master.after(0, lambda: self.add_log_entry(log_entry))

    def check_active_window(self):
        """Aktif pencereyi kontrol eder ve değişirse loglar."""
        while self.is_recording:
            try:
                active_window = gw.getActiveWindow()
                if active_window and active_window.title and active_window.title != self.last_active_window:
                    self.last_active_window = active_window.title
                    log_entry = f"Etkin Pencere Değişti: {self.last_active_window}"
                    self.master.after(0, lambda: self.add_log_entry(log_entry))
            except Exception as e:
                pass 
            time.sleep(1)

    def start_recording(self):
        """Kayıt işlemini başlatır."""
        if self.is_recording:
            return

        self.is_recording = True
        self.log_entries = []
        self.start_button.config(state=tk.DISABLED)
        self.stop_button.config(state=tk.NORMAL)
        self.status_label.config(text="Durum: Kaydediliyor...", foreground="green")
        self.add_log_entry("Kayıt başlatıldı.")
        
        self.add_log_entry("Dikkat: Sadece klavye ve fare etkinlikleri kaydedilecektir. Dosya ve klasör erişimi izlenemez.")
        self.add_log_entry("Tıklama koordinatları ve etkin pencere başlıkları, dosya/klasör erişiminin yerine geçecek şekilde kaydedilmektedir.")
        self.add_log_entry("Kayıdı durdurmak için 'F5' tuşuna veya 'Kaydı Durdur' düğmesine basabilirsiniz.")

        self.master.withdraw()  # Pencereyi tamamen gizler

        self.keyboard_thread = keyboard.Listener(on_press=self.on_key_press, on_release=self.on_key_release)
        self.mouse_thread = mouse.Listener(on_click=self.on_mouse_click)
        self.window_check_thread = threading.Thread(target=self.check_active_window, daemon=True)
        
        self.keyboard_thread.start()
        self.mouse_thread.start()
        self.window_check_thread.start()
        
    def stop_recording(self):
        """Kayıt işlemini durdurur ve logları dosyaya kaydeder."""
        if not self.is_recording:
            return

        self.is_recording = False
        self.master.deiconify() # Gizlenen pencereyi tekrar görünür yapar
        self.start_button.config(state=tk.NORMAL)
        self.stop_button.config(state=tk.DISABLED)
        self.status_label.config(text="Durum: Durduruldu.", foreground="red")
        
        if self.keyboard_thread and self.keyboard_thread.is_alive():
            self.keyboard_thread.stop()
        if self.mouse_thread and self.mouse_thread.is_alive():
            self.mouse_thread.stop()

        self.add_log_entry("Kayıt durduruldu.")
        self.write_logs_to_file()
        self.master.destroy() # Uygulamayı tamamen sonlandırır

if __name__ == "__main__":
    # Gerekli kütüphaneleri kurun:
    # Terminalde/Komut İsteminde 'pip install pynput pygetwindow' komutunu çalıştırın.
    
    root = tk.Tk()
    app = SystemLoggerApp(root)
    root.protocol("WM_DELETE_WINDOW", app.stop_recording)
    root.mainloop()
