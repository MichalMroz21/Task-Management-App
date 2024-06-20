USE secure_transact;

DROP PROCEDURE IF EXISTS insert_user;

DROP FUNCTION IF EXISTS get_id_with_login;
DROP FUNCTION IF EXISTS validate_credentials;

DROP PROCEDURE IF EXISTS get_user_data;
DROP PROCEDURE IF EXISTS update_user_description;
DROP PROCEDURE IF EXISTS update_profile_img;

DROP TABLE IF EXISTS temp_ingredients;

CREATE PROCEDURE insert_user(IN in_login VARCHAR(20), IN in_password VARCHAR(20), IN in_date DATE)
BEGIN
    DECLARE user_id INT;

    SET in_login = LOWER(in_login);

    IF CHAR_LENGTH(in_login) < 5 OR CHAR_LENGTH(in_password) < 5 THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'Login or password is shorter than 5 characters.';
    END IF;

    IF NOT in_login REGEXP '^[A-Za-z0-9]+$' THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'Login must only contain letters or numbers.';
    END IF;

    IF NOT in_password REGEXP '^[0-9a-zA-Z!@#$%^&*()-_+=<>?/]+$' THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'Password contains not allowed characters.';
    END IF;

    SELECT get_id_with_login(in_login) INTO user_id;

    IF user_id <> -1 THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'User with this login already exists.';      
    END IF;

    INSERT INTO users (login, password, join_date) VALUES (in_login, in_password, in_date);
END;


CREATE FUNCTION get_id_with_login(in_login VARCHAR(20)) RETURNS INT
BEGIN
    DECLARE out_id INT;

    SET in_login = LOWER(in_login);
    SET out_id = (-1);

    SELECT U.id INTO out_id FROM users AS U WHERE in_login = U.login LIMIT 1;
    RETURN out_id;
END;


CREATE FUNCTION validate_credentials(in_login VARCHAR(20), in_password VARCHAR(20)) RETURNS BOOLEAN
BEGIN
    DECLARE hashedPassword VARCHAR(224);
    DECLARE result_salt VARCHAR(32);
    DECLARE user_id INT;
    DECLARE user_exists BOOLEAN;
    DECLARE out_is_valid BOOLEAN;

    SET out_is_valid = FALSE;
    SET in_login = LOWER(in_login);

    SELECT get_id_with_login(in_login) INTO user_id;

    IF user_id = -1 THEN
        SET out_is_valid = FALSE;
        SIGNAL SQLSTATE '45000' SET message_text = 'Invalid login or password.';
    END IF;

    SELECT U.salt INTO result_salt FROM users AS U WHERE user_id = U.id LIMIT 1;

    SET hashedPassword = SHA2(CONCAT(in_password, result_salt), 224);
    SET user_exists = FALSE;

    SELECT 1 INTO user_exists FROM Users AS U WHERE U.login = in_login AND U.password = hashedPassword LIMIT 1;

    IF user_exists THEN
        SET out_is_valid = TRUE;
    ELSE
        SET out_is_valid = FALSE;
        SIGNAL SQLSTATE '45000' SET message_text = 'Invalid login or password.';
    END IF;

    RETURN out_is_valid;
END;

CREATE PROCEDURE update_profile_img(IN in_login VARCHAR(20), IN in_password VARCHAR(20), IN in_img LONGBLOB)
BEGIN

    DECLARE valid_cred BOOLEAN;
    DECLARE user_id INT;

    SELECT get_id_with_login(in_login) INTO user_id;
    SELECT validate_credentials(in_login, in_password) INTO valid_cred;

    IF user_id = -1 THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'Cannot find user with given login.';
    END IF;

    IF NOT valid_cred THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'Invalid login or password.';
    END IF;

    UPDATE users
    SET profile_img = in_img
    WHERE id = user_id;

END;

CREATE PROCEDURE update_user_description(IN in_description VARCHAR(250), IN in_login VARCHAR(20), IN in_password VARCHAR(20))
BEGIN

    DECLARE valid_cred BOOLEAN;
    DECLARE user_id INT;

    SELECT get_id_with_login(in_login) INTO user_id;
    SELECT validate_credentials(in_login, in_password) INTO valid_cred;

    IF user_id = -1 THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'Cannot find user with given login.';
    END IF;

    IF NOT valid_cred THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'Invalid login or password.';
    END IF;

    UPDATE users
    SET description = in_description
    WHERE id = user_id;

END;


CREATE PROCEDURE get_user_data(IN in_login VARCHAR(20), in_password VARCHAR(20))
BEGIN

    DECLARE user_id INT;
    DECLARE valid_cred BOOLEAN;

    SELECT get_id_with_login(in_login) INTO user_id;
    SELECT validate_credentials(in_login, in_password) INTO valid_cred;

    IF user_id = -1 THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'Cannot find user with given login.';
    END IF;

    IF NOT valid_cred THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'Invalid login or password.';
    END IF;

    SELECT * FROM users
    WHERE user_id = id;

END;


CREATE PROCEDURE search_recipes(IN in_title VARCHAR(150), IN in_ingredients VARCHAR(500), IN in_sortTitle BOOLEAN, IN in_sortIngredients BOOLEAN)
BEGIN

    DECLARE ingredient_index INT DEFAULT 1;
    DECLARE current_ingredient VARCHAR(100);

    DROP TABLE IF EXISTS temp_ingredients;
    CREATE TABLE temp_ingredients (ingredient VARCHAR(100));

    WHILE ingredient_index <= LENGTH(in_ingredients) - LENGTH(REPLACE(in_ingredients, '\n', '')) + 1 DO
        SET current_ingredient = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(in_ingredients, '\n', ingredient_index), '\n', -1));
        INSERT INTO temp_ingredients (ingredient) VALUES (current_ingredient);
        SET ingredient_index = ingredient_index + 1;
    END WHILE;


    SELECT id, title, ingredients, instructions, image_bin
    FROM recipes
    WHERE 
        (LENGTH(in_title) = 0 OR LOWER(title) LIKE CONCAT('%', LOWER(in_title), '%'))
        AND (
        LENGTH(in_ingredients) = 0
        OR (
            SELECT COUNT(*)
            FROM temp_ingredients
            WHERE recipes.ingredients LIKE CONCAT('%', LOWER(temp_ingredients.ingredient), '%')
        ) = (SELECT COUNT(*) FROM temp_ingredients)
    ) AND LENGTH(title) > 0 AND LENGTH(ingredients) > 0 AND LENGTH(instructions) > 0
    
    ORDER BY
    CASE
        WHEN in_sortTitle THEN title
        ELSE NULL
    END;

    DROP TABLE IF EXISTS temp_ingredients;
END;