-- 1. Вывести к каждому самолету класс обслуживания и количество мест этого класса
SELECT aircraft_code, fare_conditions, count(seat_no)
FROM bookings.seats
GROUP BY aircraft_code, fare_conditions
ORDER BY aircraft_code;

-- 2. Найти 3 самых вместительных самолета (модель + кол-во мест)
SELECT seats.aircraft_code, model, count(seat_no)
FROM bookings.seats
         FULL JOIN aircrafts_data ON
    seats.aircraft_code = aircrafts_data.aircraft_code
GROUP BY seats.aircraft_code, model
ORDER BY count(seat_no) DESC
LIMIT 3;

--3. Найти все рейсы, которые задерживались более 2 часов (800)
SELECT *
FROM flights
WHERE (actual_departure - scheduled_departure) > '02:00:00';

--4.Найти последние 10 билетов, купленные в бизнес-классе
-- (fare_conditions = 'Business'), с указанием имени пассажира
-- и контактных данных

SELECT tickets.passenger_name, book_date, fare_conditions, contact_data
FROM tickets
         FULL JOIN ticket_flights tf
                   on tickets.ticket_no = tf.ticket_no
         JOIN bookings b on tickets.book_ref = b.book_ref
WHERE fare_conditions = 'Business'
ORDER BY book_date DESC
LIMIT 10;

--5. Найти все рейсы, у которых нет забронированных мест
-- в бизнес-классе (fare_conditions = 'Business')

SELECT *
FROM bookings.flights f
         LEFT JOIN bookings.seats s
                   ON f.aircraft_code = s.aircraft_code
WHERE s.seat_no IS NULL
  AND s.fare_conditions = 'Business';


--6. Получить список аэропортов (airport_name) и городов (city)
-- , в которых есть рейсы с задержкой по вылету
SELECT airport_name, city
FROM airports_data
         JOIN flights f
              on airports_data.airport_code = f.departure_airport
WHERE (actual_departure - scheduled_departure) > '00:00:00'
GROUP BY airport_name, city;

--7. Получить список аэропортов (airport_name) и количество рейсов,
-- вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов
SELECT airport_name, count(flight_id) AS amount
FROM airports_data
         JOIN flights f
              ON airports_data.airport_code = f.departure_airport
GROUP BY airport_name
ORDER BY amount;

--8. Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival)
-- было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным
SELECT *
FROM bookings.flights
WHERE actual_arrival IS NOT NULL;

--9.Вывести код, модель самолета и места не эконом класса для самолета
-- "Аэробус A321-200" с сортировкой по местам
SELECT s.aircraft_code, model, seat_no
FROM bookings.aircrafts_data ad
         INNER JOIN seats s ON ad.aircraft_code = s.aircraft_code
WHERE fare_conditions != 'Economy'
  AND model::text LIKE '%A321-200%'
ORDER BY seat_no;


--10.Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
SELECT city
FROM bookings.airports_data
GROUP BY city
HAVING count(city) > 1;

--11.Найти пассажиров, у которых суммарная стоимость бронирований
-- превышает среднюю сумму всех бронирований:
SELECT t.passenger_id,
       SUM(tf.amount) AS total_booking_value
FROM bookings.tickets t
         JOIN bookings.ticket_flights tf
              ON t.ticket_no = tf.ticket_no
GROUP BY t.passenger_id
HAVING SUM(tf.amount) > (SELECT AVG(amount)
                         FROM bookings.ticket_flights)
ORDER BY total_booking_value;

--12. Найти ближайший вылетающий рейс из Екатеринбурга в Москву,
-- на который еще не завершилась регистрация

SELECT *
FROM bookings.flights
WHERE arrival_airport IN ('SVO', 'DME', 'VKO')
  AND departure_airport = 'SVX'
  AND status = 'On Time'
ORDER BY scheduled_departure DESC
LIMIT 1;

--13 Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
SELECT *
FROM (select ticket_no,
             amount,
             ROW_NUMBER() OVER (ORDER BY amount )     AS min_rank,
             ROW_NUMBER() OVER (ORDER BY amount DESC) AS max_rank
      FROM bookings.ticket_flights) as tf
WHERE min_rank = 1
   OR max_rank = 1;


SELECT *
FROM ticket_flights
WHERE ticket_flights.amount = ANY (SELECT MIN(amount)
                                   FROM bookings.ticket_flights)
   OR ticket_flights.amount = ANY (SELECT MAX(amount)
                                   FROM bookings.ticket_flights);

--14 Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone.
-- Добавить ограничения на поля (constraints)
CREATE TABLE bookings.Customers
(
    id        SERIAL PRIMARY KEY,
    firstName VARCHAR(50)         NOT NULL,
    lastName  VARCHAR(50)         NOT NULL,
    email     VARCHAR(100) UNIQUE NOT NULL,
    phone     VARCHAR(15)         NOT NULL
);

--15. Написать DDL таблицы Orders, должен быть id, customerId, quantity.
-- Должен быть внешний ключ на таблицу customers + constraints
CREATE TABLE bookings.Orders
(
    id         SERIAL PRIMARY KEY,
    customerId INTEGER REFERENCES Customers (id),
    quantity   INTEGER NOT NULL
);

--16 Написать 5 insert в эти таблицы
INSERT INTO bookings.Customers (firstName, lastName, email, phone)
VALUES ('Иван', 'Иванов', 'ivan@example.com', '123-456-7890'),
       ('Мария', 'Петрова', 'maria@example.com', '987-654-3210'),
       ('Алексей', 'Сидоров', 'alex@example.com', '555-123-4567'),
       ('Елена', 'Козлова', 'elena@example.com', '333-999-8888'),
       ('Петр', 'Николаев', 'peter@example.com', '777-444-5555');


INSERT INTO bookings.Orders (customerId, quantity)
VALUES (1, 3),
       (2, 5),
       (3, 2),
       (4, 4),
       (5, 1);

--17 Удалить таблицы
DROP TABLE  bookings.Orders;
DROP TABLE  bookings.Customers;

















