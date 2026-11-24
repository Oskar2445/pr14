-- Практика 14. Створення та відкат транзакцій у SQLite
-- Варіант 1: база бібліотеки (books, readers, loans).
-- Скрипт розрахований на lab_work_13.db і демонструє кожну транзакцію послідовно.
-- Структура таблиць не змінюється.
PRAGMA foreign_keys = ON;

-- =========================================================
-- Завдання 1. Атомарна пара INSERT + UPDATE
-- Додаємо позику книги №1 читачеві №2 і зменшуємо кількість
-- доступних примірників цієї книги. Обидві зміни пов'язані.
BEGIN;
INSERT INTO loans (id, book_id, reader_id, loan_date, return_date)
VALUES (9, 1, 2, '2026-11-24', NULL);

UPDATE books
SET copies_count = copies_count - 1
WHERE id = 1;

COMMIT;

-- Перевірка: нова позика існує, кількість примірників стала 5.
SELECT l.id, l.book_id, b.title, l.reader_id, l.loan_date, b.copies_count
FROM loans AS l
JOIN books AS b ON b.id = l.book_id
WHERE l.id = 9;
-- Очікуваний результат: 9 | 1 | Тигролови | 2 | 2026-11-24 | 5


-- =========================================================
-- Завдання 2. Свідомий ROLLBACK
-- Тимчасово збільшуємо кількість примірників книги №2 на 10,
-- але скасовуємо зміну.
BEGIN;
UPDATE books
SET copies_count = copies_count + 10
WHERE id = 2;

SELECT id, title, copies_count
FROM books
WHERE id = 2;
-- Усередині транзакції очікується copies_count = 14.

ROLLBACK;

SELECT id, title, copies_count
FROM books
WHERE id = 2;
-- Після ROLLBACK очікується початкове copies_count = 4.


-- =========================================================
-- Завдання 3. Проміжний стан усередині транзакції
-- Вставлений рядок видно в цій самій сесії ще до COMMIT.
BEGIN;
INSERT INTO loans (id, book_id, reader_id, loan_date, return_date)
VALUES (11, 3, 1, '2026-11-25', NULL);

SELECT id, book_id, loan_date
FROM loans
WHERE id = 11;
-- Очікуваний результат до COMMIT: 11 | 3 | 2026-11-25

ROLLBACK;

SELECT id, book_id, loan_date
FROM loans
WHERE id = 11;
-- Після ROLLBACK рядків немає.


-- =========================================================
-- Завдання 4. Свідома помилка всередині транзакції
-- Перша вставка успішна. Друга порушує PRIMARY KEY (id=12).
-- SQLite повідомляє: UNIQUE constraint failed: loans.id
-- Помилка другої команди сама по собі не скасовує першу.
BEGIN;
INSERT INTO loans (id, book_id, reader_id, loan_date, return_date)
VALUES (12, 4, 2, '2026-11-26', NULL);

-- НАВМИСНА ПОМИЛКА: повторне використання первинного ключа id=12.
INSERT INTO loans (id, book_id, reader_id, loan_date, return_date)
VALUES (12, 5, 3, '2026-11-27', NULL);
-- Очікуване повідомлення SQLite:
-- Error: UNIQUE constraint failed: loans.id

SELECT id, book_id, loan_date
FROM loans
WHERE id = 12;
-- Перша успішна вставка видима: 12 | 4 | 2026-11-26

ROLLBACK;

SELECT id, book_id, loan_date
FROM loans
WHERE id = 12;
-- Після ROLLBACK рядків немає.


-- =========================================================
-- Завдання 5. Забутий ROLLBACK: після помилки виконуємо COMMIT
-- Перша вставка успішна, друга з тим самим id=13 помилкова.
-- COMMIT зафіксує першу зміну, яка залишилася в транзакції.
BEGIN;
INSERT INTO loans (id, book_id, reader_id, loan_date, return_date)
VALUES (13, 6, 4, '2026-11-28', NULL);

-- НАВМИСНА ПОМИЛКА: повторне використання первинного ключа id=13.
INSERT INTO loans (id, book_id, reader_id, loan_date, return_date)
VALUES (13, 7, 5, '2026-11-29', NULL);
-- Очікуване повідомлення SQLite:
-- Error: UNIQUE constraint failed: loans.id

SELECT id, book_id, loan_date
FROM loans
WHERE id = 13;
-- Перша вставка видима всередині транзакції: 13 | 6 | 2026-11-28

-- Свідомо фіксуємо транзакцію, не відкочуючи першу успішну зміну.
COMMIT;

SELECT id, book_id, loan_date
FROM loans
WHERE id = 13;
-- Після COMMIT зберігся рядок: 13 | 6 | 2026-11-28.
-- Друга вставка не відбулася через порушення PRIMARY KEY.


-- Фінальна перевірка цілісності:
PRAGMA integrity_check;
PRAGMA foreign_key_check;
