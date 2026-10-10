-- Carga de dados (Idempotente via PL/pgSQL)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM funcionarios WHERE nome = 'Wellington') THEN
        INSERT INTO funcionarios (nome, cargo, salario) VALUES ('Wellington', 'Desenvolvedor Pleno', 7500.00);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM funcionarios WHERE nome = 'Maria Silva') THEN
        INSERT INTO funcionarios (nome, cargo, salario) VALUES ('Maria Silva', 'Gerente de Projetos', 12000.00);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM funcionarios WHERE nome = 'João Souza') THEN
        INSERT INTO funcionarios (nome, cargo, salario) VALUES ('João Souza', 'Analista de Sistemas', 5500.00);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM funcionarios WHERE nome = 'Ana Costa') THEN
        INSERT INTO funcionarios (nome, cargo, salario) VALUES ('Ana Costa', 'Desenvolvedor Junior', 4000.00);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM funcionarios WHERE nome = 'Pedro Santos') THEN
        INSERT INTO funcionarios (nome, cargo, salario) VALUES ('Pedro Santos', 'Diretor de TI', 25000.00);
    END IF;
END $$;
