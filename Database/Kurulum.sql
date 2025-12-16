-- 1. Veritabanını Oluştur ve Seç
CREATE DATABASE IF NOT EXISTS CinemaDB;
USE CinemaDB;

-- 2. Kullanıcılar Tablosu (Users)
-- Python kodu user[3] indeksine baktığı için sütun sırası önemlidir (ID, User, Pass, Role).
CREATE TABLE IF NOT EXISTS Users (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Password VARCHAR(50) NOT NULL,
    Role VARCHAR(20) NOT NULL -- 'admin' veya 'user' değerleri alır
);

-- 3. Filmler Tablosu (Movies)
CREATE TABLE IF NOT EXISTS Movies (
    MovieID INT AUTO_INCREMENT PRIMARY KEY,
    Title VARCHAR(100) NOT NULL,
    Genre VARCHAR(50),
    Duration INT NOT NULL, -- Dakika cinsinden
    Director VARCHAR(50),
    PosterPath VARCHAR(255) -- Dosya yolu
);

-- 4. Salonlar Tablosu (Halls)
CREATE TABLE IF NOT EXISTS Halls (
    HallID INT AUTO_INCREMENT PRIMARY KEY,
    HallName VARCHAR(50) NOT NULL,
    Capacity INT DEFAULT 50 -- Koltuk sayısı
);

-- 5. Seanslar Tablosu (Sessions)
CREATE TABLE IF NOT EXISTS Sessions (
    SessionID INT AUTO_INCREMENT PRIMARY KEY,
    MovieID INT NOT NULL,
    HallID INT NOT NULL,
    SessionDate DATE NOT NULL,
    SessionTime TIME NOT NULL,
    FOREIGN KEY (MovieID) REFERENCES Movies(MovieID) ON DELETE CASCADE,
    FOREIGN KEY (HallID) REFERENCES Halls(HallID) ON DELETE CASCADE
);

-- 6. Biletler Tablosu (Tickets)
CREATE TABLE IF NOT EXISTS Tickets (
    TicketID INT AUTO_INCREMENT PRIMARY KEY,
    SessionID INT NOT NULL,
    UserID INT NOT NULL,
    SeatNumber INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    PurchaseDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (SessionID) REFERENCES Sessions(SessionID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);

-- 7. Stored Procedure: sp_GetMovieSessions
-- Python kodunda "cursor.callproc('sp_GetMovieSessions', ...)" satırı için gereklidir.
-- Bu prosedür film arama ve kapasite durumunu (Dolu/Toplam) getirir.
DROP PROCEDURE IF EXISTS sp_GetMovieSessions;

DELIMITER //
CREATE PROCEDURE sp_GetMovieSessions(IN search_text VARCHAR(100))
BEGIN
    SELECT 
        S.SessionID,
        M.Title AS FilmAdi,
        H.HallName AS SalonAdi,
        S.SessionDate AS Tarih,
        S.SessionTime AS Saat,
        -- Python kodu kapasiteyi "Dolu / Toplam" formatında bölerek okuyor:
        CONCAT(
            (SELECT COUNT(*) FROM Tickets T WHERE T.SessionID = S.SessionID), 
            ' / ', 
            H.Capacity
        ) AS Kapasite
    FROM Sessions S
    JOIN Movies M ON S.MovieID = M.MovieID
    JOIN Halls H ON S.HallID = H.HallID
    WHERE M.Title LIKE CONCAT('%', search_text, '%')
    ORDER BY S.SessionDate, S.SessionTime;
END //
DELIMITER ;

-- ==========================================
-- ÖRNEK VERİ GİRİŞLERİ (Test İçin)
-- ==========================================

-- Örnek Kullanıcılar:
-- Admin ile tam yetkili giriş yapabilirsin.
INSERT IGNORE INTO Users (Username, Password, Role) VALUES 
('admin', '1234', 'admin'),
('gişe', '1234', 'user');

-- Örnek Salonlar:
INSERT IGNORE INTO Halls (HallName, Capacity) VALUES 
('Salon 1 (Büyük)', 50),
('Salon 2 (VIP)', 20),
('Salon 3 (Gold)', 30);

-- Örnek Bir Film Ekleyelim (Opsiyonel):
INSERT IGNORE INTO Movies (Title, Genre, Duration, Director, PosterPath) VALUES 
('Inception', 'Bilim Kurgu', 148, 'Christopher Nolan', '');

-- Örnek Bir Seans Ekleyelim:
-- Not: Tarihi bugünün tarihi olarak güncelleyebilirsin test ederken.
INSERT IGNORE INTO Sessions (MovieID, HallID, SessionDate, SessionTime) 
SELECT 1, 1, CURDATE(), '20:00:00' FROM DUAL WHERE EXISTS (SELECT * FROM Movies WHERE MovieID=1);