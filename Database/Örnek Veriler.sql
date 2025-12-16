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