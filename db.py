import mysql.connector

DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
<<<<<<< HEAD
    'password': 'Batu.2003',
=======
    'password': 'root şifren',  
>>>>>>> 39e0f57d64a4ecb7569ca44e1232f8acf1414850
    'database': 'CinemaDB'
}

def get_db_connection():
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except mysql.connector.Error as err:
        print(f"Veritabanı Hatası: {err}") 
        return None