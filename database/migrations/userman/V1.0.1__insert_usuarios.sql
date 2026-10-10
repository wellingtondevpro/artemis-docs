INSERT INTO users (username, email, password_hash) VALUES
('wellington', 'wellington@artemis.com', 'hashed_pwd_default'),
('alexandre', 'alexandre@artemis.com', 'hashed_pwd_default'),
('michael', 'michael@artemis.com', 'hashed_pwd_default'),
('hyan', 'hyan@artemis.com', 'hashed_pwd_default'),
('raquel', 'raquel@artemis.com', 'hashed_pwd_default'),
('josue', 'josue@artemis.com', 'hashed_pwd_default'),
('joaquim', 'joaquim@artemis.com', 'hashed_pwd_default'),
('guilherme', 'guilherme@artemis.com', 'hashed_pwd_default');

-- Associando todos eles ao papel de USER (role_id = 2)
INSERT INTO user_roles (user_id, role_id)
SELECT id, 2 FROM users WHERE username IN (
    'wellington', 'alexandre', 'michael', 'hyan', 'raquel', 'josue', 'joaquim', 'guilherme'
);
