USE secure_transact;

DROP TRIGGER IF EXISTS hash_password;
DROP TRIGGER IF EXISTS before_insert_limit_users;

CREATE TRIGGER `hash_password`
BEFORE INSERT ON `users` FOR EACH ROW
BEGIN
    SET NEW.salt = SUBSTRING(MD5(RAND()), 1, 32);
    SET NEW.password = SHA2(CONCAT(NEW.password, NEW.salt), 224);
END;

--prevent spamming on users table from default user
CREATE TRIGGER `before_insert_limit_users`
BEFORE INSERT ON `users`
FOR EACH ROW
BEGIN
    DECLARE user_count INT;

    SELECT COUNT(*) INTO user_count FROM users;

    IF user_count >= 5000 THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'Exceeded maximum number of users.';
    END IF;
END;
