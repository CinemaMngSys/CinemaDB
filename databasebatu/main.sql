CREATE DATABASE IF NOT EXISTS CinemaDB;
USE CinemaDB;

-- 1. Kullanıcılar (Hem admin hem gişe personeli bu tabloda)
CREATE TABLE IF NOT EXISTS Users (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Password VARCHAR(50) NOT NULL,
    Role VARCHAR(20) NOT NULL -- 'admin' veya 'user'
);

-- Örnek kullanıcıları ekle (Tekrar eklemeyi önlemek için IGNORE kullandık)
INSERT IGNORE INTO Users (Username, Password, Role) VALUES 
('admin', '123', 'admin'),
('gise', '1234', 'user');

-- 2. Filmler
CREATE TABLE IF NOT EXISTS Movies (
    MovieID INT AUTO_INCREMENT PRIMARY KEY,
    Title VARCHAR(100) NOT NULL,
    Genre VARCHAR(50),
    Duration INT NOT NULL, 
    Director VARCHAR(50),
    PosterPath VARCHAR(500)
);

-- 3. Salonlar
CREATE TABLE IF NOT EXISTS Halls (
    HallID INT AUTO_INCREMENT PRIMARY KEY,
    HallName VARCHAR(50) NOT NULL,
    Capacity INT DEFAULT 50
);

-- 4. Seanslar
CREATE TABLE IF NOT EXISTS Sessions (
    SessionID INT AUTO_INCREMENT PRIMARY KEY,
    MovieID INT NOT NULL,
    HallID INT NOT NULL,
    SessionDate DATE NOT NULL,
    SessionTime TIME NOT NULL,
    FOREIGN KEY (MovieID) REFERENCES Movies(MovieID) ON DELETE CASCADE,
    FOREIGN KEY (HallID) REFERENCES Halls(HallID) ON DELETE CASCADE
);

-- 5. Biletler
CREATE TABLE IF NOT EXISTS Tickets (
    TicketID INT AUTO_INCREMENT PRIMARY KEY,
    SessionID INT NOT NULL,
    UserID INT NOT NULL, -- Bileti satan personel veya alan kullanıcı
    SeatNumber INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    PurchaseDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (SessionID) REFERENCES Sessions(SessionID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);

-- 6. [EKSİK OLAN TABLO EKLENDİ] Hasılat Arşivi
-- Eski seanslar silindiğinde raporların bozulmaması için veriler buraya taşınacak.
CREATE TABLE IF NOT EXISTS RevenueArchive (
    ArchiveID INT AUTO_INCREMENT PRIMARY KEY,
    OriginalTicketID INT,
    MovieID INT,
    Title VARCHAR(100),
    SessionID_Old INT,
    UserID INT,
    Price DECIMAL(10,2),
    PurchaseDate DATETIME,
    ArchivedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 7. Film ve Seansları Listeleme Prosedürü
-- Python (app.py) bu prosedürden "X / Y" formatında kapasite bilgisi bekliyor.
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
        -- App.py line 289 bu formatı parçalayarak okuyor, BURASI KRİTİK:
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