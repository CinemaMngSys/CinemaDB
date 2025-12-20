USE CinemaDB;

-- Eski prosedürleri temizle
DROP PROCEDURE IF EXISTS sp_GetMovieRevenue;
DROP PROCEDURE IF EXISTS sp_SellTicket;
DROP PROCEDURE IF EXISTS sp_CleanupOldSessions;

DELIMITER //

-- 1. Film Bazlı Toplam Hasılat (Raporlama için)
CREATE PROCEDURE sp_GetMovieRevenue(IN input_movie_name VARCHAR(100))
BEGIN
    SELECT 
        m.Title AS 'Film', 
        COUNT(t.TicketID) AS 'Satılan Bilet', 
        IFNULL(SUM(t.Price), 0) AS 'Toplam Hasılat'
    FROM Movies m
    LEFT JOIN Sessions s ON m.MovieID = s.MovieID
    LEFT JOIN Tickets t ON s.SessionID = t.SessionID
    WHERE m.Title LIKE CONCAT('%', input_movie_name, '%')
    GROUP BY m.Title;
END //

-- 2. Güvenli Bilet Satışı (Python App ile Uyumlu Hale Getirildi)
-- İsim/Soyisim yerine p_userID (Gişe Personeli ID) alıyor.
CREATE PROCEDURE sp_SellTicket(
    IN p_session_id INT, 
    IN p_user_id INT, 
    IN p_seat_number INT,
    IN p_price DECIMAL(10,2)
)
BEGIN
    DECLARE v_count INT;

    -- Koltuk dolu mu kontrol et
    SELECT COUNT(*) INTO v_count 
    FROM Tickets 
    WHERE SessionID = p_session_id AND SeatNumber = p_seat_number;

    IF v_count > 0 THEN
        -- Hata fırlat (Python tarafı bunu yakalayabilir)
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hata: Bu koltuk zaten satılmış!';
    ELSE
        -- Bileti kes
        INSERT INTO Tickets (SessionID, UserID, SeatNumber, Price) 
        VALUES (p_session_id, p_user_id, p_seat_number, p_price);
    END IF;
END //

-- 3. Geçmiş Seansları Temizleme ve Arşivleme
-- Bu prosedür hasılat verilerini kaybetmeden eski seansları temizler.
CREATE PROCEDURE sp_CleanupOldSessions()
BEGIN
    -- A. Silinecek seansları geçici tabloya al
    CREATE TEMPORARY TABLE IF NOT EXISTS SessionsToArchive AS
    SELECT SessionID, MovieID
    FROM Sessions
    WHERE SessionDate < CURDATE() 
       OR (SessionDate = CURDATE() AND SessionTime < CURTIME());

    -- B. Bu seansların biletlerini ARŞİV tablosuna taşı
    INSERT INTO RevenueArchive (OriginalTicketID, MovieID, Title, SessionID_Old, UserID, Price, PurchaseDate)
    SELECT 
        T.TicketID,
        STA.MovieID,
        M.Title,
        T.SessionID,
        T.UserID,
        T.Price,
        T.PurchaseDate
    FROM Tickets T
    JOIN SessionsToArchive STA ON T.SessionID = STA.SessionID
    JOIN Movies M ON STA.MovieID = M.MovieID;

    -- C. Aktif tablolardan verileri temizle
    -- (Önce biletler, sonra seanslar silinmeli)
    DELETE T FROM Tickets T
    JOIN SessionsToArchive STA ON T.SessionID = STA.SessionID;
    
    DELETE S FROM Sessions S
    JOIN SessionsToArchive STA ON S.SessionID = STA.SessionID;
    
    -- D. Geçici tabloyu temizle
    DROP TEMPORARY TABLE IF EXISTS SessionsToArchive;
END //

DELIMITER ;

-- Event Scheduler Ayarı (Sunucuda zamanlanmış görevlerin çalışması için)
SET GLOBAL event_scheduler = ON;

-- Günlük Temizlik Görevi (Her gün çalışır)
DROP EVENT IF EXISTS daily_session_cleanup;
DELIMITER //
CREATE EVENT daily_session_cleanup
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURDATE() + INTERVAL 1 DAY, '03:00:00')) -- Her gece 03:00'te çalışır
ON COMPLETION PRESERVE ENABLE 
DO
BEGIN
    CALL sp_CleanupOldSessions();
END //
DELIMITER ;