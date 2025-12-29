USE CinemaDB;

DROP PROCEDURE IF EXISTS sp_GetMovieRevenue;
DROP PROCEDURE IF EXISTS sp_SellTicket;
DROP PROCEDURE IF EXISTS sp_CleanupOldSessions;
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

DELIMITER //

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
DELIMITER //
CREATE PROCEDURE sp_SellTicket(
    IN p_session_id INT, 
    IN p_user_id INT, 
    IN p_seat_number INT,
    IN p_price DECIMAL(10,2)
)
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count 
    FROM Tickets 
    WHERE SessionID = p_session_id AND SeatNumber = p_seat_number;

    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hata: Bu koltuk zaten satılmış!';
    ELSE
        INSERT INTO Tickets (SessionID, UserID, SeatNumber, Price) 
        VALUES (p_session_id, p_user_id, p_seat_number, p_price);
    END IF;
END //

DELIMITER //
CREATE PROCEDURE sp_CleanupOldSessions()
BEGIN
    CREATE TEMPORARY TABLE IF NOT EXISTS SessionsToArchive AS
    SELECT SessionID, MovieID
    FROM Sessions
    WHERE SessionDate < CURDATE() 
		OR (SessionDate = CURDATE() AND SessionTime < CURTIME());


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

    DELETE T FROM Tickets T
    JOIN SessionsToArchive STA ON T.SessionID = STA.SessionID;
    
    DELETE S FROM Sessions S
    JOIN SessionsToArchive STA ON S.SessionID = STA.SessionID;
    
    DROP TEMPORARY TABLE IF EXISTS SessionsToArchive;
END //

DELIMITER ;

SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS daily_session_cleanup;
DELIMITER //
CREATE EVENT daily_session_cleanup
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURDATE() + INTERVAL 1 DAY, '03:00:00')) 
ON COMPLETION PRESERVE ENABLE 
DO
BEGIN
    CALL sp_CleanupOldSessions();
END //



