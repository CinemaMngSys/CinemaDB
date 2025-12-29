
INSERT INTO Halls (HallName, Capacity) VALUES ('Salon 1 - IMAX', 100);
INSERT INTO Halls (HallName, Capacity) VALUES ('Salon 2 - Gold', 50);

INSERT INTO Movies (Title, Genre, Duration, Director) VALUES ('Inception', 'Bilim Kurgu', 148, 'Christopher Nolan');
INSERT INTO Movies (Title, Genre, Duration, Director) VALUES ('The Godfather', 'Suç/Drama', 175, 'Francis Ford Coppola');
INSERT INTO Movies (Title, Genre, Duration, Director) VALUES ('Interstellar', 'Bilim Kurgu', 169, 'Christopher Nolan');


INSERT INTO Users (Username, Password, Role) VALUES ('admin', '1234', 'Admin');
INSERT INTO Users (Username, Password, Role) VALUES ('musteri1', '1234', 'Customer');
INSERT INTO Users (Username,Password,Role) VALUES ('bthntrksy', 'batu1234', 'Admin');


INSERT INTO Sessions (MovieID, HallID, SessionDate, SessionTime) VALUES (1, 1, '2025-11-30', '20:00:00');
INSERT INTO Sessions (MovieID, HallID, SessionDate, SessionTime) VALUES (2, 2, '2025-11-30', '15:00:00');

DELIMITER //
DROP PROCEDURE IF EXISTS sp_GetMovieSessions; 
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_GetMovieSessions(IN movieName VARCHAR(100))
BEGIN
    SELECT 
        S.SessionID,
        M.Title AS FilmAdi,
        H.HallName AS SalonAdi,
        S.SessionDate AS Tarih,
        S.SessionTime AS Saat,
        H.Capacity AS Kapasite
    FROM Sessions S
    JOIN Movies M ON S.MovieID = M.MovieID
    JOIN Halls H ON S.HallID = H.HallID
    WHERE M.Title LIKE CONCAT('%', movieName, '%')
    ORDER BY S.SessionDate, S.SessionTime;
END //
DELIMITER ;

CALL sp_GetMovieSessions('Inception');