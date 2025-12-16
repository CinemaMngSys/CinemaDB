USE CinemaDB;

-- Önce var olanları temizleyelim (Hata almamak için)
DROP PROCEDURE IF EXISTS sp_GetMovieRevenue;
DROP PROCEDURE IF EXISTS sp_SellTicket;

DELIMITER //

-- 1. PROSEDÜR: Bir filmin toplam hasılatını hesaplar
-- Senaryo: Yönetici "Inception" filminden ne kadar kazandık diye sorar.
CREATE PROCEDURE sp_GetMovieRevenue(IN input_movie_name VARCHAR(100))
BEGIN
    SELECT 
        m.title AS 'Film', 
        COUNT(t.ticket_id) AS 'Satılan Bilet', 
        IFNULL(SUM(s.price), 0) AS 'Toplam Hasılat'
    FROM Movies m
    LEFT JOIN Sessions s ON m.movie_id = s.movie_id
    LEFT JOIN Tickets t ON s.session_id = t.session_id
    WHERE m.title LIKE CONCAT('%', input_movie_name, '%')
    GROUP BY m.title;
END //

-- 2. PROSEDÜR: Hızlı Bilet Satışı (Kontrollü)
-- Senaryo: Gişe görevlisi koltuk numarası ve seans ID girer, sistem boşsa satar.
CREATE PROCEDURE sp_SellTicket(
    IN p_session_id INT, 
    IN p_seat_number VARCHAR(10), 
    IN p_customer_name VARCHAR(50),
    IN p_customer_surname VARCHAR(50)
)
BEGIN
    DECLARE v_customer_id INT;
    DECLARE v_count INT;

    -- 1. Koltuk dolu mu kontrol et
    SELECT COUNT(*) INTO v_count 
    FROM Tickets 
    WHERE session_id = p_session_id AND seat_number = p_seat_number;

    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hata: Bu koltuk zaten satılmış!';
    ELSE
        -- 2. Müşteriyi bul veya ekle (Basitlik için her satışta yeni ekliyoruz veya var olanı seçebiliriz)
        -- Bu örnekte hızlıca müşteriyi ekleyip ID'sini alıyoruz
        INSERT INTO Customers (first_name, last_name) VALUES (p_customer_name, p_customer_surname);
        SET v_customer_id = LAST_INSERT_ID();

        -- 3. Bileti kes
        INSERT INTO Tickets (session_id, customer_id, seat_number) 
        VALUES (p_session_id, v_customer_id, p_seat_number);
        
        SELECT 'Başarılı: Bilet satıldı.' AS Sonuc;
    END IF;
END //

DELIMITER ;

ALTER TABLE Tickets
ADD CONSTRAINT FK_Tickets_Sessions_CASCADE
FOREIGN KEY (SessionID) 
REFERENCES Sessions(SessionID)
ON DELETE CASCADE;

SHOW VARIABLES LIKE 'event_scheduler'   -- off ise aşağıdakini çalıştır
SET GLOBAL event_scheduler = ON;

-- Event Scheduler'ın açık olduğundan emin olun (tekrar çalıştırmak zarar vermez)
SET GLOBAL event_scheduler = ON;

-- Eski event varsa silin
DROP EVENT IF EXISTS daily_session_cleanup;

DELIMITER //

CREATE EVENT daily_session_cleanup
ON SCHEDULE EVERY 1 DAY
-- Başlangıç zamanını yarın sabah 01:00 olarak ayarlar
STARTS (CURDATE() + INTERVAL 1 DAY + INTERVAL 1 HOUR) 
ON COMPLETION PRESERVE ENABLE 
DO
BEGIN
    CALL sp_CleanupOldSessions();
END //

DELIMITER ;
-- Bu bloğu da ayrı olarak çalıştırın.

DROP PROCEDURE IF EXISTS sp_CleanupOldSessions;

USE CinemaDB;

-- Stored Procedure'ü tekrar oluşturun (Eğer silindiyse)
USE CinemaDB;

DROP PROCEDURE IF EXISTS sp_CleanupOldSessions;

DELIMITER //
CREATE PROCEDURE sp_CleanupOldSessions()
BEGIN
    -- 1. Silinecek seansların ID'lerini ve Film ID'lerini geçici bir tabloya taşı.
    CREATE TEMPORARY TABLE SessionsToArchive (
        SessionID INT PRIMARY KEY,
        MovieID INT
    );
    
    INSERT INTO SessionsToArchive (SessionID, MovieID)
    SELECT 
        S.SessionID,
        S.MovieID
    FROM Sessions S
    WHERE 
        S.SessionDate < CURDATE() 
        OR (S.SessionDate = CURDATE() AND S.SessionTime < CURTIME());

    -- 2. Hasılat verilerini ARŞİV tablosuna taşı
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

    -- 3. O seanslara ait biletleri AKTİF Tickets tablosundan sil (Arşivlendiği için artık silebiliriz)
    DELETE T FROM Tickets T
    JOIN SessionsToArchive STA ON T.SessionID = STA.SessionID;
    
    -- 4. Geçmiş seansları Sessions tablosundan sil
    DELETE S FROM Sessions S
    JOIN SessionsToArchive STA ON S.SessionID = STA.SessionID;
    
    -- 5. Geçici tabloyu temizle
    DROP TEMPORARY TABLE SessionsToArchive;

END //
DELIMITER ;


   