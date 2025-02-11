-- **Step 1: Database and Schema Exploration**

-- Select the database to use
USE employees_mod;

-- List all tables in the database
SHOW TABLES;

-- View structure of the main tables
DESCRIBE t_departments;
DESCRIBE t_dept_emp;
DESCRIBE t_dept_manager;
DESCRIBE t_employees;
DESCRIBE t_salaries;

-- Preview sample data from the main tables
SELECT * FROM t_employees LIMIT 10;
SELECT * FROM t_dept_emp LIMIT 10;
SELECT * FROM t_dept_manager LIMIT 10;
SELECT * FROM t_departments LIMIT 10;
SELECT * FROM t_salaries LIMIT 10;

-- **Step 2: Exploratory Queries**

-- **Employee Distribution by Gender**
SELECT 
    gender, 
    COUNT(*) AS employee_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM t_employees), 2) AS percentage
FROM t_employees
GROUP BY gender;

-- **Count of Employees per Department**
SELECT 
    d.dept_name AS department_name,
    COUNT(de.emp_no) AS employee_count
FROM t_departments d
JOIN t_dept_emp de ON d.dept_no = de.dept_no
GROUP BY d.dept_name
ORDER BY employee_count DESC;

-- **Salary Range and Average per Department**
SELECT 
    d.dept_name AS department_name,
    MIN(s.salary) AS min_salary,
    MAX(s.salary) AS max_salary,
    ROUND(AVG(s.salary), 2) AS avg_salary
FROM t_salaries s
JOIN t_dept_emp de ON s.emp_no = de.emp_no
JOIN t_departments d ON de.dept_no = d.dept_no
GROUP BY d.dept_name
ORDER BY avg_salary DESC;

-- **Length of Salary Contracts**
SELECT 
    emp_no, 
    DATEDIFF(to_date, from_date) AS contract_days
FROM t_salaries
WHERE to_date != '9999-01-01'
ORDER BY contract_days DESC
LIMIT 10;

-- **Hiring Trends Over Time**
SELECT 
    YEAR(hire_date) AS hire_year, 
    COUNT(*) AS hires,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM t_employees), 2) AS percentage
FROM t_employees
GROUP BY hire_year
ORDER BY hire_year ASC;

-- **Average Salary by Gender and Department**
SELECT 
    d.dept_name AS department_name,
    e.gender,
    ROUND(AVG(s.salary), 2) AS avg_salary
FROM t_salaries s
JOIN t_dept_emp de ON s.emp_no = de.emp_no
JOIN t_departments d ON de.dept_no = d.dept_no
JOIN t_employees e ON s.emp_no = e.emp_no
GROUP BY d.dept_name, e.gender
ORDER BY d.dept_name, e.gender;

-- **Employees Hired in the Year 2000**
SELECT 
    emp_no, 
    CONCAT(first_name, ' ', last_name) AS full_name,
    hire_date
FROM t_employees
WHERE YEAR(hire_date) = 2000
ORDER BY hire_date ASC;

-- **Step 3: Stored Procedure**

-- **Procedure to Retrieve Last Department**
DELIMITER $$

CREATE PROCEDURE GetLastDepartment(emp_no INT)
BEGIN
    SELECT 
        emp_no, 
        de.dept_no AS department_id, 
        d.dept_name AS department_name
    FROM t_dept_emp de
    JOIN t_departments d ON de.dept_no = d.dept_no
    WHERE de.emp_no = emp_no
    ORDER BY de.to_date DESC
    LIMIT 1;
END$$

DELIMITER ;

CALL GetLastDepartment(10010);

-- **Step 4: Trigger**

-- **Trigger to Validate Hire Date**
DELIMITER $$

CREATE TRIGGER validate_hire_date
BEFORE INSERT ON t_employees
FOR EACH ROW
BEGIN
    IF NEW.hire_date > CURDATE() THEN
        SET NEW.hire_date = CURDATE();
    END IF;
END$$

DELIMITER ;

-- **Step 5: Window Functions**

-- **Query for Salary Rankings by Employee**
SELECT 
    emp_no,
    salary,
    DENSE_RANK() OVER (PARTITION BY emp_no ORDER BY salary DESC) AS rank_num
FROM t_salaries
WHERE emp_no = 10680;

-- **Compare Previous and Next Salaries**
SELECT 
    emp_no,
    salary,
    LAG(salary) OVER (PARTITION BY emp_no ORDER BY salary) AS previous_salary,
    LEAD(salary) OVER (PARTITION BY emp_no ORDER BY salary) AS next_salary,
    salary - LAG(salary) OVER (PARTITION BY emp_no ORDER BY salary) AS diff_salary_current_previous,
    LEAD(salary) OVER (PARTITION BY emp_no ORDER BY salary) - salary AS diff_salary_next_current
FROM t_salaries
WHERE salary > 90000 AND emp_no BETWEEN 10800 AND 11600;

-- **Step 6: CTE Query**

-- **Male Employees with Max Salaries Below Average**
WITH avg_salary_cte AS (
    SELECT AVG(salary) AS avg_salary FROM t_salaries
),
max_salary_cte AS (
    SELECT 
        s.emp_no, 
        MAX(s.salary) AS max_salary
    FROM t_salaries s
    JOIN t_employees e ON s.emp_no = e.emp_no AND e.gender = 'M'
    GROUP BY s.emp_no
)
SELECT 
    COUNT(*) AS count_below_avg
FROM max_salary_cte m
CROSS JOIN avg_salary_cte a
WHERE m.max_salary < a.avg_salary;
