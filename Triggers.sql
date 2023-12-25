-- 1) Impedir a inserção com data de admissão futura:
DELIMITER //
CREATE TRIGGER before_insert_funcionario
BEFORE INSERT
ON funcionario
FOR EACH ROW
BEGIN 
	IF NEW.data_admissao > CURDATE() THEN 
		SIGNAL SQLSTATE '45000' 
		SET MESSAGE_TEXT = 'Não é possível inserir um funcionário com data de admissão no futuro.'; 	END IF;
END //
DELIMITER ;

-- 2) Impedir a exclusão de funcionário alocado em um projeto.
DELIMITER //
CREATE TRIGGER before_delete_func_alocado_em_proj
BEFORE DELETE
ON func_alocado_em_proj
FOR EACH ROW
BEGIN
    IF OLD.acesso_permitido = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Não é possível excluir um funcionário alocado em um projeto concluído.';
    END IF;
END //
DELIMITER ;

-- 3) Atribuir cargo padrão na inserção de funcionário:
DELIMITER //
CREATE TRIGGER before_insert_funcionario
BEFORE INSERT
ON funcionario
FOR EACH ROW
BEGIN 
	IF NEW.cargo IS NULL THEN 
		SET NEW.cargo = 'Cargo Padrão'; 
	END IF;
END //
DELIMITER ;

-- 4) Atualizar contagem de projetos por funcionário:
DELIMITER //
CREATE TRIGGER after_insert_func_alocado_em_proj
AFTER INSERT
ON func_alocado_em_proj
FOR EACH ROW
BEGIN 
	UPDATE funcionario 
	SET quantidade_projetos = quantidade_projetos + 1 
	WHERE codigo_funcionario = NEW.codigo_funcionario;
END //
DELIMITER ;

-- 5) Restringir acesso ao concluir projeto:
DELIMITER //
CREATE TRIGGER after_update_projeto
AFTER UPDATE
ON projeto
FOR EACH ROW
BEGIN 
	IF NEW.status_projeto = 'Concluído' THEN 
		UPDATE func_alocado_em_proj 
		SET acesso_permitido = 0 
		WHERE codigo_projeto = NEW.codigo_projeto; 
	END IF;
END //
DELIMITER ;

-- 6) Manter versão anterior de informações pessoais:
DELIMITER //
CREATE TRIGGER after_update_info_pessoais_funcionario
AFTER UPDATE
ON info_pessoais_funcionario
FOR EACH ROW
BEGIN 
	INSERT INTO historico_info_pessoais_funcionario (cpf, nome, tel_celular, tel_residencial, email_pessoal, data_modificacao) 
	VALUES (OLD.cpf, OLD.nome, OLD.tel_celular, OLD.tel_residencial, OLD.email_pessoal, NOW());
END //
DELIMITER ;

-- 7) Atribuição do status de "Inativo" a funcionários sem alocações em projetos.
DELIMITER //
CREATE TRIGGER after_insert_funcionario
AFTER INSERT
ON funcionario
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM func_alocado_em_proj WHERE codigo_funcionario = NEW.codigo_funcionario) THEN
        UPDATE funcionario
        SET status_funcionario = 0
        WHERE codigo_funcionario = NEW.codigo_funcionario;
    END IF;
END //
DELIMITER ;

-- 8) Impedir a exclusão de departamento com funcionários alocados.
DELIMITER //
CREATE TRIGGER before_delete_departamento
BEFORE DELETE
ON departamento
FOR EACH ROW
BEGIN
    DECLARE qtd_funcionarios INT;
    SELECT COUNT(*) INTO qtd_funcionarios FROM funcionario WHERE codigo_depto_funcionario = OLD.codigo_depto;
    IF qtd_funcionarios > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Não é possível excluir um departamento com funcionários alocados.';
    END IF;
END //
DELIMITER ;

-- 9) Impedir a atualização do CPF do funcionário.
DELIMITER //
CREATE TRIGGER before_update_cpf_funcionario
BEFORE UPDATE
ON info_pessoais_funcionario
FOR EACH ROW
BEGIN
    IF NEW.cpf <> OLD.cpf THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Não é permitido atualizar o CPF de um funcionário.';
    END IF;
END //
DELIMITER ;
