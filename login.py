import ttkbootstrap as ttk
from ttkbootstrap.constants import *
from tkinter import messagebox
from db import get_db_connection
from app import CinemaMainApp

class LoginApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Sinema Yönetim Sistemi")
        self.root.geometry("450x350")
        self.center_window(450, 350)
        
        self.main_frame = ttk.Frame(root, padding=30)
        self.main_frame.pack(fill=BOTH, expand=True)

        ttk.Label(self.main_frame, text="SİSTEM GİRİŞİ", font=("Helvetica", 18, "bold"), bootstyle="primary").pack(pady=20)
        
        ttk.Label(self.main_frame, text="Kullanıcı Adı:").pack(fill=X)
        self.entry_user = ttk.Entry(self.main_frame)
        self.entry_user.pack(fill=X, pady=5)
        
        ttk.Label(self.main_frame, text="Şifre:").pack(fill=X, pady=(10,0))
        self.entry_pass = ttk.Entry(self.main_frame, show="*")
        self.entry_pass.pack(fill=X, pady=5)
        
        ttk.Button(self.main_frame, text="GİRİŞ YAP", command=self.login, bootstyle="success-outline", width=100).pack(pady=30)

    def center_window(self, width, height):
        screen_width = self.root.winfo_screenwidth()
        screen_height = self.root.winfo_screenheight()
        x = (screen_width/2) - (width/2)
        y = (screen_height/2) - (height/2)
        self.root.geometry('%dx%d+%d+%d' % (width, height, x, y))

    def login(self):
        username = self.entry_user.get()
        password = self.entry_pass.get()
        conn = get_db_connection()
        if conn:
            try:
                cursor = conn.cursor()
                cursor.execute("SELECT * FROM Users WHERE Username = %s AND Password = %s", (username, password))
                user = cursor.fetchone()
                if user:
                    for widget in self.root.winfo_children(): widget.destroy()
                    CinemaMainApp(self.root, user_id=user[0], user_role=user[3])
                else:
                    messagebox.showerror("Hata", "Hatalı Giriş Bilgileri")
            finally:
                conn.close()
        else:
            messagebox.showerror("Hata", "Veritabanına bağlanılamadı!")