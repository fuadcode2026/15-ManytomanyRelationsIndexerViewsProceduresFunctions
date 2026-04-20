

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'CompanyMM')
BEGIN
    CREATE DATABASE CompanyMM;
END
GO

USE CompanyMM;
GO


DROP PROCEDURE IF EXISTS sp_AssignEmployeeToProject;
DROP FUNCTION IF EXISTS fn_GetProjectCount;
DROP VIEW IF EXISTS EmployeeProjectView;
DROP TABLE IF EXISTS EmployeeProjects;
DROP TABLE IF EXISTS Employees;
DROP TABLE IF EXISTS Projects;
GO


CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    BirthDate DATE,
    Email VARCHAR(100) UNIQUE,
    CONSTRAINT chk_adult CHECK (BirthDate <= '2006-20-04') 
);

GO

CREATE TABLE Projects (
    ProjectID INT IDENTITY(1,1) PRIMARY KEY,
    ProjectName VARCHAR(100) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE,
    CONSTRAINT chk_dates CHECK (EndDate >= StartDate) 
);

GO

CREATE TABLE EmployeeProjects (
    EmployeeID INT,
    ProjectID INT,
    AssignedDate DATE DEFAULT CAST(GETDATE() AS DATE),
    PRIMARY KEY (EmployeeID, ProjectID), 
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID) ON DELETE CASCADE,
    FOREIGN KEY (ProjectID) REFERENCES Projects(ProjectID) ON DELETE CASCADE
);
GO


INSERT INTO Employees (FirstName, LastName, BirthDate, Email) VALUES
('Fuad', 'Movsumov', '2006-04-01', 'fuadmovsumovvss@example.com'),
('Aydan', 'Alakbarova', '2007-05-11', 'aydan.alakbarova@example.com'),
('Orxan', 'Eliyev', '1993-01-0', 'orxan.aliyev@example.com'),
('Aysel', 'Quliyeva', '1992-12-01', 'aysel.quliyeva@example.com'),
('Resad', 'Movsumov', '1985-07-25', 'rashad.huseynov@example.com');

INSERT INTO Projects (ProjectName, StartDate, EndDate) VALUES
('CRM System', '2023-01-10', '2023-12-31'),
('Mobile App', '2023-05-01', '2024-05-01'),
('Website Redesign', '2023-08-15', '2023-11-30');

INSERT INTO EmployeeProjects (EmployeeID, ProjectID, AssignedDate) VALUES
(1, 1, '2023-01-15'),
(1, 2, '2023-05-05'),
(1, 3, '2023-08-20'), 
(2, 1, '2023-02-01'),
(3, 2, '2023-05-10'),
(4, 3, '2023-08-16'),
(5, 1, '2023-03-01'),
(5, 2, '2023-06-01');
GO



SELECT * FROM Employees;
SELECT * FROM Projects;

SELECT e.FirstName, e.LastName, p.ProjectName
FROM Employees e
JOIN EmployeeProjects ep ON e.EmployeeID = ep.EmployeeID
JOIN Projects p ON ep.ProjectID = p.ProjectID;

SELECT p.ProjectName, COUNT(ep.EmployeeID) AS AssignedEmployeesCount
FROM Projects p
LEFT JOIN EmployeeProjects ep ON p.ProjectID = ep.ProjectID
GROUP BY p.ProjectID, p.ProjectName;

SELECT e.FirstName, e.LastName, COUNT(ep.ProjectID) AS ProjectCount
FROM Employees e
JOIN EmployeeProjects ep ON e.EmployeeID = ep.EmployeeID
GROUP BY e.EmployeeID, e.FirstName, e.LastName
HAVING COUNT(ep.ProjectID) > 2;
GO


-------------------
CREATE VIEW EmployeeProjectView AS
SELECT 
    e.EmployeeID, 
    CONCAT(e.FirstName, ' ', e.LastName) AS FullName, 
    p.ProjectID, 
    p.ProjectName, 
    ep.AssignedDate
FROM Employees e
JOIN EmployeeProjects ep ON e.EmployeeID = ep.EmployeeID
JOIN Projects p ON ep.ProjectID = p.ProjectID;
GO

SELECT * FROM EmployeeProjectView WHERE EmployeeID = 1;
GO



CREATE PROCEDURE sp_AssignEmployeeToProject
    @empId INT, 
    @projId INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM EmployeeProjects WHERE EmployeeID = @empId AND ProjectID = @projId)
    BEGIN
    INSERT INTO EmployeeProjects (EmployeeID, ProjectID, AssignedDate) 
    
    VALUES (@empId, @projId, CAST(GETDATE() AS DATE));
    END
END;
GO

CREATE FUNCTION fn_GetProjectCount(@empId INT) 
RETURNS INT
AS
BEGIN
    DECLARE @p_count INT;
    SELECT @p_count = COUNT(*) FROM EmployeeProjects WHERE EmployeeID = @empId;
    RETURN @p_count;
END;
GO


SELECT dbo.fn_GetProjectCount(5) AS TotalProjectsForEmp5;
GO


EXEC sp_AssignEmployeeToProject @empId = 2, @projId = 3;
SELECT * FROM EmployeeProjects WHERE EmployeeID = 2 AND ProjectID = 3;

DELETE FROM EmployeeProjects WHERE EmployeeID = 3;
GO