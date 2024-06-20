USE secure_transact;

DROP USER IF EXISTS 'default_user'@'%';

CREATE USER 'default_user'@'%' IDENTIFIED BY 'default_user_pass';

GRANT EXECUTE ON PROCEDURE insert_user TO 'default_user'@'%';
GRANT EXECUTE ON FUNCTION get_id_with_login TO 'default_user'@'%';
GRANT EXECUTE ON FUNCTION validate_credentials TO 'default_user'@'%';
GRANT EXECUTE ON PROCEDURE get_user_data TO 'default_user'@'%';
GRANT EXECUTE ON PROCEDURE update_user_description TO 'default_user'@'%';
GRANT EXECUTE ON PROCEDURE update_profile_img TO 'default_user'@'%';