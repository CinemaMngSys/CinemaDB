
CREATE TABLE Movies (
    MovieID INT PRIMARY KEY AUTO_INCREMENT,
    Title VARCHAR(100) NOT NULL,
    Genre VARCHAR(50),
    Duration INT, 
    Director VARCHAR(100)
);
ALTER TABLE movies ADD COLUMN PosterPath VARCHAR(500);


CREATE TABLE Halls (
    HallID INT PRIMARY KEY AUTO_INCREMENT,
    HallName VARCHAR(50) NOT NULL,
    Capacity INT NOT NULL
);


CREATE TABLE Users (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    Username VARCHAR(50) UNIQUE NOT NULL,
    Password VARCHAR(50) NOT NULL, 
    Role VARCHAR(20) DEFAULT 'user'
);
INSERT INTO Users (Username,Password,Role) Values
('gise',1234,'user'),
('admin',123,'admin');


CREATE TABLE Sessions (
    SessionID INT PRIMARY KEY AUTO_INCREMENT,
    MovieID INT,
    HallID INT,
    SessionDate DATE,
    SessionTime TIME,
    FOREIGN KEY (MovieID) REFERENCES Movies(MovieID) ON DELETE CASCADE,
    FOREIGN KEY (HallID) REFERENCES Halls(HallID) ON DELETE CASCADE
);


CREATE TABLE Tickets (
    TicketID INT PRIMARY KEY AUTO_INCREMENT,
    SessionID INT,
    UserID INT,
    SeatNumber INT NOT NULL,
    Price DECIMAL(10, 2), 
    PurchaseDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (SessionID) REFERENCES Sessions(SessionID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);


DROP PROCEDURE IF EXISTS sp_GetMovieSessions;

DELIMITER //
CREATE PROCEDURE sp_GetMovieSessions(IN movieName VARCHAR(100))
BEGIN
    SELECT 
        S.SessionID,
        M.Title AS FilmAdi,
        H.HallName AS SalonAdi,
        S.SessionDate AS Tarih,
        S.SessionTime AS Saat,
        CONCAT(
            (H.Capacity - (SELECT COUNT(*) FROM Tickets T WHERE T.SessionID = S.SessionID)), 
            ' / ', 
            H.Capacity
        ) AS KapasiteDurumu
    FROM Sessions S
    JOIN Movies M ON S.MovieID = M.MovieID
    JOIN Halls H ON S.HallID = H.HallID
    WHERE M.Title LIKE CONCAT('%', movieName, '%')
    ORDER BY S.SessionDate, S.SessionTime;
END //

DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_GetMovieSessions$$

CREATE PROCEDURE sp_GetMovieSessions(IN movieName VARCHAR(100))
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
        ) AS KapasiteDurumu
    FROM Sessions S
    JOIN Movies M ON S.MovieID = M.MovieID
    JOIN Halls H ON S.HallID = H.HallID
    WHERE M.Title LIKE CONCAT('%', movieName, '%')
    ORDER BY S.SessionDate, S.SessionTime;
END$$

DELIMITER ;