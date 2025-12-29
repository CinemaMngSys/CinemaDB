
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

