import ttkbootstrap as ttk
from login import LoginApp
import warnings

warnings.filterwarnings("ignore", category=DeprecationWarning)

if __name__ == "__main__":
    app_root = ttk.Window(themename="darkly") 
    LoginApp(app_root)
    app_root.mainloop()